// SPDX-FileCopyrightText: © 2022 semify <office@semify-eda.com>
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
module wfg_stim_sine (
    input  wire               clk,                // clock signal
    input  wire               rst_n,              // reset signal
    input  wire               wfg_axis_tready_i,  // ready signal - AXI
    output wire               wfg_axis_tvalid_o,  // valid signal - AXI
    output wire signed [31:0] wfg_axis_tdata_o,   // sine output  - AXI
    input  wire               ctrl_en_q_i,        // enable/disable simulation
    input  wire        [15:0] inc_val_q_i,        // angular increment
    input  wire        [15:0] gain_val_q_i,       // sine gain/multiplier
    input  wire signed [17:0] offset_val_q_i      // sine offset
);
    // 0.60725*2^16, expand the decimal by 2^16 to reduce the error
    parameter bit [15:0] K = 16'h9b74;

    // Because arithmetic shift is used, a signed type needs to be defined
    logic signed [16:0] sin_17;
    logic signed [17:0] sin_18;

    // Used as a temporary variable
    logic signed [16:0] x;
    logic signed [16:0] y;
    logic signed [16:0] z;

    // quadrant
    logic [1:0]  quadrant;

    // Store the angle of each rotation
    logic [15:0] rot[0:15];
    logic [3:0] iteration;
    logic signed [34:0] temp;

    logic valid;
    logic [15:0] phase_in;
    logic [15:0] increment;
    logic signed [17:0] overflow_chk;

    typedef enum {
        ST_IDLE,
        ST_CALC,
        ST_QUADRANT,
        ST_GAIN,
        ST_OFFSET,
        ST_DONE
    } wfg_stim_sine_states_t;

    wfg_stim_sine_states_t cur_state;
    wfg_stim_sine_states_t next_state;

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) cur_state <= ST_IDLE;
        else cur_state <= next_state;
    end

    always_comb begin
        next_state = cur_state;
        case (cur_state)
            ST_IDLE: begin
                if (ctrl_en_q_i == 1'b1) next_state = ST_CALC;
            end
            ST_CALC: begin
                if (iteration == 15) next_state = ST_QUADRANT;
            end
            ST_QUADRANT:    next_state = ST_GAIN;
            ST_GAIN:        next_state = ST_OFFSET;
            ST_OFFSET:      next_state = ST_DONE;
            ST_DONE: begin
                if (wfg_axis_tready_i == 1'b1) next_state = ST_IDLE;
            end
            default: next_state = ST_IDLE; // TODO wfg_stim_sine_states_t'('x);
        endcase
    end

    assign increment = inc_val_q_i + phase_in;

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            rot[0]       <= 16'h2000;  //45
            rot[1]       <= 16'h12e4;  //26.5651
            rot[2]       <= 16'h09fb;  //14.0362
            rot[3]       <= 16'h0511;  //7.1250
            rot[4]       <= 16'h028b;  //3.5763
            rot[5]       <= 16'h0145;  //1.7899
            rot[6]       <= 16'h00a3;  //0.8952
            rot[7]       <= 16'h0051;  //0.4476
            rot[8]       <= 16'h0028;  //0.2238
            rot[9]       <= 16'h0014;  //0.1119
            rot[10]      <= 16'h000a;  //0.0560
            rot[11]      <= 16'h0005;  //0.0280
            rot[12]      <= 16'h0003;  //0.0140
            rot[13]      <= 16'h0001;  //0.0070
            rot[14]      <= 16'h0001;  //0.0035
            rot[15]      <= 16'h0000;  //0.0018

            x            <= K;
            y            <= '0;
            z            <= '0;

            iteration    <= '0;
            phase_in     <= '0;

            valid        <= '0;
            sin_17       <= '0;

            quadrant     <= '0;
            sin_18       <= '0;
            temp         <= '0;
            overflow_chk <= '0;

        end else begin
            valid <= 0;

            case (cur_state)
                ST_IDLE: begin
                    iteration <= 0;
                    x <= K;
                    y <= '0;

                    // The first two digits of the input indicate the quadrant
                    quadrant <= phase_in[15:14];
                    // z is used to store the angle after transforming to the first quadrant
                    z <= {3'b0, phase_in[13:0]};
                end
                ST_CALC: begin
                    iteration <= iteration + 1;  // TODO check

                    if (z[16] == 1'b1) begin
                        x <= x + (y >>> (iteration));
                        y <= y - (x >>> (iteration));
                        z <= z + rot[iteration];
                    end else begin
                        x <= x - (y >>> (iteration));
                        y <= y + (x >>> (iteration));
                        z <= z - rot[iteration];
                    end


                end
                ST_QUADRANT: begin
                    case (quadrant)
                        2'b00: begin  // The first quadrant
                            sin_17 <= y;  // sin
                        end
                        2'b01: begin  // The second quadrant
                            sin_17 <= x;  // cos
                        end
                        2'b10: begin  // The third quadrant
                            sin_17 <= ~(y) + 1'b1;  // -sin
                        end
                        2'b11: begin  // The fourth quadrant
                            sin_17 <= ~(x) + 1'b1;  // -cos
                        end
                        default: begin
                            sin_17 <= 'x;
                        end
                    endcase
                end
                ST_GAIN: begin
                    // Multiplying by gain value - signed multiplication
                    if (gain_val_q_i[15:0] > 16'h7FFF) begin
                        temp[34:0] <= {{16{sin_17[16]}}, sin_17[15:0]} * {{16{1'b0}}, 16'h7FFF};
                    end else begin
                        temp[34:0] <=   {{16{sin_17[16]}}, sin_17[15:0]} *
                                        {{16{1'b0}}, gain_val_q_i[15:0]};
                    end
                end
                ST_OFFSET: begin
                    // Adding the offset value
                    overflow_chk[17:0] <= temp[31:14] + offset_val_q_i[17:0];
                end
                ST_DONE: begin
                    valid <= 1;
                    // Underflow check
                    if (temp[31] && offset_val_q_i[17] && !overflow_chk[17]) begin
                        sin_18 <= 18'b100000000000000000;
                        // Overflow check
                    end else if (!temp[31] && !offset_val_q_i[17] && overflow_chk[17]) begin
                        sin_18 <= 18'b011111111111111111;
                    end else begin
                        sin_18 <= overflow_chk;
                    end

                    if (wfg_axis_tready_i == 1'b1) phase_in <= increment;
                end
                default: valid <= 'x;
            endcase
        end
    end

    // I/O assignment
    assign wfg_axis_tdata_o  = sin_18;
    assign wfg_axis_tvalid_o = valid;

endmodule
`default_nettype wire
