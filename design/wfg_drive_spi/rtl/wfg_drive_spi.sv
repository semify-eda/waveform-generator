// SPDX-FileCopyrightText: © 2022 semify <office@semify-eda.com>
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
module wfg_drive_spi #(
    parameter int AXIS_DATA_WIDTH = 32
) (
    input logic clk,   // I; System clock
    input logic rst_n, // I; active low reset

    // Core synchronisation interface
    input logic wfg_core_sync_i,     // I; Sync pulse
    input logic wfg_core_subcycle_i, // I; Subcycle pulse

    // Subcore synchronisation interface
    input logic wfg_subcore_sync_i,     // I; Sync pulse
    input logic wfg_subcore_subcycle_i, // I; Subcycle pulse

    // AXI streaming interface
    output logic                       wfg_axis_tready_o,  // O; ready
    input  logic                       wfg_axis_tvalid_i,  // I; valid
    input  logic                       wfg_axis_tlast_i,   // I; last
    input  logic [AXIS_DATA_WIDTH-1:0] wfg_axis_tdata_i,   // I; data

    // Control
    input logic ctrl_en_q_i,  // I; SPI enable

    // Configuration
    input logic [7:0] clkcfg_div_q_i,    // I; SPI speed
    input logic       cfg_cpol_q_i,      // I; Clock polarity
    input logic       cfg_lsbfirst_q_i,  // I; Frame format
    input logic [1:0] cfg_dff_q_i,       // I; Data frame format
    input logic       cfg_sspol_q_i,     // I; Slave select polarity
    input logic       cfg_core_sel_q_i,  // I; Core select

    // SPI IO interface
    output logic wfg_drive_spi_sclk_o,  // O; clock
    output logic wfg_drive_spi_cs_no,   // O; chip select
    output logic wfg_drive_spi_sdo_o    // O; data out
);

    typedef enum logic [1:0] {
        ST_IDLE,
        ST_SEND_DATA,
        ST_LAST_BIT
    } my_uart_states_t;

    my_uart_states_t cur_state, next_state;

    logic transitioning;
    assign transitioning = cur_state != next_state;

    logic [7:0] counter;
    logic [7:0] clk_div;
    logic [4:0] current_bit;
    logic [31:0] spi_data;
    logic spi_cs;       // chip slect
    logic spi_clk;      // clock
    logic ready;
    logic lsbfirst;     // lsb first
    logic cpol;         // clock polarity
    logic cspol;        // chip select control
    logic [1:0] byte_cnt;
    logic [4:0] bytes_to_bits [0:3];

    logic wfg_sync_i;
    logic wfg_subcycle_i;

    always_comb begin
        wfg_sync_i = 'x;
        wfg_subcycle_i = 'x;

        case (cfg_core_sel_q_i)
            1'b0: begin
                wfg_sync_i     = wfg_core_sync_i;
                wfg_subcycle_i = wfg_core_subcycle_i;
            end
            1'b1: begin
                wfg_sync_i     = wfg_subcore_sync_i;
                wfg_subcycle_i = wfg_subcore_subcycle_i;
            end
        endcase
    end

    // Present state logic
    always_ff @(posedge clk, negedge rst_n)
        if (!rst_n) cur_state <= ST_IDLE;
        else cur_state <= next_state;

    // State transitions
    always_comb begin
        next_state = cur_state;
        case (cur_state)
            ST_IDLE: begin
                if (wfg_sync_i && wfg_axis_tvalid_i && ctrl_en_q_i) next_state = ST_SEND_DATA;
            end
            ST_SEND_DATA: begin
                if (counter == 0 && current_bit == 0 && spi_clk) begin
                    next_state = ST_LAST_BIT;
                end
            end
            ST_LAST_BIT: begin
                if (counter == 0) next_state = ST_IDLE;
            end
            default: begin
                next_state = ST_IDLE;
            end
        endcase
    end

    // Value assignments
    always_ff @(posedge clk, negedge rst_n)
        if (!rst_n) begin
            wfg_drive_spi_sclk_o <= '0;
            wfg_drive_spi_cs_no  <= '0;
            wfg_drive_spi_sdo_o  <= '0;

            counter              <= '0;
            current_bit          <= '0;
            spi_cs               <= '0;
            spi_data             <= '0;
            spi_clk              <= '0;
            ready                <= '0;
            clk_div              <= '0;
            lsbfirst             <= '0;
            cpol                 <= '0;
            cspol                <= '0;
            byte_cnt             <= '0;
            bytes_to_bits[0]     <= 5'd7;
            bytes_to_bits[1]     <= 5'd15;
            bytes_to_bits[2]     <= 5'd23;
            bytes_to_bits[3]     <= 5'd31;

        end else begin
            wfg_drive_spi_sclk_o <= cpol ? !spi_clk : spi_clk;
            wfg_drive_spi_cs_no  <= cspol ? spi_cs : !spi_cs;
            wfg_drive_spi_sdo_o  <= lsbfirst ? spi_data[0] : spi_data[bytes_to_bits[byte_cnt]];

            case (next_state)
                ST_IDLE: begin
                    counter  <= '0;
                    spi_clk  <= '0;
                    spi_cs   <= '0;
                    spi_data <= '0;

                    clk_div  <= clkcfg_div_q_i;
                    lsbfirst <= cfg_lsbfirst_q_i;
                    byte_cnt <= cfg_dff_q_i;
                    cpol     <= cfg_cpol_q_i;
                    cspol    <= cfg_sspol_q_i;
                end
                ST_SEND_DATA: begin
                    spi_cs <= 1'b1;

                    if (transitioning) begin
                        spi_data <= wfg_axis_tdata_i;
                        ready <= 1'b1;
                        counter <= clk_div;
                        current_bit <= bytes_to_bits[byte_cnt];
                    end else begin
                        counter <= counter - 1;
                        ready   <= 1'b0;

                        if (counter == 0) begin
                            spi_clk <= !spi_clk;
                            counter <= clk_div;

                            if (spi_clk == 1'b1) begin
                                current_bit <= current_bit - 1;
                                if (lsbfirst) begin
                                    spi_data <= {1'b0, spi_data[31:1]};
                                end else begin
                                    spi_data <= {spi_data[30:0], 1'b0};
                                end
                            end
                        end
                    end
                end
                ST_LAST_BIT: begin
                    if (transitioning) begin
                        counter <= clk_div;
                    end else begin
                        counter <= counter - 1;
                    end
                    spi_cs <= 1'b1;
                    spi_clk <= 1'b0;
                    ready <= 1'b0;
                    spi_data <= 1'b0;
                end
                default: begin
                    spi_cs   <= 'x;
                    spi_clk  <= 'x;
                    spi_data <= 'x;
                end
            endcase
        end

    assign wfg_axis_tready_o = ready;

endmodule
`default_nettype wire
