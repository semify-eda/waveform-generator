# SPDX-FileCopyrightText: © 2022 semify <office@semify-eda.com>
# SPDX-License-Identifier: Apache-2.0

import random
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
DATA_CNT = 10

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

async def configure_stim_sine(dut, wbs, en):
    await set_register(dut, wbs, 0x2, 0x0, en) # Enable

async def configure_drive_spi(dut, wbs, en=1, cnt=3, cpol=0, lsbfirst=0, dff=0, sspol=0):
    await set_register(dut, wbs, 0x3, 0x8, cnt) # Clock divider
    await set_register(dut, wbs, 0x3, 0x4, (cpol<<0) | (lsbfirst<<1) | (dff<<2) | (sspol<<4))
    await set_register(dut, wbs, 0x3, 0x0, en) # Enable SPI

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

    # Setup core
    dut._log.info("Configure core")
    await configure_core(dut, wbs, en=1, sync_count=16, subcycle_count=16)
    dut._log.info("Configure stim_sine")
    await configure_stim_sine(dut, wbs, en=1)
    dut._log.info("Configure drive_spi")
    await configure_drive_spi(dut, wbs, en=1, cnt=cnt, cpol=cpol, lsbfirst=lsbfirst, dff=dff, sspol=sspol)

    await long_time
    await short_per

    def test_func(x, a, b, c):
        return a * np.sin(b * x + c)

    params, params_covariance = optimize.curve_fit(test_func, spi_slave.time, spi_slave.values, p0=[70000, 0.00007, -0.5])
    
    print(params)
    print(spi_slave.time)
    print(spi_slave.values)
    
    # Loosely check parameters
    assert(abs(params[0] - 65532.57101443629) < 0.1)
    assert(abs(params[1] - 6.79379545e-05) < 0.0001)
    assert(abs(params[2] - -1.86659076e-01) < 0.001)

    x_data = np.asarray(spi_slave.time)
    y_data = np.asarray(spi_slave.values)
    y_calc = test_func(x_data, params[0], params[1], params[2])
    y_error = (y_data - y_calc)
    
    x_data_highres = np.linspace(x_data[0], x_data[-1], num=100)
    y_calc_highres = test_func(x_data_highres, params[0], params[1], params[2])
    
    fig, ax = plt.subplots(2, 1)
    fig.suptitle('Stimuli: Sine, Driver: SPI', fontsize=16)
    
    ax[0].scatter(x_data, y_data, label='SPI data')
    ax[0].plot(x_data_highres, y_calc_highres, label='Fitted function')
    ax[0].set(xlabel='time in ns', ylabel='value')
    ax[0].legend(loc='best')
    ax[0].grid()
    
    ax[1].set(xlabel='time in ns', ylabel='value')
    ax[1].plot(x_data, y_error, label='error = y_data - y_calc')
    ax[1].legend(loc='best')
    ax[1].grid()

    fig.savefig("output.png")
    #plt.show()

