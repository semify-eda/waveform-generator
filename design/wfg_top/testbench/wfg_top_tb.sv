// SPDX-FileCopyrightText: © 2022 semify <office@semify-eda.com>
// SPDX-License-Identifier: Apache-2.0

`timescale 1ns / 1ps

`ifdef VERILATOR  // make parameter readable from VPI
`define VL_RD /*verilator public_flat_rd*/
`else
`define VL_RD
`endif

module wfg_top_tb #(
    parameter int BUSW = 32
) (
    // Wishbone interface signals
    input               io_wbs_clk,
    input               io_wbs_rst,
    input  [(BUSW-1):0] io_wbs_adr,
    input  [(BUSW-1):0] io_wbs_datwr,
    output [(BUSW-1):0] io_wbs_datrd,
    input               io_wbs_we,
    input               io_wbs_stb,
    output              io_wbs_ack,
    input               io_wbs_cyc,

    input  logic wfg_drive_spi_sdi_i,   // for cocotb
    output logic wfg_drive_spi_sclk_o,
    output logic wfg_drive_spi_cs_no,
    output logic wfg_drive_spi_sdo_o,

    output logic [31:0] wfg_drive_pat_dout_o
);

    logic        csb1;
    logic [9:0 ] addr1;
    logic [31:0] dout1;

    localparam MEM_SIZE = 2 ** 10;

    logic [31:0] mem[MEM_SIZE];

    wfg_top wfg_top (
        .io_wbs_clk(io_wbs_clk),
        .io_wbs_rst(io_wbs_rst),
        .io_wbs_adr(io_wbs_adr),
        .io_wbs_datwr(io_wbs_datwr),
        .io_wbs_datrd(io_wbs_datrd),
        .io_wbs_we(io_wbs_we),
        .io_wbs_stb(io_wbs_stb),
        .io_wbs_ack(io_wbs_ack),
        .io_wbs_cyc(io_wbs_cyc),

        .wfg_drive_spi_sclk_o(wfg_drive_spi_sclk_o),
        .wfg_drive_spi_cs_no (wfg_drive_spi_cs_no),
        .wfg_drive_spi_sdo_o (wfg_drive_spi_sdo_o),

        .wfg_drive_pat_dout_o(wfg_drive_pat_dout_o),

        .csb1 (csb1),
        .addr1(addr1),
        .dout1(dout1)
    );

    initial begin
        $readmemh("memory.hex", mem);
    end

    always_ff @(negedge io_wbs_clk) begin
        if (!csb1) dout1 <= mem[addr1];
    end

    // Dump waves
`ifndef VERILATOR
    initial begin
        $dumpfile("wfg_top_tb.vcd");
        $dumpvars(0, wfg_top_tb);
    end
`endif

endmodule
