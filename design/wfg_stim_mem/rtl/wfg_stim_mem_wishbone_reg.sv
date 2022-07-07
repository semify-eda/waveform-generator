// SPDX-FileCopyrightText: © 2022 semify <office@semify-eda.com>
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
module wfg_stim_mem_wishbone_reg #(
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
    //data: ../data/wfg_stim_mem_reg.json
    //template: wishbone/register_interface.template
    //marker_template_code

    output logic [23:8] cfg_gain_q_o,  // CFG.GAIN register output
    output logic [ 7:0] cfg_inc_q_o,   // CFG.INC register output
    output logic        ctrl_en_q_o,   // CTRL.EN register output
    output logic [15:0] end_val_q_o,   // END.VAL register output
    output logic [15:0] start_val_q_o  // START.VAL register output

    //marker_template_end
);

    //marker_template_start
    //data: ../data/wfg_stim_mem_reg.json
    //template: wishbone/instantiate_registers.template
    //marker_template_code

    logic [23: 8] cfg_gain_ff;             // CFG.GAIN FF
    logic [ 7: 0] cfg_inc_ff;              // CFG.INC FF
    logic         ctrl_en_ff;              // CTRL.EN FF
    logic [15: 0] end_val_ff;              // END.VAL FF
    logic [15: 0] start_val_ff;            // START.VAL FF

    //marker_template_end

    // Wishbone write to slave
    always_ff @(posedge wb_clk_i) begin
        if (wb_rst_i) begin
            //marker_template_start
            //data: ../data/wfg_stim_mem_reg.json
            //template: wishbone/reset_registers.template
            //marker_template_code

            cfg_gain_ff  <= 8'h01;
            cfg_inc_ff   <= 8'h01;
            ctrl_en_ff   <= 1'b0;
            end_val_ff   <= 0;
            start_val_ff <= 0;

            //marker_template_end
        end else if (wbs_stb_i && wbs_we_i && wbs_cyc_i) begin
            case (wbs_adr_i)
                //marker_template_start
                //data: ../data/wfg_stim_mem_reg.json
                //template: wishbone/assign_to_registers.template
                //marker_template_code

                4'hC: begin
                    cfg_gain_ff <= wbs_dat_i[23:8];
                    cfg_inc_ff  <= wbs_dat_i[7:0];
                end
                4'h0:       ctrl_en_ff               <= wbs_dat_i[ 0: 0];
                4'h8:       end_val_ff               <= wbs_dat_i[15: 0];
                4'h4:       start_val_ff             <= wbs_dat_i[15: 0];

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
                    //data: ../data/wfg_stim_mem_reg.json
                    //template: wishbone/assign_from_registers.template
                    //marker_template_code

                    4'hC: begin
                        wbs_dat_o[23:8] <= cfg_gain_ff;
                        wbs_dat_o[7:0]  <= cfg_inc_ff;
                    end
                    4'h0:       wbs_dat_o[ 0: 0] <= ctrl_en_ff;
                    4'h8:       wbs_dat_o[15: 0] <= end_val_ff;
                    4'h4:       wbs_dat_o[15: 0] <= start_val_ff;

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
    //data: ../data/wfg_stim_mem_reg.json
    //template: wishbone/assign_outputs.template
    //marker_template_code

    assign cfg_gain_q_o  = cfg_gain_ff;
    assign cfg_inc_q_o   = cfg_inc_ff;
    assign ctrl_en_q_o   = ctrl_en_ff;
    assign end_val_q_o   = end_val_ff;
    assign start_val_q_o = start_val_ff;

    //marker_template_end
endmodule
`default_nettype wire
