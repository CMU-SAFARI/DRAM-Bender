`include "parameters.vh"

module execute_stage(
  
  // common signals
  input clk,
  input rst,

  // decode stage <-> execute stage if
  input                        ddr_valid,
  input                        exe_valid,
  input [`DDR_UOP_WIDTH*4-1:0] ddr_uop,
  input [`EXE_UOP_WIDTH-1:0]   exe_uop,
  input [`IMEM_ADDR_WIDTH-1:0] exe_pc,
 
  // branch unit <-> fetch stage if
  output                        br_resolve,
  output [`IMEM_ADDR_WIDTH-1:0] br_target,

  // execute <-> outer DDRX IP interface
  output [3:0]                ddr_write,
  output [3:0]                ddr_read,
  output [3:0]                ddr_pre,
  output [3:0]                ddr_act,
  output [3:0]                ddr_ref,
  output [3:0]                ddr_sre,
  output [3:0]                ddr_srx,
  output [3:0]                ddr_zq,
  output [3:0]                ddr_nop,
  output [3:0]                ddr_ap,
  output [3:0]                ddr_pall,
  output [3:0]                ddr_half_bl,
  output [4*`BG_WIDTH-1:0]    ddr_bg, 
  output [4*`BANK_WIDTH-1:0]  ddr_bank,
  output [4*`COL_WIDTH-1:0]   ddr_col,
  output [4*`ROW_WIDTH-1:0]   ddr_row,
  output [511:0]              ddr_wdata,
 
  // execute <-> reg file if
  output                              rf_wide_wen,
  output  [3:0]                       rf_wide_offset,
  input  [32*8-1:0]                   rf_rdata,
  output [32*8-1:0]                   rf_wdata,
  output [7:0]                        rf_wen,
  output [4*8-1:0]                    rf_raddr,
  output [4*8-1:0]                    rf_waddr,
  input  [`COL_WIDTH-1:0]             casr,
  input  [`BANK_WIDTH+`BG_WIDTH-1:0]  basr,
  input  [`ROW_WIDTH-1:0]             rasr,
  input  [511:0]                      wide_reg,
  
  // update stride registers, wen is OH (3'b001 = update rasr)
  output [31:0]                       srf_value,
  output [2:0]                        srf_wen,
  input  [32*7-1:0]                   ddr_stat
  );
  
  reg s2_exe; // exe_pipeline has regfile ports
  
  // ddr operations can optionally update
  // registers. TODO when do we read the
  // stride values?
  wire [7:0]      rf_wen_ddr;
  wire [4*8-1:0]  rf_waddr_ddr;
  wire [32*8-1:0] rf_wdata_ddr;
  wire [4*8-1:0]  rf_raddr_ddr;

  ddr_pipeline dp(
    .clk(clk),
    .rst(rst),

    // execute <-> ddr_pipe if
    .ddr_valid(ddr_valid),
    .ddr_uop(ddr_uop),

    // ddr_pipeline <-> outer DDRX IP interface
    .ddr_write(ddr_write),
    .ddr_read(ddr_read),
    .ddr_pre(ddr_pre),
    .ddr_act(ddr_act),
    .ddr_ref(ddr_ref),
    .ddr_sre(ddr_sre),
    .ddr_srx(ddr_srx),
    .ddr_zq(ddr_zq),
    .ddr_nop(ddr_nop),
    .ddr_ap(ddr_ap),
    .ddr_pall(ddr_pall),
    .ddr_half_bl(ddr_half_bl),
    .ddr_bg(ddr_bg), 
    .ddr_bank(ddr_bank),
    .ddr_col(ddr_col),
    .ddr_row(ddr_row),
    .ddr_wdata(ddr_wdata),
    // ddr_pipeline <-> regfile interface
    .update_en(rf_wen_ddr),
    .update_ids(rf_waddr_ddr),
    .update_vals(rf_wdata_ddr),   
    .casr(casr),
    .basr(basr),
    .rasr(rasr),
    .reg_ids(rf_raddr_ddr), // registers we need to read
    .reg_vals(rf_rdata), // register values
    .wide_reg(wide_reg) // write data register
  );


  wire[31:0]        rf_wdata_exe;
  wire[7:0]         rf_raddr_exe;
  wire[3:0]         rf_waddr_exe;
  wire              rf_wen_exe;
  wire              rf_wide_wen_exe;
  
  wire              mem_wen;
  wire              mem_ren;
  wire[9:0]         mem_addr;
  wire[31:0]        mem_wdata;
  wire[31:0]        mem_rdata;
  
  exe_pipeline ep(
    .clk(clk),
    .rst(rst),
 
    // exe_pipeline <-> execute stage if   
    .exe_valid(exe_valid),
    .exe_uop(exe_uop),
    .exe_pc(exe_pc),
  
    // branch unit <-> fetch stage if
    .br_resolve(br_resolve),
    .br_target(br_target),
 
    // exe_pipeline <-> regfile if
    .wide_wen(rf_wide_wen_exe),
    .rf_wdata(rf_wdata_exe),
    .rf_wen(rf_wen_exe),
    .rf_raddr(rf_raddr_exe),
    .rf_rdata(rf_rdata[0 +: 32*2]),
    .rf_waddr(rf_waddr_exe),
        
    // exe_pipeline <-> data_mem
    .mem_wen(mem_wen),
    .mem_ren(mem_ren),
    .mem_addr(mem_addr),
    .mem_wdata(mem_wdata),
    .mem_rdata(mem_rdata),
    .ddr_stat(ddr_stat)

  );
`ifdef XILINX_SIMULATOR
    reg_mem data_mem(
        .addr(mem_addr),
        .clk(clk),
        .din(mem_wdata),
        .dout(mem_rdata),
        .en(mem_wen || mem_ren),
        .we(mem_wen)
    );
`else
    scratchpad data_mem(
       .addra(mem_addr),
       .clka(clk),
       .dina(mem_wdata),
       .douta(mem_rdata),
       .ena(mem_wen || mem_ren),
       .wea(mem_wen)
    );
`endif
  
  wire exe_target_srf = rf_waddr_exe == 4'b0000 ||
        rf_waddr_exe == 4'b0001 ||
        rf_waddr_exe == 4'b0010;

  assign rf_wide_wen          = rf_wide_wen_exe;
  assign rf_wide_offset       = rf_waddr_exe;
  assign rf_wdata[32 +: 7*32] = rf_wdata_ddr[32 +: 7*32];
  assign rf_wdata[0 +: 32]    = rf_wen_exe ? rf_wdata_exe : rf_wdata_ddr[0 +: 32];
  assign rf_wen               = (rf_wen_exe & ~rf_wide_wen_exe & ~exe_target_srf) | rf_wen_ddr;
  assign rf_raddr[8 +: 6*4]   = rf_raddr_ddr[8 +: 6*4];
  assign rf_raddr[0 +: 2*4]   = s2_exe ? rf_raddr_exe : rf_raddr_ddr[0 +: 2*8];
  assign rf_waddr[4 +: 7*4]   = rf_waddr_ddr[4 +: 7*4];
  assign rf_waddr[0 +: 4]     = rf_wen_exe ? rf_waddr_exe : rf_waddr_ddr[0 +: 4];

  // First 3 register ids implicitly target stride registers
  assign srf_wen[0]           = rf_wen_exe & ~rf_wide_wen_exe & (rf_waddr_exe == 4'b0000);
  assign srf_wen[1]           = rf_wen_exe & ~rf_wide_wen_exe & (rf_waddr_exe == 4'b0001);
  assign srf_wen[2]           = rf_wen_exe & ~rf_wide_wen_exe & (rf_waddr_exe == 4'b0010);
  
  assign srf_value            = rf_wdata_exe;
  
  always @(posedge clk) begin
    s2_exe <= exe_valid;
  end

endmodule
