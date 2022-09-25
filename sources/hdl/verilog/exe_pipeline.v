`include "parameters.vh"
`include "encoding.vh"

module exe_pipeline(
  // common signals
  input clk,
  input rst,

  // exe_pipeline <-> execution stage if
  input                         exe_valid,
  input [`EXE_UOP_WIDTH-1:0]    exe_uop,
  input [`IMEM_ADDR_WIDTH-1:0]  exe_pc,

  // branch unit if
  output                        br_resolve,
  output [`IMEM_ADDR_WIDTH-1:0] br_target,

  // exe_pipeline <-> register file if
  output                        wide_wen,
  output [31:0]                 rf_wdata,
  output                        rf_wen,
  output [7:0]                  rf_raddr,
  output [3:0]                  rf_waddr,
  input  [2*32-1:0]             rf_rdata,
  input  [32*7-1:0]             ddr_stat, 
    
  // exe_pipeline <-> scratchpad
  output                        mem_wen,
  output                        mem_ren,
  output [9:0]                  mem_addr,
  output [31:0]                 mem_wdata,
  input  [31:0]                 mem_rdata
  );

  // calculated at stage one, registers
  reg                        s2_valid;
  reg [`EXE_UOP_WIDTH-1:0]   s2_uop;
  reg [`IMEM_ADDR_WIDTH-1:0] s2_pc;
  reg [3:0]                  s2_rs1;
  reg [3:0]                  s2_rs2;
  reg [3:0]                  s2_rt;
  reg                        s2_wen;
  reg                        s2_mem_ren;
  reg                        s2_mem_wen;
  reg                        s3_wen; // for loads
  reg [3:0]                  s3_rt;  // for loads
  reg                        s2_wide_wen;
  reg [31:0]                 s2_imd_r, s2_imd_ns;

  // delayed branch resolution signals
  // calculated at stage two, registers
  reg                        s3_br_resolve;
  reg [`IMEM_ADDR_WIDTH-1:0] s3_br_target;

  // combinational elements
  reg [31:0]                 s2_wdata;
  wire [31:0]                s2_rs1_data, s2_rs2_data;
  reg [31:0]                 s2_mem_wdata;
  reg [`IMEM_ADDR_WIDTH-1:0] fetch_pc;

  assign wide_wen       = s2_wide_wen;
  assign rf_wdata       = s3_wen ? mem_rdata : s2_wdata;
  assign rf_wen         = s2_wen || s3_wen;
  assign rf_raddr[0+:4] = s2_rs1; 
  assign rf_raddr[4+:4] = s2_rs2;
  assign rf_waddr       = s3_wen ? s3_rt : s2_rt;

  assign s2_rs1_data = rf_rdata[0+:32];
  assign s2_rs2_data = rf_rdata[32+:32];
  assign br_resolve  = s3_br_resolve;
  assign br_target   = s3_br_target;
  
  assign mem_addr    = s2_rs1_data + s2_imd_r;
  assign mem_wen     = s2_mem_wen;
  assign mem_ren     = s2_mem_ren;
  assign mem_wdata   = s2_mem_wdata;
  
  always @* begin
    // stage one, decode immediate value
    s2_mem_wen  = `LOW;
    s2_imd_ns   = s2_imd_r;
    fetch_pc    = {`IMEM_ADDR_WIDTH{1'bX}};
    s2_wdata    = 32'bX;
    s2_mem_wen  = `LOW;
    s2_mem_ren  = `LOW;
    if(exe_uop[`HAS_IMD]) begin
      s2_imd_ns[15:0] = exe_uop[`IMD +: 16];
      s2_imd_ns[31:16] = {16{`LOW}};
    end
    if(exe_uop[`IS_LI]) begin
      s2_imd_ns[31:16] = exe_uop[`IMD2 +: 16];
    end 
    if(exe_uop[`IS_BL] | exe_uop[`IS_BEQ]) begin
      s2_imd_ns[31:0]  = exe_uop[`IMD +: 19];
    end
    if(exe_uop[`IS_JUMP]) begin
      s2_imd_ns[31:0]  = exe_uop[`IMD +: 27];
    end
    // stage two, actual computation
    if(s2_uop[`IS_ADD]) begin
      if(s2_uop[`HAS_IMD])
        s2_wdata = s2_rs1_data + s2_imd_r;
      else
        s2_wdata = s2_rs1_data + s2_rs2_data;
    end
    if(s2_uop[`IS_SUB]) begin
      if(s2_uop[`HAS_IMD])
        s2_wdata = s2_rs1_data - s2_imd_r;
      else
        s2_wdata = s2_rs1_data - s2_rs2_data;
    end
    if(s2_uop[`IS_MOV] || s2_uop[`IS_LDWD]) begin
      s2_wdata = s2_rs1_data;
    end
    if(s2_uop[`IS_LI]) begin
      s2_wdata = s2_imd_r;
    end
    if(s2_uop[`IS_LDPC]) begin
      s2_wdata = ddr_stat[s2_rs1*32 +: 32];
    end
    if(s2_uop[`IS_SRC]) begin
      s2_wdata[30:0] = s2_rs1_data[31:1];
      s2_wdata[31]   = s2_rs1_data[0];
    end
    // Bitwise ops
    if(s2_uop[`IS_AND]) begin
      s2_wdata = s2_rs1_data & s2_rs2_data;
    end
    if(s2_uop[`IS_OR]) begin
      s2_wdata = s2_rs1_data | s2_rs2_data;
    end
    if(s2_uop[`IS_XOR]) begin
      s2_wdata = s2_rs1_data ^ s2_rs2_data;
    end
    // mem unit
    if(s2_uop[`IS_LD]) begin
      s2_mem_ren = `HIGH;
    end
    if(s2_uop[`IS_ST]) begin
      s2_mem_wdata = s2_rs2_data;
      s2_mem_wen   = `HIGH;
    end

    // branch unit
    if(s2_uop[`IS_BL]) begin
      if(s2_rs1_data < s2_rs2_data)
        fetch_pc = s2_imd_r;
      else // not taken
        fetch_pc = s2_pc + 1;
    end
    if(s2_uop[`IS_BEQ]) begin
      if(s2_rs1_data == s2_rs2_data)
        fetch_pc = s2_imd_r;
      else // not taken
        fetch_pc = s2_pc + 1;
    end
    if(s2_uop[`IS_JUMP]) begin
      fetch_pc = s2_imd_r;
    end
    if(s2_uop[`IS_SLEEP]) begin
      // not implemented
      // frontent/fetch handles api sleeps
    end
    
  end

  always @(posedge clk) begin
    // stage one, further decode
    s2_valid  <= exe_valid;
    s2_uop    <= exe_uop;
    s2_pc     <= exe_pc;
    s2_rs1    <= exe_uop[`RS1 +: 4];
    s2_rs2    <= exe_uop[`RS2 +: 4];
    s2_rt     <= exe_uop[`RT  +: 4];
    s2_imd_r  <= s2_imd_ns;
    s2_wen    <= exe_uop[`IS_ADD] || exe_uop[`IS_SUB] ||
                  exe_uop[`IS_MOV] || exe_uop[`IS_LI] ||
                  exe_uop[`IS_LDWD] || exe_uop[`IS_SRC] ||
                  exe_uop[`IS_AND] || exe_uop[`IS_OR] ||
                  exe_uop[`IS_XOR] || exe_uop[`IS_LDPC];
    s2_wide_wen <= exe_uop[`IS_LDWD];
    // stage two, delayed branch signals
    s3_br_resolve <= s2_valid && (s2_uop[`IS_BL] || 
                        s2_uop[`IS_BEQ] ||
                        s2_uop[`IS_JUMP]);
    s3_br_target  <= fetch_pc;
    s3_wen    <= s2_uop[`IS_LD]; // write path for loads
    s3_rt     <= s2_uop[`RT +: 4];
  end

endmodule
