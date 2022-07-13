// SPDX-FileCopyrightText: © 2022 semify <office@semify-eda.com>
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
module wfg_drive_pat_top #(
    parameter int BUSW = 32,
    parameter int AXIS_DATA_WIDTH = 32,
    parameter int CHANNELS = 32
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
    input wire        wfg_core_sync_i,         // I; sync pulse
    input logic [7:0] wfg_core_subcycle_cnt_i, // I; subcycle_cnt

    // Subcore synchronisation interface
    input logic       wfg_subcore_sync_i,         // I; sync pulse
    input logic [7:0] wfg_subcore_subcycle_cnt_i, // I; subcycle_cnt

    // AXI-Stream interface
    output wire wfg_axis_tready_o,
    input wire [AXIS_DATA_WIDTH-1:0] wfg_axis_tdata_i,
    input wire wfg_axis_tlast_i,
    input wire wfg_axis_tvalid_i,

    output logic [CHANNELS-1:0] pat_dout_o,    // O; output pins
    output logic [CHANNELS-1:0] pat_dout_en_o  // O; output enabled
);
    // Registers
    //marker_template_start
    //data: ../data/wfg_drive_pat_reg.json
    //template: wishbone/instantiate_top.template
    //marker_template_code

    logic [ 7: 0] cfg_begin_q;             // CFG.BEGIN register output
    logic         cfg_core_sel_q;          // CFG.CORE_SEL register output
    logic [15: 8] cfg_end_q;               // CFG.END register output
    logic [31: 0] ctrl_en_q;               // CTRL.EN register output
    logic [31: 0] patsel0_low_q;           // PATSEL0.LOW register output
    logic [31: 0] patsel1_high_q;          // PATSEL1.HIGH register output

    //marker_template_end

    wfg_drive_pat_wishbone_reg wfg_drive_pat_wishbone_reg (
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
        //data: ../data/wfg_drive_pat_reg.json
        //template: wishbone/assign_to_module.template
        //marker_template_code

        .cfg_begin_q_o   (cfg_begin_q),     // CFG.BEGIN register output
        .cfg_core_sel_q_o(cfg_core_sel_q),  // CFG.CORE_SEL register output
        .cfg_end_q_o     (cfg_end_q),       // CFG.END register output
        .ctrl_en_q_o     (ctrl_en_q),       // CTRL.EN register output
        .patsel0_low_q_o (patsel0_low_q),   // PATSEL0.LOW register output
        .patsel1_high_q_o(patsel1_high_q)   // PATSEL1.HIGH register output

        //marker_template_end
    );

    wfg_drive_pat #(
        .CHANNELS  (CHANNELS),
        .AXIS_WIDTH(AXIS_DATA_WIDTH)
    ) wfg_drive_pat (
        .clk  (wb_clk_i),  // clock signal
        .rst_n(!wb_rst_i), // reset signal

        // Core synchronisation interface
        .wfg_core_sync_i        (wfg_core_sync_i),
        .wfg_core_subcycle_cnt_i(wfg_core_subcycle_cnt_i),

        // Subcore synchronisation interface
        .wfg_subcore_sync_i        (wfg_subcore_sync_i),
        .wfg_subcore_subcycle_cnt_i(wfg_subcore_subcycle_cnt_i),

        // AXI streaming interface
        .wfg_axis_tready_o(wfg_axis_tready_o),  // O; ready
        .wfg_axis_tvalid_i(wfg_axis_tvalid_i),  // I; valid
        .wfg_axis_tlast_i (wfg_axis_tlast_i),   // I; last
        .wfg_axis_tdata_i (wfg_axis_tdata_i),   // I; data

        // Control
        .ctrl_en_q_i(ctrl_en_q),  // I; pat enable

        // Configuration
        .cfg_begin_q_i   (cfg_begin_q),
        .cfg_end_q_i     (cfg_end_q),
        .patsel_q_i      ({patsel1_high_q, patsel0_low_q}),
        .cfg_core_sel_q_i(cfg_core_sel_q),

        // Output
        .pat_dout_o   (pat_dout_o),
        .pat_dout_en_o(pat_dout_en_o)
    );

endmodule
`default_nettype wire
