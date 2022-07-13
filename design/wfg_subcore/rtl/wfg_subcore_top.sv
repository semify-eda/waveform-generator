// SPDX-FileCopyrightText: © 2022 semify <office@semify-eda.com>
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
module wfg_subcore_top #(
    parameter int BUSW = 32
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

    // subcore synchronisation interface
    output wire       wfg_subcore_sync_o,          // O; Sync signal
    output wire       wfg_subcore_subcycle_o,      // O; Subcycle signal
    output wire       wfg_subcore_start_o,         // O; Indicate start
    output wire [7:0] wfg_subcore_subcycle_cnt_o,  // O; Subcycle pulse counter
    output wire       active_o                     // O; Active indication signal
);
    // Registers
    //marker_template_start
    //data: ../data/wfg_subcore_reg.json
    //template: wishbone/instantiate_top.template
    //marker_template_code

    logic [23: 8] cfg_subcycle_q;          // CFG.SUBCYCLE register output
    logic [ 7: 0] cfg_sync_q;              // CFG.SYNC register output
    logic         ctrl_en_q;               // CTRL.EN register output

    //marker_template_end

    wfg_subcore_wishbone_reg wfg_subcore_wishbone_reg (
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
        //data: ../data/wfg_subcore_reg.json
        //template: wishbone/assign_to_module.template
        //marker_template_code

        .cfg_subcycle_q_o(cfg_subcycle_q),  // CFG.SUBCYCLE register output
        .cfg_sync_q_o    (cfg_sync_q),      // CFG.SYNC register output
        .ctrl_en_q_o     (ctrl_en_q)        // CTRL.EN register output

        //marker_template_end
    );

    wfg_subcore wfg_subcore (
        .clk  (wb_clk_i),  // clock signal
        .rst_n(!wb_rst_i), // reset signal

        // Control
        .en_i(ctrl_en_q),  // I; Enable signal

        // Configuration
        .wfg_sync_count_i    (cfg_sync_q),     // I; Sync counter threshold
        .wfg_subcycle_count_i(cfg_subcycle_q), // I: Subcycle counter threshold

        // Output
        .wfg_subcore_sync_o        (wfg_subcore_sync_o),          // O; Sync signal
        .wfg_subcore_subcycle_o    (wfg_subcore_subcycle_o),      // O; Subcycle signal
        .wfg_subcore_start_o       (wfg_subcore_start_o),         // O; Indicate start
        .wfg_subcore_subcycle_cnt_o(wfg_subcore_subcycle_cnt_o),  // O; Subcycle pulse counter
        .active_o                  (active_o)                     // O; Active indication signal
    );

endmodule
`default_nettype wire
