//                    Copyright Message
//  --------------------------------------------------------------------------
//
//  CONFIDENTIAL and PROPRIETARY
//  COPYRIGHT (c) semify 2021
//
//  All rights are reserved. Reproduction in whole or in part is
//  prohibited without the written consent of the copyright owner.
//
//  ----------------------------------------------------------------------------
//                    Design Information
//  ----------------------------------------------------------------------------
//
//  Author: Erwin Peterlin
//
//  Description : wfg_drive_pat
//

module wfg_drive_pat #(
    parameter int CHANNELS   = 8,
    parameter int AXIS_WIDTH = 32
) (
    input logic clk,   // I; System clock
    input logic rst_n, // I; Active low reset

    // Core synchronisation interface
    input logic       wfg_core_sync_i,         // I; Start Pulse for one cycle
    input logic [7:0] wfg_core_subcycle_cnt_i, // I; Current Subcycle

    // Subcore synchronisation interface
    input logic       wfg_subcore_sync_i,         // I; Start Pulse for one cycle
    input logic [7:0] wfg_subcore_subcycle_cnt_i, // I; Current Subcycle


    input logic [CHANNELS-1:0] ctrl_en_q_i,  // I; Enable signal
    input logic [(CHANNELS*2)-1:0] patsel_q_i,  // I; Output pattern selector
    input logic [7:0] cfg_begin_q_i,  // I; Selects at which subcycle the output begins
    input logic [7:0] cfg_end_q_i,  // I; Selects at which subcycle the output ends
    input logic cfg_core_sel_q_i,  // I; Core select

    // AXI streaming interface
    output wire        wfg_axis_tready_o,  // O; ready
    input  wire        wfg_axis_tvalid_i,  // I; valid
    input  wire        wfg_axis_tlast_i,   // I; last
    input  wire [31:0] wfg_axis_tdata_i,   // I; data

    output logic [CHANNELS-1:0] pat_dout_o,    // O; output pins
    output logic [CHANNELS-1:0] pat_dout_en_o  // O; output enabled
);

    // -------------------------------------------------------------------------
    // Definition
    // -------------------------------------------------------------------------

    assign pat_dout_en_o = ctrl_en_q_i;

    logic [AXIS_WIDTH-1:0] axis_data_ff;
    logic axis_ready_ff;
    assign wfg_axis_tready_o = axis_ready_ff;

    logic wfg_sync_i;
    logic [7:0] wfg_subcycle_cnt_i;

    // -------------------------------------------------------------------------
    // Implementation
    // -------------------------------------------------------------------------

    always_comb begin
        wfg_sync_i = 'x;
        wfg_subcycle_cnt_i = 'x;

        case (cfg_core_sel_q_i)
            1'b0: begin
                wfg_sync_i         = wfg_core_sync_i;
                wfg_subcycle_cnt_i = wfg_core_subcycle_cnt_i;
            end
            1'b1: begin
                wfg_sync_i         = wfg_subcore_sync_i;
                wfg_subcycle_cnt_i = wfg_subcore_subcycle_cnt_i;
            end
        endcase
    end

    genvar k;
    generate
        for (k = 0; k < CHANNELS; k++) begin : gen_channels
            wfg_drive_pat_channel drv (
                .clk(clk),
                .rst_n(rst_n),
                .wfg_core_subcycle_cnt_i(wfg_subcycle_cnt_i),
                .patsel_q_i({patsel_q_i[k+32], patsel_q_i[k]}),
                .cfg_begin_q_i(cfg_begin_q_i),
                .cfg_end_q_i(cfg_end_q_i),
                .ctrl_en_q_i(ctrl_en_q_i[k]),
                .axis_data_ff(axis_data_ff[k]),
                .data_o(pat_dout_o[k])
            );
        end
    endgenerate

    // -------------------------------------------------------------------------
    // ff
    // -------------------------------------------------------------------------

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            axis_data_ff  <= '0;
            axis_ready_ff <= '0;
        end else begin

            if (wfg_sync_i) begin
                axis_ready_ff <= '1;

                if (wfg_axis_tvalid_i) begin
                    axis_data_ff <= wfg_axis_tdata_i;
                end
            end else begin
                axis_ready_ff <= '0;
            end

        end
    end  //always_ff
endmodule

