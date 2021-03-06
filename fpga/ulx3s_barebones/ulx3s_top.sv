// SPDX-FileCopyrightText: © 2022 semify <office@semify-eda.com>
// SPDX-License-Identifier: Apache-2.0

module ulx3s_top (
	input clk_25mhz,

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
    assign io_wbs_adr = {btn[5], btn[4], btn[3], btn[2], btn[1], btn[0]};
    assign io_wbs_datwr = btn[2];
    assign io_wbs_we = btn[3];
    assign io_wbs_stb = btn[4];
    assign io_wbs_cyc = btn[5];
    
    assign led[3] = io_wbs_ack;
    assign led[4] = | io_wbs_datrd;

    logic wfg_drive_spi_sclk_o;
    logic wfg_drive_spi_cs_no;
    logic wfg_drive_spi_sdo_o;
    logic wfg_drive_spi_sdo_en_o;
    
    assign led[0] = wfg_drive_spi_sclk_o;
    assign led[1] = wfg_drive_spi_cs_no;
    assign led[2] = wfg_drive_spi_sdo_o;
    
    logic [31:0] wfg_drive_pat_dout_o;
    
    assign led[5] = | wfg_drive_pat_dout_o[7:0];
    
    // Memory interface
    logic        csb1;
    logic [ 9:0] addr1;
    logic [31:0] dout1;
    
    localparam MEM_SIZE = 2 ** 10;

    logic [31:0] mem[MEM_SIZE];
    
    always_ff @(negedge io_wbs_clk) begin
        if (!csb1) dout1 <= mem[addr1];
    end

    (*  keep *) wfg_top wfg_top (
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
        
        .wfg_drive_pat_dout_o(wfg_drive_pat_dout_o),
        
        .csb1(csb1),
        .addr1(addr1),
        .dout1(dout1)
    );

endmodule
