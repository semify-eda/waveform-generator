// SPDX-FileCopyrightText: © 2022 semify <office@semify-eda.com>
// SPDX-License-Identifier: Apache-2.0

module ulx3s_top (
	input clk_25mhz,

    // On-board
	input  ftdi_txd,
	output logic ftdi_rxd,

    input [6:0] btn,
	output logic [7:0] led
);
    parameter int BUSW = 32;

    // Wishbone interface signals
    logic               io_wbs_clk;
    logic               io_wbs_rst;
    logic  [(BUSW-1):0] io_wbs_adr;
    logic  [(BUSW-1):0] io_wbs_datwr;
    logic  [(BUSW-1):0] io_wbs_datrd;
    logic               io_wbs_we;
    logic               io_wbs_stb;
    logic               io_wbs_ack;
    logic               io_wbs_cyc;

    assign io_wbs_clk = clk_25mhz;
    assign io_wbs_rst = btn[0];
    assign io_wbs_adr = btn[1];
    assign io_wbs_datwr = btn[2];
    assign io_wbs_we = btn[3];
    assign io_wbs_stb = btn[4];
    assign io_wbs_cyc = btn[5];
    
    assign led[4] = io_wbs_ack;
    assign led[5] = | io_wbs_datrd;

    logic wfg_drive_spi_sclk_o;
    logic wfg_drive_spi_cs_no;
    logic wfg_drive_spi_sdo_o;
    logic wfg_drive_spi_sdo_en_o;
    
    assign led[0] = wfg_drive_spi_sclk_o;
    assign led[1] = wfg_drive_spi_cs_no;
    assign led[2] = wfg_drive_spi_sdo_o;
    assign led[3] = wfg_drive_spi_sdo_en_o;

    wfg_top wfg_top (
        .io_wbs_clk(io_wbs_clk),
        .io_wbs_rst(io_wbs_rst),
        .io_wbs_adr(io_wbs_adr),
        .io_wbs_datwr(io_wbs_datwr),
        .io_wbs_datrd(io_wbs_datrd),
        .io_wbs_we(io_wbs_we),
        .io_wbs_stb(io_wbs_stb),
        .io_wbs_ack(io_wbs_ack),
        .io_wbs_cyc(io_wbs_cyc),

        .wfg_drive_spi_sclk_o(wfg_drive_spi_sclk_o),
        .wfg_drive_spi_cs_no(wfg_drive_spi_cs_no),
        .wfg_drive_spi_sdo_o(wfg_drive_spi_sdo_o),
        .wfg_drive_spi_sdo_en_o(wfg_drive_spi_sdo_en_o)
    );

endmodule
