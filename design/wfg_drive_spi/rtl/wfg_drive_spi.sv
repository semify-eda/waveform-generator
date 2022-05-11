// SPDX-FileCopyrightText: © 2022 semify <office@semify-eda.com>
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
module wfg_drive_spi #(
    parameter int AXIS_DATA_WIDTH = 32
) (
    input wire clk,   // I; System clock
    input wire rst_n, // I; active low reset

    // Core synchronisation interface
    input wire wfg_pat_sync_i,     // I; Sync pulse
    input wire wfg_pat_subcycle_i, // I; Subcycle pulse

    // AXI streaming interface
    output wire                       wfg_drive_spi_tready_o,  // O; ready
    input  wire                       wfg_drive_spi_tvalid_i,  // I; valid
    input  wire                       wfg_drive_spi_tlast_i,   // I; last
    input  wire [AXIS_DATA_WIDTH-1:0] wfg_drive_spi_tdata_i,   // I; data

    // Control
    input wire ctrl_en_q_i,  // I; SPI enable

    // Configuration
    input wire [7:0] clkcfg_div_q_i,    // I; SPI speed
    input wire       cfg_cpha_q_i,      // I; Clock phase
    input wire       cfg_cpol_q_i,      // I; Clock polarity
    input wire       cfg_mstr_q_i,      // I; Master selection
    input wire       cfg_lsbfirst_q_i,  // I; Frame format
    input wire [1:0] cfg_dff_q_i,       // I; Data frame format
    input wire       cfg_ssctrl_q_i,    // I; Slave select control
    input wire       cfg_sspol_q_i,     // I; Slave select polarity
    input wire [1:0] cfg_oectrl_q_i,    // I; Output enable conrol

    // Test
    input wire test_lpen_q_i,  // I; Internal loop back enable

    // register info

    // ID

    // SPI IO interface
    output wire wfg_drive_spi_sclk_o,   // O; clock
    output wire wfg_drive_spi_cs_no,    // O; chip select
    output wire wfg_drive_spi_sdo_o,    // O; data out
    output wire wfg_drive_spi_sdo_en_o  // O; data out enable
);

    // -------------------------------------------------------------------------
    // Definition
    // -------------------------------------------------------------------------

    logic [4:0]  bit_width;     // L; SPI transmission bitwidth
    logic        cs_nff;        // L; Internal CS
    logic        cs_set;        // L; Internal CS set
    logic [7:0]  sck_cnt_ff;    // L; SCK Counter FF
    logic        sck_ff;        // L; Internal SCK
    logic        sck_set;       // L; Internal SCK Set
    logic [4:0]  bit_cnt_ff;    // L; Count transmitted bits
    logic        bit_cnt_rdy;   // L; Transmission finished
    logic [31:0] data_ff;       // L; Input data buffer
    logic [31:0] data_shft_ff;  // L; MOSI shift reg

    // -------------------------------------------------------------------------
    // Implementation
    // -------------------------------------------------------------------------

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin

            cs_set     <= 1'b0;
            cs_nff     <= 1'b0;
            sck_set    <= 1'b0;
            sck_ff     <= 1'b0;
            sck_cnt_ff <= 8'd0;
            bit_cnt_ff <= 5'd0;

        end else begin

            if (ctrl_en_q_i) begin

                // Sync reset
                if (wfg_pat_sync_i) begin
                    sck_set <= 1'b0;
                    sck_ff <= 1'b0;
                    cs_set <= 1'b1;
                    sck_cnt_ff <= clkcfg_div_q_i;

                    case (cfg_dff_q_i)
                        2'b00: begin
                            bit_cnt_ff <= 6'd7;
                            bit_width  <= 6'd7;
                        end
                        2'b01: begin
                            bit_cnt_ff <= 6'd15;
                            bit_width  <= 6'd15;
                        end
                        2'b10: begin
                            bit_cnt_ff <= 6'd23;
                            bit_width  <= 6'd23;
                        end
                        2'b11: begin
                            bit_cnt_ff <= 6'd31;
                            bit_width  <= 6'd31;
                        end
                        default: bit_cnt_ff <= 'x;
                    endcase
                end

                if (cs_nff) begin

                    cs_set <= 1'b0;

                    // SCK count
                    if (sck_cnt_ff > 0) begin
                        sck_cnt_ff <= sck_cnt_ff - 1'b1;
                        sck_set <= 1'b0;
                    end else begin
                        sck_set <= 1'b1;
                        sck_cnt_ff <= clkcfg_div_q_i;
                        sck_ff <= ~sck_ff;

                        if (~bit_cnt_rdy & sck_ff) begin
                            bit_cnt_ff <= bit_cnt_ff - 1'b1;
                            if (cfg_lsbfirst_q_i) begin
                                data_shft_ff <= {1'b0, data_shft_ff[31:1]};
                            end else if (~cfg_lsbfirst_q_i) begin
                                data_shft_ff <= {data_shft_ff[30:0], 1'b0};
                            end
                        end

                    end

                    if (bit_cnt_rdy & sck_ff & (sck_cnt_ff == 0)) begin
                        cs_nff  <= 1'b0;
                        sck_set <= 1'b0;
                    end
                end

                if (cs_set) begin
                    cs_nff <= 1'b1;
                    data_shft_ff <= data_ff;
                end

            end
        end
    end

    // -------------------------------------------------------------------------
    // Internal reg
    // -------------------------------------------------------------------------

    assign bit_cnt_rdy = (bit_cnt_ff == 0);
    assign data_ff = wfg_drive_spi_tdata_i;

    // -------------------------------------------------------------------------
    // Outputs
    // -------------------------------------------------------------------------

    assign wfg_drive_spi_tready_o = wfg_pat_sync_i;
    assign wfg_drive_spi_sdo_en_o = wfg_drive_spi_tvalid_i;
    assign wfg_drive_spi_cs_no = (cfg_sspol_q_i ? cs_nff : ~cs_nff);
    assign wfg_drive_spi_sclk_o   = cs_nff ?
                                    (cfg_cpol_q_i ? ~sck_ff : sck_ff) ^ cfg_cpha_q_i
                                    : cfg_cpol_q_i;
    assign wfg_drive_spi_sdo_o    = (cfg_lsbfirst_q_i ? data_shft_ff[0] : data_shft_ff[bit_width])
                                    & cs_nff;

endmodule
`default_nettype wire
