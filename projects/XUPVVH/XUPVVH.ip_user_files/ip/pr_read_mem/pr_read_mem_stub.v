// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.2 (lin64) Build 2708876 Wed Nov  6 21:39:14 MST 2019
// Date        : Sun Oct 18 14:26:35 2020
// Host        : jalapeno running 64-bit Ubuntu 18.04.5 LTS
// Command     : write_verilog -force -mode synth_stub
//               /home/ataberk/SoftMC_DDR4/projects/XUPVVH/XUPVVH.srcs/sources_1/ip/pr_read_mem/pr_read_mem_stub.v
// Design      : pr_read_mem
// Purpose     : Stub declaration of top-level module interface
// Device      : xcvu37p-fsvh2892-2-e
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_4_4,Vivado 2019.2" *)
module pr_read_mem(clka, ena, wea, addra, dina, douta)
/* synthesis syn_black_box black_box_pad_pin="clka,ena,wea[0:0],addra[3:0],dina[63:0],douta[63:0]" */;
  input clka;
  input ena;
  input [0:0]wea;
  input [3:0]addra;
  input [63:0]dina;
  output [63:0]douta;
endmodule
