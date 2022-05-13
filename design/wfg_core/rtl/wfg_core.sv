// SPDX-FileCopyrightText: © 2022 semify <office@semify-eda.com>
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
module wfg_core (
    input wire clk,    // I; System clock
    input wire rst_n,  // I; Active low reset
    input wire en_i,   // I; Enable signal

    // Config
    input wire [ 7:0] wfg_sync_count_i,     // I; Sync counter threshold
    input wire [15:0] wfg_subcycle_count_i, // I; Subcycle counter threshold

    // Signals
    output wire       wfg_pat_sync_o,          // O; Sync signal
    output wire       wfg_pat_subcycle_o,      // O; Subcycle signal
    output wire       wfg_pat_start_o,         // O; Indicate start
    output wire [7:0] wfg_pat_subcycle_cnt_o,  // O; Subcycle pulse counter
    output wire       active_o                 // O; Active indication signal
);

    // -------------------------------------------------------------------------
    // Definition
    // -------------------------------------------------------------------------

    reg [15:0]   subcycle_count_ff;   // L; counting variable
    reg [ 7:0]   sync_count_ff;       // L; counting variable
    reg        temp_subcycle_ff;    // L; Internal subcycle_ff
    reg        temp_sync_ff;        // L; Internal subcycle_ff
    reg        subcycle_dly;        // L; Rising edge det subcycle
    reg        sync_dly;            // L; Rising edge det sync
    reg        en_i_dly;            // L; Rising edge det enable
    reg [ 7:0]   subcycle_pls_cnt;    // L; Counts Subcycles

    // -------------------------------------------------------------------------
    // Implementation
    // -------------------------------------------------------------------------

    always @(posedge clk, negedge rst_n) begin

        if (~rst_n) begin
            subcycle_count_ff <= 16'd0;
            sync_count_ff    <=  8'd0;
            temp_subcycle_ff <=  1'b0;
            temp_sync_ff    <=  1'b0;
            subcycle_pls_cnt  <=  8'd0;
        end else begin

            if (en_i) begin

                if (subcycle_count_ff > 0) begin
                    temp_subcycle_ff  <= temp_subcycle_ff;
                    subcycle_count_ff <= subcycle_count_ff - 1;
                end else begin
                    temp_subcycle_ff  <= ~temp_subcycle_ff;
                    subcycle_count_ff <= (wfg_subcycle_count_i);

                    if (sync_count_ff > 0) begin
                        temp_sync_ff  <= temp_sync_ff;
                        sync_count_ff <= sync_count_ff - 1;
                    end else begin
                        temp_sync_ff  <= ~temp_sync_ff;
                        sync_count_ff <= (wfg_sync_count_i);
                    end

                end

                if (wfg_pat_subcycle_o) begin
                    subcycle_pls_cnt <= subcycle_pls_cnt + 1;
                end

            end else begin
                subcycle_count_ff <= 8'd0;
                sync_count_ff     <= 8'd0;
                temp_subcycle_ff  <= 1'b0;
                temp_sync_ff      <= 1'b0;
                subcycle_pls_cnt  <= 8'd0;
            end

            subcycle_dly <= temp_subcycle_ff;
            sync_dly     <= temp_sync_ff;
            en_i_dly     <= en_i;

            if (wfg_pat_sync_o) begin
                subcycle_pls_cnt <= 8'd0;
            end

        end

    end

    assign wfg_pat_subcycle_o     = temp_subcycle_ff & ~subcycle_dly;
    assign wfg_pat_sync_o         = temp_sync_ff & ~sync_dly;
    assign active_o               = en_i;
    assign wfg_pat_start_o        = en_i & ~en_i_dly;
    assign wfg_pat_subcycle_cnt_o = subcycle_pls_cnt;

endmodule
`default_nettype wire
