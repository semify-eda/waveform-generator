// SPDX-FileCopyrightText: © 2022 semify <office@semify-eda.com>
// SPDX-License-Identifier: Apache-2.0

`timescale 1ns / 1ps

`ifdef VERILATOR  // make parameter readable from VPI
`define VL_RD /*verilator public_flat_rd*/
`else
`define VL_RD
`endif

module wfg_drive_spi_tb #(
    parameter int BUSW = 32,
    parameter int AXIS_DATA_WIDTH = 32
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

    // Bus master A interface
    input logic wfg_core_sync_i,     // I; Single cycle pulse for write access
    input logic wgf_core_subcycle_i, // I; Single cycle pulse for read access

    // AXI-Stream interface
    output wire                        wfg_axis_tready,  // O; ready
    input  logic                       wfg_axis_tvalid,  // I; valid
    input  logic                       wfg_axis_tlast,   // I; last
    input  logic [AXIS_DATA_WIDTH-1:0] wfg_axis_tdata,   // I; data

    // SPI IO interface
    output wire wfg_drive_spi_sclk_o,  // O; clock
    output wire wfg_drive_spi_cs_no,   // O; chip select
    output wire wfg_drive_spi_sdo_o,   // O; data out
    input  wire wfg_drive_spi_sdi_i    // I; data in, dummy signal for cocotb
);

    wfg_drive_spi_top wfg_drive_spi_top (
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

        .wfg_core_sync_i(wfg_core_sync_i),
        .wfg_core_subcycle_i(wgf_core_subcycle_i),

        .wfg_axis_tready_o(wfg_axis_tready),
        .wfg_axis_tdata_i (wfg_axis_tdata),
        .wfg_axis_tlast_i (wfg_axis_tlast),
        .wfg_axis_tvalid_i(wfg_axis_tvalid),

        .wfg_drive_spi_sclk_o(wfg_drive_spi_sclk_o),
        .wfg_drive_spi_cs_no (wfg_drive_spi_cs_no),
        .wfg_drive_spi_sdo_o (wfg_drive_spi_sdo_o)
    );

    // Dump waves
`ifndef VERILATOR
    initial begin
        $dumpfile("wfg_drive_spi_tb.vcd");
        $dumpvars(0, wfg_drive_spi_tb);
    end
`endif

endmodule
