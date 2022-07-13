// SPDX-FileCopyrightText: © 2022 semify <office@semify-eda.com>
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
module wfg_drive_spi_wishbone_reg #(
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
    //data: ../data/wfg_drive_spi_reg.json
    //template: wishbone/register_interface.template
    //marker_template_code

    output logic       cfg_core_sel_q_o,  // CFG.CORE_SEL register output
    output logic       cfg_cpol_q_o,      // CFG.CPOL register output
    output logic [3:2] cfg_dff_q_o,       // CFG.DFF register output
    output logic       cfg_lsbfirst_q_o,  // CFG.LSBFIRST register output
    output logic       cfg_sspol_q_o,     // CFG.SSPOL register output
    output logic [7:0] clkcfg_div_q_o,    // CLKCFG.DIV register output
    output logic       ctrl_en_q_o        // CTRL.EN register output

    //marker_template_end
);

    //marker_template_start
    //data: ../data/wfg_drive_spi_reg.json
    //template: wishbone/instantiate_registers.template
    //marker_template_code

    logic         cfg_core_sel_ff;         // CFG.CORE_SEL FF
    logic         cfg_cpol_ff;             // CFG.CPOL FF
    logic [ 3: 2] cfg_dff_ff;              // CFG.DFF FF
    logic         cfg_lsbfirst_ff;         // CFG.LSBFIRST FF
    logic         cfg_sspol_ff;            // CFG.SSPOL FF
    logic [ 7: 0] clkcfg_div_ff;           // CLKCFG.DIV FF
    logic         ctrl_en_ff;              // CTRL.EN FF

    //marker_template_end

    // Wishbone write to slave
    always_ff @(posedge wb_clk_i) begin
        if (wb_rst_i) begin
            //marker_template_start
            //data: ../data/wfg_drive_spi_reg.json
            //template: wishbone/reset_registers.template
            //marker_template_code

            cfg_core_sel_ff <= 1'b0;
            cfg_cpol_ff     <= 1'b0;
            cfg_dff_ff      <= 2'b00;
            cfg_lsbfirst_ff <= 1'b0;
            cfg_sspol_ff    <= 1'b0;
            clkcfg_div_ff   <= 0;
            ctrl_en_ff      <= 1'b0;

            //marker_template_end
        end else if (wbs_stb_i && wbs_we_i && wbs_cyc_i) begin
            case (wbs_adr_i)
                //marker_template_start
                //data: ../data/wfg_drive_spi_reg.json
                //template: wishbone/assign_to_registers.template
                //marker_template_code

                4'h4: begin
                    cfg_core_sel_ff <= wbs_dat_i[5:5];
                    cfg_cpol_ff     <= wbs_dat_i[0:0];
                    cfg_dff_ff      <= wbs_dat_i[3:2];
                    cfg_lsbfirst_ff <= wbs_dat_i[1:1];
                    cfg_sspol_ff    <= wbs_dat_i[4:4];
                end
                4'h8:       clkcfg_div_ff            <= wbs_dat_i[ 7: 0];
                4'h0:       ctrl_en_ff               <= wbs_dat_i[ 0: 0];

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
                    //data: ../data/wfg_drive_spi_reg.json
                    //template: wishbone/assign_from_registers.template
                    //marker_template_code

                    4'h4: begin
                        wbs_dat_o[5:5] <= cfg_core_sel_ff;
                        wbs_dat_o[0:0] <= cfg_cpol_ff;
                        wbs_dat_o[3:2] <= cfg_dff_ff;
                        wbs_dat_o[1:1] <= cfg_lsbfirst_ff;
                        wbs_dat_o[4:4] <= cfg_sspol_ff;
                    end
                    4'h8:       wbs_dat_o[ 7: 0] <= clkcfg_div_ff;
                    4'h0:       wbs_dat_o[ 0: 0] <= ctrl_en_ff;

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
    //data: ../data/wfg_drive_spi_reg.json
    //template: wishbone/assign_outputs.template
    //marker_template_code

    assign cfg_core_sel_q_o = cfg_core_sel_ff;
    assign cfg_cpol_q_o     = cfg_cpol_ff;
    assign cfg_dff_q_o      = cfg_dff_ff;
    assign cfg_lsbfirst_q_o = cfg_lsbfirst_ff;
    assign cfg_sspol_q_o    = cfg_sspol_ff;
    assign clkcfg_div_q_o   = clkcfg_div_ff;
    assign ctrl_en_q_o      = ctrl_en_ff;

    //marker_template_end
endmodule
`default_nettype wire
