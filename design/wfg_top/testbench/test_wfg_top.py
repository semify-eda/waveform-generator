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

async def set_register(dut, wbs, peripheral_address, address, data):
    if address > 0xF:
        dut._log.error("Can not access peripheral registers outside 0xF")

    real_address = (peripheral_address<<4) | (address & 0xF)

    dut._log.info(f"Set register {real_address} : {data}")

    wbRes = await wbs.send_cycle([WBOp(real_address, data)])
    
    rvalues = [wb.datrd for wb in wbRes]
    dut._log.info(f"Returned values : {rvalues}")

async def configure_core(dut, wbs, en, sync_count, subcycle_count):
    await set_register(dut, wbs, 0x1, 0x2, (sync_count << 0) | (subcycle_count << 8))
    await set_register(dut, wbs, 0x1, 0x1, en) # Enable

async def configure_stim_sine(dut, wbs, en):
    await set_register(dut, wbs, 0x2, 0x1, en) # Enable

async def configure_drive_spi(dut, wbs, en=1, cnt=3, cpha=0, cpol=0, mstr=1, lsbfirst=0, dff=0, ssctrl=0, sspol=0, oectrl=0):
    await set_register(dut, wbs, 0x3, 0x3, cnt) # Clock divider
    await set_register(dut, wbs, 0x3, 0x2, (cpha<<0) | (cpol<<1) | (mstr<<2) | (lsbfirst<<3) | (dff<<4) | (ssctrl<<8) | (sspol<<9) | (oectrl<<10)) # Enable SPI
    await set_register(dut, wbs, 0x3, 0x1, en) # Enable SPI

@cocotb.test()
async def core_test(dut):
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
    dut._log.info("Configure core")
    await configure_core(dut, wbs, en=1, sync_count=16, subcycle_count=16)
    dut._log.info("Configure stim_sine")
    await configure_stim_sine(dut, wbs, en=1)
    dut._log.info("Configure drive_spi")
    await configure_drive_spi(dut, wbs, en=1, dff=3)

    await long_time
    await short_per

