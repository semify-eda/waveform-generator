// SPDX-FileCopyrightText: © 2022 semify <office@semify-eda.com>
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
module wfg_drive_spi_top #(
    parameter int BUSW = 32,
    parameter int AXIS_DATA_WIDTH = 32
) (
    // Wishbone Slave ports
    input                 wb_clk_i,
    input                 wb_rst_i,
    input                 wbs_stb_i,
    input                 wbs_cyc_i,
    input                 wbs_we_i,
    input  [(BUSW/8-1):0] wbs_sel_i,
    input  [  (BUSW-1):0] wbs_dat_i,
    input  [  (BUSW-1):0] wbs_adr_i,
    output                wbs_ack_o,
    output [  (BUSW-1):0] wbs_dat_o,

    // Core synchronisation interface
    input wire wfg_pat_sync_i,     // I; pat_sync pulse
    input wire wfg_pat_subcycle_i, // I; subcycle_cnt

    // AXI-Stream interface
    output wire wfg_drive_spi_axis_tready,
    input wire [AXIS_DATA_WIDTH-1:0] wfg_drive_spi_axis_tdata,
    input wire wfg_drive_spi_axis_tlast,
    input wire wfg_drive_spi_axis_tvalid,

    // SPI IO interface
    output wire wfg_drive_spi_sclk_o,   // O; clock
    output wire wfg_drive_spi_cs_no,    // O; chip select
    output wire wfg_drive_spi_sdo_o,    // O; data out
    output wire wfg_drive_spi_sdo_en_o  // O; data out enable
);
    // Registers
    //marker_template_start
    //data: ../data/wfg_drive_spi_reg.json
    //template: wishbone/instantiate_top.template
    //marker_template_code

    logic         cfg_cpha_q;              // CFG.CPHA register output
    logic         cfg_cpol_q;              // CFG.CPOL register output
    logic [ 5: 4] cfg_dff_q;               // CFG.DFF register output
    logic         cfg_lsbfirst_q;          // CFG.LSBFIRST register output
    logic         cfg_mstr_q;              // CFG.MSTR register output
    logic [11:10] cfg_oectrl_q;            // CFG.OECTRL register output
    logic         cfg_ssctrl_q;            // CFG.SSCTRL register output
    logic         cfg_sspol_q;             // CFG.SSPOL register output
    logic [ 7: 0] clkcfg_div_q;            // CLKCFG.DIV register output
    logic         ctrl_en_q;               // CTRL.EN register output
    logic [ 7: 0] id_peripheral_type_q;    // ID.PERIPHERAL_TYPE register output
    logic [15: 8] id_version_q;            // ID.VERSION register output
    logic [17: 0] reginfo_date_q;          // REGINFO.DATE register output
    logic         test_lpen_q;             // TEST.LPEN register output

    //marker_template_end

    wfg_drive_spi_wishbone_reg wfg_drive_spi_wishbone_reg (
        .wb_clk_i (wb_clk_i),
        .wb_rst_i (wb_rst_i),
        .wbs_stb_i(wbs_stb_i),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i (wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ack_o),
        .wbs_dat_o(wbs_dat_o),

        //marker_template_start
        //data: ../data/wfg_drive_spi_reg.json
        //template: wishbone/assign_to_module.template
        //marker_template_code

        .cfg_cpha_q_o    (cfg_cpha_q),      // CFG.CPHA register output
        .cfg_cpol_q_o    (cfg_cpol_q),      // CFG.CPOL register output
        .cfg_dff_q_o     (cfg_dff_q),       // CFG.DFF register output
        .cfg_lsbfirst_q_o(cfg_lsbfirst_q),  // CFG.LSBFIRST register output
        .cfg_mstr_q_o    (cfg_mstr_q),      // CFG.MSTR register output
        .cfg_oectrl_q_o  (cfg_oectrl_q),    // CFG.OECTRL register output
        .cfg_ssctrl_q_o  (cfg_ssctrl_q),    // CFG.SSCTRL register output
        .cfg_sspol_q_o   (cfg_sspol_q),     // CFG.SSPOL register output
        .clkcfg_div_q_o  (clkcfg_div_q),    // CLKCFG.DIV register output
        .ctrl_en_q_o     (ctrl_en_q),       // CTRL.EN register output
        .test_lpen_q_o   (test_lpen_q)      // TEST.LPEN register output

        //marker_template_end
    );

    wfg_drive_spi wfg_drive_spi (
        .clk  (wb_clk_i),  // clock signal
        .rst_n(!wb_rst_i), // reset signal

        // Core synchronisation interface
        .wfg_pat_sync_i    (wfg_pat_sync_i),
        .wfg_pat_subcycle_i(wfg_pat_subcycle_i),

        // AXI streaming interface
        .wfg_drive_spi_tready_o(wfg_drive_spi_axis_tready),  // O; ready
        .wfg_drive_spi_tvalid_i(wfg_drive_spi_axis_tvalid),  // I; valid
        .wfg_drive_spi_tlast_i (wfg_drive_spi_axis_tlast),   // I; last
        .wfg_drive_spi_tdata_i (wfg_drive_spi_axis_tdata),   // I; data

        // Control
        .ctrl_en_q_i(ctrl_en_q),  // I; SPI enable

        // Configuration
        .clkcfg_div_q_i  (clkcfg_div_q),    // I: clock divider
        .cfg_cpha_q_i    (cfg_cpha_q),      // I; Clock phase
        .cfg_cpol_q_i    (cfg_cpol_q),      // I; Clock polarity
        .cfg_mstr_q_i    (cfg_mstr_q),      // I; Master selection
        .cfg_lsbfirst_q_i(cfg_lsbfirst_q),  // I; Frame format
        .cfg_dff_q_i     (cfg_dff_q),       // I; Data frame format
        .cfg_ssctrl_q_i  (cfg_ssctrl_q),    // I; Slave select control
        .cfg_sspol_q_i   (cfg_sspol_q),     // I; Slave select polarity
        .cfg_oectrl_q_i  (cfg_oectrl_q),    // I; Output enable control

        // Test
        .test_lpen_q_i(test_lpen_q),  // I; Internal loop back enable

        // SPI IO interface
        .wfg_drive_spi_sclk_o  (wfg_drive_spi_sclk_o),   // O; clock
        .wfg_drive_spi_cs_no   (wfg_drive_spi_cs_no),    // O; chip select
        .wfg_drive_spi_sdo_o   (wfg_drive_spi_sdo_o),    // O; data out
        .wfg_drive_spi_sdo_en_o(wfg_drive_spi_sdo_en_o)  // O; data out enable
    );

endmodule
`default_nettype wire
