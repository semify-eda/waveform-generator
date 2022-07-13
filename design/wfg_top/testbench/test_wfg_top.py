# SPDX-FileCopyrightText: © 2022 semify <office@semify-eda.com>
# SPDX-License-Identifier: Apache-2.0

import random, math, statistics
import matplotlib.pyplot as plt
from scipy import optimize
import numpy as np
import cocotb
from cocotb.utils import get_sim_time
from cocotb.clock import Clock
from cocotb.regression import TestFactory
from cocotb.triggers import Timer, RisingEdge, FallingEdge, ClockCycles
from cocotbext.wishbone.driver import WishboneMaster
from cocotbext.wishbone.driver import WBOp
from cocotbext.spi import SpiMaster, SpiSignals, SpiConfig, SpiSlaveBase

CLK_PER_SYNC = 300
SYSCLK = 100000000

short_per = Timer(100, units="ns")
long_time = Timer(100, units="us")

class SimpleSpiSlave(SpiSlaveBase):
    def __init__(self, dut, signals, config):
        self._config = config
        self.content = 0
        super().__init__(signals)
        self.latest_value = None
        self.time = []
        self.values = []

    async def get_content(self):
        await self.idle.wait()
        return self.content

    async def _transaction(self, frame_start, frame_end):
        await frame_start
        self.content = int(await self._shift(self._config.word_width, tx_word=None))
        await frame_end
    
        # For now we have to mirror the bits ourselves
        if not self._config.msb_first:
            mirrored = 0
            bit_length = self._config.word_width
            for bit_pos in range(bit_length):
                mirrored |= ((self.content & 1<<(bit_pos)) > 0) << (bit_length-1-bit_pos)
            self.content = mirrored
        
        # Sign extend
        if self.content & (1<<17):
            self.content |= ((1<<14)-1)<<18
        
        self.latest_value = self.content.to_bytes(self._config.word_width // 8, 'big')
        
        self.latest_value = int.from_bytes(self.latest_value, 'big', signed=True)
        
        self.values.append(self.latest_value)
        self.time.append(get_sim_time('ns'))

async def set_register(dut, wbs, peripheral_address, address, data):
    if address > 0xF:
        dut._log.error("Can not access peripheral registers outside 0xF")

    real_address = (peripheral_address<<4) | (address & 0xF)
    dut._log.info(f"Set register {real_address} : {data}")

    wbRes = await wbs.send_cycle([WBOp(real_address, data)])
    rvalues = [wb.datrd for wb in wbRes]
    dut._log.info(f"Returned values : {rvalues}")

async def configure_core(dut, wbs, en, sync_count, subcycle_count):
    await set_register(dut, wbs, 0x1, 0x4, (sync_count << 0) | (subcycle_count << 8))
    await set_register(dut, wbs, 0x1, 0x0, en) # Enable

async def configure_subcore(dut, wbs, en, sync_count, subcycle_count):
    await set_register(dut, wbs, 0x2, 0x4, (sync_count << 0) | (subcycle_count << 8))
    await set_register(dut, wbs, 0x2, 0x0, en) # Enable

async def configure_interconnect(dut, wbs, en=1, driver0=0, driver1=1):
    await set_register(dut, wbs, 0x3, 0x4, driver0)
    await set_register(dut, wbs, 0x3, 0x8, driver1)
    await set_register(dut, wbs, 0x3, 0x0, en) # Enable

async def configure_stim_sine(dut, wbs, en, inc=0x1000, gain=0x4000, offset=0):
    await set_register(dut, wbs, 0x4, 0x4, inc)
    await set_register(dut, wbs, 0x4, 0x8, gain)
    await set_register(dut, wbs, 0x4, 0xC, offset)
    await set_register(dut, wbs, 0x4, 0x0, en) # Enable

async def configure_stim_mem(dut, wbs, en, start=0x0000, end=0x00FF, inc=0x01, gain=0x0001):
    await set_register(dut, wbs, 0x5, 0x4, start)
    await set_register(dut, wbs, 0x5, 0x8, end)
    await set_register(dut, wbs, 0x5, 0xC, gain<<8 | inc)
    await set_register(dut, wbs, 0x5, 0x0, en) # Enable

async def configure_drive_spi(dut, wbs, en=1, core_sel=0, cnt=3, cpol=0, lsbfirst=0, dff=0, sspol=0):
    await set_register(dut, wbs, 0x6, 0x8, cnt) # Clock divider
    await set_register(dut, wbs, 0x6, 0x4, (cpol<<0) | (lsbfirst<<1) | (dff<<2) | (sspol<<4) | (core_sel<<5))
    await set_register(dut, wbs, 0x6, 0x0, en) # Enable SPI

async def configure_drive_pat(dut, wbs, en=0xFFFFFFFF, core_sel=0, pat=0, begin=0, end=8):
    await set_register(dut, wbs, 0x7, 0x4, (begin & 0xFF) | ((end & 0xFF)<<8) | (core_sel<<16))
    await set_register(dut, wbs, 0x7, 0x8, pat[0])
    await set_register(dut, wbs, 0x7, 0xC, pat[1])
    await set_register(dut, wbs, 0x7, 0x0, en) # Enable PAT

async def checkPattern(dut, start, end, inc, gain):

    cur_address = start

    while 1:
        await FallingEdge(dut.wfg_drive_spi_cs_no)
        await FallingEdge(dut.io_wbs_clk)
        value = dut.wfg_drive_pat_dout_o.value
        
        dut._log.info(f"Test: {cur_address} == {value}")
        
        assert(cur_address*gain == value)
        
        cur_address += inc
        
        if (cur_address > end):
            cur_address = start

@cocotb.test()
async def top_test(dut):
    cocotb.start_soon(Clock(dut.io_wbs_clk, 1/SYSCLK*1e9, units="ns").start())

    dut._log.info("Initialize and reset model")

    # Start reset
    dut.io_wbs_rst.value = 1    
    await Timer(100, units='ns')

    # Stop reset
    dut.io_wbs_rst.value = 0

    # Wishbone Master
    wbs = WishboneMaster(dut, "io_wbs", dut.io_wbs_clk,
                              width=32,   # size of data bus
                              timeout=10) # in clock cycle number
    # SPI settings
    dff = 3
    cnt = 3
    cpol = 0
    cpha = 0
    lsbfirst = 0
    sspol = 0

    # Create SPI Slave
    spi_signals = SpiSignals(
        sclk = dut.wfg_drive_spi_sclk_o,
        mosi = dut.wfg_drive_spi_sdo_o,
        miso = dut.wfg_drive_spi_sdi_i,
        cs   = dut.wfg_drive_spi_cs_no,
        cs_active_low = not sspol
    )
    
    spi_config = SpiConfig(
        word_width          = (8 * (dff + 1)),          # number of bits in a SPI transaction
        sclk_freq           = SYSCLK/((cnt + 1) * 2),   # clock rate in Hz
        cpol                = cpol,                     # clock idle polarity
        cpha                = False,                     # clock phase (CPHA=True means sample on FallingEdge)
        msb_first           = not lsbfirst,             # the order that bits are clocked onto the wire
        data_output_idle    = 1,                        # the idle value of the MOSI or MISO line 
        frame_spacing_ns    = 1                         # the spacing between frames that the master waits for or the slave obeys
                                                        #       the slave should raise SpiFrameError if this is not obeyed.
    )
    
    spi_slave = SimpleSpiSlave(dut, spi_signals, spi_config)
    
    # Sine settings
    sine_inc = 0x1000
    sine_gain = 0x4000
    sine_offset = 0
    
    num_spi_values = int((2**16) / sine_inc + 1)

    # Setup core
    dut._log.info("Configure core")
    await configure_core(dut, wbs, en=1, sync_count=16, subcycle_count=16)
    dut._log.info("Configure subcore")
    await configure_subcore(dut, wbs, en=1, sync_count=32, subcycle_count=16)
    dut._log.info("Configure interconnect")
    await configure_interconnect(dut, wbs, en=1, driver0=0, driver1=1)
    dut._log.info("Configure stim_sine")
    await configure_stim_sine(dut, wbs, en=1, inc=sine_inc, gain=sine_gain, offset=sine_offset)
    dut._log.info("Configure stim_mem")
    await configure_stim_mem(dut, wbs, en=1, start=0x0000, end=0x000F, inc=0x01, gain=0x0001)
    dut._log.info("Configure drive_spi")
    await configure_drive_spi(dut, wbs, en=1, core_sel=0, cnt=cnt, cpol=cpol, lsbfirst=lsbfirst, dff=dff, sspol=sspol)
    dut._log.info("Configure drive_pat")
    pat = [0xFFFFFFFF, 0xFFFFFFFF]
    await configure_drive_pat(dut, wbs, en=0xFFFFFFFF, core_sel=0, pat=pat, begin=0, end=8)

    # Check pattern
    cocotb.start_soon(checkPattern(dut, start=0x0000, end=0x000F, inc=0x01, gain=0x0001))

    while len(spi_slave.values) < num_spi_values:
        await short_per

    def test_func(x, a, b, c):
        return a * np.sin(b * x + c)

    params, params_covariance = optimize.curve_fit(test_func, spi_slave.time, spi_slave.values, p0=[70000, 0.00007, -0.5])
    
    dut._log.info(params)
    dut._log.info(spi_slave.time)
    dut._log.info(spi_slave.values)

    x_data = np.asarray(spi_slave.time)
    y_data = np.asarray(spi_slave.values)
    
    #y_calc = test_func(x_data, params[0], params[1], params[2])
    
    y_error = []
    y_squared_error = []
    y_absolute_error = []
    y_data_float = []
    
    for (cnt, value) in enumerate(y_data):
        input_val = cnt * sine_inc
        while input_val >= (2**16):
            input_val -= (2**16)
    
        angle_rad = float(input_val) / (2**16) * 2 * math.pi
        calculated_value = math.sin(angle_rad) * (sine_gain / 2**14) + (sine_offset/2**16)
        output_as_float = float(value) / (2**16)
        y_data_float.append(output_as_float)
        y_error.append(output_as_float - calculated_value)
        y_squared_error.append((output_as_float - calculated_value)**2)
        y_absolute_error.append(abs(output_as_float - calculated_value))
    
    y_mean_squared_error = statistics.mean(y_squared_error)
    dut._log.info("y_mean_squared_error: {}".format(y_mean_squared_error))
    
    y_mean_absolute_error = statistics.mean(y_absolute_error)
    dut._log.info("y_mean_absolute_error: {}".format(y_mean_absolute_error))

    x_data_highres = np.linspace(x_data[0], x_data[-1], num=100)
    y_calc_highres = test_func(x_data_highres, params[0], params[1], params[2])
    

    
    fig, ax = plt.subplots(2, 1)
    fig.suptitle('Stimulus: Sine wave generator, Driver: SPI module', fontsize=24)
    
    ax[0].scatter(x_data, y_data_float, label='SPI data represented as float')
    #ax[0].plot(x_data_highres, y_calc_highres, label='Fitted function')
    ax[0].set(xlabel='time in ns', ylabel='Value')
    ax[0].legend(loc='best')
    ax[0].grid()
    
    ax[1].set(xlabel='time in ns', ylabel='Error')
    ax[1].plot(x_data, y_error, label='error = y_data - y_calc')
    ax[1].legend(loc='best')
    ax[1].grid()

    figure = plt.gcf()
    figure.set_size_inches(10, 6)
    plt.tight_layout()
    fig.savefig("output_inc={}_gain={}_off={}.svg".format(sine_inc, sine_gain, sine_offset))
    fig.savefig("output_inc={}_gain={}_off={}.png".format(sine_inc, sine_gain, sine_offset), dpi=199)
    #plt.show()
    
    assert(y_mean_absolute_error < 0.001)
