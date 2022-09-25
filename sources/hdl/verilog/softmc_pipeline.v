`include "parameters.vh"

module softmc_pipeline(
  
  // common signals
  input clk,
  input rst,
 
  // readback <-> fetch_stage backpressure

  output softmc_end,
  output [11:0] read_size,
  output        read_seq_incoming,
  input  [11:0] buffer_space,
 
  // frontend <-> fetch stage interface
  output  [`IMEM_ADDR_WIDTH-1:0] addr_out,
  output                         valid_out,
  input [`INSTR_WIDTH-1:0]       data_in,
  input                          valid_in,
  input [`IMEM_ADDR_WIDTH-1:0]   addr_in,
  input                          ready_out,
  
  // ddr_pipeline <-> outer DDR module
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
  output [511:0]              ddr_wdata
  );
  
  wire                        br_resolve;
  wire [`IMEM_ADDR_WIDTH-1:0] br_target;

  wire [`INSTR_WIDTH-1:0]     dec_instr;
  wire                        dec_instr_valid;
  wire [`IMEM_ADDR_WIDTH-1:0] dec_instr_pc;

  fetch_stage fs(
    .clk(clk),
    .rst(rst),

    .softmc_end(softmc_end),
    .read_size(read_size),
    .read_seq_incoming(read_seq_incoming),
    .buffer_space(buffer_space),


    .addr_out(addr_out),
    .valid_out(valid_out),
    .data_in(data_in),
    .valid_in(valid_in),
    .addr_in(addr_in),
    .ready_out(ready_out),

    .br_resolve(br_resolve),
    .br_target(br_target),

    .instr(dec_instr),
    .instr_pc(dec_instr_pc),
    .instr_valid(dec_instr_valid)
  );
  
  wire                        ddr_valid, exe_valid;
  wire [`DDR_UOP_WIDTH*4-1:0] ddr_uop;
  wire [`EXE_UOP_WIDTH-1:0]   exe_uop;
  wire [`IMEM_ADDR_WIDTH-1:0] exe_pc;
  wire [32*7-1:0]             ddr_stat;

  decode_stage ds(
    .clk(clk),
    .rst(rst),
 
    .instr(dec_instr),
    .instr_pc(dec_instr_pc),
    .instr_valid(dec_instr_valid),

    .ddr_valid(ddr_valid),
    .exe_valid(exe_valid),
    .ddr_uop(ddr_uop),
    .exe_uop(exe_uop),
    .exe_pc(exe_pc),
    .ddr_stat(ddr_stat)
  );

  wire                                rf_wide_wen;
  wire   [3:0]                        rf_wide_offset;
  wire   [511:0]                      rf_wide_data;
  wire   [32*8-1:0]                   rf_rdata;
  wire   [32*8-1:0]                   rf_wdata;
  wire   [7:0]                        rf_wen;
  wire   [4*8-1:0]                    rf_raddr;
  wire   [4*8-1:0]                    rf_waddr;
  wire   [`COL_WIDTH-1:0]             casr;
  wire   [`BANK_WIDTH+`BG_WIDTH-1:0]  basr;
  wire   [`ROW_WIDTH-1:0]             rasr;
  wire   [31:0]                       srf_value;
  wire   [2:0]                        srf_wen;
 
  execute_stage es(
    .clk(clk),
    .rst(rst),
 
    .br_resolve(br_resolve),
    .br_target(br_target),
    
    .ddr_valid(ddr_valid),
    .exe_valid(exe_valid),
    .ddr_uop(ddr_uop),
    .exe_uop(exe_uop),
    .exe_pc(exe_pc),

    .rf_wide_wen(rf_wide_wen),
    .rf_wide_offset(rf_wide_offset),
    .wide_reg(rf_wide_data),
    .rf_rdata(rf_rdata),
    .rf_wdata(rf_wdata),
    .rf_wen(rf_wen),
    .rf_raddr(rf_raddr),
    .rf_waddr(rf_waddr),
    .casr(casr),
    .basr(basr),
    .rasr(rasr),
    .srf_value(srf_value),
    .srf_wen(srf_wen),
    .ddr_stat(ddr_stat),
    
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
    .ddr_wdata(ddr_wdata)
  );
  
  register_file rf(
    .clk(clk),
    .rst(rst),
  
    .rf_wide_wen(rf_wide_wen),
    .rf_wide_offset(rf_wide_offset),
    .rf_wide_data(rf_wide_data),
    .rf_rdata(rf_rdata),
    .rf_wdata(rf_wdata),
    .rf_wen(rf_wen),
    .rf_raddr(rf_raddr),
    .rf_waddr(rf_waddr),
    .casr(casr),
    .basr(basr),
    .rasr(rasr),
    .srf_value(srf_value),
    .srf_wen(srf_wen)
  );
  
endmodule
