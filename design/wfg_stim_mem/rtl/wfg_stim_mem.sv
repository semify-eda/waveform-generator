// SPDX-FileCopyrightText: © 2022 semify <office@semify-eda.com>
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
module wfg_stim_mem (
    input wire clk,   // clock signal
    input wire rst_n, // reset signal

    input  wire        wfg_axis_tready_i,  // ready signal - AXI
    output wire        wfg_axis_tvalid_o,  // valid signal - AXI
    output wire [31:0] wfg_axis_tdata_o,   // mem output   - AXI

    input wire         ctrl_en_q_i,    // enable/disable
    input logic [15:0] end_val_q_i,    // END.VAL register output
    input logic [15:0] start_val_q_i,  // START.VAL register output
    input logic [ 7:0] cfg_inc_q_i,    // CFG.INC register output
    input logic [15:0] cfg_gain_q_i,   // CFG.GAIN register output

    // Memory interface
    output              csb1,
    output       [ 9:0] addr1,
    input  logic [31:0] dout1
);
    logic [15:0] cur_address;
    logic [31:0] data;
    logic [31:0] data_calc;
    logic valid;

    assign csb1              = !ctrl_en_q_i;  // Enable the memory
    assign addr1             = cur_address[9:0];  // Assign address

    assign wfg_axis_tvalid_o = valid;
    assign wfg_axis_tdata_o  = data;

    typedef enum {
        ST_IDLE,
        ST_READ,
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
                if (ctrl_en_q_i) next_state = ST_READ;
            end
            ST_READ: begin
                next_state = ST_CALC;
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
                ST_READ: begin
                    if (cur_address + cfg_inc_q_i > end_val_q_i) begin
                        cur_address <= start_val_q_i;
                    end else begin
                        cur_address <= cur_address + cfg_inc_q_i;
                    end
                end
                ST_CALC: begin
                    data <= data_calc;
                end
                ST_DONE: begin
                    valid <= '1;
                end
                default: valid <= 'x;
            endcase
        end
    end

    dsp_scale_sn_us #(
        .DATA_W(32),
        .SCALE_W(16),
        .SCALE_SHFT(0)
    ) dsp_scale_sn_us_inst (
        .clk     (clk),   // I; System clock
        .reset_ni(rst_n), // I; active loaw reset

        // Data interface
        .scale_gif_data_in_update_i(next_state == ST_CALC),  // I; GIF update pulse
        .scale_gif_data_in_i       (dout1),                  // I; GIF data to be scaled (signed)
        .scale_factor_i            (cfg_gain_q_i),           // I; Scaling factor (unsigned)
        .scale_gif_result_update_o (),                       // O; GIF update pulse
        .scale_gif_result_o        (data_calc)
    );

endmodule
`default_nettype wire
