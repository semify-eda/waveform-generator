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
    output wire       wfg_core_sync_o,          // O; Sync signal
    output wire       wfg_core_subcycle_o,      // O; Subcycle signal
    output wire       wfg_core_start_o,         // O; Indicate start
    output wire [7:0] wfg_core_subcycle_cnt_o,  // O; Subcycle pulse counter
    output wire       active_o                  // O; Active indication signal
);

    // -------------------------------------------------------------------------
    // Definition
    // -------------------------------------------------------------------------

    logic [15:0]   subcycle_count;   // L; counting variable
    logic [ 7:0]   sync_count;       // L; counting variable
    logic        temp_subcycle;    // L; Internal subcycle
    logic        temp_sync;        // L; Internal subcycle
    logic        subcycle_dly;        // L; Rising edge det subcycle
    logic        sync_dly;            // L; Rising edge det sync
    logic        en_i_dly;            // L; Rising edge det enable
    logic [ 7:0]   subcycle_pls_cnt;    // L; Counts Subcycles

    // -------------------------------------------------------------------------
    // Implementation
    // -------------------------------------------------------------------------

    always @(posedge clk, negedge rst_n) begin

        if (~rst_n) begin
            subcycle_count <= 16'd0;
            sync_count    <=  8'd0;
            temp_subcycle <=  1'b0;
            temp_sync    <=  1'b0;
            subcycle_pls_cnt  <=  8'd0;
        end else begin

            if (en_i) begin

                if (subcycle_count > 0) begin
                    temp_subcycle  <= temp_subcycle;
                    subcycle_count <= subcycle_count - 1;
                end else begin
                    temp_subcycle  <= ~temp_subcycle;
                    subcycle_count <= (wfg_subcycle_count_i);

                    if (sync_count > 0) begin
                        temp_sync  <= temp_sync;
                        sync_count <= sync_count - 1;
                    end else begin
                        temp_sync  <= ~temp_sync;
                        sync_count <= (wfg_sync_count_i);
                    end

                end

                if (wfg_core_subcycle_o) begin
                    subcycle_pls_cnt <= subcycle_pls_cnt + 1;
                end

            end else begin
                subcycle_count   <= 8'd0;
                sync_count       <= 8'd0;
                temp_subcycle    <= 1'b0;
                temp_sync        <= 1'b0;
                subcycle_pls_cnt <= 8'd0;
            end

            subcycle_dly <= temp_subcycle;
            sync_dly     <= temp_sync;
            en_i_dly     <= en_i;

            if (wfg_core_sync_o) begin
                subcycle_pls_cnt <= 8'd0;
            end

        end

    end

    assign wfg_core_subcycle_o     = temp_subcycle & ~subcycle_dly;
    assign wfg_core_sync_o         = temp_sync & ~sync_dly;
    assign active_o                = en_i;
    assign wfg_core_start_o        = en_i & ~en_i_dly;
    assign wfg_core_subcycle_cnt_o = subcycle_pls_cnt;

endmodule
`default_nettype wire
