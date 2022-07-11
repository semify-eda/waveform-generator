# SPDX-FileCopyrightText: © 2022 semify <office@semify-eda.com>
# SPDX-License-Identifier: Apache-2.0

import random
import cocotb
from cocotb.clock import Clock
from cocotb.regression import TestFactory
from cocotb.triggers import Timer, RisingEdge, FallingEdge, ClockCycles
from cocotbext.wishbone.driver import WishboneMaster
from cocotbext.wishbone.driver import WBOp

CLK_PER_SYNC = 300
SYSCLK = 100000000
DATA_CNT = 10

short_per = Timer(100, units="ns")
long_time = Timer(100, units="us")

async def set_register(dut, wbs, address, data):
    dut._log.info(f"Set register {address} : {data}")

    wbRes = await wbs.send_cycle([WBOp(address, data)])
    
    rvalues = [wb.datrd for wb in wbRes]
    dut._log.info(f"Returned values : {rvalues}")

async def configure(dut, wbs, en, sync_count, subcycle_count):
    await set_register(dut, wbs, 0x4, (sync_count << 0) | (subcycle_count << 8))
    await set_register(dut, wbs, 0x0, en) # Enable core

@cocotb.coroutine
async def core_test(dut, en, sync_count, subcycle_count):
    dut._log.info(f"Configuration: sync_count={sync_count}, subcycle_count={subcycle_count}")

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

    # Setup core
    await configure(dut, wbs, en, sync_count, subcycle_count)

    #await short_per
    #await short_per
    
    sync_pulse_count = 0
    clk_count = 0
    
    await FallingEdge(dut.wfg_core_sync_o)

    for i in range ((sync_count + 1) * (subcycle_count + 1) * 3):
        await ClockCycles(dut.io_wbs_clk, 1)
        clk_count += 1
   
        if dut.wfg_core_sync_o == 1:
            assert ((sync_pulse_count+1) * clk_count) == ((sync_count + 1) * (subcycle_count + 1) * 2)
            break
            
        if (dut.wfg_core_subcycle_o == 1):
            sync_pulse_count += 1
            clk_count = 0

length = 2

sync_array = []

for i in range(length):
    n = random.randint(1,2**7)
    sync_array.append(n)

subcycle_array = []

for i in range(length):
    n = random.randint(1,2**7)
    subcycle_array.append(n)


factory = TestFactory(core_test)
factory.add_option("en", [1])
factory.add_option("sync_count", sync_array)
factory.add_option("subcycle_count", subcycle_array)

factory.generate_tests()
