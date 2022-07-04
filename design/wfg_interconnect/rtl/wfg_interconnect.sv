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

module wfg_interconnect #(
    parameter int AXIS_DATA_WIDTH = 32
) (
    input logic clk,   // I; System clock
    input logic rst_n, // I; active low reset

    // Control
    input logic ctrl_en_q_i,

    // Configuration
    input logic [1:0] driver0_select_q_i,
    input logic [1:0] driver1_select_q_i,

    // Stimuli
    input axis_t stimulus_0,
    input axis_t stimulus_1,

    output logic wfg_axis_tready_stimulus_0,
    output logic wfg_axis_tready_stimulus_1,

    // Driver
    output axis_t driver_0,
    output axis_t driver_1,

    input wfg_axis_tready_driver_0,
    input wfg_axis_tready_driver_1
);

    // Driver 0
    always_comb begin
        case (driver0_select_q_i)
            2'b00: driver_0 = stimulus_0;
            2'b01: driver_0 = stimulus_1;
            2'b10: driver_0 = '0;
            2'b11: driver_0 = '0;
            default: driver_0 = 'x;
        endcase
    end

    // Driver 1
    always_comb begin
        case (driver1_select_q_i)
            2'b00: driver_1 = stimulus_0;
            2'b01: driver_1 = stimulus_1;
            2'b10: driver_1 = '0;
            2'b11: driver_1 = '0;
            default: driver_1 = 'x;
        endcase
    end

    // Stimulus 0
    always_comb begin
        if (driver0_select_q_i == 2'b00 && driver1_select_q_i == 2'b00) begin
            wfg_axis_tready_stimulus_0 = wfg_axis_tready_driver_0 && wfg_axis_tready_driver_1;
        end else if (driver0_select_q_i == 2'b00) begin
            wfg_axis_tready_stimulus_0 = wfg_axis_tready_driver_0;
        end else if (driver1_select_q_i == 2'b00) begin
            wfg_axis_tready_stimulus_0 = wfg_axis_tready_driver_1;
        end else begin
            wfg_axis_tready_stimulus_0 = '0;
        end
    end

    // Stimulus 1
    always_comb begin
        if (driver0_select_q_i == 2'b01 && driver1_select_q_i == 2'b01) begin
            wfg_axis_tready_stimulus_1 = wfg_axis_tready_driver_0 && wfg_axis_tready_driver_1;
        end else if (driver0_select_q_i == 2'b01) begin
            wfg_axis_tready_stimulus_1 = wfg_axis_tready_driver_0;
        end else if (driver1_select_q_i == 2'b01) begin
            wfg_axis_tready_stimulus_1 = wfg_axis_tready_driver_1;
        end else begin
            wfg_axis_tready_stimulus_1 = '0;
        end
    end

endmodule
`default_nettype wire
