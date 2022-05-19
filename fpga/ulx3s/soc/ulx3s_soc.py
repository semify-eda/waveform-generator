#!/usr/bin/env python3

#
# This file is part of LiteX-Boards.
#
# Copyright (c) 2018-2019 Florent Kermarrec <florent@enjoy-digital.fr>
# Copyright (c) 2018 David Shah <dave@ds0.me>
# SPDX-License-Identifier: BSD-2-Clause

from migen import *
from migen.genlib.resetsync import AsyncResetSynchronizer

from litex_boards.platforms import radiona_ulx3s

from litex.build.lattice.trellis import trellis_args, trellis_argdict

from litex.soc.cores.clock import *
from litex.soc.integration.soc_core import *
from litex.soc.integration.builder import *
from litex.soc.cores.led import LedChaser
from litex.soc.cores.gpio import GPIOOut
from litex.soc.interconnect import *
from litex.soc.integration.soc import SoCRegion

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

# BaseSoC ------------------------------------------------------------------------------------------

class BaseSoC(SoCCore):
    def __init__(self, device="LFE5U-85F", revision="2.0", toolchain="trellis",
        sys_clk_freq=int(50e6), with_led_chaser=True, **kwargs):
        platform = radiona_ulx3s.Platform(device=device, revision=revision, toolchain=toolchain)

        # CRG --------------------------------------------------------------------------------------
        self.submodules.crg = _CRG(platform, sys_clk_freq)

        # SoCCore ----------------------------------------------------------------------------------
        kwargs["cpu_type"] = "vexriscv"
        SoCCore.__init__(self, platform, sys_clk_freq, 
                            ident="LiteX SoC on ULX3S", 
                            integrated_rom_init = get_mem_data("firmware/firmware.bin", endianness="little"),
                            **kwargs)

        # Leds -------------------------------------------------------------------------------------
        if with_led_chaser:
            self.submodules.leds = LedChaser(
                pads         = platform.request_all("user_led"),
                sys_clk_freq = sys_clk_freq)
                
        # Add a wb port for external verilog module
        wfg = wishbone.Interface()
        #self.bus.add_slave(name="wfg", slave=wfg, region=SoCRegion(origin=self.mem_map["wfg"], size=0x0100000))
        self.bus.add_slave(name="wfg", slave=wfg, region=SoCRegion(origin=0x40000000, size=0x0100000))
        
        spi_sclk = Signal()
        spi_cs = Signal()
        spi_sdo = Signal()
        spi_sdo_en = Signal()
        
        platform.add_source("../../../design/wfg_top/rtl/wfg_top.sv")
        platform.add_source("../../../design/wfg_stim_sine/rtl/*.sv")
        platform.add_source("../../../design/wfg_drive_spi/rtl/*.sv")
        platform.add_source("../../../design/wfg_core/rtl/*.sv")
        
        self.specials += Instance("wfg_top",
            i_io_wbs_clk     = self.crg.cd_sys.clk,
            i_io_wbs_rst     = self.crg.rst, # TODO polarity?
            i_io_wbs_adr      = wfg.adr,
            i_io_wbs_datwr    = wfg.dat_w, # TODO switch?
            o_io_wbs_datrd    = wfg.dat_r,
            i_io_wbs_we       = wfg.we,
            i_io_wbs_stb      = wfg.stb,
            o_io_wbs_ack      = wfg.ack,
            i_io_wbs_cyc      = wfg.cyc,

            o_wfg_drive_spi_sclk_o    = spi_sclk,
            o_wfg_drive_spi_cs_no     = spi_cs,
            o_wfg_drive_spi_sdo_o     = spi_sdo,
            o_wfg_drive_spi_sdo_en_o  = spi_sdo_en
        )
        
        """
        hk_ports = platform.request("hk")
        self.comb += hk_ports.stb_o.eq(hk.stb)
        self.comb += hk_ports.cyc_o.eq(hk.cyc)
        self.comb += hk.dat_r.eq(hk_ports.dat_i)
        self.comb += hk.ack.eq(hk_ports.ack_i)
        """
        


# Build --------------------------------------------------------------------------------------------

def main():
    from litex.soc.integration.soc import LiteXSoCArgumentParser
    parser = LiteXSoCArgumentParser(description="LiteX SoC on ULX3S")
    target_group = parser.add_argument_group(title="Target options")
    target_group.add_argument("--build",           action="store_true",   help="Build design.")
    target_group.add_argument("--load",            action="store_true",   help="Load bitstream.")
    target_group.add_argument("--toolchain",       default="trellis",     help="FPGA toolchain (trellis or diamond).")
    target_group.add_argument("--device",          default="LFE5U-85F",   help="FPGA device (LFE5U-12F, LFE5U-25F, LFE5U-45F or LFE5U-85F).")
    target_group.add_argument("--revision",        default="2.0",         help="Board revision (2.0 or 1.7).")
    target_group.add_argument("--sys-clk-freq",    default=50e6,          help="System clock frequency.")
    builder_args(parser)
    soc_core_args(parser)
    trellis_args(parser)
    args = parser.parse_args()

    soc = BaseSoC(
        device                 = args.device,
        revision               = args.revision,
        toolchain              = args.toolchain,
        sys_clk_freq           = int(float(args.sys_clk_freq)),
        **soc_core_argdict(args))

    builder = Builder(soc, **builder_argdict(args))
    builder_kargs = trellis_argdict(args) if args.toolchain == "trellis" else {}
    if args.build:
        builder.build(**builder_kargs)

    if args.load:
        prog = soc.platform.create_programmer()
        prog.load_bitstream(builder.get_bitstream_filename(mode="sram", ext=".svf")) # FIXME

if __name__ == "__main__":
    main()

