// SPDX-FileCopyrightText: © 2022 semify <office@semify-eda.com>
// SPDX-License-Identifier: Apache-2.0

`timescale 1ns / 1ps

`ifdef VERILATOR  // make parameter readable from VPI
`define VL_RD /*verilator public_flat_rd*/
`else
`define VL_RD
`endif

`ifndef WFG_INTERCONNECT_PKG
`define WFG_INTERCONNECT_PKG
typedef struct packed {
    logic wfg_axis_tvalid;
    logic [31:0] wfg_axis_tdata;
} axis_t;
`endif

module wfg_interconnect_tb #(
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

    // Stimuli
    input stimulus_0_wfg_axis_tvalid,
    input logic [31:0] stimulus_0_wfg_axis_tdata,

    input stimulus_1_wfg_axis_tvalid,
    input logic [31:0] stimulus_1_wfg_axis_tdata,

    output logic stimulus_0_wfg_axis_tready,
    output logic stimulus_1_wfg_axis_tready,

    // Driver
    output driver_0_wfg_axis_tvalid,
    output logic [31:0] driver_0_wfg_axis_tdata,

    output driver_1_wfg_axis_tvalid,
    output logic [31:0] driver_1_wfg_axis_tdata,

    input driver_0_wfg_axis_tready,
    input driver_1_wfg_axis_tready
);
    axis_t stimulus_0;
    assign stimulus_0.wfg_axis_tdata  = stimulus_0_wfg_axis_tdata;
    assign stimulus_0.wfg_axis_tvalid = stimulus_0_wfg_axis_tvalid;

    axis_t stimulus_1;
    assign stimulus_1.wfg_axis_tdata  = stimulus_1_wfg_axis_tdata;
    assign stimulus_1.wfg_axis_tvalid = stimulus_1_wfg_axis_tvalid;

    axis_t driver_0;
    assign driver_0_wfg_axis_tdata  = driver_0.wfg_axis_tdata;
    assign driver_0_wfg_axis_tvalid = driver_0.wfg_axis_tvalid;

    axis_t driver_1;
    assign driver_1_wfg_axis_tdata  = driver_1.wfg_axis_tdata;
    assign driver_1_wfg_axis_tvalid = driver_1.wfg_axis_tvalid;


    wfg_interconnect_top wfg_interconnect_top (
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

        .stimulus_0,
        .stimulus_1,

        .wfg_axis_tready_stimulus_0(stimulus_0_wfg_axis_tready),
        .wfg_axis_tready_stimulus_1(stimulus_1_wfg_axis_tready),

        .driver_0,
        .driver_1,

        .wfg_axis_tready_driver_0(driver_0_wfg_axis_tready),
        .wfg_axis_tready_driver_1(driver_1_wfg_axis_tready)
    );

    // Dump waves
`ifndef VERILATOR
    initial begin
        $dumpfile("wfg_interconnect_tb.vcd");
        $dumpvars(0, wfg_interconnect_tb);
    end
`endif

endmodule
