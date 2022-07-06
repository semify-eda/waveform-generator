# SPDX-FileCopyrightText: © 2022 semify <office@semify-eda.com>
# SPDX-License-Identifier: Apache-2.0

import math
import statistics
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, FallingEdge
from cocotb.regression import TestFactory
from cocotbext.wishbone.driver import WishboneMaster
from cocotbext.wishbone.driver import WBOp

DATA_CNT = 10

short_per = Timer(100, units="ns")
long_time = Timer(100, units="us")

async def set_register(dut, wbs, peripheral_address, address, data):
    if address > 0xF:
        dut._log.error("Can not access peripheral registers outside 0xF")

    real_address = (peripheral_address<<4) | (address & 0xF)
    dut._log.info(f"Set register {real_address} : {data}")

    wbRes = await wbs.send_cycle([WBOp(real_address, data)])
    rvalues = [wb.datrd for wb in wbRes]
    dut._log.info(f"Returned values : {rvalues}")

async def configure_stim_mem(dut, wbs, en, start=0x0000, end=0x0000, inc=0x01, gain=0x0001):
    await set_register(dut, wbs, 0x0, 0x4, start)
    await set_register(dut, wbs, 0x0, 0x8, end)
    await set_register(dut, wbs, 0x0, 0xC, gain<<8 | inc)
    await set_register(dut, wbs, 0x0, 0x0, en) # Enable

@cocotb.coroutine
async def mem_test(dut, start=0x0000, end=0x0000, inc=0x01, gain=0x0001):
    cocotb.start_soon(Clock(dut.io_wbs_clk, 10, units="ns").start())

    dut._log.info("Initialize and reset model")

    # Start reset
    dut.io_wbs_rst.value = 1
    dut.wfg_axis_tready.value = 1
    
    await Timer(100, units='ns')

    # Stop reset
    dut.io_wbs_rst.value = 0

    # Wishbone Master
    wbs = WishboneMaster(dut, "io_wbs", dut.io_wbs_clk,
                              width=32,   # size of data bus
                              timeout=10) # in clock cycle number

    await short_per
    
    dut._log.info("Configure stim_mem")
    await configure_stim_mem(dut, wbs, en=1, start=start, end=end, inc=inc, gain=gain)

    cur_address = start

    # Gather data
    for i in range(DATA_CNT):
        await FallingEdge(dut.wfg_axis_tvalid)
        value = dut.wfg_axis_tdata.value
        
        dut._log.info(f"Test: {cur_address} == {value}")
        
        assert(cur_address*gain == value)
        
        cur_address += inc
        
        if (cur_address > end):
            cur_address = start

factory = TestFactory(mem_test)

factory.add_option("start", [0x0000, 0x0010])
factory.add_option("end", [0x0005, 0x001F])
factory.add_option("inc", [0x01, 0x02])
factory.add_option("gain", [0x01, 0x04])

factory.generate_tests()
