`timescale 1ns / 1ps
`include "parameters.vh"
`include "project.vh"

module ddr3_adapter
  (
    input                                               clk,
    input                                               rst,
    
    input                                               init_calib_complete,
  
    // ddr_pipeline <-> outer module if
    input [3:0]                ddr_write,
    input [3:0]                ddr_read,
    input [3:0]                ddr_pre,
    input [3:0]                ddr_act,
    input [3:0]                ddr_ref,
    input [3:0]                ddr_zq,
    input [3:0]                ddr_nop,
    input [3:0]                ddr_ap,
    input [3:0]                ddr_half_bl,
    input [3:0]                ddr_pall,
    input [4*`BG_WIDTH-1:0]    ddr_bg, 
    input [4*`BANK_WIDTH-1:0]  ddr_bank,
    input [4*`COL_WIDTH-1:0]   ddr_col,
    input [4*`ROW_WIDTH-1:0]   ddr_row,
    input [511:0]              ddr_wdata,
    
    // periodic maintenance signals
    input                      ddr_maint_read, // next read will be a maintenance read

    // Adapter <-> PHY Interface
    output [3:0]                                        mc_ras_n, // DDR Row access strobe
    output [3:0]                                        mc_cas_n, // DDR Column access strobe
    output [3:0]                                        mc_we_n,  // DDR Write enable
    output [4*14-1:0]                                   mc_address, // row address for activates / column address for read&writes
    output [11:0]                                       mc_bank, // bank address
    output [3:0]                                        mc_cs_n, // chip select, probably used to deselect in NOP cycles
    output                                              mc_reset_n, // Have no idea, probably need to keep HIGH
    output reg [1:0]                                    mc_odt, // Need some logic to drive this
    output [3:0]                                        mc_cke, // This should be HIGH all the time
    // AUX - For ODT and CKE assertion during reads and writes
    output [3:0]                                        mc_aux_out0, 
    output [3:0]                                        mc_aux_out1,
    output                                              mc_cmd_wren, // Enqueue new command
    output                                              mc_ctl_wren, // Enqueue new control singal
    output [2:0]                                        mc_cmd, // The command to enqueue
    output [1:0]                                        mc_cas_slot, // Which CAS slot we issued this command from 0-2
    output reg [5:0]                                    mc_data_offset,    
    output reg [5:0]                                    mc_data_offset_1,
    output reg [5:0]                                    mc_data_offset_2,
    output [1:0]                                        mc_rank_cnt,
    // Write
    output                                              mc_wrdata_en, // Asserted for DDR-WRITEs
    output [511:0]                                      mc_wrdata,
    output [63:0]                                       mc_wrdata_mask,
    output                                              idle,
    input                                               phy_mc_ctl_full, // CTL interface is full
    input                                               phy_mc_cmd_full, // CMD interface is full
    input                                               phy_mc_data_full, // ?????????
    input [5:0]                                         calib_rd_data_offset_0,
    input [5:0]                                         calib_rd_data_offset_1,
    input [5:0]                                         calib_rd_data_offset_2,
    // Misc
    output                                              wd_fifo_rden   
  );

  // TODO: Fix WRDATA - drive wrdata and mask at wrdata_stage 2
  // TODO2: is mask enabled when it is set to one or zero?

  localparam CWL = 5;

  reg [511:0] wrdata_s1, wrdata_s2;
  reg mc_wrdata_en_ns;
  reg wrdata_en_s1, wrdata_en_s2;
  // Pipe these signals
  reg [1:0] mc_odt_r, mc_odt_ns; // Needs to be HI for two consecutive cycles after each WRITE
  reg [2:0] mc_cmd_int;
  assign    mc_cmd = mc_cmd_int;          
  assign    mc_wrdata_mask = {64{1'b1}};
  
  assign    mc_wrdata = wrdata_s2;
  
  always @(posedge clk) begin
    wrdata_en_s1  <= mc_wrdata_en_ns;
    wrdata_s1     <= ddr_wdata;
    wrdata_en_s2  <= wrdata_en_s1;
    wrdata_s2     <= wrdata_s1;
    mc_odt_r      <= mc_odt_ns;
  end

  // TODO: can only issue CAS commands from odd slots for now
  wire [1:0] cas_offset    = ddr_read[1] | ddr_write[1] ? 2'b01 : 2'b11;
  
  assign wd_fifo_rden = wrdata_en_s1;
  assign mc_wrdata_en = wrdata_en_s2;
  assign mc_reset_n   = 1'b1;
  assign mc_cke       = {4{1'b1}}; 
  assign mc_aux_out0  = 3'b0;
  assign mc_aux_out1  = 3'b0;
  assign idle         = 1'b0;
  assign mc_cmd_wren  = init_calib_complete;
  assign mc_ctl_wren  = init_calib_complete;
  assign mc_cas_slot  = cas_offset;
  assign mc_rank_cnt  = 2'b0;
  
  genvar cmd_off;
  generate
    for(cmd_off = 0 ; cmd_off < 4 ; cmd_off = cmd_off + 1) begin: for_conv
      assign mc_cs_n[cmd_off]   = ddr_nop[cmd_off];   // NOP
      assign mc_ras_n[cmd_off]  = ddr_read[cmd_off] |  // READ
                                      ddr_write[cmd_off] |  // WRITE
                                      ddr_zq[cmd_off];   // ZQS
      assign mc_cas_n[cmd_off]  = ddr_act[cmd_off] |  // ACT
                                      ddr_pre[cmd_off] |  // PRE
                                      ddr_pall[cmd_off] |  // PRE-ALL
                                      ddr_zq[cmd_off];   // ZQS
      assign mc_we_n[cmd_off]   = ddr_act[cmd_off] |  // ACT
                                      ddr_read[cmd_off] |  // READ
                                      ddr_ref[cmd_off];   // REF
      assign mc_bank            = ddr_bank; // TODO is this correct??
      assign mc_address[cmd_off*14 +: 14] = 
            (ddr_read[cmd_off] |  // READ or WRITE
            ddr_write[cmd_off]) ? 
            ddr_col[cmd_off*`COL_WIDTH+:`COL_WIDTH]: // column address if read&write
            ddr_act[cmd_off] ?
            ddr_row[cmd_off*`ROW_WIDTH+:`ROW_WIDTH] :// row address 
            ddr_pall[cmd_off] ?
            14'b00_0100_0000_0000 : 14'b0; // all zeros if PRE - 10th bit will precharge all banks
    end
  endgenerate

  always @* begin
    mc_odt          = mc_odt_r;
    mc_odt_ns       = 2'b0;
    mc_wrdata_en_ns = 1'b0;
    mc_cmd_int      = 0;
    if(|ddr_write) begin// WRITE
      mc_cmd_int        = 3'b001;
      mc_data_offset    = CWL + 2'b10 + 1'b1;
      mc_data_offset_1  = CWL + 2'b10 + 1'b1;
      mc_data_offset_2  = CWL + 2'b10 + 1'b1;
      mc_odt_ns         = 2'b01;
      mc_odt            = 2'b01;
      mc_wrdata_en_ns   = 1'b1;
    end
    else if(|ddr_read) begin// READ
      mc_cmd_int        = 3'b011;
      mc_data_offset    = calib_rd_data_offset_0[5:0];
      mc_data_offset_1  = calib_rd_data_offset_1[5:0];
      mc_data_offset_2  = calib_rd_data_offset_2[5:0];
    end  
    else begin
      mc_cmd_int        = 3'b100;
      mc_data_offset    = 6'b0;
      mc_data_offset_1  = 6'b0;
      mc_data_offset_2  = 6'b0;
    end
  end

endmodule