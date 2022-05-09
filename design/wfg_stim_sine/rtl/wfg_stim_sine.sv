// SPDX-FileCopyrightText: © 2022 semify <office@semify-eda.com>
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
module wfg_stim_sine (
    input  wire               clk,                    // clock signal
    input  wire               rst_n,                  // reset signal
    input  wire               wfg_stim_spi_tready_o,  // ready signal - AXI
    output wire               wfg_stim_spi_tvalid_i,  // valid signal - AXI
    output wire signed [17:0] wfg_stim_spi_tdata_i,   // sine output - AXI
    input  wire               ctrl_en_q_i,            // enable/disable simulation
    input  wire        [15:0] inc_val_q_i,            // angular increment
    input  wire        [15:0] gain_val_q_i,           // sine gain/multiplier
    input  wire signed [17:0] offset_val_q_i          // sine offset
);
    // 0.60725*2^16, expand the decimal by 2^16 to reduce the error
    parameter bit [15:0] K = 16'h9b74;
    // Because arithmetic shift is used, a signed type needs to be defined
    logic signed [16:0] sin_17;
    logic signed [16:0] sin_17_ff;
    logic signed [17:0] sin_18;
    logic signed [16:0] x0;
    logic signed [16:0] y0;
    // Used as a temporary variable
    logic signed [16:0] temp1;
    logic signed [16:0] temp2;
    logic signed [16:0] z;
    logic signed [16:0] z_z;
    // quadrant
    logic [1:0]  quadrant;
    // Store the angle of each rotation
    logic [15:0] rot[0:15];
    logic [31:0] i;
    logic signed [34:0] temp;
    logic [15:0] phase_in;
    logic [15:0] increment;
    logic valid;
    logic signed [17:0] overflow_chk;

    always_ff @(posedge clk, negedge rst_n) begin
        // Reset
        if (~rst_n) begin
            temp1 <= K;
            temp2 <= 0;
            rot[0] <= 16'h2000;  //45
            rot[1] <= 16'h12e4;  //26.5651
            rot[2] <= 16'h09fb;  //14.0362
            rot[3] <= 16'h0511;  //7.1250
            rot[4] <= 16'h028b;  //3.5763
            rot[5] <= 16'h0145;  //1.7899
            rot[6] <= 16'h00a3;  //0.8952
            rot[7] <= 16'h0051;  //0.4476
            rot[8] <= 16'h0028;  //0.2238
            rot[9] <= 16'h0014;  //0.1119
            rot[10] <= 16'h000a;  //0.0560
            rot[11] <= 16'h0005;  //0.0280
            rot[12] <= 16'h0003;  //0.0140
            rot[13] <= 16'h0001;  //0.0070
            rot[14] <= 16'h0001;  //0.0035
            rot[15] <= 16'h0000;  //0.0018
            phase_in <= 16'h0000;
            valid <= 1'b0;
            i <= 32'h00000000;
            z <= 17'b00000000000000000;
            sin_17_ff <= 18'b000000000000000000;

            // Update phase by an increment value
        end else begin
            if (ctrl_en_q_i == 1'b1) begin
                if (i == 0) begin
                    temp1 <= K;
                    temp2 <= 0;
                    // The first two digits of the input indicate the quadrant
                    quadrant <= increment[15:14];
                    // z is used to store the angle after transforming to the first quadrant
                    z <= {3'b0, increment[13:0]};
                    i <= i + 1;
                    phase_in <= increment;
                end else begin
                    if (i > 15) begin
                        if (wfg_stim_spi_tready_o) begin
                            i <= 0;
                            sin_17_ff <= sin_17;
                        end
                        valid <= 1'b1;
                    end else begin
                        i <= i + 1;
                        valid <= 1'b0;
                        // You need to assign the current value to temp every time you loop
                        temp1 <= x0;
                        temp2 <= y0;
                        z <= z_z;
                    end
                end
            end
        end
    end

    always_comb begin
        if (z[16] && i >= 1 && i < 17) begin
            x0  = temp1 + (temp2 >>> (i - 1));
            y0  = temp2 - (temp1 >>> (i - 1));
            z_z = z + rot[(i-1)];
        end else if (i >= 1 && i < 17) begin
            x0  = temp1 - (temp2 >>> (i - 1));
            y0  = temp2 + (temp1 >>> (i - 1));
            z_z = z - rot[(i-1)];
        end

        if (i == 32'h0000000F) begin
            case (quadrant)
                2'b00: begin  // The first quadrant
                    sin_17 = y0;
                end
                2'b01: begin  // The second quadrant
                    sin_17 = x0;  // cos
                end
                2'b10: begin  // The third quadrant
                    sin_17 = ~(y0) + 1'b1;  // -sin
                end
                2'b11: begin  // The fourth quadrant
                    sin_17 = ~(x0) + 1'b1;  // -cos
                end
                default: begin
                    sin_17 = 'x;
                end
            endcase
        end
    end

    always_comb begin
        // Multiplying by gain value - signed multiplication
        if (gain_val_q_i[15:0] > 16'h7FFF) begin
            temp[34:0] = {{16{sin_17_ff[16]}}, sin_17_ff[15:0]} * {{16{1'b0}}, 16'h7FFF};
        end else begin
            temp[34:0] = {{16{sin_17_ff[16]}}, sin_17_ff[15:0]} * {{16{1'b0}}, gain_val_q_i[15:0]};
        end
        // Adding the offset value
        overflow_chk[17:0] = temp[31:14] + offset_val_q_i[17:0];
        // Underflow check
        if (temp[31] && offset_val_q_i[17] && !overflow_chk[17]) begin
            sin_18[17:0] = 18'b100000000000000000;
            // Overflow check
        end else if (!temp[31] && !offset_val_q_i[17] && overflow_chk[17]) begin
            sin_18[17:0] = 18'b011111111111111111;
        end else begin
            sin_18[17:0] = overflow_chk[17:0];
        end
        increment[15:0] = inc_val_q_i[15:0] + phase_in[15:0];

    end

    // I/O assignment
    assign wfg_stim_spi_tdata_i[17:0] = sin_18[17:0];
    assign wfg_stim_spi_tvalid_i = valid;

endmodule
`default_nettype wire
