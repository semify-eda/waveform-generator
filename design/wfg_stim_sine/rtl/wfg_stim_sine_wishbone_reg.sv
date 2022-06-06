// SPDX-FileCopyrightText: © 2022 semify <office@semify-eda.com>
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
module wfg_stim_sine_wishbone_reg #(
    parameter int BUSW = 32
) (
    // Wishbone Slave ports
    input                       wb_clk_i,
    input                       wb_rst_i,
    input                       wbs_stb_i,
    input                       wbs_cyc_i,
    input                       wbs_we_i,
    input        [(BUSW/8-1):0] wbs_sel_i,
    input        [  (BUSW-1):0] wbs_dat_i,
    input        [  (BUSW-1):0] wbs_adr_i,
    output logic                wbs_ack_o,
    output logic [  (BUSW-1):0] wbs_dat_o,

    // Registers
    //marker_template_start
    //data: ../data/wfg_stim_sine_reg.json
    //template: wishbone/register_interface.template
    //marker_template_code

    output logic        ctrl_en_q_o,    // CTRL.EN register output
    output logic [15:0] gain_val_q_o,   // GAIN.VAL register output
    output logic [15:0] inc_val_q_o,    // INC.VAL register output
    output logic [17:0] offset_val_q_o  // OFFSET.VAL register output

    //marker_template_end
);

    //marker_template_start
    //data: ../data/wfg_stim_sine_reg.json
    //template: wishbone/instantiate_registers.template
    //marker_template_code

    logic         ctrl_en_ff;              // CTRL.EN FF
    logic [15: 0] gain_val_ff;             // GAIN.VAL FF
    logic [15: 0] inc_val_ff;              // INC.VAL FF
    logic [17: 0] offset_val_ff;           // OFFSET.VAL FF

    //marker_template_end

    // Wishbone write to slave
    always_ff @(posedge wb_clk_i) begin
        if (wb_rst_i) begin
            //marker_template_start
            //data: ../data/wfg_stim_sine_reg.json
            //template: wishbone/reset_registers.template
            //marker_template_code

            ctrl_en_ff    <= 1'b0;
            gain_val_ff   <= 16'h4000;
            inc_val_ff    <= 16'h1000;
            offset_val_ff <= 18'h0000;

            //marker_template_end
        end else if (wbs_stb_i && wbs_we_i && wbs_cyc_i) begin
            case (wbs_adr_i)
                //marker_template_start
                //data: ../data/wfg_stim_sine_reg.json
                //template: wishbone/assign_to_registers.template
                //marker_template_code

                4'h0:       ctrl_en_ff               <= wbs_dat_i[ 0: 0];
                4'h8:       gain_val_ff              <= wbs_dat_i[15: 0];
                4'h4:       inc_val_ff               <= wbs_dat_i[15: 0];
                4'hC:       offset_val_ff            <= wbs_dat_i[17: 0];

                //marker_template_end
                default: begin
                end
            endcase
        end
    end

    // Wishbone read from slave
    always_ff @(posedge wb_clk_i) begin
        if (wb_rst_i) begin
            wbs_dat_o <= '0;
        end else begin
            if (wbs_stb_i && !wbs_we_i && wbs_cyc_i) begin
                wbs_dat_o <= '0;  // default value
                case (wbs_adr_i)
                    //marker_template_start
                    //data: ../data/wfg_stim_sine_reg.json
                    //template: wishbone/assign_from_registers.template
                    //marker_template_code

                    4'h0:       wbs_dat_o[ 0: 0] <= ctrl_en_ff;
                    4'h8:       wbs_dat_o[15: 0] <= gain_val_ff;
                    4'h4:       wbs_dat_o[15: 0] <= inc_val_ff;
                    4'hC:       wbs_dat_o[17: 0] <= offset_val_ff;

                    //marker_template_end
                    default:    wbs_dat_o <= 'X;
                endcase
            end
        end
    end

    // Acknowledgement
    always_ff @(posedge wb_clk_i) begin
        if (wb_rst_i) wbs_ack_o <= 1'b0;
        else wbs_ack_o <= wbs_stb_i && wbs_cyc_i & !wbs_ack_o;
    end

    //marker_template_start
    //data: ../data/wfg_stim_sine_reg.json
    //template: wishbone/assign_outputs.template
    //marker_template_code

    assign ctrl_en_q_o    = ctrl_en_ff;
    assign gain_val_q_o   = gain_val_ff;
    assign inc_val_q_o    = inc_val_ff;
    assign offset_val_q_o = offset_val_ff;

    //marker_template_end
endmodule
`default_nettype wire
