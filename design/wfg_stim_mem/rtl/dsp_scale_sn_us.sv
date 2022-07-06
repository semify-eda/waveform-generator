// SPDX-FileCopyrightText: © 2022 semify <office@semify-eda.com>
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

module dsp_scale_sn_us #(
    parameter integer DATA_W     = 8,
    parameter integer SCALE_W    = 16,
    parameter integer SCALE_SHFT = 1
) (
    input wire clk,      // I; System clock
    input wire reset_ni, // I; active loaw reset

    // Data interface
    input wire scale_gif_data_in_update_i,  // I; GIF update pulse
    input wire signed [DATA_W-1 : 0] scale_gif_data_in_i,  // I; GIF data to be scaled (signed)
    input wire [SCALE_W-1:0] scale_factor_i,  // I; Scaling factor (unsigned)
    output logic scale_gif_result_update_o,  // O; GIF update pulse
    output logic signed [DATA_W-1 : 0] scale_gif_result_o  // O; GIF scaled data (signed)
);



    // -------------------------------------------------------------------------
    // Definition
    // -------------------------------------------------------------------------
    localparam integer MUL_SIZE = DATA_W + SCALE_W + 1;
    localparam integer OVL_SIZE = SCALE_W - SCALE_SHFT + 1;
    localparam logic [OVL_SIZE:0] NO_OVL_POS = '0;
    localparam logic [OVL_SIZE:0] NO_OVL_NEG = '1;

    // multiplication result
    logic signed [MUL_SIZE-1:0] mul_result;
    logic signed [DATA_W-1  :0] mul_result_sat;

    // FF for storing the result
    logic                      scale_gif_result_update_ff;     // update pulse
    logic signed [DATA_W-1 :0] scale_gif_result_ff;            // GIF scaled data (signed)



    // -------------------------------------------------------------------------
    // Implementation
    // -------------------------------------------------------------------------


    // Saturation and scaling
    always_comb begin
        mul_result = $signed({1'b0, scale_factor_i}) * $signed(scale_gif_data_in_i);
        if ((mul_result[MUL_SIZE-1 -: OVL_SIZE+1] == NO_OVL_POS) | (mul_result[MUL_SIZE-1 -: OVL_SIZE+1] == NO_OVL_NEG)) begin
            // no overflow or underflow
            //mul_result_sat = mul_result[ (MUL_SIZE-1) - (SCALE_W-SCALE_SHFT+1) -: DATA_W];
            mul_result_sat = mul_result[DATA_W-1 : 0];
        end else if (mul_result[MUL_SIZE-1]) begin
            // underflow
            mul_result_sat = {1'b1, {(DATA_W - 1) {1'b0}}};
        end else begin
            // overflow
            mul_result_sat = {1'b0, {(DATA_W - 1) {1'b1}}};
        end
    end

    // Result storage
    always_ff @(posedge clk, negedge reset_ni) begin
        if (~reset_ni) begin
`ifndef FPGA_ASYNC_RESET_DISABLE
            scale_gif_result_ff <= '0;
`endif
            scale_gif_result_update_ff <= 1'b0;
        end else begin
            if (scale_gif_data_in_update_i) begin
                scale_gif_result_ff        <= mul_result_sat;
                scale_gif_result_update_ff <= 1'b1;
            end else begin
                scale_gif_result_update_ff <= 1'b0;
            end
        end
    end


    // Outputs ------------------------------------------------------------------
    assign scale_gif_result_update_o = scale_gif_result_update_ff;
    assign scale_gif_result_o        = scale_gif_result_ff;


endmodule


module dsp_scale_sn_us_2 #(
    parameter integer DATA_W     = 16,
    parameter integer SCALE_W    = 16,
    parameter integer SCALE_SHFT = 1
) (
    input wire clk,      // I; System clock
    input wire reset_ni, // I; active loaw reset

    // Data interface
    input wire scale_gif_data_in_update_i,  // I; GIF update pulse
    input wire signed [DATA_W-1 : 0] scale_gif_data_in_i,  // I; GIF data to be scaled (signed)
    input wire [SCALE_W-1:0] scale_factor_i,  // I; Scaling factor (unsigned)
    output logic scale_gif_result_update_o,  // O; GIF update pulse
    output logic signed [DATA_W-1 : 0] scale_gif_result_o  // O; GIF scaled data (signed)
);

    // -------------------------------------------------------------------------
    // Definition
    // -------------------------------------------------------------------------
    localparam integer MUL_SIZE = DATA_W + SCALE_W + SCALE_SHFT;  // width of full muliplcation
    localparam integer MUL_SAT_SIZE    = MUL_SIZE - (SCALE_W - SCALE_SHFT); // width of saturated multiplaction result

    // multiplication result
    logic signed [MUL_SIZE-1:0] mul_result;
    logic signed [MUL_SAT_SIZE-1:0] mul_result_sat;       // saturated multiplication
    logic signed [DATA_W-1      :0] mul_result_sat_round; // saturated multiplication rounded to output bit width

    // FF for storing the result
    logic                      scale_gif_result_update_ff;     // update pulse
    logic signed [DATA_W-1 :0] scale_gif_result_ff;            // GIF scaled data (signed)



    // -------------------------------------------------------------------------
    // Implementation
    // -------------------------------------------------------------------------

    // Multiplication
    // assign mul_result = $signed({1'b0, scale_factor_i}) * $signed(scale_gif_data_in_i);
    assign mul_result = {1'b0, scale_factor_i} * $signed(
        {scale_gif_data_in_i, {(SCALE_SHFT) {1'b0}}}
    );

    // Saturation
    dsp_saturate_sn #(
        .DATA_IN_W (MUL_SIZE),
        .DATA_OUT_W(MUL_SAT_SIZE)
    ) u_dsp_saturate_sn (
        .data_in_i (mul_result),     // I; data to be saturated
        .data_of_o (),               // O; indicates that a data overflow occurs
        .data_out_o(mul_result_sat)  // O; saturated data
    );

    // Rounding
    dsp_round_sn #(
        .DATA_IN_W (MUL_SAT_SIZE),
        .DATA_OUT_W(DATA_W)
    ) u_dsp_round_us (
        .data_in_i (mul_result_sat),       // I; data to be rounded
        .data_out_o(mul_result_sat_round)  // O; rounded data
    );

    // Result storage
    always_ff @(posedge clk, negedge reset_ni) begin
        if (~reset_ni) begin
`ifndef FPGA_ASYNC_RESET_DISABLE
            scale_gif_result_ff <= '0;
`endif
            scale_gif_result_update_ff <= 1'b0;
        end else begin
            if (scale_gif_data_in_update_i) begin
                scale_gif_result_ff        <= mul_result_sat;
                scale_gif_result_update_ff <= 1'b1;
            end else begin
                scale_gif_result_update_ff <= 1'b0;
            end
        end
    end


    // Outputs ------------------------------------------------------------------
    assign scale_gif_result_update_o = scale_gif_result_update_ff;
    assign scale_gif_result_o        = scale_gif_result_ff;


endmodule

`default_nettype wire


`ifdef DSP_SCALE_SN_US_TB
// Mini TB
module dsp_scale_sn_us_tb ();

    logic signed [7:0] data_in;
    logic              data_in_update;
    logic signed [7:0] data_out;
    logic        [3:0] scale_factor;

    bit clk;                       // System clock
    bit reset_ni;                  // active loaw reset

    dsp_scale_sn_us_2 #(
        .DATA_W    (8),
        .SCALE_W   (4),
        .SCALE_SHFT(3)
    ) u_dsp_scale_sn_us_2 (
        .clk     (clk),      // I; System clock
        .reset_ni(reset_ni), // I; active loaw reset

        .scale_gif_data_in_update_i(data_in_update),  // I; GIF update pulse
        .scale_gif_data_in_i       (data_in),         // I; GIF data to be scaled (signed)
        .scale_factor_i            (scale_factor),    // I; Scaling factor (unsigned)
        .scale_gif_result_update_o (),                // O; GIF update pulse
        .scale_gif_result_o        ()                 // O; GIF scaled data (signed)
    );

    dsp_scale_sn_us #(
        .DATA_W    (8),
        .SCALE_W   (4),
        .SCALE_SHFT(3)
    ) u_dsp_scale_sn_us (
        .clk     (clk),      // I; System clock
        .reset_ni(reset_ni), // I; active loaw reset

        .scale_gif_data_in_update_i(data_in_update),  // I; GIF update pulse
        .scale_gif_data_in_i       (data_in),         // I; GIF data to be scaled (signed)
        .scale_factor_i            (scale_factor),    // I; Scaling factor (unsigned)
        .scale_gif_result_update_o (),                // O; GIF update pulse
        .scale_gif_result_o        ()                 // O; GIF scaled data (signed)
    );

    assign #5 clk = ~clk;
    initial begin
        reset_ni = 1'b0;
        data_in_update = 1'b0;
        data_in = 8'h00;
        @(negedge clk);
        reset_ni = 1'b1;
        @(negedge clk);
        @(negedge clk);

        for (int i = 0; i < 16; i++) begin
            @(negedge clk);
            data_in        = 23;
            scale_factor   = i;
            data_in_update = 1'b1;
            @(negedge clk);
            data_in_update = 1'b0;
            @(negedge clk);
            @(negedge clk);
            @(negedge clk);
        end

        repeat (10) begin
            @(negedge clk);
        end

        $finish();
    end

    assign data_rounded = data_out * $signed({1'b0, 3'b100});

endmodule
`endif


