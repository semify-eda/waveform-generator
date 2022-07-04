// SPDX-FileCopyrightText: © 2022 semify <office@semify-eda.com>
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

`ifndef WFG_INTERCONNECT_PKG
`define WFG_INTERCONNECT_PKG
typedef struct packed {
    logic wfg_axis_tvalid;
    logic [31:0] wfg_axis_tdata;
} axis_t;
`endif

module wfg_interconnect_top #(
    parameter int BUSW = 32,
    parameter int AXIS_DATA_WIDTH = 32
) (
    // Wishbone Slave ports
    input                 wb_clk_i,
    input                 wb_rst_i,
    input                 wbs_stb_i,
    input                 wbs_cyc_i,
    input                 wbs_we_i,
    input  [(BUSW/8-1):0] wbs_sel_i,
    input  [  (BUSW-1):0] wbs_dat_i,
    input  [  (BUSW-1):0] wbs_adr_i,
    output                wbs_ack_o,
    output [  (BUSW-1):0] wbs_dat_o,

    // Core synchronisation interface
    input wire wfg_pat_sync_i,     // I; pat_sync pulse
    input wire wfg_pat_subcycle_i, // I; subcycle_cnt

    // Stimuli
    input axis_t stimulus_0,
    input axis_t stimulus_1,

    output wfg_axis_tready_stimulus_0,
    output wfg_axis_tready_stimulus_1,

    // Driver
    output axis_t driver_0,
    output axis_t driver_1,

    input wfg_axis_tready_driver_0,
    input wfg_axis_tready_driver_1
);
    // Registers
    //marker_template_start
    //data: ../data/wfg_interconnect_reg.json
    //template: wishbone/instantiate_top.template
    //marker_template_code

    logic         ctrl_en_q;               // CTRL.EN register output
    logic [ 1: 0] driver0_select_q;        // DRIVER0.SELECT register output
    logic [ 1: 0] driver1_select_q;        // DRIVER1.SELECT register output

    //marker_template_end

    wfg_interconnect_wishbone_reg wfg_interconnect_wishbone_reg (
        .wb_clk_i (wb_clk_i),
        .wb_rst_i (wb_rst_i),
        .wbs_stb_i(wbs_stb_i),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i (wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ack_o),
        .wbs_dat_o(wbs_dat_o),

        //marker_template_start
        //data: ../data/wfg_interconnect_reg.json
        //template: wishbone/assign_to_module.template
        //marker_template_code

        .ctrl_en_q_o       (ctrl_en_q),         // CTRL.EN register output
        .driver0_select_q_o(driver0_select_q),  // DRIVER0.SELECT register output
        .driver1_select_q_o(driver1_select_q)   // DRIVER1.SELECT register output

        //marker_template_end
    );

    wfg_interconnect wfg_interconnect (
        .clk  (wb_clk_i),  // clock signal
        .rst_n(!wb_rst_i), // reset signal

        // Control
        .ctrl_en_q_i(ctrl_en_q),

        // Configuration
        .driver0_select_q_i(driver0_select_q),
        .driver1_select_q_i(driver1_select_q),

        .stimulus_0,
        .stimulus_1,

        .wfg_axis_tready_stimulus_0,
        .wfg_axis_tready_stimulus_1,

        .driver_0,
        .driver_1,

        .wfg_axis_tready_driver_0,
        .wfg_axis_tready_driver_1
    );

endmodule
`default_nettype wire
