// SPDX-FileCopyrightText: © 2022 semify <office@semify-eda.com>
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
module wfg_stim_sine_top #(
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
    input                wfg_axis_tready_i,
    output               wfg_axis_tvalid_o,
    output signed [31:0] wfg_axis_tdata_o
);
    // Registers
    //marker_template_start
    //data: ../data/wfg_stim_sine_reg.json
    //template: wishbone/instantiate_top.template
    //marker_template_code

    logic         ctrl_en_q;               // CTRL.EN register output
    logic [15: 0] gain_val_q;              // GAIN.VAL register output
    logic [15: 0] inc_val_q;               // INC.VAL register output
    logic [17: 0] offset_val_q;            // OFFSET.VAL register output

    //marker_template_end

    wfg_stim_sine_wishbone_reg wfg_stim_sine_wishbone_reg (
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
        //data: ../data/wfg_stim_sine_reg.json
        //template: wishbone/assign_to_module.template
        //marker_template_code

        .ctrl_en_q_o   (ctrl_en_q),    // CTRL.EN register output
        .gain_val_q_o  (gain_val_q),   // GAIN.VAL register output
        .inc_val_q_o   (inc_val_q),    // INC.VAL register output
        .offset_val_q_o(offset_val_q)  // OFFSET.VAL register output

        //marker_template_end
    );

    wfg_stim_sine wfg_stim_sine (
        .clk              (wb_clk_i),           // clock signal
        .rst_n            (!wb_rst_i),          // reset signal
        .wfg_axis_tready_i(wfg_axis_tready_i),  // ready signal - AXI
        .wfg_axis_tvalid_o(wfg_axis_tvalid_o),  // valid signal - AXI
        .wfg_axis_tdata_o (wfg_axis_tdata_o),   // sine output  - AXI
        .ctrl_en_q_i      (ctrl_en_q),          // enable/disable simulation
        .inc_val_q_i      (inc_val_q),          // angular increment
        .gain_val_q_i     (gain_val_q),         // sine gain/multiplier
        .offset_val_q_i   (offset_val_q)        // sine offset
    );

endmodule
`default_nettype wire
