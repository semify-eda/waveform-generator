# SPDX-FileCopyrightText: © 2022 semify <office@semify-eda.com>
# SPDX-License-Identifier: Apache-2.0

import os
import cocotb
from cocotb.clock import Clock
from cocotb.regression import TestFactory
from cocotb.triggers import Timer, RisingEdge, FallingEdge
from cocotbext.wishbone.driver import WishboneMaster, WBOp
from cocotbext.axi import AxiStreamBus, AxiStreamSource
from cocotbext.spi import SpiMaster, SpiSignals, SpiConfig, SpiSlaveBase
#from random import randbytes # Possible in Python 3.9+

CLK_PER_SYNC = 300
SYSCLK = 100000000
DATA_CNT = 10

short_per = Timer(100, units="ns")
long_time = Timer(100, units="us")

async def drive_sync(dut):
    dut.wfg_core_sync_i.value = 0
    sync_cnt = 0
    while True:
        await RisingEdge(dut.io_wbs_clk)
        if sync_cnt == CLK_PER_SYNC-1:
            sync_cnt = 0
            dut.wfg_core_sync_i.value = 1
        else:
            sync_cnt = sync_cnt + 1
            dut.wfg_core_sync_i.value = 0

async def set_register(dut, wbs, address, data):
    dut._log.info(f"Set register {address} : {data}")

    wbRes = await wbs.send_cycle([WBOp(address, data)])
    
    rvalues = [wb.datrd for wb in wbRes]
    dut._log.info(f"Returned values : {rvalues}")

async def configure(dut, wbs, en=1, cnt=3, cpol=0, lsbfirst=0, dff=0, sspol=0):
    await set_register(dut, wbs, 0x8, cnt) # Clock divider
    await set_register(dut, wbs, 0x4, (cpol<<0) | (lsbfirst<<1) | (dff<<2) | (sspol<<4))
    await set_register(dut, wbs, 0x0, en) # Enable SPI

class SimpleSpiSlave(SpiSlaveBase):
  def __init__(self, dut, signals, config):
    self._config = config
    self.content = 0
    super().__init__(signals)
    self.latest_value = None

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
    
    self.latest_value = self.content.to_bytes(self._config.word_width // 8, 'big')

@cocotb.coroutine
async def spi_test(dut, en, cnt, cpol, lsbfirst, dff, sspol):
    dut._log.info(f"Configuration: en={en}, cnt={cnt}, cpol={cpol}, lsbfirst={lsbfirst}, dff={dff}, sspol={sspol}")

    cocotb.start_soon(Clock(dut.io_wbs_clk, 1/SYSCLK*1e9, units="ns").start())
    cocotb.fork(drive_sync(dut))

    dut._log.info("Initialize and reset model")

    # Start reset
    dut.io_wbs_rst.value = 1
    dut.wfg_axis_tdata.value = 0x00000000
    dut.wfg_axis_tlast.value = 0
    dut.wfg_axis_tvalid.value = 1
    
    await Timer(100, units='ns')

    # Stop reset
    dut.io_wbs_rst.value = 0

    # Wishbone Master
    wbs = WishboneMaster(dut, "io_wbs", dut.io_wbs_clk,
                              width=32,   # size of data bus
                              timeout=10) # in clock cycle number

    # Setup as SPI Master
    await configure(dut, wbs,  en=en, cnt=cnt, cpol=cpol, lsbfirst=lsbfirst, dff=dff, sspol=sspol)

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

    await short_per
    await short_per
    
    #await RisingEdge(dut.wfg_core_sync_i)

    axis_source = AxiStreamSource(AxiStreamBus.from_prefix(dut, "wfg_axis"), dut.io_wbs_clk, dut.io_wbs_rst)

    for i in range(DATA_CNT):
    
        random_bytes = os.getrandom(dff + 1, os.GRND_NONBLOCK) 
        #random_bytes = randbytes(dff + 1) # Possible in Python 3.9+
        
        dut._log.info("Sending data: 0x{}".format(random_bytes.hex()))
        
        await axis_source.send([int.from_bytes(random_bytes, "big")])
        # wait for operation to complete
        await axis_source.wait()

        await RisingEdge(dut.wfg_core_sync_i)

        await short_per
        
        dut._log.info("SPI received: 0x{}".format(spi_slave.latest_value.hex()))
        
        assert random_bytes == spi_slave.latest_value
       
    
    await short_per

factory = TestFactory(spi_test)
factory.add_option("en", [1])
factory.add_option("cnt", [3])
factory.add_option("cpol", [0, 1])
factory.add_option("lsbfirst", [0, 1])
factory.add_option("dff", [0,1,2,3])
factory.add_option("sspol", [0, 1])

factory.generate_tests()
