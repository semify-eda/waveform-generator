// SPDX-FileCopyrightText: © 2022 semify <office@semify-eda.com>
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
module whishbone_slave #(
    parameter BUSW = 32
)
(
    // Wishbone Slave ports
    input                       wb_clk_i,
    input                       wb_rst_i,
    input                       wbs_stb_i,
    input                       wbs_cyc_i,
    input                       wbs_we_i,
    input        [(BUSW/8-1):0] wbs_sel_i,
    input        [(BUSW-1):0]   wbs_dat_i,
    input        [(BUSW-1):0]   wbs_adr_i,
    output logic                wbs_ack_o,
    output logic [(BUSW-1):0]   wbs_dat_o,
    
    // Registers
    //marker_template_start
    //data: ../data/wfg_stim_sine_reg.json
    //template: wishbone/register_interface.template
    //marker_template_code
    
    output logic         ctrl_en_q_o,             // CTRL.EN register output
    output logic [15: 0] gain_val_q_o,            // GAIN.VAL register output
    output logic [ 7: 0] id_peripheral_type_q_o,  // ID.PERIPHERAL_TYPE register output
    output logic [15: 8] id_version_q_o,          // ID.VERSION register output
    output logic [15: 0] inc_val_q_o,             // INC.VAL register output
    output logic [15: 0] offset_val_q_o,          // OFFSET.VAL register output
    output logic [17: 0] reginfo_date_q_o         // REGINFO.DATE register output
    
    //marker_template_end
);

    //marker_template_start
    //data: ../data/wfg_stim_sine_reg.json
    //template: wishbone/instantiate_registers.template
    //marker_template_code
    
    logic         ctrl_en_ff;              // CTRL.EN FF
    logic [15: 0] gain_val_ff;             // GAIN.VAL FF
    logic [ 7: 0] id_peripheral_type_ff;   // ID.PERIPHERAL_TYPE FF
    logic [15: 8] id_version_ff;           // ID.VERSION FF
    logic [15: 0] inc_val_ff;              // INC.VAL FF
    logic [15: 0] offset_val_ff;           // OFFSET.VAL FF
    logic [17: 0] reginfo_date_ff;         // REGINFO.DATE FF
    
    //marker_template_end

    always_ff @(posedge wb_clk_i) begin
        if (wb_rst_i) begin
            //marker_template_start
            //data: ../data/wfg_stim_sine_reg.json
            //template: wishbone/reset_registers.template
            //marker_template_code
            
            ctrl_en_ff               <= 1'b0;
            gain_val_ff              <= 16'h4000;
            id_peripheral_type_ff    <= 8'h01;
            id_version_ff            <= 8'h01;
            inc_val_ff               <= 16'h1000;
            offset_val_ff            <= 16'h0000;
            reginfo_date_ff          <= 18'd210722;
            
            //marker_template_end
        end
    end


    // Wishbone write to slave
    always_ff @(posedge wb_clk_i) begin
        if ((wbs_stb_i) && (wbs_we_i) && (wbs_cyc_i)) begin
            case (wbs_adr_i)
                //marker_template_start
                //data: ../data/wfg_stim_sine_reg.json
                //template: wishbone/assign_to_registers.template
                //marker_template_code
                
                12'h10:     ctrl_en_ff               <= wbs_dat_i[ 0: 0];
                12'h1C:     gain_val_ff              <= wbs_dat_i[15: 0];
                12'hFFC:    begin
                            id_peripheral_type_ff    <= wbs_dat_i[ 7: 0];
                            id_version_ff            <= wbs_dat_i[15: 8];
                end
                12'h18:     inc_val_ff               <= wbs_dat_i[15: 0];
                12'h20:     offset_val_ff            <= wbs_dat_i[15: 0];
                12'hFF8:    reginfo_date_ff          <= wbs_dat_i[17: 0];
                
                //marker_template_end
            endcase
        end
    end

    // Wishbone read from slave
    always_comb begin
        wbs_dat_o = 0;
        
        case (wbs_adr_i)
            //marker_template_start
            //data: ../data/wfg_stim_sine_reg.json
            //template: wishbone/assign_from_registers.template
            //marker_template_code
            
            12'h10:     wbs_dat_o[ 0: 0] = ctrl_en_ff;
            12'h1C:     wbs_dat_o[15: 0] = gain_val_ff;
            12'hFFC:    begin
                        wbs_dat_o[ 7: 0] = id_peripheral_type_ff;
                        wbs_dat_o[15: 8] = id_version_ff;
            end
            12'h18:     wbs_dat_o[15: 0] = inc_val_ff;
            12'h20:     wbs_dat_o[15: 0] = offset_val_ff;
            12'hFF8:    wbs_dat_o[17: 0] = reginfo_date_ff;
            
            //marker_template_end
            default: wbs_dat_o = 'X;
        endcase
    end
    
    // Acknowledgement
    always_ff @(posedge wb_clk_i) begin
        if (wb_rst_i)
            wbs_ack_o <= 1'b0;
        else
            wbs_ack_o <= ((wbs_stb_i) && (wbs_cyc_i));
    end
    
    //marker_template_start
    //data: ../data/wfg_stim_sine_reg.json
    //template: wishbone/assign_outputs.template
    //marker_template_code
    
    assign ctrl_en_q_o              = ctrl_en_ff;
    assign gain_val_q_o             = gain_val_ff;
    assign id_peripheral_type_q_o   = id_peripheral_type_ff;
    assign id_version_q_o           = id_version_ff;
    assign inc_val_q_o              = inc_val_ff;
    assign offset_val_q_o           = offset_val_ff;
    assign reginfo_date_q_o         = reginfo_date_ff;
    
    //marker_template_end
endmodule
`default_nettype wire
