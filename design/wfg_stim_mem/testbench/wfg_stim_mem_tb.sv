// SPDX-FileCopyrightText: © 2022 semify <office@semify-eda.com>
// SPDX-License-Identifier: Apache-2.0

`timescale 1ns / 1ps

`ifdef VERILATOR  // make parameter readable from VPI
`define VL_RD /*verilator public_flat_rd*/
`else
`define VL_RD
`endif

module wfg_stim_mem_tb #(
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

    // AXI-Stream interface
    input         wfg_axis_tready,
    output        wfg_axis_tvalid,
    output [31:0] wfg_axis_tdata
);

    logic        csb1;
    logic [9:0 ] addr1;
    logic [31:0] dout1;

    localparam MEM_SIZE = 2 ** 10;

    logic [31:0] mem[MEM_SIZE];

    wfg_stim_mem_top wfg_stim_mem_top (
        .wb_clk_i (io_wbs_clk),
        .wb_rst_i (io_wbs_rst),
        .wbs_stb_i(io_wbs_stb),
        .wbs_cyc_i(io_wbs_cyc),
        .wbs_we_i (io_wbs_we),
        .wbs_sel_i(4'b1111),
        .wbs_dat_i(io_wbs_datwr),
        .wbs_adr_i(io_wbs_adr),
        .wbs_ack_o(io_wbs_ack),
        .wbs_dat_o(io_wbs_datrd),

        .wfg_axis_tready_i(wfg_axis_tready),
        .wfg_axis_tvalid_o(wfg_axis_tvalid),
        .wfg_axis_tdata_o (wfg_axis_tdata),

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
        $dumpfile("wfg_stim_mem_tb.vcd");
        $dumpvars(0, wfg_stim_mem_tb);
    end
`endif

endmodule
