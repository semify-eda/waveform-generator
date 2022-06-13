// SPDX-FileCopyrightText: © 2022 semify <office@semify-eda.com>
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
module wfg_top #(
    parameter int BUSW = 32
) (
    // Wishbone interface signals
    input                     io_wbs_clk,
    input                     io_wbs_rst,
    input        [(BUSW-1):0] io_wbs_adr,
    input        [(BUSW-1):0] io_wbs_datwr,
    output       [(BUSW-1):0] io_wbs_datrd,
    input                     io_wbs_we,
    input                     io_wbs_stb,
    output                    io_wbs_ack,
    input                     io_wbs_cyc,

    output       wfg_drive_spi_sclk_o,
    output       wfg_drive_spi_cs_no,
    output       wfg_drive_spi_sdo_o
);
    // Wishbone interconnect

    // Adress select lines
    logic wfg_core_sel;
    logic wfg_stim_sine_sel;
    logic wfg_drive_spi_sel;

    // Nothing should be assigned to the null page
    assign wfg_core_sel      = (io_wbs_adr[BUSW-1:4] == 28'h01);  // 0x10
    assign wfg_stim_sine_sel = (io_wbs_adr[BUSW-1:4] == 28'h02);  // 0x20
    assign wfg_drive_spi_sel = (io_wbs_adr[BUSW-1:4] == 28'h03);  // 0x30

    // This will be true if nothing is selected
    logic none_sel;
    assign none_sel = (!wfg_core_sel) && (!wfg_stim_sine_sel) && (!wfg_drive_spi_sel);

    // The wishbone error signal is true for one clock only, and then it
    // resets itself
    logic wb_err;
    always @(posedge io_wbs_clk) begin
        wb_err <= (io_wbs_stb) && (none_sel);
    end

    logic bus_err_address;
    always @(posedge io_wbs_clk) begin
        if (wb_err) begin
            bus_err_address <= io_wbs_adr;
        end
    end

    // Acknowledgement
    logic wfg_core_ack;
    logic wfg_stim_sine_ack;
    logic wfg_drive_spi_ack;

    assign io_wbs_ack = (wfg_core_ack) || (wfg_stim_sine_ack) || (wfg_drive_spi_ack);

    // Return data
    logic [(BUSW-1):0] wfg_core_data;
    logic [(BUSW-1):0] wfg_stim_sine_data;
    logic [(BUSW-1):0] wfg_drive_spi_data;

    logic [(BUSW-1):0] my_io_wbs_datrd;

    always_comb begin
        unique case (1'b1)
            wfg_core_sel:
                my_io_wbs_datrd = wfg_core_data;
            wfg_stim_sine_sel:
                my_io_wbs_datrd = wfg_stim_sine_data;
            wfg_drive_spi_sel:
                my_io_wbs_datrd = wfg_drive_spi_data;
            default:
                my_io_wbs_datrd = 'x;
        endcase
    end
    
    assign io_wbs_datrd = my_io_wbs_datrd;

    // Core synchronisation interface
    logic wfg_pat_sync;
    logic wfg_pat_subcycle;
    logic wfg_pat_start;
    logic [7:0] wfg_pat_subcycle_cnt;
    logic active;

    wfg_core_top wfg_core_top (
        .wb_clk_i (io_wbs_clk),
        .wb_rst_i (io_wbs_rst),
        .wbs_stb_i(io_wbs_stb && wfg_core_sel),
        .wbs_cyc_i(io_wbs_cyc),
        .wbs_we_i (io_wbs_we),
        .wbs_sel_i(4'b1111),
        .wbs_dat_i(io_wbs_datwr),
        .wbs_adr_i(wfg_core_sel ? io_wbs_adr & 4'hF : 4'h0),
        .wbs_ack_o(wfg_core_ack),
        .wbs_dat_o(wfg_core_data),

        .wfg_pat_sync_o(wfg_pat_sync),
        .wfg_pat_subcycle_o(wfg_pat_subcycle),
        .wfg_pat_start_o(wfg_pat_start),
        .wfg_pat_subcycle_cnt_o(wfg_pat_subcycle_cnt),
        .active_o(active)
    );

    logic wfg_axis_tready;
    logic wfg_axis_tvalid;
    logic wfg_axis_tlast;
    logic [17:0] wfg_axis_tdata; // TODO data size

    wfg_stim_sine_top wfg_stim_sine_top (
        .wb_clk_i (io_wbs_clk),
        .wb_rst_i (io_wbs_rst),
        .wbs_stb_i(io_wbs_stb && wfg_stim_sine_sel),
        .wbs_cyc_i(io_wbs_cyc),
        .wbs_we_i (io_wbs_we),
        .wbs_sel_i(4'b1111),
        .wbs_dat_i(io_wbs_datwr),
        .wbs_adr_i(wfg_stim_sine_sel ? io_wbs_adr & 4'hF : 4'h0),
        .wbs_ack_o(wfg_stim_sine_ack),
        .wbs_dat_o(wfg_stim_sine_data),

        .wfg_axis_tready_i(wfg_axis_tready),
        .wfg_axis_tvalid_o(wfg_axis_tvalid),
        .wfg_axis_tdata_o (wfg_axis_tdata)
    );

    wfg_drive_spi_top wfg_drive_spi_top (
        .wb_clk_i (io_wbs_clk),
        .wb_rst_i (io_wbs_rst),
        .wbs_stb_i(io_wbs_stb && wfg_drive_spi_sel),
        .wbs_cyc_i(io_wbs_cyc),
        .wbs_we_i (io_wbs_we),
        .wbs_sel_i(4'b1111),
        .wbs_dat_i(io_wbs_datwr),
        .wbs_adr_i(wfg_drive_spi_sel ? io_wbs_adr & 4'hF : 4'h0),
        .wbs_ack_o(wfg_drive_spi_ack),
        .wbs_dat_o(wfg_drive_spi_data),

        .wfg_pat_sync_i    (wfg_pat_sync),
        .wfg_pat_subcycle_i(wfg_pat_subcycle),

        .wfg_axis_tready_o(wfg_axis_tready),
        .wfg_axis_tdata_i ({14'b0, wfg_axis_tdata}),
        .wfg_axis_tlast_i (1'b0),
        .wfg_axis_tvalid_i(wfg_axis_tvalid),

        .wfg_drive_spi_sclk_o(wfg_drive_spi_sclk_o),
        .wfg_drive_spi_cs_no (wfg_drive_spi_cs_no),
        .wfg_drive_spi_sdo_o (wfg_drive_spi_sdo_o)
    );

endmodule
`default_nettype wire
