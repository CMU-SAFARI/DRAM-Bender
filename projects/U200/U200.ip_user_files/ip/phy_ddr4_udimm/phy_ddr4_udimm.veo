// (c) Copyright 1995-2022 Xilinx, Inc. All rights reserved.
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

// IP VLNV: xilinx.com:ip:ddr4:2.2
// IP Revision: 10

// The following must be inserted into your Verilog file for this
// core to be instantiated. Change the instance name and port connections
// (in parentheses) to your own signal names.

//----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
phy_ddr4_udimm your_instance_name (
  .c0_init_calib_complete(c0_init_calib_complete),    // output wire c0_init_calib_complete
  .dbg_clk(dbg_clk),                                  // output wire dbg_clk
  .c0_sys_clk_p(c0_sys_clk_p),                        // input wire c0_sys_clk_p
  .c0_sys_clk_n(c0_sys_clk_n),                        // input wire c0_sys_clk_n
  .dbg_bus(dbg_bus),                                  // output wire [511 : 0] dbg_bus
  .c0_ddr4_ui_clk(c0_ddr4_ui_clk),                    // output wire c0_ddr4_ui_clk
  .c0_ddr4_ui_clk_sync_rst(c0_ddr4_ui_clk_sync_rst),  // output wire c0_ddr4_ui_clk_sync_rst
  .sys_rst(sys_rst),                                  // input wire sys_rst
  .rdDataEn(rdDataEn),                                // output wire [0 : 0] rdDataEn
  .rdDataEnd(rdDataEnd),                              // output wire [0 : 0] rdDataEnd
  .per_rd_done(per_rd_done),                          // output wire [0 : 0] per_rd_done
  .rmw_rd_done(rmw_rd_done),                          // output wire [0 : 0] rmw_rd_done
  .wrDataEn(wrDataEn),                                // output wire [0 : 0] wrDataEn
  .mc_ACT_n(mc_ACT_n),                                // input wire [7 : 0] mc_ACT_n
  .mcCasSlot(mcCasSlot),                              // input wire [1 : 0] mcCasSlot
  .mcCasSlot2(mcCasSlot2),                            // input wire [0 : 0] mcCasSlot2
  .mcRdCAS(mcRdCAS),                                  // input wire [0 : 0] mcRdCAS
  .mcWrCAS(mcWrCAS),                                  // input wire [0 : 0] mcWrCAS
  .winInjTxn(winInjTxn),                              // input wire [0 : 0] winInjTxn
  .winRmw(winRmw),                                    // input wire [0 : 0] winRmw
  .gt_data_ready(gt_data_ready),                      // input wire gt_data_ready
  .winRank(winRank),                                  // input wire [1 : 0] winRank
  .tCWL(tCWL),                                        // output wire [5 : 0] tCWL
  .wrData(wrData),                                    // input wire [511 : 0] wrData
  .wrDataMask(wrDataMask),                            // input wire [63 : 0] wrDataMask
  .rdData(rdData),                                    // output wire [511 : 0] rdData
  .mc_ADR(mc_ADR),                                    // input wire [135 : 0] mc_ADR
  .mc_BA(mc_BA),                                      // input wire [15 : 0] mc_BA
  .mc_CKE(mc_CKE),                                    // input wire [7 : 0] mc_CKE
  .mc_CS_n(mc_CS_n),                                  // input wire [7 : 0] mc_CS_n
  .mc_ODT(mc_ODT),                                    // input wire [7 : 0] mc_ODT
  .dBufAdr(dBufAdr),                                  // input wire [4 : 0] dBufAdr
  .rdDataAddr(rdDataAddr),                            // output wire [4 : 0] rdDataAddr
  .wrDataAddr(wrDataAddr),                            // output wire [4 : 0] wrDataAddr
  .winBuf(winBuf),                                    // input wire [4 : 0] winBuf
  .ddr4_act_n(ddr4_act_n),                            // output wire ddr4_act_n
  .ddr4_adr(ddr4_adr),                                // output wire [16 : 0] ddr4_adr
  .ddr4_ba(ddr4_ba),                                  // output wire [1 : 0] ddr4_ba
  .ddr4_bg(ddr4_bg),                                  // output wire [1 : 0] ddr4_bg
  .ddr4_par(ddr4_par),                                // output wire ddr4_par
  .ddr4_cke(ddr4_cke),                                // output wire [0 : 0] ddr4_cke
  .ddr4_odt(ddr4_odt),                                // output wire [0 : 0] ddr4_odt
  .ddr4_cs_n(ddr4_cs_n),                              // output wire [0 : 0] ddr4_cs_n
  .ddr4_ck_t(ddr4_ck_t),                              // output wire ddr4_ck_t
  .ddr4_ck_c(ddr4_ck_c),                              // output wire ddr4_ck_c
  .ddr4_reset_n(ddr4_reset_n),                        // output wire ddr4_reset_n
  .ddr4_dm_dbi_n(ddr4_dm_dbi_n),                      // inout wire [7 : 0] ddr4_dm_dbi_n
  .ddr4_dq(ddr4_dq),                                  // inout wire [63 : 0] ddr4_dq
  .ddr4_dqs_c(ddr4_dqs_c),                            // inout wire [7 : 0] ddr4_dqs_c
  .ddr4_dqs_t(ddr4_dqs_t),                            // inout wire [7 : 0] ddr4_dqs_t
  .mc_BG(mc_BG)                                      // input wire [15 : 0] mc_BG
);
// INST_TAG_END ------ End INSTANTIATION Template ---------

// You must compile the wrapper file phy_ddr4_udimm.v when simulating
// the core, phy_ddr4_udimm. When compiling the wrapper file, be sure to
// reference the Verilog simulation library.

