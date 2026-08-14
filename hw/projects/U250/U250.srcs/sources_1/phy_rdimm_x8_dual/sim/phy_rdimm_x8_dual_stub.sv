// (c) Copyright 1995-2026 Xilinx, Inc. All rights reserved.
// 
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
// 
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
// 
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
// 
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
// 
// DO NOT MODIFY THIS FILE.


//------------------------------------------------------------------------------------
// Filename:    phy_rdimm_x8_dual_stub.sv
// Description: This HDL file is intended to be used with following simulators only:
//
//   Vivado Simulator (XSim)
//   Cadence Xcelium Simulator
//   Aldec Riviera-PRO Simulator
//
//------------------------------------------------------------------------------------
`timescale 1ps/1ps

`ifdef XILINX_SIMULATOR

`ifndef XILINX_SIMULATOR_BITASBOOL
`define XILINX_SIMULATOR_BITASBOOL
typedef bit bit_as_bool;
`endif

(* SC_MODULE_EXPORT *)
module phy_rdimm_x8_dual (
  output bit_as_bool c0_init_calib_complete,
  output bit_as_bool dbg_clk,
  input bit_as_bool c0_sys_clk_p,
  input bit_as_bool c0_sys_clk_n,
  output bit [511 : 0] dbg_bus,
  output bit_as_bool c0_ddr4_parity,
  output bit_as_bool c0_ddr4_ui_clk,
  output bit_as_bool c0_ddr4_ui_clk_sync_rst,
  input bit_as_bool sys_rst,
  output bit [0 : 0] rdDataEn,
  output bit [0 : 0] rdDataEnd,
  output bit [0 : 0] per_rd_done,
  output bit [0 : 0] rmw_rd_done,
  output bit [0 : 0] wrDataEn,
  input bit [7 : 0] mc_ACT_n,
  input bit [1 : 0] mcCasSlot,
  input bit [0 : 0] mcCasSlot2,
  input bit [0 : 0] mcRdCAS,
  input bit [0 : 0] mcWrCAS,
  input bit [0 : 0] winInjTxn,
  input bit [0 : 0] winRmw,
  input bit_as_bool gt_data_ready,
  input bit [1 : 0] winRank,
  output bit [5 : 0] tCWL,
  input bit [575 : 0] wrData,
  input bit [71 : 0] wrDataMask,
  output bit [575 : 0] rdData,
  input bit [135 : 0] mc_ADR,
  input bit [15 : 0] mc_BA,
  input bit [7 : 0] mc_CKE,
  input bit [7 : 0] mc_CS_n,
  input bit [7 : 0] mc_ODT,
  input bit [4 : 0] dBufAdr,
  output bit [4 : 0] rdDataAddr,
  output bit [4 : 0] wrDataAddr,
  input bit [4 : 0] winBuf,
  output bit_as_bool ddr4_act_n,
  output bit [16 : 0] ddr4_adr,
  output bit [1 : 0] ddr4_ba,
  output bit [1 : 0] ddr4_bg,
  output bit_as_bool ddr4_par,
  output bit [0 : 0] ddr4_cke,
  output bit [0 : 0] ddr4_odt,
  output bit [0 : 0] ddr4_cs_n,
  output bit_as_bool ddr4_ck_t,
  output bit_as_bool ddr4_ck_c,
  output bit_as_bool ddr4_reset_n,
  output bit_as_bool ddr4_parity,
  output bit [8 : 0] ddr4_dm_dbi_n,
  output bit [71 : 0] ddr4_dq,
  output bit [8 : 0] ddr4_dqs_c,
  output bit [8 : 0] ddr4_dqs_t,
  input bit [15 : 0] mc_BG
);
endmodule
`endif

`ifdef XCELIUM
(* XMSC_MODULE_EXPORT *)
module phy_rdimm_x8_dual (c0_init_calib_complete,dbg_clk,c0_sys_clk_p,c0_sys_clk_n,dbg_bus,c0_ddr4_parity,c0_ddr4_ui_clk,c0_ddr4_ui_clk_sync_rst,sys_rst,rdDataEn,rdDataEnd,per_rd_done,rmw_rd_done,wrDataEn,mc_ACT_n,mcCasSlot,mcCasSlot2,mcRdCAS,mcWrCAS,winInjTxn,winRmw,gt_data_ready,winRank,tCWL,wrData,wrDataMask,rdData,mc_ADR,mc_BA,mc_CKE,mc_CS_n,mc_ODT,dBufAdr,rdDataAddr,wrDataAddr,winBuf,ddr4_act_n,ddr4_adr,ddr4_ba,ddr4_bg,ddr4_par,ddr4_cke,ddr4_odt,ddr4_cs_n,ddr4_ck_t,ddr4_ck_c,ddr4_reset_n,ddr4_parity,ddr4_dm_dbi_n,ddr4_dq,ddr4_dqs_c,ddr4_dqs_t,mc_BG)
(* integer foreign = "SystemC";
*);
  output wire c0_init_calib_complete;
  output wire dbg_clk;
  input bit c0_sys_clk_p;
  input bit c0_sys_clk_n;
  output wire [511 : 0] dbg_bus;
  output wire c0_ddr4_parity;
  output wire c0_ddr4_ui_clk;
  output wire c0_ddr4_ui_clk_sync_rst;
  input bit sys_rst;
  output wire [0 : 0] rdDataEn;
  output wire [0 : 0] rdDataEnd;
  output wire [0 : 0] per_rd_done;
  output wire [0 : 0] rmw_rd_done;
  output wire [0 : 0] wrDataEn;
  input bit [7 : 0] mc_ACT_n;
  input bit [1 : 0] mcCasSlot;
  input bit [0 : 0] mcCasSlot2;
  input bit [0 : 0] mcRdCAS;
  input bit [0 : 0] mcWrCAS;
  input bit [0 : 0] winInjTxn;
  input bit [0 : 0] winRmw;
  input bit gt_data_ready;
  input bit [1 : 0] winRank;
  output wire [5 : 0] tCWL;
  input bit [575 : 0] wrData;
  input bit [71 : 0] wrDataMask;
  output wire [575 : 0] rdData;
  input bit [135 : 0] mc_ADR;
  input bit [15 : 0] mc_BA;
  input bit [7 : 0] mc_CKE;
  input bit [7 : 0] mc_CS_n;
  input bit [7 : 0] mc_ODT;
  input bit [4 : 0] dBufAdr;
  output wire [4 : 0] rdDataAddr;
  output wire [4 : 0] wrDataAddr;
  input bit [4 : 0] winBuf;
  output wire ddr4_act_n;
  output wire [16 : 0] ddr4_adr;
  output wire [1 : 0] ddr4_ba;
  output wire [1 : 0] ddr4_bg;
  output wire ddr4_par;
  output wire [0 : 0] ddr4_cke;
  output wire [0 : 0] ddr4_odt;
  output wire [0 : 0] ddr4_cs_n;
  output wire ddr4_ck_t;
  output wire ddr4_ck_c;
  output wire ddr4_reset_n;
  output wire ddr4_parity;
  inout wire [8 : 0] ddr4_dm_dbi_n;
  inout wire [71 : 0] ddr4_dq;
  inout wire [8 : 0] ddr4_dqs_c;
  inout wire [8 : 0] ddr4_dqs_t;
  input bit [15 : 0] mc_BG;
endmodule
`endif

`ifdef RIVIERA
(* SC_MODULE_EXPORT *)
module phy_rdimm_x8_dual (c0_init_calib_complete,dbg_clk,c0_sys_clk_p,c0_sys_clk_n,dbg_bus,c0_ddr4_parity,c0_ddr4_ui_clk,c0_ddr4_ui_clk_sync_rst,sys_rst,rdDataEn,rdDataEnd,per_rd_done,rmw_rd_done,wrDataEn,mc_ACT_n,mcCasSlot,mcCasSlot2,mcRdCAS,mcWrCAS,winInjTxn,winRmw,gt_data_ready,winRank,tCWL,wrData,wrDataMask,rdData,mc_ADR,mc_BA,mc_CKE,mc_CS_n,mc_ODT,dBufAdr,rdDataAddr,wrDataAddr,winBuf,ddr4_act_n,ddr4_adr,ddr4_ba,ddr4_bg,ddr4_par,ddr4_cke,ddr4_odt,ddr4_cs_n,ddr4_ck_t,ddr4_ck_c,ddr4_reset_n,ddr4_parity,ddr4_dm_dbi_n,ddr4_dq,ddr4_dqs_c,ddr4_dqs_t,mc_BG)
  output wire c0_init_calib_complete;
  output wire dbg_clk;
  input bit c0_sys_clk_p;
  input bit c0_sys_clk_n;
  output wire [511 : 0] dbg_bus;
  output wire c0_ddr4_parity;
  output wire c0_ddr4_ui_clk;
  output wire c0_ddr4_ui_clk_sync_rst;
  input bit sys_rst;
  output wire [0 : 0] rdDataEn;
  output wire [0 : 0] rdDataEnd;
  output wire [0 : 0] per_rd_done;
  output wire [0 : 0] rmw_rd_done;
  output wire [0 : 0] wrDataEn;
  input bit [7 : 0] mc_ACT_n;
  input bit [1 : 0] mcCasSlot;
  input bit [0 : 0] mcCasSlot2;
  input bit [0 : 0] mcRdCAS;
  input bit [0 : 0] mcWrCAS;
  input bit [0 : 0] winInjTxn;
  input bit [0 : 0] winRmw;
  input bit gt_data_ready;
  input bit [1 : 0] winRank;
  output wire [5 : 0] tCWL;
  input bit [575 : 0] wrData;
  input bit [71 : 0] wrDataMask;
  output wire [575 : 0] rdData;
  input bit [135 : 0] mc_ADR;
  input bit [15 : 0] mc_BA;
  input bit [7 : 0] mc_CKE;
  input bit [7 : 0] mc_CS_n;
  input bit [7 : 0] mc_ODT;
  input bit [4 : 0] dBufAdr;
  output wire [4 : 0] rdDataAddr;
  output wire [4 : 0] wrDataAddr;
  input bit [4 : 0] winBuf;
  output wire ddr4_act_n;
  output wire [16 : 0] ddr4_adr;
  output wire [1 : 0] ddr4_ba;
  output wire [1 : 0] ddr4_bg;
  output wire ddr4_par;
  output wire [0 : 0] ddr4_cke;
  output wire [0 : 0] ddr4_odt;
  output wire [0 : 0] ddr4_cs_n;
  output wire ddr4_ck_t;
  output wire ddr4_ck_c;
  output wire ddr4_reset_n;
  output wire ddr4_parity;
  inout wire [8 : 0] ddr4_dm_dbi_n;
  inout wire [71 : 0] ddr4_dq;
  inout wire [8 : 0] ddr4_dqs_c;
  inout wire [8 : 0] ddr4_dqs_t;
  input bit [15 : 0] mc_BG;
endmodule
`endif
