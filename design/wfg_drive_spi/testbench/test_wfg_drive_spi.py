# SPDX-FileCopyrightText: © 2022 semify <office@semify-eda.com>
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, FallingEdge
from cocotbext.wishbone.driver import WishboneMaster
from cocotbext.wishbone.driver import WBOp
from cocotbext.axi import AxiStreamBus, AxiStreamSource

CLK_PER_SYNC = 300

short_per = Timer(100, units="ns")
long_time = Timer(100, units="us")

async def drive_sync(dut):
    dut.wfg_pat_sync_i.value = 0
    sync_cnt = 0
    while True:
        await RisingEdge(dut.io_wbs_clk)
        if sync_cnt == CLK_PER_SYNC-1:
            sync_cnt = 0
            dut.wfg_pat_sync_i.value = 1
        else:
            sync_cnt = sync_cnt + 1
            dut.wfg_pat_sync_i.value = 0

async def configure(dut, wbs, en, cnt, cpha, cpol, lsbfirst, dff, sspol):
    # read at address 2,3,0,1
    wbRes = await wbs.send_cycle([WBOp(0x10), WBOp(0x18), WBOp(0x1C), WBOp(0x20), WBOp(0xFF8), WBOp(0xFFC)])

    rvalues = [wb.datrd for wb in wbRes]
    dut._log.info(f"Returned values : {rvalues}")
    
    await short_per

    # activate wfg_stim_sine
    wbRes = await wbs.send_cycle([WBOp(0x10, 1)])
    
    rvalues = [wb.datrd for wb in wbRes]
    dut._log.info(f"Returned values : {rvalues}")

@cocotb.test()
async def my_first_test(dut):
    cocotb.start_soon(Clock(dut.io_wbs_clk, 10, units="ns").start())
    cocotb.fork(drive_sync(dut))

    dut._log.info("Initialize and reset model")

    dut.io_wbs_rst.value = 1
    dut.wfg_drive_spi_axis_tdata.value = 0xDEADBEEF
    dut.wfg_drive_spi_axis_tlast.value = 0
    dut.wfg_drive_spi_axis_tvalid.value = 1
    
    await Timer(100, units='ns')

    dut.io_wbs_rst.value = 0

    wbs = WishboneMaster(dut, "io_wbs", dut.io_wbs_clk,
                              width=32,   # size of data bus
                              timeout=10) # in clock cycle number

    await configure(dut, wbs, en=True, cnt=3, cpha=False, cpol=True, lsbfirst=True, dff=0, sspol=True)

    await short_per
    await short_per
    
    await RisingEdge(dut.wfg_pat_sync_i)

    axis_source = AxiStreamSource(AxiStreamBus.from_prefix(dut, "wfg_drive_spi_axis"), dut.io_wbs_clk, dut.io_wbs_rst)

    await axis_source.send(b'test data')
    
    # wait for operation to complete
    await axis_source.wait()

    await FallingEdge(dut.wfg_drive_spi_sdo_en_o)
