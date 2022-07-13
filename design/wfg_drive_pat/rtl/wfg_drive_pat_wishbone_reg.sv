// SPDX-FileCopyrightText: © 2022 semify <office@semify-eda.com>
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
module wfg_drive_pat_wishbone_reg #(
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
    //data: ../data/wfg_drive_pat_reg.json
    //template: wishbone/register_interface.template
    //marker_template_code

    output logic [ 7:0] cfg_begin_q_o,     // CFG.BEGIN register output
    output logic        cfg_core_sel_q_o,  // CFG.CORE_SEL register output
    output logic [15:8] cfg_end_q_o,       // CFG.END register output
    output logic [31:0] ctrl_en_q_o,       // CTRL.EN register output
    output logic [31:0] patsel0_low_q_o,   // PATSEL0.LOW register output
    output logic [31:0] patsel1_high_q_o   // PATSEL1.HIGH register output

    //marker_template_end
);

    //marker_template_start
    //data: ../data/wfg_drive_pat_reg.json
    //template: wishbone/instantiate_registers.template
    //marker_template_code

    logic [ 7: 0] cfg_begin_ff;            // CFG.BEGIN FF
    logic         cfg_core_sel_ff;         // CFG.CORE_SEL FF
    logic [15: 8] cfg_end_ff;              // CFG.END FF
    logic [31: 0] ctrl_en_ff;              // CTRL.EN FF
    logic [31: 0] patsel0_low_ff;          // PATSEL0.LOW FF
    logic [31: 0] patsel1_high_ff;         // PATSEL1.HIGH FF

    //marker_template_end

    // Wishbone write to slave
    always_ff @(posedge wb_clk_i) begin
        if (wb_rst_i) begin
            //marker_template_start
            //data: ../data/wfg_drive_pat_reg.json
            //template: wishbone/reset_registers.template
            //marker_template_code

            cfg_begin_ff    <= 0;
            cfg_core_sel_ff <= 1'b0;
            cfg_end_ff      <= 0;
            ctrl_en_ff      <= 0;
            patsel0_low_ff  <= 0;
            patsel1_high_ff <= 0;

            //marker_template_end
        end else if (wbs_stb_i && wbs_we_i && wbs_cyc_i) begin
            case (wbs_adr_i)
                //marker_template_start
                //data: ../data/wfg_drive_pat_reg.json
                //template: wishbone/assign_to_registers.template
                //marker_template_code

                4'h4: begin
                    cfg_begin_ff    <= wbs_dat_i[7:0];
                    cfg_core_sel_ff <= wbs_dat_i[16:16];
                    cfg_end_ff      <= wbs_dat_i[15:8];
                end
                4'h0:       ctrl_en_ff               <= wbs_dat_i[31: 0];
                4'h8:       patsel0_low_ff           <= wbs_dat_i[31: 0];
                4'hC:       patsel1_high_ff          <= wbs_dat_i[31: 0];

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
                    //data: ../data/wfg_drive_pat_reg.json
                    //template: wishbone/assign_from_registers.template
                    //marker_template_code

                    4'h4: begin
                        wbs_dat_o[7:0]   <= cfg_begin_ff;
                        wbs_dat_o[16:16] <= cfg_core_sel_ff;
                        wbs_dat_o[15:8]  <= cfg_end_ff;
                    end
                    4'h0:       wbs_dat_o[31: 0] <= ctrl_en_ff;
                    4'h8:       wbs_dat_o[31: 0] <= patsel0_low_ff;
                    4'hC:       wbs_dat_o[31: 0] <= patsel1_high_ff;

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
    //data: ../data/wfg_drive_pat_reg.json
    //template: wishbone/assign_outputs.template
    //marker_template_code

    assign cfg_begin_q_o    = cfg_begin_ff;
    assign cfg_core_sel_q_o = cfg_core_sel_ff;
    assign cfg_end_q_o      = cfg_end_ff;
    assign ctrl_en_q_o      = ctrl_en_ff;
    assign patsel0_low_q_o  = patsel0_low_ff;
    assign patsel1_high_q_o = patsel1_high_ff;

    //marker_template_end
endmodule
`default_nettype wire
