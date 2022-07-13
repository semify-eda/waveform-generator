#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import random
import cocotb
import pdb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from cocotbext.wishbone.driver import WishboneMaster, WBOp
from cocotbext.axi import AxiStreamBus, AxiStreamSource
from cocotb.triggers import RisingEdge, FallingEdge
from cocotb_bus.monitors import Monitor
from cocotb_bus.scoreboard import Scoreboard
from cocotb.regression import TestFactory

ADDITIONAL_OUTPUT = False

CHANNELS = 32
SUBCYCLES_PER_SYNC = 24

class OutputMonitor(Monitor):
    def __init__(self, dut, name="",callback=None, event=None):
        self.dut = dut
        self.name = name
        Monitor.__init__(self, callback, event)

    async def _monitor_recv(self):
        clkedge = RisingEdge(self.dut.io_wbs_clk)
        while True:
            await clkedge
            output = self.dut.wfg_drive_pat_dout_o.value
            self._recv(str(output))
#========

"""
async def drive_sync(dut):
    dut.wfg_wfg_pat_sync_i.value = 0
    sync_cnt = 0
    while True:
        await RisingEdge(dut.io_wbs_clk)
        if sync_cnt == CLK_PER_SYNC-1:
            sync_cnt = 0
            dut.wfg_wfg_pat_sync_i.value = 1
        else:
            sync_cnt = sync_cnt + 1
            dut.wfg_wfg_pat_sync_i.value = 0
"""

async def reset(dut):
    await ClockCycles(dut.io_wbs_clk, 1)
    dut.io_wbs_rst.value = 1
    await ClockCycles(dut.io_wbs_clk, 1)
    dut.io_wbs_rst.value = 0
    await ClockCycles(dut.io_wbs_clk, 1)

async def set_register(dut, wbs, address, data):
    dut._log.info(f"Set register {address} : {data}")

    wbRes = await wbs.send_cycle([WBOp(address, data)])
    
    rvalues = [wb.datrd for wb in wbRes]
    dut._log.info(f"Returned values : {rvalues}")

async def configure(dut, wbs, en, pat, begin, end): # TODO
    #begin = 9
    #end = 16

    #en = 7
    #pat = [1,2]
    #pat[0] = 3
    #pat[1] = 1

    await set_register(dut, wbs, 0x4, (begin & 0xFF) | ((end & 0xFF)<<8))
    await set_register(dut, wbs, 0x8, pat[0])
    await set_register(dut, wbs, 0xC, pat[1])
    await set_register(dut, wbs, 0x0, en) # Enable PAT

class MyScoreboard(Scoreboard):
    def compare(self, got, exp, log, **_):
        if got != exp and exp != 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx':
            self.errors += 1
            #log.error("Received transaction differed from expected output.")
            log.warning("Received transaction differed from expected output.")
            log.warning("Expected: {0!s}.\nReceived: {1!s}.".format(exp, got))
            #if self._imm:
            #  raise TestFailure("Received transaction differed from expected transaction.")
        elif ADDITIONAL_OUTPUT:
            log.info("Received transaction matches expected output.")
            log.info("Expected: {0!s}.\nReceived: {1!s}.".format(exp, got))
#========

class Testbench(object):
    def __init__(self, dut):
        self.dut = dut
        self.dut._log.info("Init TB...")

        clock = Clock(dut.io_wbs_clk, 10, units="ns")  # Create a 10ns period clock on port clk
        cocotb.fork(clock.start())  # Start the clock
        cocotb.fork(self.drive_subcycles())  # count subcycles

    async def drive_subcycles(self):
        self.dut.wfg_core_subcycle_cnt_i.value = 0
        self.dut.wfg_core_sync_i.value = 1
        while True:
            await RisingEdge(self.dut.io_wbs_clk)
            subcycles = self.dut.wfg_core_subcycle_cnt_i.value
            if subcycles == SUBCYCLES_PER_SYNC-2:
                self.dut.wfg_core_subcycle_cnt_i.value = subcycles + 1
                self.dut.wfg_core_sync_i.value = 1
            elif subcycles == SUBCYCLES_PER_SYNC-1:
                self.dut.wfg_core_subcycle_cnt_i.value = 0
                self.dut.wfg_core_sync_i.value = 0
            else:
                self.dut.wfg_core_subcycle_cnt_i.value = subcycles + 1
                self.dut.wfg_core_sync_i.value = 0
#========

def make_expected_output(dut, input, out_begin, out_end, pat_select_i, en_i):
    expected_output = []

    print(input)

    byte = bin(input)[2:].rjust(CHANNELS, '0')[::-1]

    print("byte")
    print(byte)
    print("en")
    print(bin(en_i))    
    
    for i in range(SUBCYCLES_PER_SYNC):

        next_output = ''
        for j in range(CHANNELS):
            pat_select = (pat_select_i[0]>>j & 1) | ((pat_select_i[1]>>j & 1)<<1)
            en         = (en_i>>j) & 1
            bit        = str((input>>j) & 1)
            
            print("i={}, j={}, en={}, pat={}, bit={}".format(i, j, en, pat_select, bit))

            if en == 0:
                next_output = 'z' + next_output
            elif pat_select == 0: # RZ
                if i >= out_end:
                    next_output = '0' + next_output
                elif i >= out_begin:
                    next_output = bit + next_output
                else:
                    next_output = '0' + next_output
            elif pat_select == 1: # RO
                if i >= out_end:
                    next_output = '1' + next_output
                elif i >= out_begin:
                    next_output = bit + next_output
                else:
                    next_output = '0' + next_output
            elif pat_select == 2: # NRZ
                if i >= out_end:
                    next_output = bit + next_output
                elif i >= out_begin:
                    next_output = bit + next_output
                else:
                    next_output = '0' + next_output
            elif pat_select == 3: # RC
                if i >= out_end:
                    if bit == '0':
                        next_output = '1' + next_output
                    else:
                        next_output = '0' + next_output
                elif i >= out_begin:
                    next_output = bit + next_output
                else:
                    next_output = '0' + next_output
            else:
                dut._log.error('should not happen!')
                
            print(next_output)

        expected_output.append(''.join(next_output))
    
    print()
    
    for j in reversed(range(CHANNELS)):
        pat_select = (pat_select_i[0]>>j & 1) | ((pat_select_i[1]>>j & 1)<<1)
        print(pat_select, end="")
    print("")
    
    print(byte)
    
    for exp in expected_output:
        print(exp)
    
    return expected_output
    
@cocotb.coroutine
async def run_test(dut, en=None, pat=None, begin=None, end=None, inputlen=None):

    if en == None:
        en = random.randint(0, 2**(CHANNELS-1))
    if pat == None:
        pat = [random.randint(0, 2**(CHANNELS-1)), random.randint(0, 2**(CHANNELS-1))]
    if begin == None:
        begin = 0x08 # int.from_bytes(b'\x08\x08\x08\x08\x08\x08\x08\x09', byteorder='big')
    if end == None:
        end = 0x10 # int.from_bytes(b'\x10\x10\x10\x10\x10\x10\x10\x10', byteorder='big')
    if inputlen == None:
        inputlen = random.randint(1, 20)

    tb = Testbench(dut)

    input = [random.randint(0, 2**(CHANNELS-1)) for _ in range(inputlen)]
    print(input)
    
    for byte in input:
        expected_output = make_expected_output(dut, input=byte, out_begin=begin, out_end=end, pat_select_i=pat, en_i=en)

        await reset(dut)
        
        # Wishbone Master
        wbs = WishboneMaster(dut, "io_wbs", dut.io_wbs_clk,
                                      width=32,   # size of data bus
                                      timeout=10) # in clock cycle number

        await configure(dut, wbs, en=en, pat=pat, begin=begin, end=end)

        await FallingEdge(dut.wfg_core_sync_i) # TODO
        
        output_mon = OutputMonitor(dut)
        
        scoreboard = MyScoreboard(dut)
        scoreboard.add_interface(output_mon, expected_output)

        print("Sending data")
    
        axis_source = AxiStreamSource(AxiStreamBus.from_prefix(dut, "wfg_axis"), dut.io_wbs_clk, dut.io_wbs_rst)
        for byte in input:
            await axis_source.send([byte])
            
        await axis_source.send([0xFF])
        await axis_source.send([0xFF])

        print("Waiting for expected_output != []")

        while expected_output != []:
            print(expected_output)
            await ClockCycles(dut.io_wbs_clk, 1)

        output_mon.kill()

        print("Result")

        raise scoreboard.result


factory = TestFactory(run_test)
factory.add_option("en", [None])

#pat = [None] + [sum(j * 2**i for i in range(0, 15, 2)) for j in range (0, 4)]
pat = [None]
factory.add_option("pat", pat)

#begin = [None, int.from_bytes(b'\x01\x01\x01\x01\x01\x01\x01\x01', byteorder='big')]
begin = [None]

factory.add_option("begin", begin)

end = [None]
factory.add_option("end", end)

inputlen = [None, 1]
factory.add_option("inputlen", inputlen)

factory.generate_tests()
