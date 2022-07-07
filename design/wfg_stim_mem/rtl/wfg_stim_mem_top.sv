// SPDX-FileCopyrightText: © 2022 semify <office@semify-eda.com>
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
module wfg_stim_mem_top #(
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

    // AXI-Stream interface
    input         wfg_axis_tready_i,
    output        wfg_axis_tvalid_o,
    output [31:0] wfg_axis_tdata_o,

    // Memory interface
    output        csb1,
    output [ 9:0] addr1,
    input  [31:0] dout1
);
    // Registers
    //marker_template_start
    //data: ../data/wfg_stim_mem_reg.json
    //template: wishbone/instantiate_top.template
    //marker_template_code

    logic [23: 8] cfg_gain_q;              // CFG.GAIN register output
    logic [ 7: 0] cfg_inc_q;               // CFG.INC register output
    logic         ctrl_en_q;               // CTRL.EN register output
    logic [15: 0] end_val_q;               // END.VAL register output
    logic [15: 0] start_val_q;             // START.VAL register output

    //marker_template_end

    wfg_stim_mem_wishbone_reg wfg_stim_mem_wishbone_reg (
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
        //data: ../data/wfg_stim_mem_reg.json
        //template: wishbone/assign_to_module.template
        //marker_template_code

        .cfg_gain_q_o (cfg_gain_q),  // CFG.GAIN register output
        .cfg_inc_q_o  (cfg_inc_q),   // CFG.INC register output
        .ctrl_en_q_o  (ctrl_en_q),   // CTRL.EN register output
        .end_val_q_o  (end_val_q),   // END.VAL register output
        .start_val_q_o(start_val_q)  // START.VAL register output

        //marker_template_end
    );

    wfg_stim_mem wfg_stim_mem (
        .clk              (wb_clk_i),           // clock signal
        .rst_n            (!wb_rst_i),          // reset signal
        .wfg_axis_tready_i(wfg_axis_tready_i),  // ready signal - AXI
        .wfg_axis_tvalid_o(wfg_axis_tvalid_o),  // valid signal - AXI
        .wfg_axis_tdata_o (wfg_axis_tdata_o),   // mem output   - AXI
        .ctrl_en_q_i      (ctrl_en_q),          // enable/disable
        .end_val_q_i      (end_val_q),
        .start_val_q_i    (start_val_q),
        .cfg_inc_q_i      (cfg_inc_q),
        .cfg_gain_q_i     (cfg_gain_q),
        .csb1             (csb1),
        .addr1            (addr1),
        .dout1            (dout1)
    );

endmodule
`default_nettype wire
