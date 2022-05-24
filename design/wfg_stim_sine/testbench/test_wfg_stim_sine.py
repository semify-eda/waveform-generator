# SPDX-FileCopyrightText: © 2022 semify <office@semify-eda.com>
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer
from cocotbext.wishbone.driver import WishboneMaster
from cocotbext.wishbone.driver import WBOp

@cocotb.test()
async def my_first_test(dut):
    cocotb.start_soon(Clock(dut.io_wbs_clk, 10, units="ns").start())

    dut._log.info("Initialize and reset model")

    dut.io_wbs_rst.value = 1
    dut.wfg_axis_tready.value = 1
    
    await Timer(100, units='ns')

    dut.io_wbs_rst.value = 0

    wbs = WishboneMaster(dut, "io_wbs", dut.io_wbs_clk,
                              width=32,   # size of data bus
                              timeout=10) # in clock cycle number
    
    short_per = Timer(100, units="ns")
    await short_per

    # activate wfg_stim_sine
    wbRes = await wbs.send_cycle([WBOp(0x0, 1)])
    
    rvalues = [wb.datrd for wb in wbRes]
    dut._log.info(f"Returned values : {rvalues}")
    
    await short_per
    await short_per
    
    long_time = Timer(100, units="us")
    await long_time
    
    # reduce increment
    wbRes = await wbs.send_cycle([WBOp(0x4, 0x200)])
    
    await long_time
    
    # reduce increment
    wbRes = await wbs.send_cycle([WBOp(0x4, 0x50)])
    
    await long_time
