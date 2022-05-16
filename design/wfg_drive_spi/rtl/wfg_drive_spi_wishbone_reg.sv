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

    output logic         cfg_cpha_q_o,            // CFG.CPHA register output
    output logic         cfg_cpol_q_o,            // CFG.CPOL register output
    output logic [  5:4] cfg_dff_q_o,             // CFG.DFF register output
    output logic         cfg_lsbfirst_q_o,        // CFG.LSBFIRST register output
    output logic         cfg_mstr_q_o,            // CFG.MSTR register output
    output logic [11:10] cfg_oectrl_q_o,          // CFG.OECTRL register output
    output logic         cfg_ssctrl_q_o,          // CFG.SSCTRL register output
    output logic         cfg_sspol_q_o,           // CFG.SSPOL register output
    output logic [  7:0] clkcfg_div_q_o,          // CLKCFG.DIV register output
    output logic         ctrl_en_q_o,             // CTRL.EN register output
    output logic [  7:0] id_peripheral_type_q_o,  // ID.PERIPHERAL_TYPE register output
    output logic [ 15:8] id_version_q_o,          // ID.VERSION register output
    output logic [ 17:0] reginfo_date_q_o,        // REGINFO.DATE register output
    output logic         test_lpen_q_o            // TEST.LPEN register output

    //marker_template_end
);

    //marker_template_start
    //data: ../data/wfg_drive_spi_reg.json
    //template: wishbone/instantiate_registers.template
    //marker_template_code

    logic         cfg_cpha_ff;             // CFG.CPHA FF
    logic         cfg_cpol_ff;             // CFG.CPOL FF
    logic [ 5: 4] cfg_dff_ff;              // CFG.DFF FF
    logic         cfg_lsbfirst_ff;         // CFG.LSBFIRST FF
    logic         cfg_mstr_ff;             // CFG.MSTR FF
    logic [11:10] cfg_oectrl_ff;           // CFG.OECTRL FF
    logic         cfg_ssctrl_ff;           // CFG.SSCTRL FF
    logic         cfg_sspol_ff;            // CFG.SSPOL FF
    logic [ 7: 0] clkcfg_div_ff;           // CLKCFG.DIV FF
    logic         ctrl_en_ff;              // CTRL.EN FF
    logic [ 7: 0] id_peripheral_type_ff;   // ID.PERIPHERAL_TYPE FF
    logic [15: 8] id_version_ff;           // ID.VERSION FF
    logic [17: 0] reginfo_date_ff;         // REGINFO.DATE FF
    logic         test_lpen_ff;            // TEST.LPEN FF

    //marker_template_end

    always_ff @(posedge wb_clk_i) begin
        if (wb_rst_i) begin
            //marker_template_start
            //data: ../data/wfg_drive_spi_reg.json
            //template: wishbone/reset_registers.template
            //marker_template_code

            cfg_cpha_ff           <= 1'b0;
            cfg_cpol_ff           <= 1'b0;
            cfg_dff_ff            <= 2'b00;
            cfg_lsbfirst_ff       <= 1'b0;
            cfg_mstr_ff           <= 1'b1;
            cfg_oectrl_ff         <= 2'b00;
            cfg_ssctrl_ff         <= 1'b0;
            cfg_sspol_ff          <= 1'b0;
            clkcfg_div_ff         <= 1'b0;
            ctrl_en_ff            <= 1'b0;
            id_peripheral_type_ff <= 8'h01;
            id_version_ff         <= 8'h01;
            reginfo_date_ff       <= 18'd210715;
            test_lpen_ff          <= 1'b0;

            //marker_template_end
        end
    end


    // Wishbone write to slave
    always_ff @(posedge wb_clk_i) begin
        if ((wbs_stb_i) && (wbs_we_i) && (wbs_cyc_i)) begin
            case (wbs_adr_i)
                //marker_template_start
                //data: ../data/wfg_drive_spi_reg.json
                //template: wishbone/assign_to_registers.template
                //marker_template_code

                4'h2: begin
                    cfg_cpha_ff     <= wbs_dat_i[0:0];
                    cfg_cpol_ff     <= wbs_dat_i[1:1];
                    cfg_dff_ff      <= wbs_dat_i[5:4];
                    cfg_lsbfirst_ff <= wbs_dat_i[3:3];
                    cfg_mstr_ff     <= wbs_dat_i[2:2];
                    cfg_oectrl_ff   <= wbs_dat_i[11:10];
                    cfg_ssctrl_ff   <= wbs_dat_i[8:8];
                    cfg_sspol_ff    <= wbs_dat_i[9:9];
                end
                4'h3:       clkcfg_div_ff            <= wbs_dat_i[ 7: 0];
                4'h1:       ctrl_en_ff               <= wbs_dat_i[ 0: 0];
                4'hF:       begin
                            id_peripheral_type_ff    <= wbs_dat_i[ 7: 0];
                            id_version_ff            <= wbs_dat_i[15: 8];
                end
                4'hE:       reginfo_date_ff          <= wbs_dat_i[17: 0];
                4'h4:       test_lpen_ff             <= wbs_dat_i[ 1: 1];

                //marker_template_end
                default: begin
                end
            endcase
        end
    end

    // Wishbone read from slave
    always_comb begin
        wbs_dat_o = 0;

        case (wbs_adr_i)
            //marker_template_start
            //data: ../data/wfg_drive_spi_reg.json
            //template: wishbone/assign_from_registers.template
            //marker_template_code

            4'h2: begin
                wbs_dat_o[0:0]   = cfg_cpha_ff;
                wbs_dat_o[1:1]   = cfg_cpol_ff;
                wbs_dat_o[5:4]   = cfg_dff_ff;
                wbs_dat_o[3:3]   = cfg_lsbfirst_ff;
                wbs_dat_o[2:2]   = cfg_mstr_ff;
                wbs_dat_o[11:10] = cfg_oectrl_ff;
                wbs_dat_o[8:8]   = cfg_ssctrl_ff;
                wbs_dat_o[9:9]   = cfg_sspol_ff;
            end
            4'h3:       wbs_dat_o[ 7: 0] = clkcfg_div_ff;
            4'h1:       wbs_dat_o[ 0: 0] = ctrl_en_ff;
            4'hF:       begin
                        wbs_dat_o[ 7: 0] = id_peripheral_type_ff;
                        wbs_dat_o[15: 8] = id_version_ff;
            end
            4'hE:       wbs_dat_o[17: 0] = reginfo_date_ff;
            4'h4:       wbs_dat_o[ 1: 1] = test_lpen_ff;

            //marker_template_end
            default:    wbs_dat_o = 'X;
        endcase
    end

    // Acknowledgement
    always_ff @(posedge wb_clk_i) begin
        if (wb_rst_i) wbs_ack_o <= 1'b0;
        else wbs_ack_o <= ((wbs_stb_i) && (wbs_cyc_i));
    end

    //marker_template_start
    //data: ../data/wfg_drive_spi_reg.json
    //template: wishbone/assign_outputs.template
    //marker_template_code

    assign cfg_cpha_q_o           = cfg_cpha_ff;
    assign cfg_cpol_q_o           = cfg_cpol_ff;
    assign cfg_dff_q_o            = cfg_dff_ff;
    assign cfg_lsbfirst_q_o       = cfg_lsbfirst_ff;
    assign cfg_mstr_q_o           = cfg_mstr_ff;
    assign cfg_oectrl_q_o         = cfg_oectrl_ff;
    assign cfg_ssctrl_q_o         = cfg_ssctrl_ff;
    assign cfg_sspol_q_o          = cfg_sspol_ff;
    assign clkcfg_div_q_o         = clkcfg_div_ff;
    assign ctrl_en_q_o            = ctrl_en_ff;
    assign id_peripheral_type_q_o = id_peripheral_type_ff;
    assign id_version_q_o         = id_version_ff;
    assign reginfo_date_q_o       = reginfo_date_ff;
    assign test_lpen_q_o          = test_lpen_ff;

    //marker_template_end
endmodule
`default_nettype wire
