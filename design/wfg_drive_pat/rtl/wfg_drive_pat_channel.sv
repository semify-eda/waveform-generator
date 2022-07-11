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
//  Description : wfg_drive_pat_channel
//
module wfg_drive_pat_channel (
    input logic clk,   // I; System clock
    input logic rst_n, // I; Active low reset

    input logic [7:0] wfg_core_subcycle_cnt_i,
    input logic [1:0] patsel_q_i,
    input logic [7:0] cfg_begin_q_i,
    input logic [7:0] cfg_end_q_i,
    input logic       ctrl_en_q_i,
    input logic       axis_data_ff,

    output logic data_o
);

    logic data_next, data_ff;
    assign data_o = data_ff;

    always_comb begin
        data_next = data_ff;

        if (wfg_core_subcycle_cnt_i == cfg_begin_q_i) begin
            data_next = axis_data_ff;
        end  //if

        if (wfg_core_subcycle_cnt_i == cfg_end_q_i) begin
            case (patsel_q_i)
                2'b00: begin
                    data_next = '0;
                end  //RZ
                2'b01: begin
                    data_next = '1;
                end  //RO
                2'b10: begin
                    data_next = data_ff;
                end  //NRZ
                2'b11: begin
                    if (data_ff == '0 || data_ff == '1) begin
                        data_next = !axis_data_ff;
                    end  //if
                end  //RC
                default: data_next = 'x;
                //default: $error("invalid pat_select");
            endcase
        end  //if

        if (!ctrl_en_q_i) begin
            data_next = '0;
        end  //if
    end  //always_comb


    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_ff <= '0;
        end else begin
            data_ff <= data_next;
        end
    end  //always_ff
endmodule
