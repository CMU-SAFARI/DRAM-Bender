// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.2 (lin64) Build 3064766 Wed Nov 18 09:12:47 MST 2020
// Date        : Fri Mar 31 17:33:08 2023
// Host        : safari-aolgun0 running 64-bit Ubuntu 22.04.2 LTS
// Command     : write_verilog -force -mode synth_stub
//               /home/ataberk/DRAM-Bender/gitlab/projects/U50-HBM/U50-HBM.srcs/sources_1/ip/rdback_fifo/rdback_fifo_stub.v
// Design      : rdback_fifo
// Purpose     : Stub declaration of top-level module interface
// Device      : xcu50-fsvh2104-2-e
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "fifo_generator_v13_2_5,Vivado 2020.2" *)
module rdback_fifo(clk, srst, din, wr_en, rd_en, dout, full, empty, valid, 
  prog_full, prog_empty, wr_rst_busy, rd_rst_busy)
/* synthesis syn_black_box black_box_pad_pin="clk,srst,din[511:0],wr_en,rd_en,dout[255:0],full,empty,valid,prog_full,prog_empty,wr_rst_busy,rd_rst_busy" */;
  input clk;
  input srst;
  input [511:0]din;
  input wr_en;
  input rd_en;
  output [255:0]dout;
  output full;
  output empty;
  output valid;
  output prog_full;
  output prog_empty;
  output wr_rst_busy;
  output rd_rst_busy;
endmodule
