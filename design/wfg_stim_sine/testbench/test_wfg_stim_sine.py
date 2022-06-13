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

async def configure_stim_sine(dut, wbs, en, inc=0x1000, gain=0x4000, offset=0):
    await set_register(dut, wbs, 0x0, 0x4, inc)
    await set_register(dut, wbs, 0x0, 0x8, gain)
    await set_register(dut, wbs, 0x0, 0xC, offset)
    await set_register(dut, wbs, 0x0, 0x0, en) # Enable

@cocotb.coroutine
async def sine_test(dut, sine_inc=0x1000, sine_gain=0x4000, sine_offset=0):
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
    
    dut._log.info("Configure stim_sine")
    await configure_stim_sine(dut, wbs, en=1, inc=sine_inc, gain=sine_gain, offset=sine_offset)

    num_values = int((2**16) / sine_inc + 1)
    y_data = []

    # Gather data
    for i in range(num_values):
        await FallingEdge(dut.wfg_axis_tvalid)
        value = int(dut.wfg_axis_tdata.value)
        
        # Sign extend
        if value & (1<<17):
            value |= ((1<<14)-1)<<18
            
        value = value.to_bytes(4, 'big')
        value = int.from_bytes(value, 'big', signed=True)
        y_data.append(value)

    y_data_float = []
    
    y_error = []
    y_squared_error = []
    y_absolute_error = []

    # Compare results
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

    assert(y_mean_absolute_error < 0.001)

factory = TestFactory(sine_test)

factory.add_option("sine_inc", [0x500, 0x1000])
factory.add_option("sine_gain", [0x4000, 0x2000, 0x6000])
factory.add_option("sine_offset", [0x0000, 0x8000])

factory.generate_tests()
