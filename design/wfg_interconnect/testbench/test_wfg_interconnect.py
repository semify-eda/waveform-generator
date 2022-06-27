# SPDX-FileCopyrightText: © 2022 semify <office@semify-eda.com>
# SPDX-License-Identifier: Apache-2.0

import os
import cocotb
from cocotb.clock import Clock
from cocotb.regression import TestFactory
from cocotb.triggers import Timer, RisingEdge, FallingEdge
from cocotbext.wishbone.driver import WishboneMaster
from cocotbext.wishbone.driver import WBOp
from cocotbext.axi import AxiStreamBus, AxiStreamSource, AxiStreamSink
from cocotbext.spi import SpiMaster, SpiSignals, SpiConfig, SpiSlaveBase
#from random import randbytes # Possible in Python 3.9+

SYSCLK = 100000000
DATA_CNT = 10
NUM_CHANNELS = 2

short_per = Timer(100, units="ns")
long_time = Timer(100, units="us")

async def set_register(dut, wbs, address, data):
    dut._log.info(f"Set register {address} : {data}")
    wbRes = await wbs.send_cycle([WBOp(address, data)])
    rvalues = [wb.datrd for wb in wbRes]
    dut._log.info(f"Returned values : {rvalues}")

async def configure(dut, wbs, en=1, select0=0, select1=0):
    await set_register(dut, wbs, 0x8, select1)
    await set_register(dut, wbs, 0x4, select0)
    await set_register(dut, wbs, 0x0, en) # Enable

async def receive_data(axis_sink, received_data, cnt):
    while 1:
        data = await axis_sink.recv()
        received_data[cnt].append(data.tdata[0])

@cocotb.coroutine
async def test_interconnect(dut, en, select0, select1):
    dut._log.info(f"Configuration: en={en}, select0={select0}, select1={select1}")

    cocotb.start_soon(Clock(dut.io_wbs_clk, 1/SYSCLK*1e9, units="ns").start())

    dut._log.info("Initialize and reset model")
    
    received_data = [[] for y in range(NUM_CHANNELS)]
    
    # Start reset
    dut.io_wbs_rst.value = 1
    dut.stimulus_0.value = 1
    await Timer(100, units='ns')

    # Stop reset
    dut.io_wbs_rst.value = 0

    # Wishbone Master
    wbs = WishboneMaster(dut, "io_wbs", dut.io_wbs_clk,
                              width=32,   # size of data bus
                              timeout=10) # in clock cycle number

    # Setup
    await configure(dut, wbs, en=en, select0=select0, select1=select1)

    await short_per

    axis_stimulus_0 = AxiStreamSource(AxiStreamBus.from_prefix(dut, "stimulus_0_wfg_axis"), dut.io_wbs_clk, dut.io_wbs_rst)
    
    axis_stimulus_1 = AxiStreamSource(AxiStreamBus.from_prefix(dut, "stimulus_1_wfg_axis"), dut.io_wbs_clk, dut.io_wbs_rst)

    axis_driver_0 = AxiStreamSink(AxiStreamBus.from_prefix(dut, "driver_0_wfg_axis"), dut.io_wbs_clk, dut.io_wbs_rst)

    axis_driver_1 = AxiStreamSink(AxiStreamBus.from_prefix(dut, "driver_1_wfg_axis"), dut.io_wbs_clk, dut.io_wbs_rst)
    
    cocotb.start_soon(receive_data(axis_driver_0, received_data, 0))
    cocotb.start_soon(receive_data(axis_driver_1, received_data, 1))

    send_data = [[int.from_bytes(os.getrandom(4, os.GRND_NONBLOCK), "big") for _ in range(DATA_CNT)] for y in range(NUM_CHANNELS)]

    for cnt in range(len(send_data)):
        for data in send_data[cnt]:

            if cnt == 0:
                await axis_stimulus_0.send([data])
            if cnt == 1:
                await axis_stimulus_1.send([data])

            await short_per
    
    await short_per

    if select0 == 0 and select1 == 0:
        assert(received_data[0] == send_data[0])
        assert(received_data[1] == send_data[0])
    if select0 == 1 and select1 == 0:
        assert(received_data[0] == send_data[1])
        assert(received_data[1] == send_data[0])
    if select0 == 0 and select1 == 1:
        assert(received_data[0] == send_data[0])
        assert(received_data[1] == send_data[1])
    if select0 == 1 and select1 == 1:
        assert(received_data[0] == send_data[1])
        assert(received_data[1] == send_data[1])

factory = TestFactory(test_interconnect)
factory.add_option("en", [1])
factory.add_option("select0", [0, 1])
factory.add_option("select1", [0, 1])

factory.generate_tests()
