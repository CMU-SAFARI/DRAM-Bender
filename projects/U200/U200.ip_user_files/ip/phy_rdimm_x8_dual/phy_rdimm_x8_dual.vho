-- (c) Copyright 1995-2022 Xilinx, Inc. All rights reserved.
-- 
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
-- 
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
-- 
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
-- 
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
-- 
-- DO NOT MODIFY THIS FILE.

-- IP VLNV: xilinx.com:ip:ddr4:2.2
-- IP Revision: 10

-- The following code must appear in the VHDL architecture header.

------------- Begin Cut here for COMPONENT Declaration ------ COMP_TAG
COMPONENT phy_rdimm_x8_dual
  PORT (
    c0_init_calib_complete : OUT STD_LOGIC;
    dbg_clk : OUT STD_LOGIC;
    c0_sys_clk_p : IN STD_LOGIC;
    c0_sys_clk_n : IN STD_LOGIC;
    dbg_bus : OUT STD_LOGIC_VECTOR(511 DOWNTO 0);
    c0_ddr4_parity : OUT STD_LOGIC;
    c0_ddr4_ui_clk : OUT STD_LOGIC;
    c0_ddr4_ui_clk_sync_rst : OUT STD_LOGIC;
    sys_rst : IN STD_LOGIC;
    rdDataEn : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    rdDataEnd : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    per_rd_done : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    rmw_rd_done : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    wrDataEn : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    mc_ACT_n : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    mcCasSlot : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    mcCasSlot2 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    mcRdCAS : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    mcWrCAS : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    winInjTxn : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    winRmw : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gt_data_ready : IN STD_LOGIC;
    winRank : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    tCWL : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    wrData : IN STD_LOGIC_VECTOR(575 DOWNTO 0);
    wrDataMask : IN STD_LOGIC_VECTOR(71 DOWNTO 0);
    rdData : OUT STD_LOGIC_VECTOR(575 DOWNTO 0);
    mc_ADR : IN STD_LOGIC_VECTOR(135 DOWNTO 0);
    mc_BA : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    mc_CKE : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    mc_CS_n : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    mc_ODT : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dBufAdr : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
    rdDataAddr : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
    wrDataAddr : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
    winBuf : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
    ddr4_act_n : OUT STD_LOGIC;
    ddr4_adr : OUT STD_LOGIC_VECTOR(16 DOWNTO 0);
    ddr4_ba : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    ddr4_bg : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    ddr4_par : OUT STD_LOGIC;
    ddr4_cke : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    ddr4_odt : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    ddr4_cs_n : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    ddr4_ck_t : OUT STD_LOGIC;
    ddr4_ck_c : OUT STD_LOGIC;
    ddr4_reset_n : OUT STD_LOGIC;
    ddr4_parity : OUT STD_LOGIC;
    ddr4_dm_dbi_n : INOUT STD_LOGIC_VECTOR(8 DOWNTO 0);
    ddr4_dq : INOUT STD_LOGIC_VECTOR(71 DOWNTO 0);
    ddr4_dqs_c : INOUT STD_LOGIC_VECTOR(8 DOWNTO 0);
    ddr4_dqs_t : INOUT STD_LOGIC_VECTOR(8 DOWNTO 0);
    mc_BG : IN STD_LOGIC_VECTOR(15 DOWNTO 0)
  );
END COMPONENT;
-- COMP_TAG_END ------ End COMPONENT Declaration ------------

-- The following code must appear in the VHDL architecture
-- body. Substitute your own instance name and net names.

------------- Begin Cut here for INSTANTIATION Template ----- INST_TAG
your_instance_name : phy_rdimm_x8_dual
  PORT MAP (
    c0_init_calib_complete => c0_init_calib_complete,
    dbg_clk => dbg_clk,
    c0_sys_clk_p => c0_sys_clk_p,
    c0_sys_clk_n => c0_sys_clk_n,
    dbg_bus => dbg_bus,
    c0_ddr4_parity => c0_ddr4_parity,
    c0_ddr4_ui_clk => c0_ddr4_ui_clk,
    c0_ddr4_ui_clk_sync_rst => c0_ddr4_ui_clk_sync_rst,
    sys_rst => sys_rst,
    rdDataEn => rdDataEn,
    rdDataEnd => rdDataEnd,
    per_rd_done => per_rd_done,
    rmw_rd_done => rmw_rd_done,
    wrDataEn => wrDataEn,
    mc_ACT_n => mc_ACT_n,
    mcCasSlot => mcCasSlot,
    mcCasSlot2 => mcCasSlot2,
    mcRdCAS => mcRdCAS,
    mcWrCAS => mcWrCAS,
    winInjTxn => winInjTxn,
    winRmw => winRmw,
    gt_data_ready => gt_data_ready,
    winRank => winRank,
    tCWL => tCWL,
    wrData => wrData,
    wrDataMask => wrDataMask,
    rdData => rdData,
    mc_ADR => mc_ADR,
    mc_BA => mc_BA,
    mc_CKE => mc_CKE,
    mc_CS_n => mc_CS_n,
    mc_ODT => mc_ODT,
    dBufAdr => dBufAdr,
    rdDataAddr => rdDataAddr,
    wrDataAddr => wrDataAddr,
    winBuf => winBuf,
    ddr4_act_n => ddr4_act_n,
    ddr4_adr => ddr4_adr,
    ddr4_ba => ddr4_ba,
    ddr4_bg => ddr4_bg,
    ddr4_par => ddr4_par,
    ddr4_cke => ddr4_cke,
    ddr4_odt => ddr4_odt,
    ddr4_cs_n => ddr4_cs_n,
    ddr4_ck_t => ddr4_ck_t,
    ddr4_ck_c => ddr4_ck_c,
    ddr4_reset_n => ddr4_reset_n,
    ddr4_parity => ddr4_parity,
    ddr4_dm_dbi_n => ddr4_dm_dbi_n,
    ddr4_dq => ddr4_dq,
    ddr4_dqs_c => ddr4_dqs_c,
    ddr4_dqs_t => ddr4_dqs_t,
    mc_BG => mc_BG
  );
-- INST_TAG_END ------ End INSTANTIATION Template ---------

-- You must compile the wrapper file phy_rdimm_x8_dual.vhd when simulating
-- the core, phy_rdimm_x8_dual. When compiling the wrapper file, be sure to
-- reference the VHDL simulation library.

