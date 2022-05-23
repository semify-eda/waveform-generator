#!/usr/bin/env python3

#
# This file is part of LiteX.
#
# Copyright (c) 2015-2020 Florent Kermarrec <florent@enjoy-digital.fr>
# Copyright (c) 2020 Antmicro <www.antmicro.com>
# Copyright (c) 2017 Pierre-Olivier Vauboin <po@lambdaconcept>
# SPDX-License-Identifier: BSD-2-Clause

import sys
import argparse

from migen import *

from litex_boards.platforms import radiona_ulx3s

from litex.build.lattice.trellis import trellis_args, trellis_argdict

from litex.soc.cores.clock import *

from litex.build.generic_platform import *
from litex.build.sim import SimPlatform
from litex.build.sim.config import SimConfig
from litex.build.sim.verilator import verilator_build_args, verilator_build_argdict

from litex.soc.integration.common import *
from litex.soc.integration.soc_core import *
from litex.soc.integration.builder import *
from litex.soc.integration.soc import *
from litex.soc.cores.bitbang import *
from litex.soc.cores.gpio import GPIOTristate
from litex.soc.cores.cpu import CPUS

from litescope import LiteScopeAnalyzer

# IOs ----------------------------------------------------------------------------------------------

_io = [
    # Clk / Rst.
    ("sys_clk", 0, Pins(1)),
    ("sys_rst", 0, Pins(1)),

    # Serial.
    ("serial", 0,
        Subsignal("source_valid", Pins(1)),
        Subsignal("source_ready", Pins(1)),
        Subsignal("source_data",  Pins(8)),

        Subsignal("sink_valid",   Pins(1)),
        Subsignal("sink_ready",   Pins(1)),
        Subsignal("sink_data",    Pins(8)),
    ),

    # Tristate GPIOs (for sim control/status).
    ("gpio", 0,
        Subsignal("oe", Pins(32)),
        Subsignal("o",  Pins(32)),
        Subsignal("i",  Pins(32)),
    ),
    
    ("spi_sclk", 0, Pins(1)),
    ("spi_cs", 0, Pins(1)),
    ("spi_sdo", 0, Pins(1)),
    ("spi_sdo_en", 0, Pins(1)),
]

# Platform -----------------------------------------------------------------------------------------

class Platform(SimPlatform):
    def __init__(self):
        SimPlatform.__init__(self, "SIM", _io)

# CRG ----------------------------------------------------------------------------------------------

class _CRG(Module):
    def __init__(self, platform, sys_clk_freq):
        self.rst = Signal()
        self.clock_domains.cd_sys    = ClockDomain()

        # # #

        # Clk / Rst
        clk25 = platform.request("clk25")
        rst   = platform.request("rst")

        # PLL
        self.submodules.pll = pll = ECP5PLL()
        self.comb += pll.reset.eq(rst | self.rst)
        pll.register_clkin(clk25, 25e6)
        pll.create_clkout(self.cd_sys,    sys_clk_freq)

        # Prevent ESP32 from resetting FPGA
        self.comb += platform.request("wifi_gpio0").eq(1)

# Simulation SoC -----------------------------------------------------------------------------------

class MySoC(SoCCore):
    def __init__(self,
        with_analyzer         = False,
        with_gpio             = False,
        with_wfg              = False,
        sim_debug             = False,
        trace_reset_on        = False,
        sys_clk_freq          = int(50e6),
        simulate              = True,
        device                = "LFE5U-85F",
        revision              = "2.0",
        toolchain             = "trellis",
        **kwargs):
        
        if simulate:
            platform = Platform()
        else:
            platform = radiona_ulx3s.Platform(device=device, revision=revision, toolchain=toolchain)


        # SoCCore ----------------------------------------------------------------------------------
        SoCCore.__init__(self, platform, clk_freq=sys_clk_freq,
            ident = "LiteX SoC",
            **kwargs)

        # CRG --------------------------------------------------------------------------------------
        if simulate:
            self.submodules.crg = CRG(platform.request("sys_clk"))
        else:
            self.submodules.crg = _CRG(platform, sys_clk_freq)

        # GPIO --------------------------------------------------------------------------------------
        if with_gpio:
            self.submodules.gpio = GPIOTristate(platform.request("gpio"), with_irq=True)
            self.irq.add("gpio", use_loc_if_exists=True)

        # Simulation debugging ----------------------------------------------------------------------
        if simulate:
            if sim_debug:
                platform.add_debug(self, reset=1 if trace_reset_on else 0)
            else:
                self.comb += platform.trace.eq(1)

        # Analyzer ---------------------------------------------------------------------------------
        if with_analyzer:
            analyzer_signals = [
                # IBus (could also just added as self.cpu.ibus)
                self.cpu.ibus.stb,
                self.cpu.ibus.cyc,
                self.cpu.ibus.adr,
                self.cpu.ibus.we,
                self.cpu.ibus.ack,
                self.cpu.ibus.sel,
                self.cpu.ibus.dat_w,
                self.cpu.ibus.dat_r,
                # DBus (could also just added as self.cpu.dbus)
                self.cpu.dbus.stb,
                self.cpu.dbus.cyc,
                self.cpu.dbus.adr,
                self.cpu.dbus.we,
                self.cpu.dbus.ack,
                self.cpu.dbus.sel,
                self.cpu.dbus.dat_w,
                self.cpu.dbus.dat_r,
            ]
            self.submodules.analyzer = LiteScopeAnalyzer(analyzer_signals,
                depth        = 512,
                clock_domain = "sys",
                csr_csv      = "analyzer.csv")
        
        if with_wfg:
            # Add a wb port for external verilog module
            wfg = wishbone.Interface()
            self.bus.add_slave(name="wfg", slave=wfg, region=SoCRegion(origin=0x30000000, size=0x0100000)) #, cached=False)) TODO?

            if simulate:
                spi_sclk    = platform.request("spi_sclk")
                spi_cs      = platform.request("spi_cs")
                spi_sdo     = platform.request("spi_sdo")
                spi_sdo_en  = platform.request("spi_sdo_en")
            else:
                spi_sclk    = platform.request("user_led", 0)
                spi_cs      = platform.request("user_led", 1)
                spi_sdo     = platform.request("user_led", 2)
                spi_sdo_en  = platform.request("user_led", 3)
            
            platform.add_source("../../../design/wfg_top/rtl/wfg_top.sv")
            platform.add_source("../../../design/wfg_stim_sine/rtl/*.sv")
            platform.add_source("../../../design/wfg_drive_spi/rtl/*.sv")
            platform.add_source("../../../design/wfg_core/rtl/*.sv")
            
            self.specials += Instance("wfg_top",
                i_io_wbs_clk      = self.crg.cd_sys.clk,
                i_io_wbs_rst      = self.crg.cd_sys.rst,
                i_io_wbs_adr      = (wfg.adr << 2) & 0x000000FF , # add two zeros
                i_io_wbs_datwr    = wfg.dat_w,
                o_io_wbs_datrd    = wfg.dat_r,
                i_io_wbs_we       = wfg.we,
                i_io_wbs_stb      = (((wfg.adr<<2)[24:32] == 0x30) & wfg.stb),
                o_io_wbs_ack      = wfg.ack,
                i_io_wbs_cyc      = wfg.cyc,

                o_wfg_drive_spi_sclk_o    = spi_sclk,
                o_wfg_drive_spi_cs_no     = spi_cs,
                o_wfg_drive_spi_sdo_o     = spi_sdo,
                o_wfg_drive_spi_sdo_en_o  = spi_sdo_en
            )

# Build --------------------------------------------------------------------------------------------

def generate_gtkw_savefile(builder, vns, trace_fst):
    from litex.build.sim import gtkwave as gtkw
    dumpfile = os.path.join(builder.gateware_dir, "sim.{}".format("fst" if trace_fst else "vcd"))
    savefile = os.path.join(builder.gateware_dir, "sim.gtkw")
    soc = builder.soc

    with gtkw.GTKWSave(vns, savefile=savefile, dumpfile=dumpfile) as save:
        save.clocks()
        save.fsm_states(soc)
        if "main_ram" in soc.bus.slaves.keys():
            save.add(soc.bus.slaves["main_ram"], mappers=[gtkw.wishbone_sorter(), gtkw.wishbone_colorer()])

        if hasattr(soc, "sdrphy"):
            # all dfi signals
            save.add(soc.sdrphy.dfi, mappers=[gtkw.dfi_sorter(), gtkw.dfi_in_phase_colorer()])

            # each phase in separate group
            with save.gtkw.group("dfi phaseX", closed=True):
                for i, phase in enumerate(soc.sdrphy.dfi.phases):
                    save.add(phase, group_name="dfi p{}".format(i), mappers=[
                        gtkw.dfi_sorter(phases=False),
                        gtkw.dfi_in_phase_colorer(),
                    ])

            # only dfi command/data signals
            def dfi_group(name, suffixes):
                save.add(soc.sdrphy.dfi, group_name=name, mappers=[
                    gtkw.regex_filter(gtkw.suffixes2re(suffixes)),
                    gtkw.dfi_sorter(),
                    gtkw.dfi_per_phase_colorer(),
                ])

            dfi_group("dfi commands", ["cas_n", "ras_n", "we_n"])
            dfi_group("dfi commands", ["wrdata"])
            dfi_group("dfi commands", ["wrdata_mask"])
            dfi_group("dfi commands", ["rddata"])

def sim_args(parser):
    builder_args(parser)
    soc_core_args(parser)
    verilator_build_args(parser)
    parser.add_argument("--rom-init",             default=None,            help="ROM init file (.bin or .json).")
    parser.add_argument("--with-analyzer",        action="store_true",     help="Enable Analyzer support.")
    parser.add_argument("--with-gpio",            action="store_true",     help="Enable Tristate GPIO (32 pins).")
    parser.add_argument("--with-wfg",             action="store_true",     help="Enable the waveform generator module")
    parser.add_argument("--sim-debug",            action="store_true",     help="Add simulation debugging modules.")
    parser.add_argument("--gtkwave-savefile",     action="store_true",     help="Generate GTKWave savefile.")
    parser.add_argument("--non-interactive",      action="store_true",     help="Run simulation without user input.")
    parser.add_argument("--simulate",             action="store_true",     help="Run simulation")
    parser.add_argument("--build",                action="store_true",     help="Build design")
    parser.add_argument("--toolchain",            default="trellis",     help="FPGA toolchain (trellis or diamond).")
    parser.add_argument("--device",               default="LFE5U-85F",   help="FPGA device (LFE5U-12F, LFE5U-25F, LFE5U-45F or LFE5U-85F).")
    parser.add_argument("--revision",             default="2.0",         help="Board revision (2.0 or 1.7).")
    parser.add_argument("--sys-clk-freq",         default=50e6,          help="System clock frequency.")
    
def main():
    from litex.soc.integration.soc import LiteXSoCArgumentParser
    parser = LiteXSoCArgumentParser(description="LiteX SoC Simulation utility")
    sim_args(parser)
    args = parser.parse_args()

    soc_kwargs             = soc_core_argdict(args)
    builder_kwargs         = builder_argdict(args)
    verilator_build_kwargs = verilator_build_argdict(args)
    trellis_args(parser) # TODO
    
    sys_clk_freq = int(float(args.sys_clk_freq))
    
    if args.simulate:
        sys_clk_freq = int(1e6) # TODO try out higher clk
        sim_config   = SimConfig()
        sim_config.add_clocker("sys_clk", freq_hz=sys_clk_freq)

    # Configuration --------------------------------------------------------------------------------

    cpu = CPUS.get(soc_kwargs.get("cpu_type", "vexriscv"))

    # UART.
    if args.simulate and soc_kwargs["uart_name"] == "serial":
        soc_kwargs["uart_name"] = "sim"
        sim_config.add_module("serial2console", "serial")

    # ROM.
    if args.rom_init:
        soc_kwargs["integrated_rom_init"] = get_mem_data(args.rom_init, endianness=cpu.endianness)

    # SoC ------------------------------------------------------------------------------------------
    soc = MySoC(
        with_analyzer      = args.with_analyzer,
        with_gpio          = args.with_gpio,
        with_wfg           = args.with_wfg,
        sim_debug          = args.sim_debug,
        trace_reset_on     = int(float(args.trace_start)) > 0 or int(float(args.trace_end)) > 0,
        sys_clk_freq       = sys_clk_freq,
        simulate           = args.simulate,
        **soc_kwargs)

    # Build/Run ------------------------------------------------------------------------------------
    def pre_run_callback(vns):
        if args.trace:
            generate_gtkw_savefile(builder, vns, args.trace_fst)

    builder_kwargs["csr_csv"] = "csr.csv"
    builder_kwargs["compile_software"] = False
    builder = Builder(soc, **builder_kwargs)
    
    if args.simulate:
        builder.build(
            sim_config       = sim_config,
            interactive      = not args.non_interactive,
            pre_run_callback = pre_run_callback,
            **verilator_build_kwargs,
        )
    elif args.build:
        builder_kargs = trellis_argdict(args) if args.toolchain == "trellis" else {}
        builder.build(**builder_kargs)

if __name__ == "__main__":
    main()

