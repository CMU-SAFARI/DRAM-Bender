//*****************************************************************************
// (c) Copyright 2009 - 2013 Xilinx, Inc. All rights reserved.
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
//*****************************************************************************
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor             : Xilinx
// \   \   \/     Version            : 4.0
//  \   \         Application        : MIG
//  /   /         Filename           : memctl_mig.v
// /___/   /\     Date Last Modified : $Date: 2011/06/02 08:35:03 $
// \   \  /  \    Date Created       : Tue Sept 21 2010
//  \___\/\___\
//
// Device           : 7 Series
// Design Name      : DDR3 SDRAM
// Purpose          :
//   Top-level  module. This module can be instantiated in the
//   system and interconnect as shown in user design wrapper file (user top module).
//   In addition to the memory controller, the module instantiates:
//     1. Clock generation/distribution, reset logic
//     2. IDELAY control block
//     3. Debug logic
// Reference        :
// Revision History :
//*****************************************************************************

//`define SKIP_CALIB
`timescale 1ps/1ps

module memctl_mig #
  (

   //***************************************************************************
   // The following parameters refer to width of various ports
   //***************************************************************************
   parameter BANK_WIDTH            = 3,
                                     // # of memory Bank Address bits.
   parameter CK_WIDTH              = 1,
                                     // # of CK/CK# outputs to memory.
   parameter COL_WIDTH             = 10,
                                     // # of memory Column Address bits.
   parameter CS_WIDTH              = 1,
                                     // # of unique CS outputs to memory.
   parameter nCS_PER_RANK          = 1,
                                     // # of unique CS outputs per rank for phy
   parameter CKE_WIDTH             = 1,
                                     // # of CKE outputs to memory.
   parameter DATA_BUF_ADDR_WIDTH   = 5,
   parameter DQ_CNT_WIDTH          = 6,
                                     // = ceil(log2(DQ_WIDTH))
   parameter DQ_PER_DM             = 8,
   parameter DM_WIDTH              = 8,
                                     // # of DM (data mask)
   parameter DQ_WIDTH              = 64,
                                     // # of DQ (data)
   parameter DQS_WIDTH             = 8,
   parameter DQS_CNT_WIDTH         = 3,
                                     // = ceil(log2(DQS_WIDTH))
   parameter DRAM_WIDTH            = 8,
                                     // # of DQ per DQS
   parameter ECC                   = "OFF",
   parameter DATA_WIDTH            = 64,
   parameter ECC_TEST              = "OFF",
   parameter PAYLOAD_WIDTH         = (ECC_TEST == "OFF") ? DATA_WIDTH : DQ_WIDTH,
   parameter MEM_ADDR_ORDER        = "BANK_ROW_COLUMN",
                                      //Possible Parameters
                                      //1.BANK_ROW_COLUMN : Address mapping is
                                      //                    in form of Bank Row Column.
                                      //2.ROW_BANK_COLUMN : Address mapping is
                                      //                    in the form of Row Bank Column.
                                      //3.TG_TEST : Scrambles Address bits
                                      //            for distributed Addressing.
      
   parameter nBANK_MACHS           = 4,
   parameter RANKS                 = 1,
                                     // # of Ranks.
   parameter ODT_WIDTH             = 1,
                                     // # of ODT outputs to memory.
   parameter ROW_WIDTH             = 14,
                                     // # of memory Row Address bits.
   parameter ADDR_WIDTH            = 28,
                                     // # = RANK_WIDTH + BANK_WIDTH
                                     //     + ROW_WIDTH + COL_WIDTH;
                                     // Chip Select is always tied to low for
                                     // single rank devices
   parameter USE_CS_PORT          = 1,
                                     // # = 1, When Chip Select (CS#) output is enabled
                                     //   = 0, When Chip Select (CS#) output is disabled
                                     // If CS_N disabled, user must connect
                                     // DRAM CS_N input(s) to ground
   parameter USE_DM_PORT           = 1,
                                     // # = 1, When Data Mask option is enabled
                                     //   = 0, When Data Mask option is disbaled
                                     // When Data Mask option is disabled in
                                     // MIG Controller Options page, the logic
                                     // related to Data Mask should not get
                                     // synthesized
   parameter USE_ODT_PORT          = 1,
                                     // # = 1, When ODT output is enabled
                                     //   = 0, When ODT output is disabled
                                     // Parameter configuration for Dynamic ODT support:
                                     // USE_ODT_PORT = 0, RTT_NOM = "DISABLED", RTT_WR = "60/120".
                                     // This configuration allows to save ODT pin mapping from FPGA.
                                     // The user can tie the ODT input of DRAM to HIGH.
   parameter IS_CLK_SHARED          = "FALSE",
                                      // # = "true" when clock is shared
                                      //   = "false" when clock is not shared

   parameter PHY_CONTROL_MASTER_BANK = 1,
                                     // The bank index where master PHY_CONTROL resides,
                                     // equal to the PLL residing bank
   parameter MEM_DENSITY           = "1Gb",
                                     // Indicates the density of the Memory part
                                     // Added for the sake of Vivado simulations
   parameter MEM_SPEEDGRADE        = "125",
                                     // Indicates the Speed grade of Memory Part
                                     // Added for the sake of Vivado simulations
   parameter MEM_DEVICE_WIDTH      = 8,
                                     // Indicates the device width of the Memory Part
                                     // Added for the sake of Vivado simulations

   //***************************************************************************
   // The following parameters are mode register settings
   //***************************************************************************
   parameter AL                    = "0",
                                     // DDR3 SDRAM:
                                     // Additive Latency (Mode Register 1).
                                     // # = "0", "CL-1", "CL-2".
                                     // DDR2 SDRAM:
                                     // Additive Latency (Extended Mode Register).
   parameter nAL                   = 0,
                                     // # Additive Latency in number of clock
                                     // cycles.
   parameter BURST_MODE            = "8",
                                     // DDR3 SDRAM:
                                     // Burst Length (Mode Register 0).
                                     // # = "8", "4", "OTF".
                                     // DDR2 SDRAM:
                                     // Burst Length (Mode Register).
                                     // # = "8", "4".
   parameter BURST_TYPE            = "SEQ",
                                     // DDR3 SDRAM: Burst Type (Mode Register 0).
                                     // DDR2 SDRAM: Burst Type (Mode Register).
                                     // # = "SEQ" - (Sequential),
                                     //   = "INT" - (Interleaved).
   parameter CL                    = 6,
                                     // in number of clock cycles
                                     // DDR3 SDRAM: CAS Latency (Mode Register 0).
                                     // DDR2 SDRAM: CAS Latency (Mode Register).
   parameter CWL                   = 5,
                                     // in number of clock cycles
                                     // DDR3 SDRAM: CAS Write Latency (Mode Register 2).
                                     // DDR2 SDRAM: Can be ignored
   parameter OUTPUT_DRV            = "HIGH",
                                     // Output Driver Impedance Control (Mode Register 1).
                                     // # = "HIGH" - RZQ/7,
                                     //   = "LOW" - RZQ/6.
   parameter RTT_NOM               = "60",
                                     // RTT_NOM (ODT) (Mode Register 1).
                                     //   = "120" - RZQ/2,
                                     //   = "60"  - RZQ/4,
                                     //   = "40"  - RZQ/6.
   parameter RTT_WR                = "OFF",
                                     // RTT_WR (ODT) (Mode Register 2).
                                     // # = "OFF" - Dynamic ODT off,
                                     //   = "120" - RZQ/2,
                                     //   = "60"  - RZQ/4,
   parameter ADDR_CMD_MODE         = "1T" ,
                                     // # = "1T", "2T".
   parameter REG_CTRL              = "OFF",
                                     // # = "ON" - RDIMMs,
                                     //   = "OFF" - Components, SODIMMs, UDIMMs.
   parameter CA_MIRROR             = "OFF",
                                     // C/A mirror opt for DDR3 dual rank

   parameter VDD_OP_VOLT           = "150",
                                     // # = "150" - 1.5V Vdd Memory part
                                     //   = "135" - 1.35V Vdd Memory part

   
   //***************************************************************************
   // The following parameters are multiplier and divisor factors for PLLE2.
   // Based on the selected design frequency these parameters vary.
   //***************************************************************************
   parameter CLKIN_PERIOD          = 5000,
                                     // Input Clock Period
   parameter CLKFBOUT_MULT         = 4,
                                     // write PLL VCO multiplier
   parameter DIVCLK_DIVIDE         = 1,
                                     // write PLL VCO divisor
   parameter CLKOUT0_PHASE         = 337.5,
                                     // Phase for PLL output clock (CLKOUT0)
   parameter CLKOUT0_DIVIDE        = 2,
                                     // VCO output divisor for PLL output clock (CLKOUT0)
   parameter CLKOUT1_DIVIDE        = 2,
                                     // VCO output divisor for PLL output clock (CLKOUT1)
   parameter CLKOUT2_DIVIDE        = 32,
                                     // VCO output divisor for PLL output clock (CLKOUT2)
   parameter CLKOUT3_DIVIDE        = 8,
                                     // VCO output divisor for PLL output clock (CLKOUT3)
   parameter MMCM_VCO              = 800,
                                     // Max Freq (MHz) of MMCM VCO
   parameter MMCM_MULT_F           = 8,
                                     // write MMCM VCO multiplier
   parameter MMCM_DIVCLK_DIVIDE    = 1,
                                     // write MMCM VCO divisor

   //***************************************************************************
   // Memory Timing Parameters. These parameters varies based on the selected
   // memory part.
   //***************************************************************************
   parameter tCKE                  = 5000,
                                     // memory tCKE paramter in pS
   parameter tFAW                  = 30000,
                                     // memory tRAW paramter in pS.
   parameter tPRDI                 = 1_000_000,
                                     // memory tPRDI paramter in pS.
   parameter tRAS                  = 35000,
                                     // memory tRAS paramter in pS.
   parameter tRCD                  = 13750,
                                     // memory tRCD paramter in pS.
   parameter tREFI                 = 7800000,
                                     // memory tREFI paramter in pS.
   parameter tRFC                  = 110000,
                                     // memory tRFC paramter in pS.
   parameter tRP                   = 13750,
                                     // memory tRP paramter in pS.
   parameter tRRD                  = 6000,
                                     // memory tRRD paramter in pS.
   parameter tRTP                  = 7500,
                                     // memory tRTP paramter in pS.
   parameter tWTR                  = 7500,
                                     // memory tWTR paramter in pS.
   parameter tZQI                  = 128_000_000,
                                     // memory tZQI paramter in nS.
   parameter tZQCS                 = 64,//64,
                                     // memory tZQCS paramter in clock cycles.

   //***************************************************************************
   // Simulation parameters
   //***************************************************************************
   parameter SIM_BYPASS_INIT_CAL   = "OFF",
                                     // # = "OFF" -  Complete memory init &
                                     //              calibration sequence
                                     // # = "SKIP" - Not supported
                                     // # = "FAST" - Complete memory init & use
                                     //              abbreviated calib sequence

   parameter SIMULATION            = "FALSE",
                                     // Should be TRUE during design simulations and
                                     // FALSE during implementations

   //***************************************************************************
   // The following parameters varies based on the pin out entered in MIG GUI.
   // Do not change any of these parameters directly by editing the RTL.
   // Any changes required should be done through GUI and the design regenerated.
   //***************************************************************************
   parameter BYTE_LANES_B0         = 4'b0111,
                                     // Byte lanes used in an IO column.
   parameter BYTE_LANES_B1         = 4'b1111,
                                     // Byte lanes used in an IO column.
   parameter BYTE_LANES_B2         = 4'b1111,
                                     // Byte lanes used in an IO column.
   parameter BYTE_LANES_B3         = 4'b0000,
                                     // Byte lanes used in an IO column.
   parameter BYTE_LANES_B4         = 4'b0000,
                                     // Byte lanes used in an IO column.
   parameter DATA_CTL_B0           = 4'b0111,
                                     // Indicates Byte lane is data byte lane
                                     // or control Byte lane. '1' in a bit
                                     // position indicates a data byte lane and
                                     // a '0' indicates a control byte lane
   parameter DATA_CTL_B1           = 4'b0001,
                                     // Indicates Byte lane is data byte lane
                                     // or control Byte lane. '1' in a bit
                                     // position indicates a data byte lane and
                                     // a '0' indicates a control byte lane
   parameter DATA_CTL_B2           = 4'b1111,
                                     // Indicates Byte lane is data byte lane
                                     // or control Byte lane. '1' in a bit
                                     // position indicates a data byte lane and
                                     // a '0' indicates a control byte lane
   parameter DATA_CTL_B3           = 4'b0000,
                                     // Indicates Byte lane is data byte lane
                                     // or control Byte lane. '1' in a bit
                                     // position indicates a data byte lane and
                                     // a '0' indicates a control byte lane
   parameter DATA_CTL_B4           = 4'b0000,
                                     // Indicates Byte lane is data byte lane
                                     // or control Byte lane. '1' in a bit
                                     // position indicates a data byte lane and
                                     // a '0' indicates a control byte lane
   parameter PHY_0_BITLANES        = 48'h000_1FF_3FE_2FF,
   parameter PHY_1_BITLANES        = 48'h7D4_BF0_8FF_2FF,
   parameter PHY_2_BITLANES        = 48'h3FE_1FF_1FF_2FF,

   // control/address/data pin mapping parameters
   parameter CK_BYTE_MAP
     = 144'h00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_12,
   parameter ADDR_MAP
     = 192'h000_000_138_12B_134_112_11B_139_116_117_132_126_136_127_137_125,
   parameter BANK_MAP   = 36'h13A_111_115,
   parameter CAS_MAP    = 12'h113,
   parameter CKE_ODT_BYTE_MAP = 8'h00,
   parameter CKE_MAP    = 96'h000_000_000_000_000_000_000_124,
   parameter ODT_MAP    = 96'h000_000_000_000_000_000_000_110,
   parameter CS_MAP     = 120'h000_000_000_000_000_000_000_000_000_129,
   parameter PARITY_MAP = 12'h000,
   parameter RAS_MAP    = 12'h128,
   parameter WE_MAP     = 12'h114,
   parameter DQS_BYTE_MAP
     = 144'h00_00_00_00_00_00_00_00_00_00_00_01_02_10_20_21_22_23,
   parameter DATA0_MAP  = 96'h231_232_235_236_239_233_234_237,
   parameter DATA1_MAP  = 96'h220_221_225_224_222_227_223_226,
   parameter DATA2_MAP  = 96'h214_210_216_217_218_215_213_212,
   parameter DATA3_MAP  = 96'h209_204_202_201_207_206_203_200,
   parameter DATA4_MAP  = 96'h109_107_103_105_106_100_102_104,
   parameter DATA5_MAP  = 96'h023_022_024_027_028_025_021_020,
   parameter DATA6_MAP  = 96'h011_016_012_013_019_015_018_017,
   parameter DATA7_MAP  = 96'h003_009_004_001_002_000_007_006,
   parameter DATA8_MAP  = 96'h000_000_000_000_000_000_000_000,
   parameter DATA9_MAP  = 96'h000_000_000_000_000_000_000_000,
   parameter DATA10_MAP = 96'h000_000_000_000_000_000_000_000,
   parameter DATA11_MAP = 96'h000_000_000_000_000_000_000_000,
   parameter DATA12_MAP = 96'h000_000_000_000_000_000_000_000,
   parameter DATA13_MAP = 96'h000_000_000_000_000_000_000_000,
   parameter DATA14_MAP = 96'h000_000_000_000_000_000_000_000,
   parameter DATA15_MAP = 96'h000_000_000_000_000_000_000_000,
   parameter DATA16_MAP = 96'h000_000_000_000_000_000_000_000,
   parameter DATA17_MAP = 96'h000_000_000_000_000_000_000_000,
   parameter MASK0_MAP  = 108'h000_005_014_026_101_205_211_228_238,
   parameter MASK1_MAP  = 108'h000_000_000_000_000_000_000_000_000,

   parameter SLOT_0_CONFIG         = 8'b0000_0001,
                                     // Mapping of Ranks.
   parameter SLOT_1_CONFIG         = 8'b0000_0000,
                                     // Mapping of Ranks.

   //***************************************************************************
   // IODELAY and PHY related parameters
   //***************************************************************************
   parameter IBUF_LPWR_MODE        = "OFF",
                                     // to phy_top
   parameter DATA_IO_IDLE_PWRDWN   = "ON",
                                     // # = "ON", "OFF"
   parameter BANK_TYPE             = "HP_IO",
                                     // # = "HP_IO", "HPL_IO", "HR_IO", "HRL_IO"
   parameter DATA_IO_PRIM_TYPE     = "HP_LP",
                                     // # = "HP_LP", "HR_LP", "DEFAULT"
   parameter CKE_ODT_AUX           = "FALSE",
   parameter USER_REFRESH          = "OFF",
   parameter WRLVL                 = "ON",
                                     // # = "ON" - DDR3 SDRAM
                                     //   = "OFF" - DDR2 SDRAM.
   parameter ORDERING              = "NORM",
                                     // # = "NORM", "STRICT", "RELAXED".
   parameter CALIB_ROW_ADD         = 16'h0000,
                                     // Calibration row address will be used for
                                     // calibration read and write operations
   parameter CALIB_COL_ADD         = 12'h000,
                                     // Calibration column address will be used for
                                     // calibration read and write operations
   parameter CALIB_BA_ADD          = 3'h0,
                                     // Calibration bank address will be used for
                                     // calibration read and write operations
   parameter TCQ                   = 100,
   parameter IDELAY_ADJ            = "OFF",
   parameter FINE_PER_BIT          = "OFF",
   parameter CENTER_COMP_MODE      = "OFF",
   parameter PI_VAL_ADJ            = "OFF",
   parameter IODELAY_GRP0          = "MEMCTL_IODELAY_MIG0",
                                     // It is associated to a set of IODELAYs with
                                     // an IDELAYCTRL that have same IODELAY CONTROLLER
                                     // clock frequency (200MHz).
   parameter IODELAY_GRP1          = "MEMCTL_IODELAY_MIG1",
                                     // It is associated to a set of IODELAYs with
                                     // an IDELAYCTRL that have same IODELAY CONTROLLER
                                     // clock frequency (300MHz/400MHz).
   parameter SYSCLK_TYPE           = "DIFFERENTIAL",
                                     // System clock type DIFFERENTIAL, SINGLE_ENDED,
                                     // NO_BUFFER
   parameter REFCLK_TYPE           = "USE_SYSTEM_CLOCK",
                                     // Reference clock type DIFFERENTIAL, SINGLE_ENDED,
                                     // NO_BUFFER, USE_SYSTEM_CLOCK
   parameter SYS_RST_PORT          = "TRUE",
                                     // "TRUE" - if pin is selected for sys_rst
                                     //          and IBUF will be instantiated.
                                     // "FALSE" - if pin is not selected for sys_rst
   parameter FPGA_SPEED_GRADE      = 2,
                                     // FPGA speed grade
      
   parameter CMD_PIPE_PLUS1        = "ON",
                                     // add pipeline stage between MC and PHY
   parameter DRAM_TYPE             = "DDR3",
   parameter CAL_WIDTH             = "HALF",
   parameter STARVE_LIMIT          = 2,
                                     // # = 2,3,4.
   parameter REF_CLK_MMCM_IODELAY_CTRL    = "FALSE",
      

   //***************************************************************************
   // Referece clock frequency parameters
   //***************************************************************************
   parameter REFCLK_FREQ           = 200.0,
                                     // IODELAYCTRL reference clock frequency
   parameter DIFF_TERM_REFCLK      = "TRUE",
                                     // Differential Termination for idelay
                                     // reference clock input pins
   //***************************************************************************
   // System clock frequency parameters
   //***************************************************************************
   parameter tCK                   = 2500,
                                     // memory tCK paramter.
                                     // # = Clock Period in pS.
   parameter nCK_PER_CLK           = 4,
   // # of memory CKs per fabric CLK
   
   parameter DIFF_TERM_SYSCLK      = "FALSE",
                                     // Differential Termination for System
                                     // clock input pins
      

   

   //***************************************************************************
   // Debug parameters
   //***************************************************************************
   parameter DEBUG_PORT            = "OFF",
                                     // # = "ON" Enable debug signals/controls.
                                     //   = "OFF" Disable debug signals/controls.

   //***************************************************************************
   // Temparature monitor parameter
   //***************************************************************************
   parameter TEMP_MON_CONTROL      = "INTERNAL",
                                     // # = "INTERNAL", "EXTERNAL"
   //***************************************************************************
   // FPGA Voltage Type parameter
   //***************************************************************************
   parameter FPGA_VOLT_TYPE        = "N",
                                     // # = "L", "N". When FPGA VccINT is 0.9v,
                                     // the value is "L", else it is "N"
      
   parameter RST_ACT_LOW           = 0
                                     // =1 for active low reset,
                                     // =0 for active high.
   )
  (
    // DDR Interface
    inout [DQ_WIDTH-1:0]                         ddr3_dq,
    inout [DQS_WIDTH-1:0]                        ddr3_dqs_n,
    inout [DQS_WIDTH-1:0]                        ddr3_dqs_p,
    output [ROW_WIDTH-1:0]                       ddr3_addr,
    output [BANK_WIDTH-1:0]                      ddr3_ba,
    output                                       ddr3_ras_n,
    output                                       ddr3_cas_n,
    output                                       ddr3_we_n,
    output                                       ddr3_reset_n,
    output [CK_WIDTH-1:0]                        ddr3_ck_p,
    output [CK_WIDTH-1:0]                        ddr3_ck_n,
    output [CKE_WIDTH-1:0]                       ddr3_cke,
    output [(CS_WIDTH*nCS_PER_RANK)-1:0]         ddr3_cs_n,
    output [DM_WIDTH-1:0]                        ddr3_dm,
    output [ODT_WIDTH-1:0]                       ddr3_odt,

    // MC <-> PHY Interface
    input [nCK_PER_CLK-1:0]   mc_ras_n,
    input [nCK_PER_CLK-1:0]   mc_cas_n,
    input [nCK_PER_CLK-1:0]   mc_we_n,
    input [nCK_PER_CLK*ROW_WIDTH-1:0] mc_address,
    input [nCK_PER_CLK*BANK_WIDTH-1:0] mc_bank,
    input [CS_WIDTH*nCS_PER_RANK*nCK_PER_CLK-1:0] mc_cs_n,
    input                     mc_reset_n,
    input [1:0]           mc_odt,
    input [nCK_PER_CLK-1:0]   mc_cke,
    // AUX - For ODT and CKE assertion during reads and writes
    input [3:0]               mc_aux_out0,
    input [3:0]               mc_aux_out1,
    input                     mc_cmd_wren,
    input                     mc_ctl_wren,
    input [2:0]               mc_cmd,
    input [1:0]               mc_cas_slot,
    input [5:0]               mc_data_offset,
    input [5:0]               mc_data_offset_1,
    input [5:0]               mc_data_offset_2,
    input [1:0]               mc_rank_cnt,
    // Write
    input                     mc_wrdata_en,
    input [2*nCK_PER_CLK*DQ_WIDTH-1:0] mc_wrdata,
    input [2*nCK_PER_CLK*(DQ_WIDTH/8)-1:0] mc_wrdata_mask,
    input                     idle,
    output                              phy_mc_ctl_full,
    output                              phy_mc_cmd_full,
    output                              phy_mc_data_full,
    output [6*RANKS-1:0]                calib_rd_data_offset_0,
    output [6*RANKS-1:0]                calib_rd_data_offset_1,
    output [6*RANKS-1:0]                calib_rd_data_offset_2,
    output                              phy_rddata_valid,
    output [2*nCK_PER_CLK*DQ_WIDTH-1:0] phy_rd_data,
   
   // Differential system clocks
   input                                        sys_clk_p,
   input                                        sys_clk_n,

   output                                       ui_clk,
   output                                       ui_clk_sync_rst,
        
   output                                       init_calib_complete,

   // System reset - Default polarity of sys_rst pin is Active Low.
   // System reset polarity will change based on the option 
   // selected in GUI.
   input                                        sys_rst
   );

  function integer clogb2 (input integer size);
    begin
      size = size - 1;
      for (clogb2=1; size>1; clogb2=clogb2+1)
        size = size >> 1;
    end
  endfunction // clogb2


  localparam BM_CNT_WIDTH = clogb2(nBANK_MACHS);
  localparam RANK_WIDTH = clogb2(RANKS);

  localparam ECC_WIDTH = (ECC == "OFF")?
                           0 : (DATA_WIDTH <= 4)?
                            4 : (DATA_WIDTH <= 10)?
                             5 : (DATA_WIDTH <= 26)?
                              6 : (DATA_WIDTH <= 57)?
                               7 : (DATA_WIDTH <= 120)?
                                8 : (DATA_WIDTH <= 247)?
                                 9 : 10;
  localparam DATA_BUF_OFFSET_WIDTH = 1;
  localparam MC_ERR_ADDR_WIDTH = ((CS_WIDTH == 1) ? 0 : RANK_WIDTH)
                                 + BANK_WIDTH + ROW_WIDTH + COL_WIDTH
                                 + DATA_BUF_OFFSET_WIDTH;

  localparam TEMP_MON_EN           = (SIMULATION == "FALSE") ? "ON" : "OFF";
                                                 // Enable or disable the temp monitor module
  localparam tTEMPSAMPLE           = 10000000;   // sample every 10 us
  localparam XADC_CLK_PERIOD       = 5000;       // Use 200 MHz IODELAYCTRL clock
  `ifdef SKIP_CALIB
  localparam SKIP_CALIB = "TRUE";
  `else
  localparam SKIP_CALIB = "FALSE";
  `endif
      

  localparam TAPSPERKCLK = (56*MMCM_MULT_F)/nCK_PER_CLK;
  

  // Wire declarations
      
  wire [BM_CNT_WIDTH-1:0]           bank_mach_next;
  wire                              clk;
  wire [1:0]                        clk_ref;
  wire [1:0]                        iodelay_ctrl_rdy;
  wire                              clk_ref_in;
  wire                              sys_rst_o;
  wire                              clk_div2;
  wire                              rst_div2;
  wire                              freq_refclk ;
  wire                              mem_refclk ;
  wire                              pll_lock ;
  wire                              sync_pulse;
  wire                              mmcm_ps_clk;
  wire                              poc_sample_pd;
  wire                              psen;
  wire                              psincdec;
  wire                              psdone;
  wire                              iddr_rst;
  wire                              ref_dll_lock;
  wire                              rst_phaser_ref;
  wire                              pll_locked;

  wire                              rst;
  
  wire [(2*nCK_PER_CLK)-1:0]            app_ecc_multiple_err;
  wire [(2*nCK_PER_CLK)-1:0]            app_ecc_single_err;
  wire                                ddr3_parity;
      

  wire                              sys_clk_i;
  wire                              mmcm_clk;
  wire                              clk_ref_p;
  wire                              clk_ref_n;
  wire                              clk_ref_i;
  wire [11:0]                       device_temp_i;
  wire [11:0]                       device_temp;
  
      

//***************************************************************************

  assign ui_clk = clk;
  assign ui_clk_sync_rst = rst;
  
  assign sys_clk_i = 1'b0;
  assign clk_ref_i = 1'b0;
      

  generate
    if (REFCLK_TYPE == "USE_SYSTEM_CLOCK")
      assign clk_ref_in = mmcm_clk;
    else
      assign clk_ref_in = clk_ref_i;
  endgenerate

  mig_7series_v4_0_iodelay_ctrl #
    (
     .TCQ                       (TCQ),
     .IODELAY_GRP0              (IODELAY_GRP0),
     .IODELAY_GRP1              (IODELAY_GRP1),
     .REFCLK_TYPE               (REFCLK_TYPE),
     .SYSCLK_TYPE               (SYSCLK_TYPE),
     .SYS_RST_PORT              (SYS_RST_PORT),
     .RST_ACT_LOW               (RST_ACT_LOW),
     .DIFF_TERM_REFCLK          (DIFF_TERM_REFCLK),
     .FPGA_SPEED_GRADE          (FPGA_SPEED_GRADE),
     .REF_CLK_MMCM_IODELAY_CTRL (REF_CLK_MMCM_IODELAY_CTRL)
     )
    u_iodelay_ctrl
      (
       // Outputs
       .iodelay_ctrl_rdy (iodelay_ctrl_rdy),
       .sys_rst_o        (sys_rst_o),
       .clk_ref          (clk_ref),
       // Inputs
       .clk_ref_p        (clk_ref_p),
       .clk_ref_n        (clk_ref_n),
       .clk_ref_i        (clk_ref_in),
       .sys_rst          (sys_rst)
       );
  mig_7series_v4_0_clk_ibuf #
    (
     .SYSCLK_TYPE      (SYSCLK_TYPE),
     .DIFF_TERM_SYSCLK (DIFF_TERM_SYSCLK)
     )
    u_ddr3_clk_ibuf
      (
       .sys_clk_p        (sys_clk_p),
       .sys_clk_n        (sys_clk_n),
       .sys_clk_i        (sys_clk_i),
       .mmcm_clk         (mmcm_clk)
       );
  // Temperature monitoring logic

  generate
    if (TEMP_MON_EN == "ON") begin: temp_mon_enabled

      mig_7series_v4_0_tempmon #
        (
         .TCQ              (TCQ),
         .TEMP_MON_CONTROL (TEMP_MON_CONTROL),
         .XADC_CLK_PERIOD  (XADC_CLK_PERIOD),
         .tTEMPSAMPLE      (tTEMPSAMPLE)
         )
        u_tempmon
          (
           .clk            (clk),
           .xadc_clk       (clk_ref[0]),
           .rst            (rst),
           .device_temp_i  (device_temp_i),
           .device_temp    (device_temp)
          );
    end else begin: temp_mon_disabled

      assign device_temp = 'b0;

    end
  endgenerate
         
  mig_7series_v4_0_infrastructure #
    (
     //.SIMULATION         (SIMULATION),
     .TCQ                (TCQ),
     .nCK_PER_CLK        (nCK_PER_CLK),
     .CLKIN_PERIOD       (CLKIN_PERIOD),
     .SYSCLK_TYPE        (SYSCLK_TYPE),
     .CLKFBOUT_MULT      (CLKFBOUT_MULT),
     .DIVCLK_DIVIDE      (DIVCLK_DIVIDE),
     .CLKOUT0_PHASE      (CLKOUT0_PHASE),
     .CLKOUT0_DIVIDE     (CLKOUT0_DIVIDE),
     .CLKOUT1_DIVIDE     (CLKOUT1_DIVIDE),
     .CLKOUT2_DIVIDE     (CLKOUT2_DIVIDE),
     .CLKOUT3_DIVIDE     (CLKOUT3_DIVIDE),
     .MMCM_VCO           (MMCM_VCO),
     .MMCM_MULT_F        (MMCM_MULT_F),
     .MMCM_DIVCLK_DIVIDE (MMCM_DIVCLK_DIVIDE),
     .RST_ACT_LOW        (RST_ACT_LOW),
     .tCK                (tCK),
     .MEM_TYPE           (DRAM_TYPE)
     )
    u_ddr3_infrastructure
      (
       // Outputs
       .rstdiv0          (rst),
       .clk              (clk),
       .clk_div2         (clk_div2),
       .rst_div2         (rst_div2),
       .mem_refclk       (mem_refclk),
       .freq_refclk      (freq_refclk),
       .sync_pulse       (sync_pulse),
       .mmcm_ps_clk      (mmcm_ps_clk),
       .poc_sample_pd    (poc_sample_pd),
       .psdone           (psdone),
       .iddr_rst         (iddr_rst),
//       .auxout_clk       (),
       .ui_addn_clk_0    (),
       .ui_addn_clk_1    (),
       .ui_addn_clk_2    (),
       .ui_addn_clk_3    (),
       .ui_addn_clk_4    (),
       .pll_locked       (pll_locked),
       .mmcm_locked      (),
       .rst_phaser_ref   (rst_phaser_ref),
       // Inputs
       .psen             (psen),
       .psincdec         (psincdec),
       .mmcm_clk         (mmcm_clk),
       .sys_rst          (sys_rst_o),
       .iodelay_ctrl_rdy (iodelay_ctrl_rdy),
       .ref_dll_lock     (ref_dll_lock)
       );
      

  //=================== INIT PHY WITH WRAPPER CODE =======================
  localparam nSLOTS  = 1 + (|SLOT_1_CONFIG ? 1 : 0);
  localparam SLOT_0_CONFIG_MC = (nSLOTS == 2)? 8'b0000_0101 : 8'b0000_1111;
  localparam SLOT_1_CONFIG_MC = (nSLOTS == 2)? 8'b0000_1010 : 8'b0000_0000;

  // 8*tREFI in ps is divided by fabric clock period also in ps. 270 is the number
  // of fabric clock cycles that accounts for the Writes, read, and PRECHARGE time
  localparam REFRESH_TIMER = (8*tREFI/(tCK*nCK_PER_CLK)) - 270;

  reg [7:0]               slot_0_present_mc;
  reg [7:0]               slot_1_present_mc;

  reg user_periodic_rd_req = 1'b0;
  reg user_ref_req = 1'b0;
  reg user_zq_req = 1'b0;

  // MC/PHY interface
  wire                                mc_ref_zq_wip;
  wire                                tempmon_sample_en;

  wire                                init_calib_complete_w;
  wire                                init_wrcal_complete_w;
  wire                                mux_calib_complete;
  wire                                reset = rst;
  // assigning CWL = CL -1 for DDR2. DDR2 customers will not know anything
  // about CWL. There is also nCWL parameter. Need to clean it up.
  localparam CWL_T            = (DRAM_TYPE == "DDR3") ? CWL : CL-1;
  localparam PRE_REV3ES       = "OFF";
  localparam DDR2_DQSN_ENABLE = "YES";
  localparam PHYCTL_CMD_FIFO  = "FALSE";
  localparam IODELAY_GRP      = "IODELAY_MIG";
  localparam MASTER_PHY_CTL   = 0;
  // following calculations should be moved inside PHY
  // odt bus should  be added to PHY.
  localparam CLK_PERIOD = tCK * nCK_PER_CLK;
  localparam nCL  = CL;
  localparam nCWL = CWL_T;
  
  assign init_wrcal_complete = init_wrcal_complete_w;
  assign mux_calib_complete  = (PRE_REV3ES == "OFF") ? init_calib_complete_w :
                               (init_calib_complete_w | init_wrcal_complete_w);

  assign init_calib_complete = mux_calib_complete;

  // Enable / disable temperature monitoring
  assign tempmon_sample_en = TEMP_MON_EN == "OFF" ? 1'b0 : mc_ref_zq_wip;

  mig_7series_v4_0_ddr_phy_top #
    (
     .TCQ                (TCQ),
     .DDR3_VDD_OP_VOLT   (VDD_OP_VOLT),
     .REFCLK_FREQ        (REFCLK_FREQ),
     .BYTE_LANES_B0      (BYTE_LANES_B0),
     .BYTE_LANES_B1      (BYTE_LANES_B1),
     .BYTE_LANES_B2      (BYTE_LANES_B2),
     .BYTE_LANES_B3      (BYTE_LANES_B3),
     .BYTE_LANES_B4      (BYTE_LANES_B4),
     .PHY_0_BITLANES     (PHY_0_BITLANES),
     .PHY_1_BITLANES     (PHY_1_BITLANES),
     .PHY_2_BITLANES     (PHY_2_BITLANES),
     .CA_MIRROR          (CA_MIRROR),
     .CK_BYTE_MAP        (CK_BYTE_MAP),
     .ADDR_MAP           (ADDR_MAP),
     .BANK_MAP           (BANK_MAP),
     .CAS_MAP            (CAS_MAP),
     .CKE_ODT_BYTE_MAP   (CKE_ODT_BYTE_MAP),
     .CKE_MAP            (CKE_MAP),
     .ODT_MAP            (ODT_MAP),
     .CKE_ODT_AUX        (CKE_ODT_AUX),
     .CS_MAP             (CS_MAP),
     .PARITY_MAP         (PARITY_MAP),
     .RAS_MAP            (RAS_MAP),
     .WE_MAP             (WE_MAP),
     .DQS_BYTE_MAP       (DQS_BYTE_MAP),
     .DATA0_MAP          (DATA0_MAP),
     .DATA1_MAP          (DATA1_MAP),
     .DATA2_MAP          (DATA2_MAP),
     .DATA3_MAP          (DATA3_MAP),
     .DATA4_MAP          (DATA4_MAP),
     .DATA5_MAP          (DATA5_MAP),
     .DATA6_MAP          (DATA6_MAP),
     .DATA7_MAP          (DATA7_MAP),
     .DATA8_MAP          (DATA8_MAP),
     .DATA9_MAP          (DATA9_MAP),
     .DATA10_MAP         (DATA10_MAP),
     .DATA11_MAP         (DATA11_MAP),
     .DATA12_MAP         (DATA12_MAP),
     .DATA13_MAP         (DATA13_MAP),
     .DATA14_MAP         (DATA14_MAP),
     .DATA15_MAP         (DATA15_MAP),
     .DATA16_MAP         (DATA16_MAP),
     .DATA17_MAP         (DATA17_MAP),
     .MASK0_MAP          (MASK0_MAP),
     .MASK1_MAP          (MASK1_MAP),
     .CALIB_ROW_ADD      (CALIB_ROW_ADD),
     .CALIB_COL_ADD      (CALIB_COL_ADD),
     .CALIB_BA_ADD       (CALIB_BA_ADD),
     .nCS_PER_RANK       (nCS_PER_RANK),
     .CS_WIDTH           (CS_WIDTH),
     .nCK_PER_CLK        (nCK_PER_CLK),
     .PRE_REV3ES         (PRE_REV3ES),
     .CKE_WIDTH          (CKE_WIDTH),
     .DATA_CTL_B0        (DATA_CTL_B0),
     .DATA_CTL_B1        (DATA_CTL_B1),
     .DATA_CTL_B2        (DATA_CTL_B2),
     .DATA_CTL_B3        (DATA_CTL_B3),
     .DATA_CTL_B4        (DATA_CTL_B4),
     .DDR2_DQSN_ENABLE   (DDR2_DQSN_ENABLE),
     .DRAM_TYPE          (DRAM_TYPE),
     .BANK_WIDTH         (BANK_WIDTH),
     .CK_WIDTH           (CK_WIDTH),
     .COL_WIDTH          (COL_WIDTH),
     .DM_WIDTH           (DM_WIDTH),
     .DQ_WIDTH           (DQ_WIDTH),
     .DQS_CNT_WIDTH      (DQS_CNT_WIDTH),
     .DQS_WIDTH          (DQS_WIDTH),
     .DRAM_WIDTH         (DRAM_WIDTH),
     .PHYCTL_CMD_FIFO    (PHYCTL_CMD_FIFO),
     .ROW_WIDTH          (ROW_WIDTH),
     .AL                 (AL),
     .ADDR_CMD_MODE      (ADDR_CMD_MODE),
     .BURST_MODE         (BURST_MODE),
     .BURST_TYPE         (BURST_TYPE),
     .CL                 (nCL),
     .CWL                (nCWL),
     .tRFC               (tRFC),
     .tREFI              (tREFI),
     .tCK                (tCK),
     .OUTPUT_DRV         (OUTPUT_DRV),
     .RANKS              (RANKS),
     .ODT_WIDTH          (ODT_WIDTH),
     .REG_CTRL           (REG_CTRL),
     .RTT_NOM            (RTT_NOM),
     .RTT_WR             (RTT_WR),
     .SLOT_1_CONFIG      (SLOT_1_CONFIG),
     .WRLVL              (WRLVL),
     .BANK_TYPE          (BANK_TYPE),
     .DATA_IO_PRIM_TYPE  (DATA_IO_PRIM_TYPE),
     .DATA_IO_IDLE_PWRDWN(DATA_IO_IDLE_PWRDWN),
     .IODELAY_GRP        (IODELAY_GRP),
     .FPGA_SPEED_GRADE   (FPGA_SPEED_GRADE),
     // Prevent the following simulation-related parameters from
     // being overridden for synthesis - for synthesis only the
     // default values of these parameters should be used
     // synthesis translate_off
     .SIM_BYPASS_INIT_CAL (SIM_BYPASS_INIT_CAL),
     // synthesis translate_on
     .USE_CS_PORT        (USE_CS_PORT),
     .USE_DM_PORT        (USE_DM_PORT),
     .USE_ODT_PORT       (USE_ODT_PORT),
     .MASTER_PHY_CTL     (MASTER_PHY_CTL),
     .DEBUG_PORT         (DEBUG_PORT),
     .IDELAY_ADJ         (IDELAY_ADJ),
     .FINE_PER_BIT       (FINE_PER_BIT),
     .CENTER_COMP_MODE   (CENTER_COMP_MODE),
     .PI_VAL_ADJ         (PI_VAL_ADJ),
     .TAPSPERKCLK        (TAPSPERKCLK),
     .SKIP_CALIB         (SKIP_CALIB),
     .FPGA_VOLT_TYPE     (FPGA_VOLT_TYPE)
     )
    ddr_phy_top0
      (
       // Outputs
       .calib_rd_data_offset_0      (calib_rd_data_offset_0),
       .calib_rd_data_offset_1      (calib_rd_data_offset_1),
       .calib_rd_data_offset_2      (calib_rd_data_offset_2),
       .ddr_ck                      (ddr3_ck_p),
       .ddr_ck_n                    (ddr3_ck_n),
       .ddr_addr                    (ddr3_addr),
       .ddr_ba                      (ddr3_ba),
       .ddr_ras_n                   (ddr3_ras_n),
       .ddr_cas_n                   (ddr3_cas_n),
       .ddr_we_n                    (ddr3_we_n),
       .ddr_cs_n                    (ddr3_cs_n),
       .ddr_cke                     (ddr3_cke),
       .ddr_odt                     (ddr3_odt),
       .ddr_reset_n                 (ddr3_reset_n),
       .ddr_parity                  (ddr3_parity),
       .ddr_dm                      (ddr3_dm),
       .init_calib_complete         (init_calib_complete_w),
       .init_wrcal_complete         (init_wrcal_complete_w),
       .mc_address                  (mc_address),
       .mc_aux_out0                 (mc_aux_out0),
       .mc_aux_out1                 (mc_aux_out1),
       .mc_bank                     (mc_bank),
       .mc_cke                      (mc_cke),
       .mc_odt                      (mc_odt),
       .mc_cas_n                    (mc_cas_n),
       .mc_cmd                      (mc_cmd),
       .mc_cmd_wren                 (mc_cmd_wren),
       .mc_cas_slot                 (mc_cas_slot),
       .mc_cs_n                     (mc_cs_n),
       .mc_ctl_wren                 (mc_ctl_wren),
       .mc_data_offset              (mc_data_offset),
       .mc_data_offset_1            (mc_data_offset_1),
       .mc_data_offset_2            (mc_data_offset_2),
       .mc_rank_cnt                 (mc_rank_cnt),
       .mc_ras_n                    (mc_ras_n),
       .mc_reset_n                  (mc_reset_n),
       .mc_we_n                     (mc_we_n),
       .mc_wrdata                   (mc_wrdata),
       .mc_wrdata_en                (mc_wrdata_en),
       .mc_wrdata_mask              (mc_wrdata_mask),
       .idle                        (idle),
       .mem_refclk                  (mem_refclk),
       .phy_mc_ctl_full             (phy_mc_ctl_full),
       .phy_mc_cmd_full             (phy_mc_cmd_full),
       .phy_mc_data_full            (phy_mc_data_full),
       .phy_rd_data                 (phy_rd_data),
       .phy_rddata_valid            (phy_rddata_valid),
       .pll_lock                    (pll_locked),
       .sync_pulse                  (sync_pulse),
       // Inouts
       .ddr_dqs                     (ddr3_dqs_p),
       .ddr_dqs_n                   (ddr3_dqs_n),
       .ddr_dq                      (ddr3_dq),
        // Inputs
       .clk_ref                     (tCK <= 1500 ? clk_ref[1] : clk_ref[0]),
       .freq_refclk                 (freq_refclk),
       .clk                         (clk),
       .clk_div2                    (clk_div2),
       .rst_div2                    (rst_div2),
       .mmcm_ps_clk                 (mmcm_ps_clk),
       .poc_sample_pd               (poc_sample_pd),
       .rst                         (rst),
       
       .slot_0_present              (SLOT_0_CONFIG),
       .slot_1_present              (SLOT_1_CONFIG)

       ,.device_temp                (device_temp)
       ,.tempmon_sample_en          (tempmon_sample_en)
       ,.psen                       (psen)
       ,.psincdec                   (psincdec)
       ,.psdone                     (psdone)

       ,.ref_dll_lock               (ref_dll_lock)
       ,.rst_phaser_ref             (rst_phaser_ref)
       ,.iddr_rst                   (iddr_rst)
      );

endmodule
