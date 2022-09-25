`include "parameters.vh"
`include "encoding.vh"

module ddr_pipeline(
  
  // common signals
  input clk,
  input rst,
  
  // execute_stage <-> ddr_pipeline if
  input                         ddr_valid,
  input [`DDR_UOP_WIDTH*4-1:0]  ddr_uop,

  // ddr_pipeline <-> outer DDRX IP interface
  output [3:0]                ddr_write,
  output [3:0]                ddr_read,
  output [3:0]                ddr_pre,
  output [3:0]                ddr_act,
  output [3:0]                ddr_ref,
  output [3:0]                ddr_zq,
  output [3:0]                ddr_nop,
  output [3:0]                ddr_sre,
  output [3:0]                ddr_srx,
  output [3:0]                ddr_ap,
  output [3:0]                ddr_pall,
  output [3:0]                ddr_half_bl,
  output [4*`BG_WIDTH-1:0]    ddr_bg, 
  output [4*`BANK_WIDTH-1:0]  ddr_bank,
  output [4*`COL_WIDTH-1:0]   ddr_col,
  output [4*`ROW_WIDTH-1:0]   ddr_row,
  output [511:0]              ddr_wdata,

  // ddr_pipeline <-> regfile interface
  input  [511:0]                        wide_reg,
  output [7:0]                          update_en,
  output [4*8-1:0]                      update_ids,
  output [32*8-1:0]                     update_vals,   
  input  [`COL_WIDTH-1:0]               casr,
  input  [`BANK_WIDTH+`BG_WIDTH-1:0]    basr,
  input  [`ROW_WIDTH-1:0]               rasr,
  output [4*8-1:0]                      reg_ids, // registers we need to read
  input  [32*8-1:0]                     reg_vals // register values
  );

  //Split input uop into four ways
  wire [`DDR_UOP_WIDTH-1:0] uop [3:0];
  genvar uops;
  generate
    for(uops = 0 ; uops < 4 ; uops = uops + 1) begin: split_uops
      assign uop[uops] = ddr_uop[`DDR_UOP_WIDTH*uops +: `DDR_UOP_WIDTH];
    end
  endgenerate 

  // Figure out reg ids in the bubble cycle
  reg [4*8-1:0] reg_ids_ns, reg_ids_r;

  reg s2_valid;
  reg [`DDR_UOP_WIDTH-1:0] s2_uop [3:0];
  reg [7:0] s2_update_en; // which registers will we update
  reg [8*32-1:0] s2_update_val; 

  reg [3:0]                ddr_write_ns, ddr_write_r;
  reg [3:0]                ddr_read_ns, ddr_read_r; 
  reg [3:0]                ddr_pre_ns, ddr_pre_r;
  reg [3:0]                ddr_act_ns, ddr_act_r;
  reg [3:0]                ddr_ref_ns, ddr_ref_r;
  reg [3:0]                ddr_sre_ns, ddr_sre_r;
  reg [3:0]                ddr_srx_ns, ddr_srx_r;
  reg [3:0]                ddr_zq_ns, ddr_zq_r;
  reg [3:0]                ddr_nop_ns, ddr_nop_r;
  reg [3:0]                ddr_ap_ns, ddr_ap_r;
  reg [3:0]                ddr_pall_ns, ddr_pall_r;
  reg [3:0]                ddr_half_bl_ns, ddr_half_bl_r;
  reg [4*`BG_WIDTH-1:0]    ddr_bg_ns, ddr_bg_r;
  reg [4*`BANK_WIDTH-1:0]  ddr_bank_ns, ddr_bank_r;
  reg [4*`COL_WIDTH-1:0]   ddr_col_ns, ddr_col_r;
  reg [4*`ROW_WIDTH-1:0]   ddr_row_ns, ddr_row_r;
  reg [511:0]              ddr_data_r;

  assign update_vals  = s2_update_val;
  assign update_en    = s2_update_en;
  assign update_ids   = reg_ids_r;
  assign reg_ids      = reg_ids_r;
  // these values are registered before
  // being offloaded to the outer module
  assign ddr_write    = ddr_write_r;
  assign ddr_read     = ddr_read_r;
  assign ddr_pre      = ddr_pre_r;
  assign ddr_act      = ddr_act_r;
  assign ddr_ref      = ddr_ref_r;
  assign ddr_sre      = ddr_sre_r;
  assign ddr_srx      = ddr_srx_r;
  assign ddr_zq       = ddr_zq_r;
  assign ddr_nop      = ddr_nop_r;
  assign ddr_ap       = ddr_ap_r;
  assign ddr_pall     = ddr_pall_r;
  assign ddr_half_bl  = ddr_half_bl_r;
  assign ddr_bg       = ddr_bg_r;
  assign ddr_bank     = ddr_bank_r;
  assign ddr_col      = ddr_col_r;
  assign ddr_row      = ddr_row_r;
  assign ddr_wdata    = ddr_data_r;

  integer i;
  always @* begin
    ddr_nop_ns = {4{`HIGH}};
    s2_update_en = {4{`LOW}};
    reg_ids_ns = reg_ids_r;
    s2_update_val = 8*32'bX;
    for(i = 0 ; i < 4 ; i = i + 1) begin: gen_ddrx_sigs
      // Decide which registers to read in stage 1
      if(uop[i][`IS_WRITE] || uop[i][`IS_READ]) begin
        reg_ids_ns[i*8   +: 4] = uop[i][`BAR +: 4];
        reg_ids_ns[i*8+4 +: 4] = uop[i][`CAR +: 4];
      end
      if(uop[i][`IS_PRE]) begin
        reg_ids_ns[i*8   +: 4] = uop[i][`BAR +: 4];
      end
      if(uop[i][`IS_ACT]) begin
        reg_ids_ns[i*8   +: 4] = uop[i][`BAR +: 4];
        reg_ids_ns[i*8+4 +: 4] = uop[i][`RAR +: 4];
      end
      // stage 2 control sigs
      ddr_pall_ns[i]    = s2_uop[i][`PRE_ALL] & s2_uop[i][`IS_PRE];
      ddr_write_ns[i]   = s2_uop[i][`IS_WRITE];
      ddr_read_ns[i]    = s2_uop[i][`IS_READ];
      ddr_pre_ns[i]     = s2_uop[i][`IS_PRE];
      ddr_act_ns[i]     = s2_uop[i][`IS_ACT];
      ddr_zq_ns[i]      = s2_uop[i][`IS_ZQ];
      ddr_ref_ns[i]     = s2_uop[i][`IS_REF];
      ddr_sre_ns[i]     = s2_uop[i][`IS_SRE];
      ddr_srx_ns[i]     = s2_uop[i][`IS_SRX];
      ddr_ap_ns[i]      = s2_uop[i][`DO_AP] & (s2_uop[i][`IS_WRITE] | s2_uop[i][`IS_READ]);
      ddr_half_bl_ns[i] = s2_uop[i][`IS_BL4] & (s2_uop[i][`IS_WRITE] | s2_uop[i][`IS_READ]);
      ddr_nop_ns[i]     = s2_valid ? s2_uop[i][`IS_NOP] : {4{`HIGH}};
      // stage 2 address calculation
      ddr_row_ns[i*`ROW_WIDTH +: `ROW_WIDTH] 
        = reg_vals[i*64+32 +: `ROW_WIDTH];
      ddr_bank_ns[i*`BANK_WIDTH +: `BANK_WIDTH] 
        = reg_vals[i*64 +: `BANK_WIDTH];
      ddr_bg_ns[i*`BG_WIDTH +: `BG_WIDTH]
        = reg_vals[i*64+`BANK_WIDTH +: `BG_WIDTH];
      ddr_col_ns[i*`COL_WIDTH +: `COL_WIDTH]
        = reg_vals[i*64+32 +: `COL_WIDTH];
      // stage 2 reg update
      if(s2_uop[i][`INC_CAR] & (s2_uop[i][`IS_WRITE] | s2_uop[i][`IS_READ])) begin
        s2_update_en[i*2+1] = `HIGH;
        s2_update_val[i*64+32 +: 32] = reg_vals[i*64+32 +: `COL_WIDTH]
            + casr;
      end 
      else if(s2_uop[i][`INC_RAR] & (s2_uop[i][`IS_ACT])) begin
        s2_update_en[i*2+1] = `HIGH;
        s2_update_val[i*64+32 +: 32] = reg_vals[i*64+32 +: `ROW_WIDTH]
            + rasr;
      end
      if(s2_uop[i][`INC_BAR]) begin
        s2_update_en[i*2] = `HIGH;
        s2_update_val[i*64 +: 32] = reg_vals[i*64 +: `BANK_WIDTH+`BG_WIDTH]
            + basr;
      end
    end // for
  end

  always @(posedge clk) begin
    if(rst) begin
      s2_valid <= `LOW;
      for(i = 0 ; i < 4 ; i = i + 1)
        s2_uop[i] <= {`DDR_UOP_WIDTH{`LOW}};
      ddr_write_r    <= {4{`LOW}};
      ddr_read_r     <= {4{`LOW}};
      ddr_pre_r      <= {4{`LOW}};
      ddr_act_r      <= {4{`LOW}};
      ddr_ref_r      <= {4{`LOW}};
      ddr_sre_r      <= {4{`LOW}};
      ddr_srx_r      <= {4{`LOW}};
      ddr_zq_r       <= {4{`LOW}};
      ddr_nop_r      <= {4{`HIGH}};
      ddr_ap_r       <= {4{`LOW}};
      ddr_half_bl_r  <= {4{`LOW}};
    end
    else begin
      reg_ids_r <= reg_ids_ns;
      s2_valid <= ddr_valid;
      for(i = 0 ; i < 4 ; i = i + 1)
        s2_uop[i] <= uop[i];
      ddr_write_r    <= ddr_write_ns;
      ddr_read_r     <= ddr_read_ns;
      ddr_pre_r      <= ddr_pre_ns;
      ddr_act_r      <= ddr_act_ns;
      ddr_ref_r      <= ddr_ref_ns;
      ddr_sre_r      <= ddr_sre_ns;
      ddr_srx_r      <= ddr_srx_ns;
      ddr_zq_r       <= ddr_zq_ns;
      ddr_nop_r      <= ddr_nop_ns;
      ddr_ap_r       <= ddr_ap_ns;
      ddr_pall_r     <= ddr_pall_ns;
      ddr_half_bl_r  <= ddr_half_bl_ns;
      ddr_bg_r       <= ddr_bg_ns;
      ddr_bank_r     <= ddr_bank_ns;
      ddr_col_r      <= ddr_col_ns;
      ddr_row_r      <= ddr_row_ns;
      ddr_data_r     <= wide_reg;
    end
  end

endmodule
