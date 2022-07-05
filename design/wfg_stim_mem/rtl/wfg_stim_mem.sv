// SPDX-FileCopyrightText: © 2022 semify <office@semify-eda.com>
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
module wfg_stim_mem (
    input wire clk,   // clock signal
    input wire rst_n, // reset signal

    input  wire        wfg_axis_tready_i,  // ready signal - AXI
    output wire        wfg_axis_tvalid_o,  // valid signal - AXI
    output wire [31:0] wfg_axis_tdata_o,   // mem output   - AXI

    input wire         ctrl_en_q_i,   // enable/disable
    input logic [15:0] end_val_q_i,   // END.VAL register output
    input logic [ 7:0] inc_val_q_i,   // INC.VAL register output
    input logic [15:0] start_val_q_i, // START.VAL register output

    // Memory interface
    output              csb1,
    output       [ 9:0] addr1,
    input  logic [31:0] dout1
);
    logic [15:0] cur_address;
    logic [31:0] data;
    logic valid;

    assign csb1              = !ctrl_en_q_i;  // Enable the memory
    assign addr1             = cur_address[9:0];  // Assign address

    assign wfg_axis_tvalid_o = valid;
    assign wfg_axis_tdata_o  = data;

    typedef enum {
        ST_IDLE,
        ST_CALC,
        ST_DONE
    } wfg_stim_mem_states_t;

    wfg_stim_mem_states_t cur_state;
    wfg_stim_mem_states_t next_state;

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) cur_state <= ST_IDLE;
        else cur_state <= next_state;
    end

    always_comb begin
        next_state = cur_state;
        case (cur_state)
            ST_IDLE: begin
                if (ctrl_en_q_i) next_state = ST_CALC;
            end
            ST_CALC: begin
                next_state = ST_DONE;
            end
            ST_DONE: begin
                if (wfg_axis_tready_i == 1'b1) next_state = ST_IDLE;
            end
        endcase
    end

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            cur_address <= '0;
            valid <= '0;
            data <= '0;
        end else begin
            valid <= '0;

            case (cur_state)
                ST_IDLE: begin
                    if (!ctrl_en_q_i) begin
                        cur_address <= start_val_q_i;
                    end
                end
                ST_CALC: begin
                    if (cur_address + inc_val_q_i > end_val_q_i) begin
                        cur_address <= start_val_q_i;
                    end else begin
                        cur_address <= cur_address + inc_val_q_i;
                    end

                    data <= dout1;
                end
                ST_DONE: begin
                    valid <= '1;
                end
                default: valid <= 'x;
            endcase
        end
    end

endmodule
`default_nettype wire
