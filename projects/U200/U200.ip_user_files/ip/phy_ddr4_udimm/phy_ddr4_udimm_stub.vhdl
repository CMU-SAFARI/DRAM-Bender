-- Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2020.2 (lin64) Build 3064766 Wed Nov 18 09:12:47 MST 2020
-- Date        : Tue Mar  8 15:10:28 2022
-- Host        : machine running 64-bit Ubuntu 20.04.4 LTS
-- Command     : write_vhdl -force -mode synth_stub
--               /home/ataberk/SoftMC_DDR4/projects/U200/U200.srcs/sources_1/ip/phy_ddr4_udimm/phy_ddr4_udimm_stub.vhdl
-- Design      : phy_ddr4_udimm
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xcu200-fsgd2104-2-e
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity phy_ddr4_udimm is
  Port ( 
    sys_rst : in STD_LOGIC;
    c0_sys_clk_p : in STD_LOGIC;
    c0_sys_clk_n : in STD_LOGIC;
    c0_ddr4_ui_clk : out STD_LOGIC;
    c0_ddr4_ui_clk_sync_rst : out STD_LOGIC;
    dbg_clk : out STD_LOGIC;
    c0_ddr4_act_n : out STD_LOGIC;
    c0_ddr4_adr : out STD_LOGIC_VECTOR ( 16 downto 0 );
    c0_ddr4_ba : out STD_LOGIC_VECTOR ( 1 downto 0 );
    c0_ddr4_bg : out STD_LOGIC_VECTOR ( 1 downto 0 );
    c0_ddr4_cke : out STD_LOGIC_VECTOR ( 0 to 0 );
    c0_ddr4_odt : out STD_LOGIC_VECTOR ( 0 to 0 );
    c0_ddr4_cs_n : out STD_LOGIC_VECTOR ( 0 to 0 );
    c0_ddr4_ck_t : out STD_LOGIC_VECTOR ( 0 to 0 );
    c0_ddr4_ck_c : out STD_LOGIC_VECTOR ( 0 to 0 );
    c0_ddr4_reset_n : out STD_LOGIC;
    c0_ddr4_dm_dbi_n : inout STD_LOGIC_VECTOR ( 7 downto 0 );
    c0_ddr4_dq : inout STD_LOGIC_VECTOR ( 63 downto 0 );
    c0_ddr4_dqs_c : inout STD_LOGIC_VECTOR ( 7 downto 0 );
    c0_ddr4_dqs_t : inout STD_LOGIC_VECTOR ( 7 downto 0 );
    c0_init_calib_complete : out STD_LOGIC;
    dBufAdr : in STD_LOGIC_VECTOR ( 4 downto 0 );
    wrData : in STD_LOGIC_VECTOR ( 511 downto 0 );
    wrDataMask : in STD_LOGIC_VECTOR ( 63 downto 0 );
    rdData : out STD_LOGIC_VECTOR ( 511 downto 0 );
    rdDataAddr : out STD_LOGIC_VECTOR ( 4 downto 0 );
    rdDataEn : out STD_LOGIC_VECTOR ( 0 to 0 );
    rdDataEnd : out STD_LOGIC_VECTOR ( 0 to 0 );
    per_rd_done : out STD_LOGIC_VECTOR ( 0 to 0 );
    rmw_rd_done : out STD_LOGIC_VECTOR ( 0 to 0 );
    wrDataAddr : out STD_LOGIC_VECTOR ( 4 downto 0 );
    wrDataEn : out STD_LOGIC_VECTOR ( 0 to 0 );
    mc_ACT_n : in STD_LOGIC_VECTOR ( 7 downto 0 );
    mc_ADR : in STD_LOGIC_VECTOR ( 135 downto 0 );
    mc_BA : in STD_LOGIC_VECTOR ( 15 downto 0 );
    mc_BG : in STD_LOGIC_VECTOR ( 15 downto 0 );
    mc_CKE : in STD_LOGIC_VECTOR ( 7 downto 0 );
    mc_CS_n : in STD_LOGIC_VECTOR ( 7 downto 0 );
    mc_ODT : in STD_LOGIC_VECTOR ( 7 downto 0 );
    mcCasSlot : in STD_LOGIC_VECTOR ( 1 downto 0 );
    mcCasSlot2 : in STD_LOGIC_VECTOR ( 0 to 0 );
    mcRdCAS : in STD_LOGIC_VECTOR ( 0 to 0 );
    mcWrCAS : in STD_LOGIC_VECTOR ( 0 to 0 );
    winInjTxn : in STD_LOGIC_VECTOR ( 0 to 0 );
    winRmw : in STD_LOGIC_VECTOR ( 0 to 0 );
    gt_data_ready : in STD_LOGIC;
    winBuf : in STD_LOGIC_VECTOR ( 4 downto 0 );
    winRank : in STD_LOGIC_VECTOR ( 1 downto 0 );
    tCWL : out STD_LOGIC_VECTOR ( 5 downto 0 );
    dbg_bus : out STD_LOGIC_VECTOR ( 511 downto 0 )
  );

end phy_ddr4_udimm;

architecture stub of phy_ddr4_udimm is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "sys_rst,c0_sys_clk_p,c0_sys_clk_n,c0_ddr4_ui_clk,c0_ddr4_ui_clk_sync_rst,dbg_clk,c0_ddr4_act_n,c0_ddr4_adr[16:0],c0_ddr4_ba[1:0],c0_ddr4_bg[1:0],c0_ddr4_cke[0:0],c0_ddr4_odt[0:0],c0_ddr4_cs_n[0:0],c0_ddr4_ck_t[0:0],c0_ddr4_ck_c[0:0],c0_ddr4_reset_n,c0_ddr4_dm_dbi_n[7:0],c0_ddr4_dq[63:0],c0_ddr4_dqs_c[7:0],c0_ddr4_dqs_t[7:0],c0_init_calib_complete,dBufAdr[4:0],wrData[511:0],wrDataMask[63:0],rdData[511:0],rdDataAddr[4:0],rdDataEn[0:0],rdDataEnd[0:0],per_rd_done[0:0],rmw_rd_done[0:0],wrDataAddr[4:0],wrDataEn[0:0],mc_ACT_n[7:0],mc_ADR[135:0],mc_BA[15:0],mc_BG[15:0],mc_CKE[7:0],mc_CS_n[7:0],mc_ODT[7:0],mcCasSlot[1:0],mcCasSlot2[0:0],mcRdCAS[0:0],mcWrCAS[0:0],winInjTxn[0:0],winRmw[0:0],gt_data_ready,winBuf[4:0],winRank[1:0],tCWL[5:0],dbg_bus[511:0]";
attribute X_CORE_INFO : string;
attribute X_CORE_INFO of stub : architecture is "ddr4_v2_2_10,Vivado 2020.2";
begin
end;
