

/******************************************************************************
// (c) Copyright 2013 - 2014 Xilinx, Inc. All rights reserved.
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
******************************************************************************/
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor             : Xilinx
// \   \   \/     Version            : 1.0
//  \   \         Application        : DDR4
//  /   /         Filename           : phy_ddr4_udimm_ddr4.sv
// /___/   /\     Date Last Modified : $Date: 2011/06/17 11:11:25 $
// \   \  /  \    Date Created       : Thu Apr 18 2013
//  \___\/\___\
//
// Device           : UltraScale
// Design Name      : DDR4_SDRAM
// Purpose          :
//   Top-level  module. This module can be instantiated in the
//   system and interconnect as shown in user design wrapper file
//   (user top module).
// Reference        :
// Revision History :
//*****************************************************************************



  

`timescale 1ps/1ps
`ifdef MODEL_TECH
    `ifndef CALIB_SIM
       `define SIMULATION
     `endif
`elsif INCA
    `ifndef CALIB_SIM
       `define SIMULATION
     `endif
`elsif VCS
    `ifndef CALIB_SIM
       `define SIMULATION
     `endif
`elsif XILINX_SIMULATOR
    `ifndef CALIB_SIM
       `define SIMULATION
     `endif
`elsif _VCP
    `ifndef CALIB_SIM
       `define SIMULATION
     `endif
`endif

(*

  X_MIG_OLYMPUS = 1,
  X_ULTRASCALE_IO_FLOW = "xilinx.com:ip:ddr4_phy:2.2",
  LIVE_DESIGN = 0,
  MEM_CORE_VER = "xilinx.com:ip:mem:1.4",
  PhyIP_CUSTOM_PART_ATTRIBUTES = "NONE",
  ControllerType = "ddr4_sdram",
  PhyIP_TimePeriod = 1500,
  PhyIP_InputClockPeriod = 3333,
  PhyIP_MemoryType = "UDIMMs",
  PhyIP_MemoryPart = "MTA8ATF1G64AZ-2G3",
  PhyIP_PhyClockRatio = "4:1",
  PhyIP_ECC = "false",
  PhyIP_CasLatency = 10,
  PhyIP_CasWriteLatency = 9,
  PhyIP_DataWidth = 64,
  PhyIP_ChipSelect = "true",
  PhyIP_Slot = "Single",
  PhyIP_isCKEShared = "false",
  PhyIP_DataMask = "DM_NO_DBI",
  PhyIP_MemoryVoltage = "1.2V",
  PhyIP_PARTIAL_RECONFIG_FLOW_MIG = "false",
  PhyIP_CLKFBOUT_MULT = "5",
  PhyIP_DIVCLK_DIVIDE = "1",
  PhyIP_CLKOUT0_DIVIDE = "9",
  PhyIP_CLKOUT1_DIVIDE = "0",
  PhyIP_CLKOUT2_DIVIDE = "0",
  PhyIP_CLKOUT3_DIVIDE = "0",
  PhyIP_CLKOUT4_DIVIDE = "0",
  PhyIP_VrefVoltage = "0.84",
  PhyIP_StackHeight = "1",
  PhyIP_IS_FROM_PHY = "1",
  PhyIP_CA_MIRROR = "0",
  PhyIP_SELF_REFRESH = "false",
  PhyIP_SAVE_RESTORE = "false",
  PhyIP_Enable_LVAUX = "false", 

  PhyIP_EN_PARITY = "false",  
  PhyIP_System_Clock = "Differential",
  PhyIP_Simulation_Mode = "BFM",
  PhyIP_Phy_Only = "Phy_Only_Single",
  PhyIP_DEBUG_SIGNAL = "Disable",
  PhyIP_CLKOUTPHY_MODE = "VCO",
  PhyIP_DQ_WIDTH = 64,
  PhyIP_MEM_DEVICE_WIDTH = 64,
  PhyIP_MIN_PERIOD = 833,
  PhyIP_USE_DM_PORT = "DM_NO_DBI",
  PhyIP_USE_CS_PORT = "true",
  PhyIP_ADDR_WIDTH = 17,
  PhyIP_BANK_WIDTH = 2,
  PhyIP_BANK_GROUP_WIDTH = 2,
  PhyIP_CKE_WIDTH = 1,
  PhyIP_CK_WIDTH = 1,
  PhyIP_CS_WIDTH = 1,
  PhyIP_CLAMSHELL = "false",
  PhyIP_RANK_WIDTH = 1,
  PhyIP_tCK = 1500,
  PhyIP_HR_MIN_FREQ = 0,
  PhyIP_DCI_CASCADE_CUTOFF = 938,
  PhyIP_IS_FASTER_SPEED_RAM = "No",
  PhyIP_ODT_WIDTH = 1,
  PhyIP_nCS_PER_RANK = 1,
  PhyIP_DATABITS_PER_STROBE = 8,
  PhyIP_DQS_WIDTH = 8,
  PhyIP_DM_WIDTH = 8

*)

(* dont_touch = "true" *) module phy_ddr4_udimm_ddr4 #
 (
	
    parameter         PING_PONG_PHY           = 1, 
    parameter integer ADDR_WIDTH              = 17,
    parameter integer BANK_WIDTH              = 2,
    parameter integer BANK_GROUP_WIDTH        = 2,
    parameter integer S_HEIGHT                = 1,
    parameter integer LR_WIDTH                = 1,
    parameter integer CKE_WIDTH               = 1,
    parameter integer CK_WIDTH                = 1,
    parameter integer COL_WIDTH               = 10,
    parameter integer CS_WIDTH                = 1,
    parameter integer ODT_WIDTH               = 1,
    parameter integer DQ_WIDTH                = 64,
    parameter integer DQS_WIDTH               = 8,
    parameter integer DM_WIDTH                = 8,

    parameter         DRAM_TYPE               = "DDR4",
    parameter integer DATA_BUF_ADDR_WIDTH  = 5,
    parameter DM_DBI                          = "DM_NODBI",

    parameter         USE_CS_PORT             = 1,
    parameter         REG_CTRL                = "OFF",
    parameter         LRDIMM_MODE             = "OFF", // LRDIMM Mode
    parameter         MCS_ECC_ENABLE       = "FALSE",

    parameter         DDR4_DB_HIF_RTT_NOM     = 4'b0011, 
    parameter         DDR4_DB_HIF_RTT_WR      = 4'b0000, 
    parameter         DDR4_DB_HIF_RTT_PARK    = 4'b0000, 
    parameter         DDR4_DB_HIF_DI          = 4'b0001, 
    parameter         DDR4_DB_DIF_ODT         = 4'b0011, 
    parameter         DDR4_DB_DIF_DI          = 4'b0000, 
    parameter         DDR4_DB_HIF_VREF        = 8'b0001_1011,
    parameter         DDR4_DB_DIF_VREF        = 8'b0001_1011,

    parameter         tCK                     = 1500,  // Memory clock period (DDR4 clock cycle)
    parameter         ODTWRDEL                = 5'd9,
    parameter         ODTWRDUR                = 4'd6,
    parameter         ODTWRODEL               = 5'd9,
    parameter         ODTWRODUR               = 4'd6,
    parameter         ODTRDDEL                = 5'd10,
    parameter         ODTRDDUR                = 4'd6,
    parameter         ODTRDODEL               = 5'd9,
    parameter         ODTRDODUR               = 4'd6,
    parameter         ODTNOP                  = 16'h0000,

    parameter real    TCQ                     = 100,
    parameter         DRAM_WIDTH              = 8,
    parameter         RANKS                   = 1,
    parameter         RTL_VERSION             = 0,
    parameter         EXTRA_CMD_DELAY         = 0,
    parameter         nCK_PER_CLK             = 4,

    parameter         CLKIN_PERIOD_MMCM        = 3333,
    parameter         CLKFBOUT_MULT_MMCM       = 5,
    parameter         DIVCLK_DIVIDE_MMCM       = 1,
    parameter         CLKOUT0_DIVIDE_MMCM      = 9,
    parameter         CLKOUT1_DIVIDE_MMCM      = 9,
    parameter         CLKOUT2_DIVIDE_MMCM      = 9,
    parameter         CLKOUT3_DIVIDE_MMCM      = 9,
    parameter         CLKOUT4_DIVIDE_MMCM      = 9,
    parameter         CLKOUT6_DIVIDE_MMCM      = 18,
    parameter         CLKOUTPHY_MODE           = "VCO",
    parameter         C_FAMILY                 = "virtexuplus",

// following local parameters are defined for coverage purpose and is for internal use
    parameter C_S_AXI_ID_WIDTH = 0, // for internal use only
    parameter C_S_AXI_ADDR_WIDTH = 0, // for internal use only
    parameter C_S_AXI_DATA_WIDTH = 0, // for internal use only
    parameter C_S_AXI_SUPPORTS_NARROW_BURST   = 0, // for internal use only
    parameter C_RD_WR_ARB_ALGORITHM           = "RD_PRI_REG", // for internal use only
    parameter BURST_MODE                      = "8",     // Burst length // for internal use only
    parameter ADV_USER_REQ                    ="NONE",
    parameter         APP_ADDR_WIDTH          = 30,
    parameter         ORDERING                = "NORM",
    parameter ECC                               = "OFF",
    parameter MIG_PARAM_CHECKS                  ="FALSE",
    parameter INTERFACE                         ="PHY",
    parameter FPGA			                        = "xcu200-fsgd2104-2-e-",
    parameter DEVICE			                      = "xcu200-",
    parameter FAMILY                            = "ULTRASCALEPLUS",
    parameter DEBUG_SIGNAL		                  = "Disable",
    parameter AL                                = "0",
    parameter SELF_REFRESH                      = "false",
    parameter SAVE_RESTORE                      = "false",
    parameter RESTORE_CRC                       = "false",
    parameter IS_CKE_SHARED                     = "false",
    parameter MEMORY_PART                       = "MTA8ATF1G64AZ-2G3",
    parameter integer COMPONENT_WIDTH	          = 64,
    parameter integer ROW_WIDTH                 = 16,
    parameter MEM_ADDR_ORDER                    = "ROW_COLUMN_BANK",
    parameter MEMORY_DENSITY                    = "8Gb",
    parameter MEMORY_SPEED_GRADE                = "083",
    parameter MEMORY_WIDTH                      = "8",
    parameter NUM_SLOT                          = 1,
    parameter RANK_SLOT                         = 1,

    parameter         SYSCLK_TYPE             = "DIFFERENTIAL",
                                // input clock type
    parameter MEMORY_CONFIGURATION              = "UDIMM",
    parameter CALIB_HIGH_SPEED                  = "FALSE",
    parameter         CA_MIRROR                 = "OFF",
    // Clamshell architecture of DRAM parts on PCB
    parameter         DDR4_CLAMSHELL       = "OFF",

    parameter DDR4_REG_PARITY_ENABLE            = "OFF",
    parameter integer DBYTES                    = 8,
 
    parameter         MR0                       = 13'b0000100000100,

    parameter         ODTWR                     = 16'h0001, 
    parameter         ODTRD                     = 16'h0000,
    parameter         AL_SEL                    = "0",
      parameter         MR1                       = 13'b0001100000001,
    parameter         MR5                       = 13'b0010000000000,
    parameter         MR6                       = 13'b0000000011011,


    parameter         MR2                       = 13'b0000000000000,
    parameter         MR3                       = 13'b0000000000000,
    parameter         MR4                       = 13'b0000000000000,

    parameter         RD_VREF_VAL               = 7'h1D,

    parameter         SLOT0_CONFIG              = {{(8-CS_WIDTH){1'b0}},{CS_WIDTH{1'b1}}},  
    parameter         SLOT1_CONFIG              = 8'b0000_0000,
    parameter         SLOT0_FUNC_CS             = {{(8-CS_WIDTH){1'b0}},{CS_WIDTH{1'b1}}},  
    parameter         SLOT1_FUNC_CS             = 8'b0000_0000,
    parameter         SLOT0_ODD_CS              = 8'b0000_0000, 
    parameter         SLOT1_ODD_CS              = 8'b0000_0000,

    parameter         DDR4_REG_RC03             = {9'b0_0000_0011, 4'b0000},

    parameter         DDR4_REG_RC04             = {9'b0_0000_0100, 4'b0000},

    parameter         DDR4_REG_RC05             = {9'b0_0000_0101, 4'b0000},
    parameter         tXPR                      = 60, // In fabric clock cycles
    parameter         tMOD                      = 6, // In fabric clock cycles
    parameter         tMRD                      = 2, // In fabric clock cycles
    parameter         tZQINIT                   = 256, // In fabric clock cycles
    parameter         tRFC                    = 234, //In DDR4 clock cycles
    parameter         MEM_CODE                  = 0,
    parameter         C_DEBUG_ENABLED           = 0,
    parameter         CPLX_PAT_LENGTH           = "LONG",
    parameter         EARLY_WR_DATA             = "OFF",

    // Migration parameters
    parameter                    MIGRATION = "OFF",

    parameter [8*CK_WIDTH-1:0]   CK_SKEW   = 8'd0,
    parameter [8*ADDR_WIDTH-1:0] ADDR_SKEW = {8'd0,8'd0,8'd0,8'd0,8'd0,8'd0,8'd0,8'd0,8'd0,8'd0,8'd0,8'd0,8'd0,8'd0,8'd0,8'd0,8'd0},
    parameter [8*BANK_WIDTH-1:0] BA_SKEW   = {8'd0,8'd0},
    parameter [8*BANK_GROUP_WIDTH-1:0] BG_SKEW   = {8'd0,8'd0},
    parameter [8*1-1:0]          ACT_SKEW  = 8'd0,
    parameter [8*1-1:0]          PAR_SKEW  = 8'd0,
    parameter [8*CS_WIDTH-1:0]   CS_SKEW   = 8'd0,
    parameter [8*CKE_WIDTH-1:0]  CKE_SKEW  = 8'd0,
    parameter [8*ODT_WIDTH-1:0]  ODT_SKEW  = 8'd0,
    parameter [8*LR_WIDTH-1:0]   C_SKEW    = 8'd0,
  `ifdef SIMULATION
    parameter         SIM_MODE                  = "BFM",
    parameter         BISC_EN                   = 0,
    parameter         BYPASS_CAL                = "TRUE",
    parameter         CAL_DQS_GATE              = "SKIP",
    parameter         CAL_WRLVL                 = "SKIP",
    parameter         CAL_RDLVL                 = "SKIP",
    parameter         CAL_RDLVL_DBI             = "SKIP",
    parameter         CAL_WR_DQS_DQ             = "SKIP",
    parameter         CAL_WR_DQS_DM_DBI         = "SKIP",
    parameter         CAL_WRITE_LAT             = "FAST",
    parameter         CAL_RDLVL_COMPLEX         = "SKIP",
    parameter         CAL_WR_DQS_COMPLEX        = "SKIP",
    parameter         CAL_RD_VREF               = "SKIP",
    parameter         CAL_RD_VREF_PATTERN       = "SIMPLE",
    parameter         CAL_WR_VREF               = "SKIP",
    parameter         CAL_WR_VREF_PATTERN       = "SIMPLE",
    parameter         CAL_DQS_TRACKING          = "SKIP",
    parameter         CAL_JITTER                = "NONE",
    parameter         t200us                    = 100, // In fabric clock cycles
    parameter         t500us                    = 150 // In fabric clock cycles
  `else
    parameter         SIM_MODE                  = "FULL",
    parameter         BISC_EN                   = 1,
    parameter         BYPASS_CAL                = "FALSE",
    parameter         CAL_DQS_GATE              = "FULL",
    parameter         CAL_WRLVL                 = "FULL",
    parameter         CAL_RDLVL                 = "FULL",
    parameter         CAL_RDLVL_DBI             = "SKIP",
    parameter         CAL_WR_DQS_DQ             = "FULL",
    parameter         CAL_WR_DQS_DM_DBI         = "FULL",
    parameter         CAL_WRITE_LAT             = "FULL",
    parameter         CAL_RDLVL_COMPLEX         = "FULL",
    parameter         CAL_WR_DQS_COMPLEX        = "FULL",
    parameter         CAL_RD_VREF               = "SKIP",
    parameter         CAL_RD_VREF_PATTERN       = "SIMPLE",
    parameter         CAL_WR_VREF               = "SKIP",
    parameter         CAL_WR_VREF_PATTERN       = "SIMPLE",
    parameter         CAL_DQS_TRACKING          = "FULL",
    parameter         CAL_JITTER                = "FULL",
    parameter         t200us                    = 33334, // In fabric clock cycles
    parameter         t500us                    = 83334 // In fabric clock cycles
  `endif
  ) 
  (
    input                                           sys_rst,

    input                                           c0_sys_clk_p,
    input                                           c0_sys_clk_n,
    output                                          c0_ddr4_ui_clk,
    output                                          c0_ddr4_ui_clk_sync_rst,
    output                                          dbg_clk,
    output                                          c0_ddr4_act_n,
    output [ADDR_WIDTH-1:0]                         c0_ddr4_adr,
    output [BANK_WIDTH-1:0]                         c0_ddr4_ba,
    output [BANK_GROUP_WIDTH-1:0]                   c0_ddr4_bg,
    output [PING_PONG_PHY*CKE_WIDTH-1:0]            c0_ddr4_cke,
    output [PING_PONG_PHY*ODT_WIDTH-1:0]            c0_ddr4_odt,
    output [PING_PONG_PHY*CS_WIDTH-1:0]             c0_ddr4_cs_n,
    output [CK_WIDTH-1:0]                           c0_ddr4_ck_t,
    output [CK_WIDTH-1:0]                           c0_ddr4_ck_c,
    output                                          c0_ddr4_reset_n,
    inout  [DM_WIDTH-1:0]                           c0_ddr4_dm_dbi_n,
    inout  [DQ_WIDTH-1:0]                           c0_ddr4_dq,
    inout  [DQS_WIDTH-1:0]                          c0_ddr4_dqs_c,
    inout  [DQS_WIDTH-1:0]                          c0_ddr4_dqs_t,

    output                                          c0_init_calib_complete,

    output                                          addn_ui_clkout1,
    output                                          addn_ui_clkout2,
    output                                          addn_ui_clkout3,
    output                                          addn_ui_clkout4,

   // native<emcCal signals
    input  [PING_PONG_PHY*DATA_BUF_ADDR_WIDTH-1:0]  dBufAdr,
    input  [DQ_WIDTH*8-1:0]                         wrData,
    input  [DM_WIDTH*8-1:0]                         wrDataMask,
    output [DQ_WIDTH*8-1:0]                         rdData,
    output [PING_PONG_PHY*DATA_BUF_ADDR_WIDTH-1:0]  rdDataAddr,
    output [PING_PONG_PHY-1:0]                      rdDataEn,
    output [PING_PONG_PHY-1:0]                      rdDataEnd,
    output [PING_PONG_PHY-1:0]                      per_rd_done,
    output [PING_PONG_PHY-1:0]                      rmw_rd_done,
    output [PING_PONG_PHY*DATA_BUF_ADDR_WIDTH-1:0]  wrDataAddr,
    output [PING_PONG_PHY-1:0]                      wrDataEn,

    input  [7:0]                                    mc_ACT_n,
    input  [ADDR_WIDTH*8-1:0]                       mc_ADR,
    input  [BANK_WIDTH*8-1:0]                       mc_BA,
    input  [BANK_GROUP_WIDTH*8-1:0]                 mc_BG,
    input  [PING_PONG_PHY*CKE_WIDTH*8-1:0]          mc_CKE,
    input  [PING_PONG_PHY*CS_WIDTH*8-1:0]           mc_CS_n,
    input  [PING_PONG_PHY*ODT_WIDTH*8-1:0]          mc_ODT,
    input  [PING_PONG_PHY*2-1:0]                    mcCasSlot,
    input  [PING_PONG_PHY-1:0]                      mcCasSlot2,
    input  [PING_PONG_PHY-1:0]                      mcRdCAS,
    input  [PING_PONG_PHY-1:0]                      mcWrCAS,
    input  [PING_PONG_PHY-1:0]                      winInjTxn,
    input  [PING_PONG_PHY-1:0]                      winRmw,
    input                                           gt_data_ready,
    input  [PING_PONG_PHY*DATA_BUF_ADDR_WIDTH-1:0]  winBuf,
    input  [PING_PONG_PHY*2-1:0]                    winRank,

    output [5:0]                                    tCWL,

    input  [36:0]                                   sl_iport0,
    output [16:0]                                   sl_oport0,
   // Debug Port
   output wire [511:0]                              dbg_bus
);

  // RDIMM register RC3X
  localparam mts_min = 1240;
  localparam mts_max = 3200;
  localparam mts_gap = 20;
  localparam mts = 2000000/tCK;
  localparam mts_final = (mts>mts_max) ? mts_max :
             (mts<mts_min) ? mts_min :
             mts;
  localparam [7:0] ddr4_reg_rc3x = ((mts_final-mts_min)>=1) ? (mts_final-mts_min-1)/mts_gap : 0;
  localparam         DDR4_REG_RC3X = {5'b0_0011, ddr4_reg_rc3x[7:0]};

  wire c0_div_clk;
  wire c0_div_clk_rst;
  wire c0_riu_clk;
  wire c0_riu_clk_rst;
  wire c0_mmcm_clk_in;
  wire sys_clk_in;
  wire mmcm_lock;
  wire pll_lock;
  wire reset_ub;
  wire pllGate;
   wire                sample_gts;
   wire [31:0] io_address;

   wire                [7:0] mcal_ACT_n;
   wire                [7:0] mcal_CAS_n;
   wire                [7:0] mcal_RAS_n;
   wire                [7:0] mcal_WE_n;
   wire        [ADDR_WIDTH*8-1:0] mcal_ADR;
   wire       [BANK_WIDTH*8-1:0] mcal_BA;
   wire       [BANK_GROUP_WIDTH*8-1:0] mcal_BG;
   wire      [PING_PONG_PHY*CKE_WIDTH*8-1:0] mcal_CKE;
   wire       [PING_PONG_PHY*CS_WIDTH*8-1:0] mcal_CS_n;
   wire                           [7:0] mcal_C;
   wire       [DBYTES*8-1:0] ch0_mcal_DMOut_n;
   wire     [DBYTES*8*8-1:0] ch0_mcal_DQOut;
   wire                [7:0] ch0_mcal_DQSOut;

   wire       [DBYTES*8-1:0] ch1_mcal_DMOut_n;
   wire     [DBYTES*8*8-1:0] ch1_mcal_DQOut;
   wire                [7:0] ch1_mcal_DQSOut;

   wire      [PING_PONG_PHY*ODT_WIDTH*8-1:0] mcal_ODT;
   wire                [7:0] mcal_PAR;

   wire     [DBYTES*13-1:0] ch0_mcal_clb2phy_fifo_rden;
   wire        [DBYTES*4-1:0] ch0_mcal_clb2phy_t_b_upp;
   wire        [DBYTES*4-1:0] ch0_mcal_clb2phy_t_b_low;
   wire        [DBYTES*4-1:0] ch0_mcal_clb2phy_rden_upp;
   wire        [DBYTES*4-1:0] ch0_mcal_clb2phy_rden_low;
   wire     [DBYTES*4-1:0] ch0_mcal_clb2phy_wrcs0_upp;
   wire     [DBYTES*4-1:0] ch0_mcal_clb2phy_wrcs1_upp;
   wire     [DBYTES*4-1:0] ch0_mcal_clb2phy_wrcs0_low;
   wire     [DBYTES*4-1:0] ch0_mcal_clb2phy_wrcs1_low;
   wire     [DBYTES*4-1:0] ch0_mcal_clb2phy_rdcs0_upp;
   wire     [DBYTES*4-1:0] ch0_mcal_clb2phy_rdcs1_upp;
   wire     [DBYTES*4-1:0] ch0_mcal_clb2phy_rdcs0_low;
   wire     [DBYTES*4-1:0] ch0_mcal_clb2phy_rdcs1_low;
   wire        [DBYTES*7-1:0] ch0_mcal_clb2phy_odt_upp;
   wire        [DBYTES*7-1:0] ch0_mcal_clb2phy_odt_low;

   wire [DBYTES*13-1:0] ch1_mcal_clb2phy_fifo_rden;
   wire        [DBYTES*4-1:0] ch1_mcal_clb2phy_t_b_upp;
   wire        [DBYTES*4-1:0] ch1_mcal_clb2phy_t_b_low;
   wire        [DBYTES*4-1:0] ch1_mcal_clb2phy_rden_upp;
   wire        [DBYTES*4-1:0] ch1_mcal_clb2phy_rden_low;
   wire     [DBYTES*4-1:0] ch1_mcal_clb2phy_wrcs0_upp;
   wire     [DBYTES*4-1:0] ch1_mcal_clb2phy_wrcs1_upp;
   wire     [DBYTES*4-1:0] ch1_mcal_clb2phy_wrcs0_low;
   wire     [DBYTES*4-1:0] ch1_mcal_clb2phy_wrcs1_low;
   wire     [DBYTES*4-1:0] ch1_mcal_clb2phy_rdcs0_upp;
   wire     [DBYTES*4-1:0] ch1_mcal_clb2phy_rdcs1_upp;
   wire     [DBYTES*4-1:0] ch1_mcal_clb2phy_rdcs0_low;
   wire     [DBYTES*4-1:0] ch1_mcal_clb2phy_rdcs1_low;
   wire        [DBYTES*7-1:0] ch1_mcal_clb2phy_odt_upp;
   wire        [DBYTES*7-1:0] ch1_mcal_clb2phy_odt_low;

   wire       [DBYTES*7-1:0] mcal_rd_vref_value;

   wire     [DBYTES*8-1:0] mcal_DMIn_n;
   wire     [DBYTES*8*8-1:0] mcal_DQIn;
 
  wire  [20*1-1:0] phy2clb_fixdly_rdy_low;
  wire  [20*1-1:0] phy2clb_fixdly_rdy_upp;
  wire  [20*1-1:0] phy2clb_phy_rdy_low;
  wire  [20*1-1:0] phy2clb_phy_rdy_upp;

  wire  [20*1-1:0] phy2clb_fixdly_rdy_low_riuclk;
  wire  [20*1-1:0] phy2clb_fixdly_rdy_upp_riuclk;
  wire  [20*1-1:0] phy2clb_phy_rdy_low_riuclk;
  wire  [20*1-1:0] phy2clb_phy_rdy_upp_riuclk;


// MB IO bus signals
wire [31:0] io_read_data_riuclk, io_read_data;
wire    io_ready_lvl_riuclk, io_ready_lvl;
wire io_addr_strobe_lvl_riuclk, io_addr_strobe_lvl;
wire [31:0] io_address_riuclk;
wire [31:0] io_write_data_riuclk, io_write_data;
wire        io_write_strobe_riuclk, io_write_strobe;

wire        en_vtc_riuclk;
wire        ub_rst_out_riuclk;
wire        phy_ready_riuclk;
wire        bisc_complete_riuclk;
wire        phy_ready;
wire        bisc_complete;
wire        en_vtc;
wire        fab_rst_sync;
wire        stop_gate_tracking_req;
wire [CK_WIDTH*8-1:0] mcal_CK_t;
wire [CK_WIDTH*8-1:0] mcal_CK_c;


  wire  [7:0]           phy2clb_rd_dq_bits; // selected raw read data from phy (includes all bytes)
  wire  [8:0]           bisc_byte;      // bit select from Microblaze to ready rd_dq_bits
  wire [15:0]           riu2clb_vld_read_data; // riu read data selected by bisc_byte
  wire              io_addr_strobe_clb2riu_riuclk;
  
  wire [7:0] riu_nibble_8;    // selected physical nibble in PHY - status to MB
  wire [5:0] riu_addr_cal;
  wire [20-1:0] riu2clb_valid_r1_riuclk, riu2clb_valid_riuclk, riu2clb_valid; // max number of bytes possible
  wire [7:0] cal_RESET_n;

(* dont_touch = "true" *) reg rst_r1;
(* dont_touch = "true" *) reg en_vtc_in;

  assign c0_ddr4_ui_clk = c0_div_clk;
  assign c0_ddr4_ui_clk_sync_rst = c0_div_clk_rst;

  ddr4_v2_2_10_infrastructure #
    (
     .CLKIN_PERIOD_MMCM   (CLKIN_PERIOD_MMCM),
     .CLKFBOUT_MULT_MMCM  (CLKFBOUT_MULT_MMCM),
     .DIVCLK_DIVIDE_MMCM  (DIVCLK_DIVIDE_MMCM),
     .CLKOUT0_DIVIDE_MMCM (CLKOUT0_DIVIDE_MMCM),
     .CLKOUT1_DIVIDE_MMCM (CLKOUT1_DIVIDE_MMCM),
     .CLKOUT2_DIVIDE_MMCM (CLKOUT2_DIVIDE_MMCM),
     .CLKOUT3_DIVIDE_MMCM (CLKOUT3_DIVIDE_MMCM),
     .CLKOUT4_DIVIDE_MMCM (CLKOUT4_DIVIDE_MMCM),
     .CLKOUT6_DIVIDE_MMCM (CLKOUT6_DIVIDE_MMCM),
     .C_FAMILY            (C_FAMILY),
     .TCQ                 (TCQ)
     )
  u_ddr4_infrastructure
    (
     .sys_rst          (sys_rst),
     .sys_clk_in       (sys_clk_in),
     .mmcm_clk_in      (c0_mmcm_clk_in),
     .pll_lock         (pll_lock),
	 
     .mmcm_lock        (mmcm_lock),
     .div_clk          (c0_div_clk),
     .riu_clk          (c0_riu_clk),
     .addn_ui_clkout1  (addn_ui_clkout1),
     .addn_ui_clkout2  (addn_ui_clkout2),
     .addn_ui_clkout3  (addn_ui_clkout3),
     .addn_ui_clkout4  (addn_ui_clkout4),
     .dbg_clk          (dbg_clk),
     .rstdiv0          (c0_div_clk_rst),
     .rstdiv1          (c0_riu_clk_rst),
     .reset_ub         (reset_ub),
     .pllgate          (pllGate)
     );

phy_ddr4_udimm_phy u_mig_ddr4_phy
    (
     .sys_clk_p            (c0_sys_clk_p),
     .sys_clk_n            (c0_sys_clk_n),
     .sys_clk_in           (sys_clk_in),
     .mmcm_lock            (mmcm_lock),
     .pllGate              (pllGate),
     .div_clk              (c0_div_clk),
     .div_clk_rst          (c0_div_clk_rst),
     .riu_clk              (c0_riu_clk),
     .riu_clk_rst          (c0_riu_clk_rst),
     .pll_lock             (pll_lock),
     .mmcm_clk_in          (c0_mmcm_clk_in),

     .ddr4_act_n           (c0_ddr4_act_n),
     .ddr4_adr             (c0_ddr4_adr),
     .ddr4_ba              (c0_ddr4_ba),
     .ddr4_bg              (c0_ddr4_bg),
     .ddr4_c               (),
     .ddr4_cke             (c0_ddr4_cke),
     .ddr4_odt             (c0_ddr4_odt),
     .ddr4_cs_n            (c0_ddr4_cs_n),
     .ddr4_ck_t            (c0_ddr4_ck_t),
     .ddr4_ck_c            (c0_ddr4_ck_c),
     .ddr4_reset_n         (c0_ddr4_reset_n),
     .ddr4_dm_dbi_n        (c0_ddr4_dm_dbi_n),
     .ddr4_dq              (c0_ddr4_dq),
     .ddr4_dqs_c           (c0_ddr4_dqs_c),
     .ddr4_dqs_t           (c0_ddr4_dqs_t),

     .en_vtc_riuclk        (en_vtc_riuclk),
     .ub_rst_out_riuclk    (ub_rst_out_riuclk),
     .cal_RESET_n          (cal_RESET_n),
     
     .riu_nibble_8         (riu_nibble_8),
     .riu_addr_cal         (riu_addr_cal),
     
     .phy_ready_riuclk     (phy_ready_riuclk),
     .bisc_complete_riuclk (bisc_complete_riuclk),
     .phy2clb_rd_dq_bits   (phy2clb_rd_dq_bits),
     .bisc_byte            (bisc_byte),

     .io_addr_strobe_clb2riu_riuclk   (io_addr_strobe_clb2riu_riuclk),
     .io_address_riuclk               (io_address_riuclk),
     .io_write_data_riuclk            (io_write_data_riuclk),
     .io_write_strobe_riuclk          (io_write_strobe_riuclk),
     .riu2clb_vld_read_data           (riu2clb_vld_read_data),
     .riu2clb_valid_riuclk            (riu2clb_valid_riuclk),
     .mcal_CK_t                       (mcal_CK_t),
     .mcal_CK_c                       (mcal_CK_c),
     .mcal_C                          (mcal_C), 
     .mcal_ODT                        (mcal_ODT),
     .mcal_PAR                        (mcal_PAR),
     .mcal_ADR                        (mcal_ADR),
     .mcal_BA                         (mcal_BA),
     .mcal_BG                         (mcal_BG),
     .mcal_CKE                        (mcal_CKE),
     .mcal_CS_n                       (mcal_CS_n),
     .mcal_ACT_n                      (mcal_ACT_n),
     .ch0_mcal_DMOut_n                (ch0_mcal_DMOut_n),
     .ch0_mcal_DQOut                  (ch0_mcal_DQOut),
     .ch0_mcal_DQSOut                 (ch0_mcal_DQSOut),
     .ch0_mcal_clb2phy_fifo_rden      (ch0_mcal_clb2phy_fifo_rden),
     .ch0_mcal_clb2phy_t_b_upp        (ch0_mcal_clb2phy_t_b_upp),
     .ch0_mcal_clb2phy_t_b_low        (ch0_mcal_clb2phy_t_b_low),
     .ch0_mcal_clb2phy_rden_upp       (ch0_mcal_clb2phy_rden_upp),
     .ch0_mcal_clb2phy_rden_low       (ch0_mcal_clb2phy_rden_low),
     .ch0_mcal_clb2phy_wrcs0_upp      (ch0_mcal_clb2phy_wrcs0_upp),
     .ch0_mcal_clb2phy_wrcs1_upp      (ch0_mcal_clb2phy_wrcs1_upp),
     .ch0_mcal_clb2phy_wrcs0_low      (ch0_mcal_clb2phy_wrcs0_low),
     .ch0_mcal_clb2phy_wrcs1_low      (ch0_mcal_clb2phy_wrcs1_low),
     .ch0_mcal_clb2phy_rdcs0_upp      (ch0_mcal_clb2phy_rdcs0_upp),
     .ch0_mcal_clb2phy_rdcs1_upp      (ch0_mcal_clb2phy_rdcs1_upp),
     .ch0_mcal_clb2phy_rdcs0_low      (ch0_mcal_clb2phy_rdcs0_low),
     .ch0_mcal_clb2phy_rdcs1_low      (ch0_mcal_clb2phy_rdcs1_low),
     .ch0_mcal_clb2phy_odt_upp        (ch0_mcal_clb2phy_odt_upp),
     .ch0_mcal_clb2phy_odt_low        (ch0_mcal_clb2phy_odt_low),

     .mcal_rd_vref_value              (mcal_rd_vref_value),
     .mcal_DMIn_n                     (mcal_DMIn_n),
     .mcal_DQIn                       (mcal_DQIn),

     .ch1_mcal_DMOut_n                (ch1_mcal_DMOut_n),
     .ch1_mcal_DQOut                  (ch1_mcal_DQOut),
     .ch1_mcal_DQSOut                 (ch1_mcal_DQSOut),
     .ch1_mcal_clb2phy_fifo_rden      (ch1_mcal_clb2phy_fifo_rden),
     .ch1_mcal_clb2phy_t_b_upp        (ch1_mcal_clb2phy_t_b_upp),
     .ch1_mcal_clb2phy_t_b_low        (ch1_mcal_clb2phy_t_b_low),
     .ch1_mcal_clb2phy_rden_upp       (ch1_mcal_clb2phy_rden_upp),
     .ch1_mcal_clb2phy_rden_low       (ch1_mcal_clb2phy_rden_low),
     .ch1_mcal_clb2phy_wrcs0_upp      (ch1_mcal_clb2phy_wrcs0_upp),
     .ch1_mcal_clb2phy_wrcs1_upp      (ch1_mcal_clb2phy_wrcs1_upp),
     .ch1_mcal_clb2phy_wrcs0_low      (ch1_mcal_clb2phy_wrcs0_low),
     .ch1_mcal_clb2phy_wrcs1_low      (ch1_mcal_clb2phy_wrcs1_low),
     .ch1_mcal_clb2phy_rdcs0_upp      (ch1_mcal_clb2phy_rdcs0_upp),
     .ch1_mcal_clb2phy_rdcs1_upp      (ch1_mcal_clb2phy_rdcs1_upp),
     .ch1_mcal_clb2phy_rdcs0_low      (ch1_mcal_clb2phy_rdcs0_low),
     .ch1_mcal_clb2phy_rdcs1_low      (ch1_mcal_clb2phy_rdcs1_low),
     .ch1_mcal_clb2phy_odt_upp        (ch1_mcal_clb2phy_odt_upp),
     .ch1_mcal_clb2phy_odt_low        (ch1_mcal_clb2phy_odt_low),

     .phy2clb_fixdly_rdy_low_riuclk   (phy2clb_fixdly_rdy_low_riuclk),
     .phy2clb_fixdly_rdy_upp_riuclk   (phy2clb_fixdly_rdy_upp_riuclk),
     .phy2clb_phy_rdy_low_riuclk      (phy2clb_phy_rdy_low_riuclk),
     .phy2clb_phy_rdy_upp_riuclk      (phy2clb_phy_rdy_upp_riuclk),
// DDR3 signals which are not used for DDR4
     .mcal_RAS_n                      (8'b0),
     .mcal_CAS_n                      (8'b0),
     .mcal_WE_n                       (8'b0),
     .dbg_bus                         (dbg_bus)
     );

// Calibration Logic 
  // PLL Multiply and Divide values
  // write PLL VCO multiplier
  localparam CLKFBOUT_MULT_PLL  = (CLKOUTPHY_MODE == "VCO_2X") ?
                                    ((nCK_PER_CLK == 4) ? 4 : 2) : 
                                  (CLKOUTPHY_MODE == "VCO") ? 
                                    ((nCK_PER_CLK == 4) ? 8 : 4)
                                  : ((nCK_PER_CLK == 4) ? 16 : 8);
  // VCO output divisor for PLL clkout0
  localparam CLKOUT0_DIVIDE_PLL = (CLKOUTPHY_MODE == "VCO_2X") ? 1 : 
                                  (CLKOUTPHY_MODE == "VCO") ? 2 : 4;

ddr4_v2_2_10_cal_top # (
    .PING_PONG_PHY  (PING_PONG_PHY)
   ,.ABITS          (ADDR_WIDTH)
   ,.BABITS         (BANK_WIDTH)
   ,.BGBITS         (BANK_GROUP_WIDTH)
   ,.S_HEIGHT       (S_HEIGHT)
   ,.CKEBITS        (CKE_WIDTH)
   ,.COLBITS        (COL_WIDTH)
   ,.CSBITS         (CS_WIDTH)
   ,.CKBITS         (CK_WIDTH)
   ,.ODTBITS        (ODT_WIDTH)
   ,.ODTWR          (ODTWR)
   ,.ODTWRDEL       (ODTWRDEL)
   ,.ODTWRDUR       (ODTWRDUR)
   ,.ODTWRODEL      (ODTWRODEL)
   ,.ODTWRODUR      (ODTWRODUR)
   ,.ODTRD          (ODTRD)
   ,.ODTRDDEL       (ODTRDDEL)
   ,.ODTRDDUR       (ODTRDDUR)
   ,.ODTRDODEL      (ODTRDODEL)
   ,.ODTRDODUR      (ODTRDODUR)
   ,.ODTNOP         (ODTNOP)
   ,.MEM            (DRAM_TYPE)
   ,.DQ_WIDTH       (DQ_WIDTH)
   ,.DBYTES         (DBYTES)
   ,.DBAW           (DATA_BUF_ADDR_WIDTH)
   ,.LRDIMM_MODE    (LRDIMM_MODE)
   ,.DDR4_DB_HIF_RTT_NOM   (DDR4_DB_HIF_RTT_NOM)
   ,.DDR4_DB_HIF_RTT_WR    (DDR4_DB_HIF_RTT_WR)
   ,.DDR4_DB_HIF_RTT_PARK  (DDR4_DB_HIF_RTT_PARK)
   ,.DDR4_DB_HIF_DI        (DDR4_DB_HIF_DI)
   ,.DDR4_DB_DIF_ODT       (DDR4_DB_DIF_ODT)
   ,.DDR4_DB_DIF_DI        (DDR4_DB_DIF_DI)
   ,.DDR4_DB_HIF_VREF      (DDR4_DB_HIF_VREF)
   ,.DDR4_DB_DIF_VREF      (DDR4_DB_DIF_VREF)
   ,.MR0            (MR0)
   ,.MR1            (MR1)
   ,.MR2            (MR2)
   ,.MR3            (MR3)
   ,.MR4            (MR4)
   ,.MR5            (MR5)
   ,.MR6            (MR6)
   ,.RD_VREF_VAL    (RD_VREF_VAL)

   ,.SLOT0_CONFIG   (SLOT0_CONFIG)
   ,.SLOT1_CONFIG   (SLOT1_CONFIG)
   ,.SLOT0_FUNC_CS  (SLOT0_FUNC_CS)
   ,.SLOT1_FUNC_CS  (SLOT1_FUNC_CS)
   ,.SLOT0_ODD_CS   (SLOT0_ODD_CS)
   ,.SLOT1_ODD_CS   (SLOT1_ODD_CS)

   ,.REG_CTRL       (REG_CTRL)
   ,.CA_MIRROR      (CA_MIRROR)
   ,.DDR4_CLAMSHELL (DDR4_CLAMSHELL)
   ,.DDR4_REG_PARITY_ENABLE (DDR4_REG_PARITY_ENABLE)
   ,.DDR4_REG_RC03  (DDR4_REG_RC03)
   ,.DDR4_REG_RC04  (DDR4_REG_RC04)
   ,.DDR4_REG_RC05  (DDR4_REG_RC05)
   ,.DDR4_REG_RC3X  (DDR4_REG_RC3X)

   ,.tCK            (tCK)
   ,.t200us         (t200us)
   ,.t500us         (t500us)
   ,.tXPR           (tXPR)
   ,.tMOD           (tMOD)
   ,.tMRD           (tMRD)
   ,.tZQINIT        (tZQINIT)
   ,.tRFC           (tRFC)
   ,.TCQ            (TCQ/1000)

   ,.MEMORY_CONFIGURATION (MEMORY_CONFIGURATION)
   ,.EARLY_WR_DATA   (EARLY_WR_DATA)
   ,.ECC             (ECC)
   ,.DRAM_WIDTH      (DRAM_WIDTH)
   ,.RANKS           (RANKS)
   ,.nCK_PER_CLK     (nCK_PER_CLK)
   ,.MEM_CODE        (MEM_CODE)

   ,.MIGRATION          (MIGRATION)
   ,.CK_SKEW            (CK_SKEW)
   ,.ADDR_SKEW          (ADDR_SKEW)
   ,.ACT_SKEW           (ACT_SKEW)
   ,.PAR_SKEW           (PAR_SKEW)
   ,.CKE_SKEW           (CKE_SKEW)
   ,.CS_SKEW            (CS_SKEW)
   ,.ODT_SKEW           (ODT_SKEW)
   ,.C_SKEW             (C_SKEW)

   ,.BISC_EN            (BISC_EN)
   ,.BYPASS_CAL         (BYPASS_CAL)
   ,.CAL_DQS_GATE       (CAL_DQS_GATE)
   ,.CAL_WRLVL          (CAL_WRLVL)
   ,.CAL_RDLVL          (CAL_RDLVL)
   ,.CAL_RDLVL_DBI      (CAL_RDLVL_DBI)
   ,.CAL_WR_DQS_DQ      (CAL_WR_DQS_DQ)
   ,.CAL_WR_DQS_DM_DBI  (CAL_WR_DQS_DM_DBI)
   ,.CAL_WRITE_LAT      (CAL_WRITE_LAT)
   ,.CAL_RDLVL_COMPLEX  (CAL_RDLVL_COMPLEX)
   ,.CAL_WR_DQS_COMPLEX (CAL_WR_DQS_COMPLEX)
   ,.CAL_RD_VREF        (CAL_RD_VREF)
   ,.CAL_RD_VREF_PATTERN  (CAL_RD_VREF_PATTERN)
   ,.CAL_WR_VREF        (CAL_WR_VREF)
   ,.CAL_WR_VREF_PATTERN  (CAL_WR_VREF_PATTERN)
   ,.CAL_DQS_TRACKING   (CAL_DQS_TRACKING)
   ,.CAL_JITTER         (CAL_JITTER)
   ,.DM_DBI             (DM_DBI)
   ,.USE_CS_PORT        (USE_CS_PORT)
   ,.CPLX_PAT_LENGTH    (CPLX_PAT_LENGTH)
   ,.C_FAMILY           (C_FAMILY)
   ,.RESTORE_CRC         (1'b0)
   ,.CLKFBOUT_MULT_PLL    (CLKFBOUT_MULT_PLL)
   ,.CLKOUT0_DIVIDE_PLL   (CLKOUT0_DIVIDE_PLL)
   ,.CLKFBOUT_MULT_MMCM   (CLKFBOUT_MULT_MMCM)
   ,.DIVCLK_DIVIDE_MMCM   (DIVCLK_DIVIDE_MMCM)
   ,.CLKOUT0_DIVIDE_MMCM  (CLKOUT0_DIVIDE_MMCM)
   ,.EXTRA_CMD_DELAY	  (EXTRA_CMD_DELAY)
   ,.RTL_VERSION          (RTL_VERSION)
) u_ddr_cal_top (
    .clk                         (c0_div_clk)
   ,.rst                         (c0_div_clk_rst)

   ,.calDone_gated               (c0_init_calib_complete)   // calibration calDone gated with phy_ready
   ,.pllGate                     (pllGate)
   ,.sample_gts                        (sample_gts)
   ,.io_address                  (io_address)
   ,.io_addr_strobe_lvl          (io_addr_strobe_lvl)
   ,.io_write_data               (io_write_data)
   ,.io_write_strobe             (io_write_strobe)
   ,.io_read_data                (io_read_data)
   ,.io_ready_lvl                (io_ready_lvl)
   ,.phy_ready                   (phy_ready)
   ,.bisc_complete               (bisc_complete)
   ,.en_vtc                      (en_vtc)
  //  ,.clb2phy_t_b_addr_en      (clb2phy_t_b_addr_en)

   // native
   ,.rdData                      (rdData)
   ,.rdDataAddr                  (rdDataAddr)
   ,.rdDataEn                    (rdDataEn)
   ,.rdDataEnd                   (rdDataEnd)
   ,.per_rd_done                 (per_rd_done)
   ,.rmw_rd_done                 (rmw_rd_done)
   ,.wrData                      (wrData)
   ,.wrDataMask                  (wrDataMask)
   ,.wrDataAddr                  (wrDataAddr)
   ,.wrDataEn                    (wrDataEn)

   // mc
   ,.mcCKt                       (8'b01010101)
   ,.mcCKc                       (8'b10101010)
   ,.mc_ACT_n                    (mc_ACT_n)
   ,.mc_RAS_n                    (8'b0)
   ,.mc_CAS_n                    (8'b0)
   ,.mc_WE_n                     (8'b0)
   ,.mc_ADR                      (mc_ADR)
   ,.mc_BA                       (mc_BA)
   ,.mc_BG                       (mc_BG)
   ,.mc_C                        ({8{1'b1}})
    ,.mc_CKE                      (mc_CKE)
   ,.mc_CS_n                     (mc_CS_n)
   ,.mc_ODT                      (mc_ODT)
   ,.mcCasSlot                   (mcCasSlot)
   ,.mcCasSlot2                  (mcCasSlot2)
   ,.mcRdCAS                     (mcRdCAS)
   ,.mcWrCAS                     (mcWrCAS)
   ,.winInjTxn                   (winInjTxn)
   ,.winRmw                      (winRmw)
   ,.gt_data_ready               (gt_data_ready)
   ,.winBuf                      (winBuf)
   ,.winRank                     (winRank)
  
   ,.mcal_CK_t                   (mcal_CK_t)
   ,.mcal_CK_c                   (mcal_CK_c)
   ,.mcal_ACT_n                  (mcal_ACT_n)
   ,.mcal_CAS_n                  (mcal_CAS_n)
   ,.mcal_RAS_n                  (mcal_RAS_n)
   ,.mcal_WE_n                   (mcal_WE_n)
   ,.mcal_ADR                    (mcal_ADR)
   ,.mcal_BA                     (mcal_BA)
   ,.mcal_BG                     (mcal_BG)
   ,.mcal_C                      (mcal_C)
   ,.mcal_CKE                    (mcal_CKE)
   ,.mcal_CS_n                   (mcal_CS_n)

   ,.mcal_DMOut_n                (ch0_mcal_DMOut_n)
   ,.mcal_DQOut                  (ch0_mcal_DQOut)
   ,.mcal_DQSOut                 (ch0_mcal_DQSOut)
   ,.mcal_ODT                    (mcal_ODT)
   ,.mcal_PAR                    (mcal_PAR)
   ,.mcal_clb2phy_fifo_rden      (ch0_mcal_clb2phy_fifo_rden)
   ,.mcal_clb2phy_t_b_upp        (ch0_mcal_clb2phy_t_b_upp)
   ,.mcal_clb2phy_t_b_low        (ch0_mcal_clb2phy_t_b_low)
   ,.mcal_clb2phy_rden_upp       (ch0_mcal_clb2phy_rden_upp)
   ,.mcal_clb2phy_rden_low       (ch0_mcal_clb2phy_rden_low)
   ,.mcal_clb2phy_wrcs0_upp      (ch0_mcal_clb2phy_wrcs0_upp)
   ,.mcal_clb2phy_wrcs1_upp      (ch0_mcal_clb2phy_wrcs1_upp)
   ,.mcal_clb2phy_wrcs0_low      (ch0_mcal_clb2phy_wrcs0_low)
   ,.mcal_clb2phy_wrcs1_low      (ch0_mcal_clb2phy_wrcs1_low)
   ,.mcal_clb2phy_rdcs0_upp      (ch0_mcal_clb2phy_rdcs0_upp)
   ,.mcal_clb2phy_rdcs1_upp      (ch0_mcal_clb2phy_rdcs1_upp)
   ,.mcal_clb2phy_rdcs0_low      (ch0_mcal_clb2phy_rdcs0_low)
   ,.mcal_clb2phy_rdcs1_low      (ch0_mcal_clb2phy_rdcs1_low)
   ,.mcal_clb2phy_odt_upp        (ch0_mcal_clb2phy_odt_upp)
   ,.mcal_clb2phy_odt_low        (ch0_mcal_clb2phy_odt_low)

   ,.mcal_rd_vref_value          (mcal_rd_vref_value)

   ,.ch1_mcal_DMOut_n                (ch1_mcal_DMOut_n)
   ,.ch1_mcal_DQOut                  (ch1_mcal_DQOut)
   ,.ch1_mcal_DQSOut                 (ch1_mcal_DQSOut)
   ,.ch1_mcal_clb2phy_fifo_rden      (ch1_mcal_clb2phy_fifo_rden)
   ,.ch1_mcal_clb2phy_t_b_upp        (ch1_mcal_clb2phy_t_b_upp)
   ,.ch1_mcal_clb2phy_t_b_low        (ch1_mcal_clb2phy_t_b_low)
   ,.ch1_mcal_clb2phy_rden_upp       (ch1_mcal_clb2phy_rden_upp)
   ,.ch1_mcal_clb2phy_rden_low       (ch1_mcal_clb2phy_rden_low)
   ,.ch1_mcal_clb2phy_wrcs0_upp      (ch1_mcal_clb2phy_wrcs0_upp)
   ,.ch1_mcal_clb2phy_wrcs1_upp      (ch1_mcal_clb2phy_wrcs1_upp)
   ,.ch1_mcal_clb2phy_wrcs0_low      (ch1_mcal_clb2phy_wrcs0_low)
   ,.ch1_mcal_clb2phy_wrcs1_low      (ch1_mcal_clb2phy_wrcs1_low)
   ,.ch1_mcal_clb2phy_rdcs0_upp      (ch1_mcal_clb2phy_rdcs0_upp)
   ,.ch1_mcal_clb2phy_rdcs1_upp      (ch1_mcal_clb2phy_rdcs1_upp)
   ,.ch1_mcal_clb2phy_rdcs0_low      (ch1_mcal_clb2phy_rdcs0_low)
   ,.ch1_mcal_clb2phy_rdcs1_low      (ch1_mcal_clb2phy_rdcs1_low)
   ,.ch1_mcal_clb2phy_odt_upp        (ch1_mcal_clb2phy_odt_upp)
   ,.ch1_mcal_clb2phy_odt_low        (ch1_mcal_clb2phy_odt_low)

   ,.mcal_DMIn_n                     (mcal_DMIn_n)
   ,.mcal_DQIn                       (mcal_DQIn)

   ,.phy2clb_rd_dq_bits              (phy2clb_rd_dq_bits)
   ,.bisc_byte                       (bisc_byte)

   ,.cal_RESET_n                 (cal_RESET_n)

   ,.riu2clb_valid               (riu2clb_valid)
   ,.dBufAdr                     (dBufAdr)
   ,.tCWL                        (tCWL)
   ,.cal_pre_status              ()
   ,.cal_r1_status               ()
   ,.cal_r2_status               ()
   ,.cal_r3_status               ()
   ,.cal_error                   ()
   ,.cal_error_bit               ()
   ,.cal_error_nibble            ()
   ,.cal_error_code              ()
   ,.cal_crc_error              ()
   ,.traffic_wr_done             (1'b0)
   ,.traffic_error               ({DBYTES*8*8{1'b0}})
   ,.traffic_clr_error           ()
   ,.traffic_status_err_bit_valid   (1'b0)
   ,.traffic_status_err_type_valid  (1'b0)
   ,.traffic_status_err_type        (1'b0)
   ,.traffic_status_done            (1'b0)
   ,.traffic_status_watch_dog_hang  (1'b0)
   ,.traffic_start                  ()
   ,.traffic_rst                    ()
   ,.traffic_err_chk_en             ()
   ,.traffic_instr_addr_mode        ()
   ,.traffic_instr_data_mode        ()
   ,.traffic_instr_rw_mode          ()
   ,.traffic_instr_rw_submode       ()
   ,.traffic_instr_num_of_iter      ()
   ,.traffic_instr_nxt_instr        ()

   ,.win_start                   (4'b0)


   ,.app_mem_init_skip           (1'b0)
   ,.stop_gate_tracking_req      (1'b0)
   ,.stop_gate_tracking_ack      ()
   ,.app_restore_en              (1'b0)
   ,.app_restore_complete        (1'b0) 
   ,.xsdb_select                 (1'b0)
   ,.xsdb_rd_en		               (1'b0)
   ,.xsdb_wr_en		               (1'b0)
   ,.xsdb_addr	  	             (16'b0)
   ,.xsdb_wr_data	               (9'b0)
   ,.xsdb_rd_data                ()
   ,.xsdb_rdy                    ()
   ,.dbg_out                     ()

   ,.sl_iport0                   (sl_iport0)
   ,.sl_oport0                   (sl_oport0)
   ,.dbg_rd_data_cmp             ()
   ,.dbg_expected_data           ()
   ,.dbg_cal_seq                 ()
   ,.dbg_cal_seq_cnt             ()
   ,.dbg_cal_seq_rd_cnt          ()
   ,.dbg_rd_valid                ()
   ,.dbg_cmp_byte                ()
   ,.dbg_rd_data                 ()
   ,.dbg_cplx_config             ()
   ,.dbg_cplx_status             ()
   ,.win_status                  ()
   ,.cal_r0_status               ()
   ,.cal_post_status             ()
);

//######################## Fabric Clock Domain ########################
  always @(posedge c0_div_clk) begin
    en_vtc_in    <= #TCQ en_vtc;
  end

  always @(posedge c0_div_clk) begin
    rst_r1    <= #TCQ c0_div_clk_rst;
  end


phy_ddr4_udimm_ddr4_cal_riu #
  (
     .TCQ              (TCQ)
    ,.MCS_ECC_ENABLE   (MCS_ECC_ENABLE)
  )  u_ddr_cal_riu (
    .riu_clk                            (c0_riu_clk)
    ,.riu_clk_rst                       (c0_riu_clk_rst)
    ,.riu2clb_valid_riuclk              (riu2clb_valid_riuclk)
    ,.riu2clb_vld_read_data             (riu2clb_vld_read_data)
   ,.sample_gts                        (sample_gts)
    ,.io_read_data_riuclk               (io_read_data_riuclk)
    ,.io_ready_lvl_riuclk               (io_ready_lvl_riuclk)
    ,.fab_rst_sync                      (fab_rst_sync)
    ,.reset_ub_riuclk                   (reset_ub)
    ,.riu_addr_cal                      (riu_addr_cal)
    ,.riu_nibble_8                      (riu_nibble_8)

    ,.riu2clb_valid_r1_riuclk           (riu2clb_valid_r1_riuclk)
    ,.io_addr_strobe_lvl_riuclk         (io_addr_strobe_lvl_riuclk)
    ,.io_addr_strobe_clb2riu_riuclk     (io_addr_strobe_clb2riu_riuclk)
    ,.io_address_riuclk                 (io_address_riuclk)
    ,.io_write_data_riuclk              (io_write_data_riuclk)
   ,.LMB_UE                ()
   ,.LMB_CE                ()
    ,.io_write_strobe_riuclk            (io_write_strobe_riuclk)
    ,.ub_rst_out_riuclk                 (ub_rst_out_riuclk)
);


  localparam INSERT_DELAY = 0; // Insert delay for simulations
  localparam HANDSHAKE_MAX_DELAYf2r = 5000; // RIU Clock Max frequency 200MHz
  localparam STATIC_MAX_DELAY = 10000; // Max delay for static signals
  localparam SYNC_MTBF = 2; // Synchronizer Depth based on MTBF

  ddr4_v2_2_10_cal_sync #(SYNC_MTBF, 1, INSERT_DELAY, STATIC_MAX_DELAY, TCQ)  u_en_vtc_sync       (c0_riu_clk, en_vtc_in, en_vtc_riuclk);
  ddr4_v2_2_10_cal_sync #(SYNC_MTBF, 1, INSERT_DELAY, STATIC_MAX_DELAY, TCQ)  u_fab_rst_sync      (c0_riu_clk, rst_r1, fab_rst_sync);

  ddr4_v2_2_10_cal_sync #(SYNC_MTBF, 32, INSERT_DELAY, HANDSHAKE_MAX_DELAYf2r, TCQ) u_io_read_data_sync (c0_riu_clk, io_read_data, io_read_data_riuclk); // MAN - can we remove this sync

  ddr4_v2_2_10_cal_sync #(SYNC_MTBF, 1, INSERT_DELAY, HANDSHAKE_MAX_DELAYf2r, TCQ)  u_io_ready_lvl_sync (c0_riu_clk, io_ready_lvl, io_ready_lvl_riuclk);

  localparam HANDSHAKE_MAX_DELAYr2f = 3000; // Fabric Clock Max frequency 333MHz

  ddr4_v2_2_10_cal_sync #(SYNC_MTBF, 1, INSERT_DELAY, STATIC_MAX_DELAY, TCQ) u_phy2clb_phy_ready_sync     (c0_div_clk, phy_ready_riuclk, phy_ready);
  ddr4_v2_2_10_cal_sync #(SYNC_MTBF, 1, INSERT_DELAY, STATIC_MAX_DELAY, TCQ) u_phy2clb_bisc_complete_sync  (c0_div_clk, bisc_complete_riuclk, bisc_complete);
  ddr4_v2_2_10_cal_sync #(SYNC_MTBF, 20, INSERT_DELAY, STATIC_MAX_DELAY, TCQ) u_riu2clb_valid_sync     (c0_div_clk, riu2clb_valid_r1_riuclk, riu2clb_valid);

  ddr4_v2_2_10_cal_sync #(SYNC_MTBF, 20, INSERT_DELAY, STATIC_MAX_DELAY, TCQ) u_phy2clb_fixdly_rdy_low (c0_div_clk, phy2clb_fixdly_rdy_low_riuclk, phy2clb_fixdly_rdy_low); // DEBUG only
  ddr4_v2_2_10_cal_sync #(SYNC_MTBF, 20, INSERT_DELAY, STATIC_MAX_DELAY, TCQ) u_phy2clb_fixdly_rdy_upp (c0_div_clk, phy2clb_fixdly_rdy_upp_riuclk, phy2clb_fixdly_rdy_upp); // DEBUG only
  ddr4_v2_2_10_cal_sync #(SYNC_MTBF, 20, INSERT_DELAY, STATIC_MAX_DELAY, TCQ) u_phy2clb_phy_rdy_low    (c0_div_clk, phy2clb_phy_rdy_low_riuclk, phy2clb_phy_rdy_low); // DEBUG only
  ddr4_v2_2_10_cal_sync #(SYNC_MTBF, 20, INSERT_DELAY, STATIC_MAX_DELAY, TCQ) u_phy2clb_phy_rdy_upp    (c0_div_clk, phy2clb_phy_rdy_upp_riuclk, phy2clb_phy_rdy_upp); // DEBUG only

  ddr4_v2_2_10_cal_sync #(SYNC_MTBF, 32, INSERT_DELAY, HANDSHAKE_MAX_DELAYr2f, TCQ) u_io_addr_sync         (c0_div_clk, io_address_riuclk, io_address); // MAN - can we remove this sync
  ddr4_v2_2_10_cal_sync #(SYNC_MTBF, 1, INSERT_DELAY, HANDSHAKE_MAX_DELAYr2f, TCQ)  u_io_write_strobe_sync (c0_div_clk, io_write_strobe_riuclk, io_write_strobe);
  ddr4_v2_2_10_cal_sync #(SYNC_MTBF, 32, INSERT_DELAY, HANDSHAKE_MAX_DELAYr2f, TCQ) u_io_write_data_sync   (c0_div_clk, io_write_data_riuclk, io_write_data);
  ddr4_v2_2_10_cal_sync #(SYNC_MTBF, 1, INSERT_DELAY, HANDSHAKE_MAX_DELAYr2f, TCQ) u_io_addr_strobe_lvl_sync (c0_div_clk, io_addr_strobe_lvl_riuclk, io_addr_strobe_lvl);

//synthesis translate_off
  generate
    if (MIG_PARAM_CHECKS  == "TRUE") begin
       `include "ddr4_v2_2_10_ddr4_phy_assert.vh"
    end
  endgenerate
//synthesis translate_on

endmodule
