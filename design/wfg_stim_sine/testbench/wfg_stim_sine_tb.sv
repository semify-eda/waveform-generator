// SPDX-FileCopyrightText: © 2022 semify <office@semify-eda.com>
// SPDX-License-Identifier: Apache-2.0

`timescale 1ns / 1ps

`ifdef VERILATOR  // make parameter readable from VPI
`define VL_RD /*verilator public_flat_rd*/
`else
`define VL_RD
`endif

module wfg_stim_sine_tb #(
    parameter BUSW = 32
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
    input                wfg_stim_spi_tready_o,
    output               wfg_stim_spi_tvalid_i,
    output signed [17:0] wfg_stim_spi_tdata_i
);

    wfg_stim_sine_top wfg_stim_sine_top (
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

        .wfg_stim_spi_tready_o(wfg_stim_spi_tready_o),
        .wfg_stim_spi_tvalid_i(wfg_stim_spi_tvalid_i),
        .wfg_stim_spi_tdata_i (wfg_stim_spi_tdata_i)
    );

    // Dump waves
`ifndef VERILATOR
    initial begin
        $dumpfile("wfg_stim_sine_tb.vcd");
        $dumpvars(0, wfg_stim_sine_tb);
    end
`endif

endmodule
