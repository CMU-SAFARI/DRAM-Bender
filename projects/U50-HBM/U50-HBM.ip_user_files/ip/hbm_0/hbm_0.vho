-- (c) Copyright 1995-2023 Xilinx, Inc. All rights reserved.
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

-- IP VLNV: xilinx.com:ip:hbm:1.0
-- IP Revision: 9

-- The following code must appear in the VHDL architecture header.

------------- Begin Cut here for COMPONENT Declaration ------ COMP_TAG
COMPONENT hbm_0
  PORT (
    HBM_REF_CLK_0 : IN STD_LOGIC;
    HBM_REF_CLK_1 : IN STD_LOGIC;
    dfi_0_clk : IN STD_LOGIC;
    dfi_0_rst_n : IN STD_LOGIC;
    dfi_0_init_start : IN STD_LOGIC;
    dfi_0_aw_ck_p0 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_0_aw_cke_p0 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_0_aw_row_p0 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    dfi_0_aw_col_p0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_0_dw_wrdata_p0 : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_0_dw_wrdata_mask_p0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_0_dw_wrdata_dbi_p0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_0_dw_wrdata_par_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_0_dw_wrdata_dq_en_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_0_dw_wrdata_par_en_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_0_aw_ck_p1 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_0_aw_cke_p1 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_0_aw_row_p1 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    dfi_0_aw_col_p1 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_0_dw_wrdata_p1 : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_0_dw_wrdata_mask_p1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_0_dw_wrdata_dbi_p1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_0_dw_wrdata_par_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_0_dw_wrdata_dq_en_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_0_dw_wrdata_par_en_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_0_aw_ck_dis : IN STD_LOGIC;
    dfi_0_lp_pwr_e_req : IN STD_LOGIC;
    dfi_0_lp_sr_e_req : IN STD_LOGIC;
    dfi_0_lp_pwr_x_req : IN STD_LOGIC;
    dfi_0_aw_tx_indx_ld : IN STD_LOGIC;
    dfi_0_dw_tx_indx_ld : IN STD_LOGIC;
    dfi_0_dw_rx_indx_ld : IN STD_LOGIC;
    dfi_0_ctrlupd_ack : IN STD_LOGIC;
    dfi_0_phyupd_req : IN STD_LOGIC;
    dfi_0_dw_wrdata_dqs_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_0_dw_wrdata_dqs_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_1_clk : IN STD_LOGIC;
    dfi_1_rst_n : IN STD_LOGIC;
    dfi_1_init_start : IN STD_LOGIC;
    dfi_1_aw_ck_p0 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_1_aw_cke_p0 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_1_aw_row_p0 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    dfi_1_aw_col_p0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_1_dw_wrdata_p0 : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_1_dw_wrdata_mask_p0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_1_dw_wrdata_dbi_p0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_1_dw_wrdata_par_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_1_dw_wrdata_dq_en_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_1_dw_wrdata_par_en_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_1_aw_ck_p1 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_1_aw_cke_p1 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_1_aw_row_p1 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    dfi_1_aw_col_p1 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_1_dw_wrdata_p1 : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_1_dw_wrdata_mask_p1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_1_dw_wrdata_dbi_p1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_1_dw_wrdata_par_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_1_dw_wrdata_dq_en_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_1_dw_wrdata_par_en_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_1_aw_ck_dis : IN STD_LOGIC;
    dfi_1_lp_pwr_e_req : IN STD_LOGIC;
    dfi_1_lp_sr_e_req : IN STD_LOGIC;
    dfi_1_lp_pwr_x_req : IN STD_LOGIC;
    dfi_1_aw_tx_indx_ld : IN STD_LOGIC;
    dfi_1_dw_tx_indx_ld : IN STD_LOGIC;
    dfi_1_dw_rx_indx_ld : IN STD_LOGIC;
    dfi_1_ctrlupd_ack : IN STD_LOGIC;
    dfi_1_phyupd_req : IN STD_LOGIC;
    dfi_1_dw_wrdata_dqs_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_1_dw_wrdata_dqs_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_2_clk : IN STD_LOGIC;
    dfi_2_rst_n : IN STD_LOGIC;
    dfi_2_init_start : IN STD_LOGIC;
    dfi_2_aw_ck_p0 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_2_aw_cke_p0 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_2_aw_row_p0 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    dfi_2_aw_col_p0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_2_dw_wrdata_p0 : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_2_dw_wrdata_mask_p0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_2_dw_wrdata_dbi_p0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_2_dw_wrdata_par_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_2_dw_wrdata_dq_en_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_2_dw_wrdata_par_en_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_2_aw_ck_p1 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_2_aw_cke_p1 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_2_aw_row_p1 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    dfi_2_aw_col_p1 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_2_dw_wrdata_p1 : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_2_dw_wrdata_mask_p1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_2_dw_wrdata_dbi_p1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_2_dw_wrdata_par_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_2_dw_wrdata_dq_en_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_2_dw_wrdata_par_en_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_2_aw_ck_dis : IN STD_LOGIC;
    dfi_2_lp_pwr_e_req : IN STD_LOGIC;
    dfi_2_lp_sr_e_req : IN STD_LOGIC;
    dfi_2_lp_pwr_x_req : IN STD_LOGIC;
    dfi_2_aw_tx_indx_ld : IN STD_LOGIC;
    dfi_2_dw_tx_indx_ld : IN STD_LOGIC;
    dfi_2_dw_rx_indx_ld : IN STD_LOGIC;
    dfi_2_ctrlupd_ack : IN STD_LOGIC;
    dfi_2_phyupd_req : IN STD_LOGIC;
    dfi_2_dw_wrdata_dqs_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_2_dw_wrdata_dqs_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_3_clk : IN STD_LOGIC;
    dfi_3_rst_n : IN STD_LOGIC;
    dfi_3_init_start : IN STD_LOGIC;
    dfi_3_aw_ck_p0 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_3_aw_cke_p0 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_3_aw_row_p0 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    dfi_3_aw_col_p0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_3_dw_wrdata_p0 : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_3_dw_wrdata_mask_p0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_3_dw_wrdata_dbi_p0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_3_dw_wrdata_par_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_3_dw_wrdata_dq_en_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_3_dw_wrdata_par_en_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_3_aw_ck_p1 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_3_aw_cke_p1 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_3_aw_row_p1 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    dfi_3_aw_col_p1 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_3_dw_wrdata_p1 : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_3_dw_wrdata_mask_p1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_3_dw_wrdata_dbi_p1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_3_dw_wrdata_par_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_3_dw_wrdata_dq_en_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_3_dw_wrdata_par_en_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_3_aw_ck_dis : IN STD_LOGIC;
    dfi_3_lp_pwr_e_req : IN STD_LOGIC;
    dfi_3_lp_sr_e_req : IN STD_LOGIC;
    dfi_3_lp_pwr_x_req : IN STD_LOGIC;
    dfi_3_aw_tx_indx_ld : IN STD_LOGIC;
    dfi_3_dw_tx_indx_ld : IN STD_LOGIC;
    dfi_3_dw_rx_indx_ld : IN STD_LOGIC;
    dfi_3_ctrlupd_ack : IN STD_LOGIC;
    dfi_3_phyupd_req : IN STD_LOGIC;
    dfi_3_dw_wrdata_dqs_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_3_dw_wrdata_dqs_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_4_clk : IN STD_LOGIC;
    dfi_4_rst_n : IN STD_LOGIC;
    dfi_4_init_start : IN STD_LOGIC;
    dfi_4_aw_ck_p0 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_4_aw_cke_p0 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_4_aw_row_p0 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    dfi_4_aw_col_p0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_4_dw_wrdata_p0 : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_4_dw_wrdata_mask_p0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_4_dw_wrdata_dbi_p0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_4_dw_wrdata_par_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_4_dw_wrdata_dq_en_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_4_dw_wrdata_par_en_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_4_aw_ck_p1 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_4_aw_cke_p1 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_4_aw_row_p1 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    dfi_4_aw_col_p1 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_4_dw_wrdata_p1 : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_4_dw_wrdata_mask_p1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_4_dw_wrdata_dbi_p1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_4_dw_wrdata_par_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_4_dw_wrdata_dq_en_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_4_dw_wrdata_par_en_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_4_aw_ck_dis : IN STD_LOGIC;
    dfi_4_lp_pwr_e_req : IN STD_LOGIC;
    dfi_4_lp_sr_e_req : IN STD_LOGIC;
    dfi_4_lp_pwr_x_req : IN STD_LOGIC;
    dfi_4_aw_tx_indx_ld : IN STD_LOGIC;
    dfi_4_dw_tx_indx_ld : IN STD_LOGIC;
    dfi_4_dw_rx_indx_ld : IN STD_LOGIC;
    dfi_4_ctrlupd_ack : IN STD_LOGIC;
    dfi_4_phyupd_req : IN STD_LOGIC;
    dfi_4_dw_wrdata_dqs_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_4_dw_wrdata_dqs_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_5_clk : IN STD_LOGIC;
    dfi_5_rst_n : IN STD_LOGIC;
    dfi_5_init_start : IN STD_LOGIC;
    dfi_5_aw_ck_p0 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_5_aw_cke_p0 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_5_aw_row_p0 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    dfi_5_aw_col_p0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_5_dw_wrdata_p0 : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_5_dw_wrdata_mask_p0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_5_dw_wrdata_dbi_p0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_5_dw_wrdata_par_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_5_dw_wrdata_dq_en_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_5_dw_wrdata_par_en_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_5_aw_ck_p1 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_5_aw_cke_p1 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_5_aw_row_p1 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    dfi_5_aw_col_p1 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_5_dw_wrdata_p1 : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_5_dw_wrdata_mask_p1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_5_dw_wrdata_dbi_p1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_5_dw_wrdata_par_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_5_dw_wrdata_dq_en_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_5_dw_wrdata_par_en_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_5_aw_ck_dis : IN STD_LOGIC;
    dfi_5_lp_pwr_e_req : IN STD_LOGIC;
    dfi_5_lp_sr_e_req : IN STD_LOGIC;
    dfi_5_lp_pwr_x_req : IN STD_LOGIC;
    dfi_5_aw_tx_indx_ld : IN STD_LOGIC;
    dfi_5_dw_tx_indx_ld : IN STD_LOGIC;
    dfi_5_dw_rx_indx_ld : IN STD_LOGIC;
    dfi_5_ctrlupd_ack : IN STD_LOGIC;
    dfi_5_phyupd_req : IN STD_LOGIC;
    dfi_5_dw_wrdata_dqs_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_5_dw_wrdata_dqs_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_6_clk : IN STD_LOGIC;
    dfi_6_rst_n : IN STD_LOGIC;
    dfi_6_init_start : IN STD_LOGIC;
    dfi_6_aw_ck_p0 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_6_aw_cke_p0 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_6_aw_row_p0 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    dfi_6_aw_col_p0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_6_dw_wrdata_p0 : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_6_dw_wrdata_mask_p0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_6_dw_wrdata_dbi_p0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_6_dw_wrdata_par_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_6_dw_wrdata_dq_en_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_6_dw_wrdata_par_en_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_6_aw_ck_p1 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_6_aw_cke_p1 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_6_aw_row_p1 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    dfi_6_aw_col_p1 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_6_dw_wrdata_p1 : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_6_dw_wrdata_mask_p1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_6_dw_wrdata_dbi_p1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_6_dw_wrdata_par_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_6_dw_wrdata_dq_en_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_6_dw_wrdata_par_en_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_6_aw_ck_dis : IN STD_LOGIC;
    dfi_6_lp_pwr_e_req : IN STD_LOGIC;
    dfi_6_lp_sr_e_req : IN STD_LOGIC;
    dfi_6_lp_pwr_x_req : IN STD_LOGIC;
    dfi_6_aw_tx_indx_ld : IN STD_LOGIC;
    dfi_6_dw_tx_indx_ld : IN STD_LOGIC;
    dfi_6_dw_rx_indx_ld : IN STD_LOGIC;
    dfi_6_ctrlupd_ack : IN STD_LOGIC;
    dfi_6_phyupd_req : IN STD_LOGIC;
    dfi_6_dw_wrdata_dqs_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_6_dw_wrdata_dqs_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_7_clk : IN STD_LOGIC;
    dfi_7_rst_n : IN STD_LOGIC;
    dfi_7_init_start : IN STD_LOGIC;
    dfi_7_aw_ck_p0 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_7_aw_cke_p0 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_7_aw_row_p0 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    dfi_7_aw_col_p0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_7_dw_wrdata_p0 : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_7_dw_wrdata_mask_p0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_7_dw_wrdata_dbi_p0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_7_dw_wrdata_par_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_7_dw_wrdata_dq_en_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_7_dw_wrdata_par_en_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_7_aw_ck_p1 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_7_aw_cke_p1 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_7_aw_row_p1 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    dfi_7_aw_col_p1 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_7_dw_wrdata_p1 : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_7_dw_wrdata_mask_p1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_7_dw_wrdata_dbi_p1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_7_dw_wrdata_par_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_7_dw_wrdata_dq_en_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_7_dw_wrdata_par_en_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_7_aw_ck_dis : IN STD_LOGIC;
    dfi_7_lp_pwr_e_req : IN STD_LOGIC;
    dfi_7_lp_sr_e_req : IN STD_LOGIC;
    dfi_7_lp_pwr_x_req : IN STD_LOGIC;
    dfi_7_aw_tx_indx_ld : IN STD_LOGIC;
    dfi_7_dw_tx_indx_ld : IN STD_LOGIC;
    dfi_7_dw_rx_indx_ld : IN STD_LOGIC;
    dfi_7_ctrlupd_ack : IN STD_LOGIC;
    dfi_7_phyupd_req : IN STD_LOGIC;
    dfi_7_dw_wrdata_dqs_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_7_dw_wrdata_dqs_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_8_clk : IN STD_LOGIC;
    dfi_8_rst_n : IN STD_LOGIC;
    dfi_8_init_start : IN STD_LOGIC;
    dfi_8_aw_ck_p0 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_8_aw_cke_p0 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_8_aw_row_p0 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    dfi_8_aw_col_p0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_8_dw_wrdata_p0 : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_8_dw_wrdata_mask_p0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_8_dw_wrdata_dbi_p0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_8_dw_wrdata_par_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_8_dw_wrdata_dq_en_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_8_dw_wrdata_par_en_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_8_aw_ck_p1 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_8_aw_cke_p1 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_8_aw_row_p1 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    dfi_8_aw_col_p1 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_8_dw_wrdata_p1 : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_8_dw_wrdata_mask_p1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_8_dw_wrdata_dbi_p1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_8_dw_wrdata_par_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_8_dw_wrdata_dq_en_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_8_dw_wrdata_par_en_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_8_aw_ck_dis : IN STD_LOGIC;
    dfi_8_lp_pwr_e_req : IN STD_LOGIC;
    dfi_8_lp_sr_e_req : IN STD_LOGIC;
    dfi_8_lp_pwr_x_req : IN STD_LOGIC;
    dfi_8_aw_tx_indx_ld : IN STD_LOGIC;
    dfi_8_dw_tx_indx_ld : IN STD_LOGIC;
    dfi_8_dw_rx_indx_ld : IN STD_LOGIC;
    dfi_8_ctrlupd_ack : IN STD_LOGIC;
    dfi_8_phyupd_req : IN STD_LOGIC;
    dfi_8_dw_wrdata_dqs_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_8_dw_wrdata_dqs_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_9_clk : IN STD_LOGIC;
    dfi_9_rst_n : IN STD_LOGIC;
    dfi_9_init_start : IN STD_LOGIC;
    dfi_9_aw_ck_p0 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_9_aw_cke_p0 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_9_aw_row_p0 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    dfi_9_aw_col_p0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_9_dw_wrdata_p0 : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_9_dw_wrdata_mask_p0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_9_dw_wrdata_dbi_p0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_9_dw_wrdata_par_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_9_dw_wrdata_dq_en_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_9_dw_wrdata_par_en_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_9_aw_ck_p1 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_9_aw_cke_p1 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_9_aw_row_p1 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    dfi_9_aw_col_p1 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_9_dw_wrdata_p1 : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_9_dw_wrdata_mask_p1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_9_dw_wrdata_dbi_p1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_9_dw_wrdata_par_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_9_dw_wrdata_dq_en_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_9_dw_wrdata_par_en_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_9_aw_ck_dis : IN STD_LOGIC;
    dfi_9_lp_pwr_e_req : IN STD_LOGIC;
    dfi_9_lp_sr_e_req : IN STD_LOGIC;
    dfi_9_lp_pwr_x_req : IN STD_LOGIC;
    dfi_9_aw_tx_indx_ld : IN STD_LOGIC;
    dfi_9_dw_tx_indx_ld : IN STD_LOGIC;
    dfi_9_dw_rx_indx_ld : IN STD_LOGIC;
    dfi_9_ctrlupd_ack : IN STD_LOGIC;
    dfi_9_phyupd_req : IN STD_LOGIC;
    dfi_9_dw_wrdata_dqs_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_9_dw_wrdata_dqs_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_10_clk : IN STD_LOGIC;
    dfi_10_rst_n : IN STD_LOGIC;
    dfi_10_init_start : IN STD_LOGIC;
    dfi_10_aw_ck_p0 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_10_aw_cke_p0 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_10_aw_row_p0 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    dfi_10_aw_col_p0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_10_dw_wrdata_p0 : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_10_dw_wrdata_mask_p0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_10_dw_wrdata_dbi_p0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_10_dw_wrdata_par_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_10_dw_wrdata_dq_en_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_10_dw_wrdata_par_en_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_10_aw_ck_p1 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_10_aw_cke_p1 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_10_aw_row_p1 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    dfi_10_aw_col_p1 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_10_dw_wrdata_p1 : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_10_dw_wrdata_mask_p1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_10_dw_wrdata_dbi_p1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_10_dw_wrdata_par_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_10_dw_wrdata_dq_en_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_10_dw_wrdata_par_en_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_10_aw_ck_dis : IN STD_LOGIC;
    dfi_10_lp_pwr_e_req : IN STD_LOGIC;
    dfi_10_lp_sr_e_req : IN STD_LOGIC;
    dfi_10_lp_pwr_x_req : IN STD_LOGIC;
    dfi_10_aw_tx_indx_ld : IN STD_LOGIC;
    dfi_10_dw_tx_indx_ld : IN STD_LOGIC;
    dfi_10_dw_rx_indx_ld : IN STD_LOGIC;
    dfi_10_ctrlupd_ack : IN STD_LOGIC;
    dfi_10_phyupd_req : IN STD_LOGIC;
    dfi_10_dw_wrdata_dqs_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_10_dw_wrdata_dqs_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_11_clk : IN STD_LOGIC;
    dfi_11_rst_n : IN STD_LOGIC;
    dfi_11_init_start : IN STD_LOGIC;
    dfi_11_aw_ck_p0 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_11_aw_cke_p0 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_11_aw_row_p0 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    dfi_11_aw_col_p0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_11_dw_wrdata_p0 : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_11_dw_wrdata_mask_p0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_11_dw_wrdata_dbi_p0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_11_dw_wrdata_par_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_11_dw_wrdata_dq_en_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_11_dw_wrdata_par_en_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_11_aw_ck_p1 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_11_aw_cke_p1 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_11_aw_row_p1 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    dfi_11_aw_col_p1 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_11_dw_wrdata_p1 : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_11_dw_wrdata_mask_p1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_11_dw_wrdata_dbi_p1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_11_dw_wrdata_par_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_11_dw_wrdata_dq_en_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_11_dw_wrdata_par_en_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_11_aw_ck_dis : IN STD_LOGIC;
    dfi_11_lp_pwr_e_req : IN STD_LOGIC;
    dfi_11_lp_sr_e_req : IN STD_LOGIC;
    dfi_11_lp_pwr_x_req : IN STD_LOGIC;
    dfi_11_aw_tx_indx_ld : IN STD_LOGIC;
    dfi_11_dw_tx_indx_ld : IN STD_LOGIC;
    dfi_11_dw_rx_indx_ld : IN STD_LOGIC;
    dfi_11_ctrlupd_ack : IN STD_LOGIC;
    dfi_11_phyupd_req : IN STD_LOGIC;
    dfi_11_dw_wrdata_dqs_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_11_dw_wrdata_dqs_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_12_clk : IN STD_LOGIC;
    dfi_12_rst_n : IN STD_LOGIC;
    dfi_12_init_start : IN STD_LOGIC;
    dfi_12_aw_ck_p0 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_12_aw_cke_p0 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_12_aw_row_p0 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    dfi_12_aw_col_p0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_12_dw_wrdata_p0 : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_12_dw_wrdata_mask_p0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_12_dw_wrdata_dbi_p0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_12_dw_wrdata_par_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_12_dw_wrdata_dq_en_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_12_dw_wrdata_par_en_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_12_aw_ck_p1 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_12_aw_cke_p1 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_12_aw_row_p1 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    dfi_12_aw_col_p1 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_12_dw_wrdata_p1 : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_12_dw_wrdata_mask_p1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_12_dw_wrdata_dbi_p1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_12_dw_wrdata_par_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_12_dw_wrdata_dq_en_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_12_dw_wrdata_par_en_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_12_aw_ck_dis : IN STD_LOGIC;
    dfi_12_lp_pwr_e_req : IN STD_LOGIC;
    dfi_12_lp_sr_e_req : IN STD_LOGIC;
    dfi_12_lp_pwr_x_req : IN STD_LOGIC;
    dfi_12_aw_tx_indx_ld : IN STD_LOGIC;
    dfi_12_dw_tx_indx_ld : IN STD_LOGIC;
    dfi_12_dw_rx_indx_ld : IN STD_LOGIC;
    dfi_12_ctrlupd_ack : IN STD_LOGIC;
    dfi_12_phyupd_req : IN STD_LOGIC;
    dfi_12_dw_wrdata_dqs_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_12_dw_wrdata_dqs_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_13_clk : IN STD_LOGIC;
    dfi_13_rst_n : IN STD_LOGIC;
    dfi_13_init_start : IN STD_LOGIC;
    dfi_13_aw_ck_p0 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_13_aw_cke_p0 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_13_aw_row_p0 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    dfi_13_aw_col_p0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_13_dw_wrdata_p0 : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_13_dw_wrdata_mask_p0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_13_dw_wrdata_dbi_p0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_13_dw_wrdata_par_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_13_dw_wrdata_dq_en_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_13_dw_wrdata_par_en_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_13_aw_ck_p1 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_13_aw_cke_p1 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_13_aw_row_p1 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    dfi_13_aw_col_p1 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_13_dw_wrdata_p1 : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_13_dw_wrdata_mask_p1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_13_dw_wrdata_dbi_p1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_13_dw_wrdata_par_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_13_dw_wrdata_dq_en_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_13_dw_wrdata_par_en_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_13_aw_ck_dis : IN STD_LOGIC;
    dfi_13_lp_pwr_e_req : IN STD_LOGIC;
    dfi_13_lp_sr_e_req : IN STD_LOGIC;
    dfi_13_lp_pwr_x_req : IN STD_LOGIC;
    dfi_13_aw_tx_indx_ld : IN STD_LOGIC;
    dfi_13_dw_tx_indx_ld : IN STD_LOGIC;
    dfi_13_dw_rx_indx_ld : IN STD_LOGIC;
    dfi_13_ctrlupd_ack : IN STD_LOGIC;
    dfi_13_phyupd_req : IN STD_LOGIC;
    dfi_13_dw_wrdata_dqs_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_13_dw_wrdata_dqs_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_14_clk : IN STD_LOGIC;
    dfi_14_rst_n : IN STD_LOGIC;
    dfi_14_init_start : IN STD_LOGIC;
    dfi_14_aw_ck_p0 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_14_aw_cke_p0 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_14_aw_row_p0 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    dfi_14_aw_col_p0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_14_dw_wrdata_p0 : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_14_dw_wrdata_mask_p0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_14_dw_wrdata_dbi_p0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_14_dw_wrdata_par_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_14_dw_wrdata_dq_en_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_14_dw_wrdata_par_en_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_14_aw_ck_p1 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_14_aw_cke_p1 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_14_aw_row_p1 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    dfi_14_aw_col_p1 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_14_dw_wrdata_p1 : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_14_dw_wrdata_mask_p1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_14_dw_wrdata_dbi_p1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_14_dw_wrdata_par_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_14_dw_wrdata_dq_en_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_14_dw_wrdata_par_en_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_14_aw_ck_dis : IN STD_LOGIC;
    dfi_14_lp_pwr_e_req : IN STD_LOGIC;
    dfi_14_lp_sr_e_req : IN STD_LOGIC;
    dfi_14_lp_pwr_x_req : IN STD_LOGIC;
    dfi_14_aw_tx_indx_ld : IN STD_LOGIC;
    dfi_14_dw_tx_indx_ld : IN STD_LOGIC;
    dfi_14_dw_rx_indx_ld : IN STD_LOGIC;
    dfi_14_ctrlupd_ack : IN STD_LOGIC;
    dfi_14_phyupd_req : IN STD_LOGIC;
    dfi_14_dw_wrdata_dqs_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_14_dw_wrdata_dqs_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_15_clk : IN STD_LOGIC;
    dfi_15_rst_n : IN STD_LOGIC;
    dfi_15_init_start : IN STD_LOGIC;
    dfi_15_aw_ck_p0 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_15_aw_cke_p0 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_15_aw_row_p0 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    dfi_15_aw_col_p0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_15_dw_wrdata_p0 : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_15_dw_wrdata_mask_p0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_15_dw_wrdata_dbi_p0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_15_dw_wrdata_par_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_15_dw_wrdata_dq_en_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_15_dw_wrdata_par_en_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_15_aw_ck_p1 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_15_aw_cke_p1 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_15_aw_row_p1 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    dfi_15_aw_col_p1 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_15_dw_wrdata_p1 : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_15_dw_wrdata_mask_p1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_15_dw_wrdata_dbi_p1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_15_dw_wrdata_par_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_15_dw_wrdata_dq_en_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_15_dw_wrdata_par_en_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_15_aw_ck_dis : IN STD_LOGIC;
    dfi_15_lp_pwr_e_req : IN STD_LOGIC;
    dfi_15_lp_sr_e_req : IN STD_LOGIC;
    dfi_15_lp_pwr_x_req : IN STD_LOGIC;
    dfi_15_aw_tx_indx_ld : IN STD_LOGIC;
    dfi_15_dw_tx_indx_ld : IN STD_LOGIC;
    dfi_15_dw_rx_indx_ld : IN STD_LOGIC;
    dfi_15_ctrlupd_ack : IN STD_LOGIC;
    dfi_15_phyupd_req : IN STD_LOGIC;
    dfi_15_dw_wrdata_dqs_p0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_15_dw_wrdata_dqs_p1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    APB_0_PCLK : IN STD_LOGIC;
    APB_0_PRESET_N : IN STD_LOGIC;
    APB_1_PCLK : IN STD_LOGIC;
    APB_1_PRESET_N : IN STD_LOGIC;
    dfi_0_dw_rddata_p0 : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_0_dw_rddata_dm_p0 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_0_dw_rddata_dbi_p0 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_0_dw_rddata_par_p0 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_0_dw_rddata_p1 : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_0_dw_rddata_dm_p1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_0_dw_rddata_dbi_p1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_0_dw_rddata_par_p1 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_0_dbi_byte_disable : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_0_dw_rddata_valid : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    dfi_0_dw_derr_n : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_0_aw_aerr_n : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_0_ctrlupd_req : OUT STD_LOGIC;
    dfi_0_phyupd_ack : OUT STD_LOGIC;
    dfi_0_clk_init : OUT STD_LOGIC;
    dfi_0_init_complete : OUT STD_LOGIC;
    dfi_0_out_rst_n : OUT STD_LOGIC;
    dfi_1_dw_rddata_p0 : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_1_dw_rddata_dm_p0 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_1_dw_rddata_dbi_p0 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_1_dw_rddata_par_p0 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_1_dw_rddata_p1 : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_1_dw_rddata_dm_p1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_1_dw_rddata_dbi_p1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_1_dw_rddata_par_p1 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_1_dbi_byte_disable : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_1_dw_rddata_valid : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    dfi_1_dw_derr_n : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_1_aw_aerr_n : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_1_ctrlupd_req : OUT STD_LOGIC;
    dfi_1_phyupd_ack : OUT STD_LOGIC;
    dfi_1_clk_init : OUT STD_LOGIC;
    dfi_1_init_complete : OUT STD_LOGIC;
    dfi_1_out_rst_n : OUT STD_LOGIC;
    dfi_2_dw_rddata_p0 : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_2_dw_rddata_dm_p0 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_2_dw_rddata_dbi_p0 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_2_dw_rddata_par_p0 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_2_dw_rddata_p1 : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_2_dw_rddata_dm_p1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_2_dw_rddata_dbi_p1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_2_dw_rddata_par_p1 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_2_dbi_byte_disable : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_2_dw_rddata_valid : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    dfi_2_dw_derr_n : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_2_aw_aerr_n : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_2_ctrlupd_req : OUT STD_LOGIC;
    dfi_2_phyupd_ack : OUT STD_LOGIC;
    dfi_2_clk_init : OUT STD_LOGIC;
    dfi_2_init_complete : OUT STD_LOGIC;
    dfi_2_out_rst_n : OUT STD_LOGIC;
    dfi_3_dw_rddata_p0 : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_3_dw_rddata_dm_p0 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_3_dw_rddata_dbi_p0 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_3_dw_rddata_par_p0 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_3_dw_rddata_p1 : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_3_dw_rddata_dm_p1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_3_dw_rddata_dbi_p1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_3_dw_rddata_par_p1 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_3_dbi_byte_disable : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_3_dw_rddata_valid : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    dfi_3_dw_derr_n : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_3_aw_aerr_n : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_3_ctrlupd_req : OUT STD_LOGIC;
    dfi_3_phyupd_ack : OUT STD_LOGIC;
    dfi_3_clk_init : OUT STD_LOGIC;
    dfi_3_init_complete : OUT STD_LOGIC;
    dfi_3_out_rst_n : OUT STD_LOGIC;
    dfi_4_dw_rddata_p0 : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_4_dw_rddata_dm_p0 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_4_dw_rddata_dbi_p0 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_4_dw_rddata_par_p0 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_4_dw_rddata_p1 : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_4_dw_rddata_dm_p1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_4_dw_rddata_dbi_p1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_4_dw_rddata_par_p1 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_4_dbi_byte_disable : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_4_dw_rddata_valid : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    dfi_4_dw_derr_n : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_4_aw_aerr_n : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_4_ctrlupd_req : OUT STD_LOGIC;
    dfi_4_phyupd_ack : OUT STD_LOGIC;
    dfi_4_clk_init : OUT STD_LOGIC;
    dfi_4_init_complete : OUT STD_LOGIC;
    dfi_4_out_rst_n : OUT STD_LOGIC;
    dfi_5_dw_rddata_p0 : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_5_dw_rddata_dm_p0 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_5_dw_rddata_dbi_p0 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_5_dw_rddata_par_p0 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_5_dw_rddata_p1 : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_5_dw_rddata_dm_p1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_5_dw_rddata_dbi_p1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_5_dw_rddata_par_p1 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_5_dbi_byte_disable : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_5_dw_rddata_valid : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    dfi_5_dw_derr_n : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_5_aw_aerr_n : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_5_ctrlupd_req : OUT STD_LOGIC;
    dfi_5_phyupd_ack : OUT STD_LOGIC;
    dfi_5_clk_init : OUT STD_LOGIC;
    dfi_5_init_complete : OUT STD_LOGIC;
    dfi_5_out_rst_n : OUT STD_LOGIC;
    dfi_6_dw_rddata_p0 : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_6_dw_rddata_dm_p0 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_6_dw_rddata_dbi_p0 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_6_dw_rddata_par_p0 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_6_dw_rddata_p1 : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_6_dw_rddata_dm_p1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_6_dw_rddata_dbi_p1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_6_dw_rddata_par_p1 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_6_dbi_byte_disable : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_6_dw_rddata_valid : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    dfi_6_dw_derr_n : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_6_aw_aerr_n : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_6_ctrlupd_req : OUT STD_LOGIC;
    dfi_6_phyupd_ack : OUT STD_LOGIC;
    dfi_6_clk_init : OUT STD_LOGIC;
    dfi_6_init_complete : OUT STD_LOGIC;
    dfi_6_out_rst_n : OUT STD_LOGIC;
    dfi_7_dw_rddata_p0 : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_7_dw_rddata_dm_p0 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_7_dw_rddata_dbi_p0 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_7_dw_rddata_par_p0 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_7_dw_rddata_p1 : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_7_dw_rddata_dm_p1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_7_dw_rddata_dbi_p1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_7_dw_rddata_par_p1 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_7_dbi_byte_disable : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_7_dw_rddata_valid : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    dfi_7_dw_derr_n : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_7_aw_aerr_n : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_7_ctrlupd_req : OUT STD_LOGIC;
    dfi_7_phyupd_ack : OUT STD_LOGIC;
    dfi_7_clk_init : OUT STD_LOGIC;
    dfi_7_init_complete : OUT STD_LOGIC;
    dfi_7_out_rst_n : OUT STD_LOGIC;
    dfi_8_dw_rddata_p0 : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_8_dw_rddata_dm_p0 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_8_dw_rddata_dbi_p0 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_8_dw_rddata_par_p0 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_8_dw_rddata_p1 : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_8_dw_rddata_dm_p1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_8_dw_rddata_dbi_p1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_8_dw_rddata_par_p1 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_8_dbi_byte_disable : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_8_dw_rddata_valid : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    dfi_8_dw_derr_n : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_8_aw_aerr_n : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_8_ctrlupd_req : OUT STD_LOGIC;
    dfi_8_phyupd_ack : OUT STD_LOGIC;
    dfi_8_clk_init : OUT STD_LOGIC;
    dfi_8_init_complete : OUT STD_LOGIC;
    dfi_8_out_rst_n : OUT STD_LOGIC;
    dfi_9_dw_rddata_p0 : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_9_dw_rddata_dm_p0 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_9_dw_rddata_dbi_p0 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_9_dw_rddata_par_p0 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_9_dw_rddata_p1 : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_9_dw_rddata_dm_p1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_9_dw_rddata_dbi_p1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_9_dw_rddata_par_p1 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_9_dbi_byte_disable : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_9_dw_rddata_valid : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    dfi_9_dw_derr_n : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_9_aw_aerr_n : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_9_ctrlupd_req : OUT STD_LOGIC;
    dfi_9_phyupd_ack : OUT STD_LOGIC;
    dfi_9_clk_init : OUT STD_LOGIC;
    dfi_9_init_complete : OUT STD_LOGIC;
    dfi_9_out_rst_n : OUT STD_LOGIC;
    dfi_10_dw_rddata_p0 : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_10_dw_rddata_dm_p0 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_10_dw_rddata_dbi_p0 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_10_dw_rddata_par_p0 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_10_dw_rddata_p1 : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_10_dw_rddata_dm_p1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_10_dw_rddata_dbi_p1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_10_dw_rddata_par_p1 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_10_dbi_byte_disable : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_10_dw_rddata_valid : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    dfi_10_dw_derr_n : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_10_aw_aerr_n : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_10_ctrlupd_req : OUT STD_LOGIC;
    dfi_10_phyupd_ack : OUT STD_LOGIC;
    dfi_10_clk_init : OUT STD_LOGIC;
    dfi_10_init_complete : OUT STD_LOGIC;
    dfi_10_out_rst_n : OUT STD_LOGIC;
    dfi_11_dw_rddata_p0 : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_11_dw_rddata_dm_p0 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_11_dw_rddata_dbi_p0 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_11_dw_rddata_par_p0 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_11_dw_rddata_p1 : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_11_dw_rddata_dm_p1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_11_dw_rddata_dbi_p1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_11_dw_rddata_par_p1 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_11_dbi_byte_disable : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_11_dw_rddata_valid : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    dfi_11_dw_derr_n : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_11_aw_aerr_n : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_11_ctrlupd_req : OUT STD_LOGIC;
    dfi_11_phyupd_ack : OUT STD_LOGIC;
    dfi_11_clk_init : OUT STD_LOGIC;
    dfi_11_init_complete : OUT STD_LOGIC;
    dfi_11_out_rst_n : OUT STD_LOGIC;
    dfi_12_dw_rddata_p0 : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_12_dw_rddata_dm_p0 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_12_dw_rddata_dbi_p0 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_12_dw_rddata_par_p0 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_12_dw_rddata_p1 : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_12_dw_rddata_dm_p1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_12_dw_rddata_dbi_p1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_12_dw_rddata_par_p1 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_12_dbi_byte_disable : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_12_dw_rddata_valid : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    dfi_12_dw_derr_n : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_12_aw_aerr_n : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_12_ctrlupd_req : OUT STD_LOGIC;
    dfi_12_phyupd_ack : OUT STD_LOGIC;
    dfi_12_clk_init : OUT STD_LOGIC;
    dfi_12_init_complete : OUT STD_LOGIC;
    dfi_12_out_rst_n : OUT STD_LOGIC;
    dfi_13_dw_rddata_p0 : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_13_dw_rddata_dm_p0 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_13_dw_rddata_dbi_p0 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_13_dw_rddata_par_p0 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_13_dw_rddata_p1 : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_13_dw_rddata_dm_p1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_13_dw_rddata_dbi_p1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_13_dw_rddata_par_p1 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_13_dbi_byte_disable : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_13_dw_rddata_valid : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    dfi_13_dw_derr_n : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_13_aw_aerr_n : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_13_ctrlupd_req : OUT STD_LOGIC;
    dfi_13_phyupd_ack : OUT STD_LOGIC;
    dfi_13_clk_init : OUT STD_LOGIC;
    dfi_13_init_complete : OUT STD_LOGIC;
    dfi_13_out_rst_n : OUT STD_LOGIC;
    dfi_14_dw_rddata_p0 : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_14_dw_rddata_dm_p0 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_14_dw_rddata_dbi_p0 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_14_dw_rddata_par_p0 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_14_dw_rddata_p1 : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_14_dw_rddata_dm_p1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_14_dw_rddata_dbi_p1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_14_dw_rddata_par_p1 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_14_dbi_byte_disable : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_14_dw_rddata_valid : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    dfi_14_dw_derr_n : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_14_aw_aerr_n : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_14_ctrlupd_req : OUT STD_LOGIC;
    dfi_14_phyupd_ack : OUT STD_LOGIC;
    dfi_14_clk_init : OUT STD_LOGIC;
    dfi_14_init_complete : OUT STD_LOGIC;
    dfi_14_out_rst_n : OUT STD_LOGIC;
    dfi_15_dw_rddata_p0 : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_15_dw_rddata_dm_p0 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_15_dw_rddata_dbi_p0 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_15_dw_rddata_par_p0 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_15_dw_rddata_p1 : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
    dfi_15_dw_rddata_dm_p1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_15_dw_rddata_dbi_p1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    dfi_15_dw_rddata_par_p1 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_15_dbi_byte_disable : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    dfi_15_dw_rddata_valid : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    dfi_15_dw_derr_n : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    dfi_15_aw_aerr_n : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    dfi_15_ctrlupd_req : OUT STD_LOGIC;
    dfi_15_phyupd_ack : OUT STD_LOGIC;
    dfi_15_clk_init : OUT STD_LOGIC;
    dfi_15_init_complete : OUT STD_LOGIC;
    dfi_15_out_rst_n : OUT STD_LOGIC;
    apb_complete_0 : OUT STD_LOGIC;
    apb_complete_1 : OUT STD_LOGIC;
    DRAM_0_STAT_CATTRIP : OUT STD_LOGIC;
    DRAM_0_STAT_TEMP : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
    DRAM_1_STAT_CATTRIP : OUT STD_LOGIC;
    DRAM_1_STAT_TEMP : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
  );
END COMPONENT;
-- COMP_TAG_END ------ End COMPONENT Declaration ------------

-- The following code must appear in the VHDL architecture
-- body. Substitute your own instance name and net names.

------------- Begin Cut here for INSTANTIATION Template ----- INST_TAG
your_instance_name : hbm_0
  PORT MAP (
    HBM_REF_CLK_0 => HBM_REF_CLK_0,
    HBM_REF_CLK_1 => HBM_REF_CLK_1,
    dfi_0_clk => dfi_0_clk,
    dfi_0_rst_n => dfi_0_rst_n,
    dfi_0_init_start => dfi_0_init_start,
    dfi_0_aw_ck_p0 => dfi_0_aw_ck_p0,
    dfi_0_aw_cke_p0 => dfi_0_aw_cke_p0,
    dfi_0_aw_row_p0 => dfi_0_aw_row_p0,
    dfi_0_aw_col_p0 => dfi_0_aw_col_p0,
    dfi_0_dw_wrdata_p0 => dfi_0_dw_wrdata_p0,
    dfi_0_dw_wrdata_mask_p0 => dfi_0_dw_wrdata_mask_p0,
    dfi_0_dw_wrdata_dbi_p0 => dfi_0_dw_wrdata_dbi_p0,
    dfi_0_dw_wrdata_par_p0 => dfi_0_dw_wrdata_par_p0,
    dfi_0_dw_wrdata_dq_en_p0 => dfi_0_dw_wrdata_dq_en_p0,
    dfi_0_dw_wrdata_par_en_p0 => dfi_0_dw_wrdata_par_en_p0,
    dfi_0_aw_ck_p1 => dfi_0_aw_ck_p1,
    dfi_0_aw_cke_p1 => dfi_0_aw_cke_p1,
    dfi_0_aw_row_p1 => dfi_0_aw_row_p1,
    dfi_0_aw_col_p1 => dfi_0_aw_col_p1,
    dfi_0_dw_wrdata_p1 => dfi_0_dw_wrdata_p1,
    dfi_0_dw_wrdata_mask_p1 => dfi_0_dw_wrdata_mask_p1,
    dfi_0_dw_wrdata_dbi_p1 => dfi_0_dw_wrdata_dbi_p1,
    dfi_0_dw_wrdata_par_p1 => dfi_0_dw_wrdata_par_p1,
    dfi_0_dw_wrdata_dq_en_p1 => dfi_0_dw_wrdata_dq_en_p1,
    dfi_0_dw_wrdata_par_en_p1 => dfi_0_dw_wrdata_par_en_p1,
    dfi_0_aw_ck_dis => dfi_0_aw_ck_dis,
    dfi_0_lp_pwr_e_req => dfi_0_lp_pwr_e_req,
    dfi_0_lp_sr_e_req => dfi_0_lp_sr_e_req,
    dfi_0_lp_pwr_x_req => dfi_0_lp_pwr_x_req,
    dfi_0_aw_tx_indx_ld => dfi_0_aw_tx_indx_ld,
    dfi_0_dw_tx_indx_ld => dfi_0_dw_tx_indx_ld,
    dfi_0_dw_rx_indx_ld => dfi_0_dw_rx_indx_ld,
    dfi_0_ctrlupd_ack => dfi_0_ctrlupd_ack,
    dfi_0_phyupd_req => dfi_0_phyupd_req,
    dfi_0_dw_wrdata_dqs_p0 => dfi_0_dw_wrdata_dqs_p0,
    dfi_0_dw_wrdata_dqs_p1 => dfi_0_dw_wrdata_dqs_p1,
    dfi_1_clk => dfi_1_clk,
    dfi_1_rst_n => dfi_1_rst_n,
    dfi_1_init_start => dfi_1_init_start,
    dfi_1_aw_ck_p0 => dfi_1_aw_ck_p0,
    dfi_1_aw_cke_p0 => dfi_1_aw_cke_p0,
    dfi_1_aw_row_p0 => dfi_1_aw_row_p0,
    dfi_1_aw_col_p0 => dfi_1_aw_col_p0,
    dfi_1_dw_wrdata_p0 => dfi_1_dw_wrdata_p0,
    dfi_1_dw_wrdata_mask_p0 => dfi_1_dw_wrdata_mask_p0,
    dfi_1_dw_wrdata_dbi_p0 => dfi_1_dw_wrdata_dbi_p0,
    dfi_1_dw_wrdata_par_p0 => dfi_1_dw_wrdata_par_p0,
    dfi_1_dw_wrdata_dq_en_p0 => dfi_1_dw_wrdata_dq_en_p0,
    dfi_1_dw_wrdata_par_en_p0 => dfi_1_dw_wrdata_par_en_p0,
    dfi_1_aw_ck_p1 => dfi_1_aw_ck_p1,
    dfi_1_aw_cke_p1 => dfi_1_aw_cke_p1,
    dfi_1_aw_row_p1 => dfi_1_aw_row_p1,
    dfi_1_aw_col_p1 => dfi_1_aw_col_p1,
    dfi_1_dw_wrdata_p1 => dfi_1_dw_wrdata_p1,
    dfi_1_dw_wrdata_mask_p1 => dfi_1_dw_wrdata_mask_p1,
    dfi_1_dw_wrdata_dbi_p1 => dfi_1_dw_wrdata_dbi_p1,
    dfi_1_dw_wrdata_par_p1 => dfi_1_dw_wrdata_par_p1,
    dfi_1_dw_wrdata_dq_en_p1 => dfi_1_dw_wrdata_dq_en_p1,
    dfi_1_dw_wrdata_par_en_p1 => dfi_1_dw_wrdata_par_en_p1,
    dfi_1_aw_ck_dis => dfi_1_aw_ck_dis,
    dfi_1_lp_pwr_e_req => dfi_1_lp_pwr_e_req,
    dfi_1_lp_sr_e_req => dfi_1_lp_sr_e_req,
    dfi_1_lp_pwr_x_req => dfi_1_lp_pwr_x_req,
    dfi_1_aw_tx_indx_ld => dfi_1_aw_tx_indx_ld,
    dfi_1_dw_tx_indx_ld => dfi_1_dw_tx_indx_ld,
    dfi_1_dw_rx_indx_ld => dfi_1_dw_rx_indx_ld,
    dfi_1_ctrlupd_ack => dfi_1_ctrlupd_ack,
    dfi_1_phyupd_req => dfi_1_phyupd_req,
    dfi_1_dw_wrdata_dqs_p0 => dfi_1_dw_wrdata_dqs_p0,
    dfi_1_dw_wrdata_dqs_p1 => dfi_1_dw_wrdata_dqs_p1,
    dfi_2_clk => dfi_2_clk,
    dfi_2_rst_n => dfi_2_rst_n,
    dfi_2_init_start => dfi_2_init_start,
    dfi_2_aw_ck_p0 => dfi_2_aw_ck_p0,
    dfi_2_aw_cke_p0 => dfi_2_aw_cke_p0,
    dfi_2_aw_row_p0 => dfi_2_aw_row_p0,
    dfi_2_aw_col_p0 => dfi_2_aw_col_p0,
    dfi_2_dw_wrdata_p0 => dfi_2_dw_wrdata_p0,
    dfi_2_dw_wrdata_mask_p0 => dfi_2_dw_wrdata_mask_p0,
    dfi_2_dw_wrdata_dbi_p0 => dfi_2_dw_wrdata_dbi_p0,
    dfi_2_dw_wrdata_par_p0 => dfi_2_dw_wrdata_par_p0,
    dfi_2_dw_wrdata_dq_en_p0 => dfi_2_dw_wrdata_dq_en_p0,
    dfi_2_dw_wrdata_par_en_p0 => dfi_2_dw_wrdata_par_en_p0,
    dfi_2_aw_ck_p1 => dfi_2_aw_ck_p1,
    dfi_2_aw_cke_p1 => dfi_2_aw_cke_p1,
    dfi_2_aw_row_p1 => dfi_2_aw_row_p1,
    dfi_2_aw_col_p1 => dfi_2_aw_col_p1,
    dfi_2_dw_wrdata_p1 => dfi_2_dw_wrdata_p1,
    dfi_2_dw_wrdata_mask_p1 => dfi_2_dw_wrdata_mask_p1,
    dfi_2_dw_wrdata_dbi_p1 => dfi_2_dw_wrdata_dbi_p1,
    dfi_2_dw_wrdata_par_p1 => dfi_2_dw_wrdata_par_p1,
    dfi_2_dw_wrdata_dq_en_p1 => dfi_2_dw_wrdata_dq_en_p1,
    dfi_2_dw_wrdata_par_en_p1 => dfi_2_dw_wrdata_par_en_p1,
    dfi_2_aw_ck_dis => dfi_2_aw_ck_dis,
    dfi_2_lp_pwr_e_req => dfi_2_lp_pwr_e_req,
    dfi_2_lp_sr_e_req => dfi_2_lp_sr_e_req,
    dfi_2_lp_pwr_x_req => dfi_2_lp_pwr_x_req,
    dfi_2_aw_tx_indx_ld => dfi_2_aw_tx_indx_ld,
    dfi_2_dw_tx_indx_ld => dfi_2_dw_tx_indx_ld,
    dfi_2_dw_rx_indx_ld => dfi_2_dw_rx_indx_ld,
    dfi_2_ctrlupd_ack => dfi_2_ctrlupd_ack,
    dfi_2_phyupd_req => dfi_2_phyupd_req,
    dfi_2_dw_wrdata_dqs_p0 => dfi_2_dw_wrdata_dqs_p0,
    dfi_2_dw_wrdata_dqs_p1 => dfi_2_dw_wrdata_dqs_p1,
    dfi_3_clk => dfi_3_clk,
    dfi_3_rst_n => dfi_3_rst_n,
    dfi_3_init_start => dfi_3_init_start,
    dfi_3_aw_ck_p0 => dfi_3_aw_ck_p0,
    dfi_3_aw_cke_p0 => dfi_3_aw_cke_p0,
    dfi_3_aw_row_p0 => dfi_3_aw_row_p0,
    dfi_3_aw_col_p0 => dfi_3_aw_col_p0,
    dfi_3_dw_wrdata_p0 => dfi_3_dw_wrdata_p0,
    dfi_3_dw_wrdata_mask_p0 => dfi_3_dw_wrdata_mask_p0,
    dfi_3_dw_wrdata_dbi_p0 => dfi_3_dw_wrdata_dbi_p0,
    dfi_3_dw_wrdata_par_p0 => dfi_3_dw_wrdata_par_p0,
    dfi_3_dw_wrdata_dq_en_p0 => dfi_3_dw_wrdata_dq_en_p0,
    dfi_3_dw_wrdata_par_en_p0 => dfi_3_dw_wrdata_par_en_p0,
    dfi_3_aw_ck_p1 => dfi_3_aw_ck_p1,
    dfi_3_aw_cke_p1 => dfi_3_aw_cke_p1,
    dfi_3_aw_row_p1 => dfi_3_aw_row_p1,
    dfi_3_aw_col_p1 => dfi_3_aw_col_p1,
    dfi_3_dw_wrdata_p1 => dfi_3_dw_wrdata_p1,
    dfi_3_dw_wrdata_mask_p1 => dfi_3_dw_wrdata_mask_p1,
    dfi_3_dw_wrdata_dbi_p1 => dfi_3_dw_wrdata_dbi_p1,
    dfi_3_dw_wrdata_par_p1 => dfi_3_dw_wrdata_par_p1,
    dfi_3_dw_wrdata_dq_en_p1 => dfi_3_dw_wrdata_dq_en_p1,
    dfi_3_dw_wrdata_par_en_p1 => dfi_3_dw_wrdata_par_en_p1,
    dfi_3_aw_ck_dis => dfi_3_aw_ck_dis,
    dfi_3_lp_pwr_e_req => dfi_3_lp_pwr_e_req,
    dfi_3_lp_sr_e_req => dfi_3_lp_sr_e_req,
    dfi_3_lp_pwr_x_req => dfi_3_lp_pwr_x_req,
    dfi_3_aw_tx_indx_ld => dfi_3_aw_tx_indx_ld,
    dfi_3_dw_tx_indx_ld => dfi_3_dw_tx_indx_ld,
    dfi_3_dw_rx_indx_ld => dfi_3_dw_rx_indx_ld,
    dfi_3_ctrlupd_ack => dfi_3_ctrlupd_ack,
    dfi_3_phyupd_req => dfi_3_phyupd_req,
    dfi_3_dw_wrdata_dqs_p0 => dfi_3_dw_wrdata_dqs_p0,
    dfi_3_dw_wrdata_dqs_p1 => dfi_3_dw_wrdata_dqs_p1,
    dfi_4_clk => dfi_4_clk,
    dfi_4_rst_n => dfi_4_rst_n,
    dfi_4_init_start => dfi_4_init_start,
    dfi_4_aw_ck_p0 => dfi_4_aw_ck_p0,
    dfi_4_aw_cke_p0 => dfi_4_aw_cke_p0,
    dfi_4_aw_row_p0 => dfi_4_aw_row_p0,
    dfi_4_aw_col_p0 => dfi_4_aw_col_p0,
    dfi_4_dw_wrdata_p0 => dfi_4_dw_wrdata_p0,
    dfi_4_dw_wrdata_mask_p0 => dfi_4_dw_wrdata_mask_p0,
    dfi_4_dw_wrdata_dbi_p0 => dfi_4_dw_wrdata_dbi_p0,
    dfi_4_dw_wrdata_par_p0 => dfi_4_dw_wrdata_par_p0,
    dfi_4_dw_wrdata_dq_en_p0 => dfi_4_dw_wrdata_dq_en_p0,
    dfi_4_dw_wrdata_par_en_p0 => dfi_4_dw_wrdata_par_en_p0,
    dfi_4_aw_ck_p1 => dfi_4_aw_ck_p1,
    dfi_4_aw_cke_p1 => dfi_4_aw_cke_p1,
    dfi_4_aw_row_p1 => dfi_4_aw_row_p1,
    dfi_4_aw_col_p1 => dfi_4_aw_col_p1,
    dfi_4_dw_wrdata_p1 => dfi_4_dw_wrdata_p1,
    dfi_4_dw_wrdata_mask_p1 => dfi_4_dw_wrdata_mask_p1,
    dfi_4_dw_wrdata_dbi_p1 => dfi_4_dw_wrdata_dbi_p1,
    dfi_4_dw_wrdata_par_p1 => dfi_4_dw_wrdata_par_p1,
    dfi_4_dw_wrdata_dq_en_p1 => dfi_4_dw_wrdata_dq_en_p1,
    dfi_4_dw_wrdata_par_en_p1 => dfi_4_dw_wrdata_par_en_p1,
    dfi_4_aw_ck_dis => dfi_4_aw_ck_dis,
    dfi_4_lp_pwr_e_req => dfi_4_lp_pwr_e_req,
    dfi_4_lp_sr_e_req => dfi_4_lp_sr_e_req,
    dfi_4_lp_pwr_x_req => dfi_4_lp_pwr_x_req,
    dfi_4_aw_tx_indx_ld => dfi_4_aw_tx_indx_ld,
    dfi_4_dw_tx_indx_ld => dfi_4_dw_tx_indx_ld,
    dfi_4_dw_rx_indx_ld => dfi_4_dw_rx_indx_ld,
    dfi_4_ctrlupd_ack => dfi_4_ctrlupd_ack,
    dfi_4_phyupd_req => dfi_4_phyupd_req,
    dfi_4_dw_wrdata_dqs_p0 => dfi_4_dw_wrdata_dqs_p0,
    dfi_4_dw_wrdata_dqs_p1 => dfi_4_dw_wrdata_dqs_p1,
    dfi_5_clk => dfi_5_clk,
    dfi_5_rst_n => dfi_5_rst_n,
    dfi_5_init_start => dfi_5_init_start,
    dfi_5_aw_ck_p0 => dfi_5_aw_ck_p0,
    dfi_5_aw_cke_p0 => dfi_5_aw_cke_p0,
    dfi_5_aw_row_p0 => dfi_5_aw_row_p0,
    dfi_5_aw_col_p0 => dfi_5_aw_col_p0,
    dfi_5_dw_wrdata_p0 => dfi_5_dw_wrdata_p0,
    dfi_5_dw_wrdata_mask_p0 => dfi_5_dw_wrdata_mask_p0,
    dfi_5_dw_wrdata_dbi_p0 => dfi_5_dw_wrdata_dbi_p0,
    dfi_5_dw_wrdata_par_p0 => dfi_5_dw_wrdata_par_p0,
    dfi_5_dw_wrdata_dq_en_p0 => dfi_5_dw_wrdata_dq_en_p0,
    dfi_5_dw_wrdata_par_en_p0 => dfi_5_dw_wrdata_par_en_p0,
    dfi_5_aw_ck_p1 => dfi_5_aw_ck_p1,
    dfi_5_aw_cke_p1 => dfi_5_aw_cke_p1,
    dfi_5_aw_row_p1 => dfi_5_aw_row_p1,
    dfi_5_aw_col_p1 => dfi_5_aw_col_p1,
    dfi_5_dw_wrdata_p1 => dfi_5_dw_wrdata_p1,
    dfi_5_dw_wrdata_mask_p1 => dfi_5_dw_wrdata_mask_p1,
    dfi_5_dw_wrdata_dbi_p1 => dfi_5_dw_wrdata_dbi_p1,
    dfi_5_dw_wrdata_par_p1 => dfi_5_dw_wrdata_par_p1,
    dfi_5_dw_wrdata_dq_en_p1 => dfi_5_dw_wrdata_dq_en_p1,
    dfi_5_dw_wrdata_par_en_p1 => dfi_5_dw_wrdata_par_en_p1,
    dfi_5_aw_ck_dis => dfi_5_aw_ck_dis,
    dfi_5_lp_pwr_e_req => dfi_5_lp_pwr_e_req,
    dfi_5_lp_sr_e_req => dfi_5_lp_sr_e_req,
    dfi_5_lp_pwr_x_req => dfi_5_lp_pwr_x_req,
    dfi_5_aw_tx_indx_ld => dfi_5_aw_tx_indx_ld,
    dfi_5_dw_tx_indx_ld => dfi_5_dw_tx_indx_ld,
    dfi_5_dw_rx_indx_ld => dfi_5_dw_rx_indx_ld,
    dfi_5_ctrlupd_ack => dfi_5_ctrlupd_ack,
    dfi_5_phyupd_req => dfi_5_phyupd_req,
    dfi_5_dw_wrdata_dqs_p0 => dfi_5_dw_wrdata_dqs_p0,
    dfi_5_dw_wrdata_dqs_p1 => dfi_5_dw_wrdata_dqs_p1,
    dfi_6_clk => dfi_6_clk,
    dfi_6_rst_n => dfi_6_rst_n,
    dfi_6_init_start => dfi_6_init_start,
    dfi_6_aw_ck_p0 => dfi_6_aw_ck_p0,
    dfi_6_aw_cke_p0 => dfi_6_aw_cke_p0,
    dfi_6_aw_row_p0 => dfi_6_aw_row_p0,
    dfi_6_aw_col_p0 => dfi_6_aw_col_p0,
    dfi_6_dw_wrdata_p0 => dfi_6_dw_wrdata_p0,
    dfi_6_dw_wrdata_mask_p0 => dfi_6_dw_wrdata_mask_p0,
    dfi_6_dw_wrdata_dbi_p0 => dfi_6_dw_wrdata_dbi_p0,
    dfi_6_dw_wrdata_par_p0 => dfi_6_dw_wrdata_par_p0,
    dfi_6_dw_wrdata_dq_en_p0 => dfi_6_dw_wrdata_dq_en_p0,
    dfi_6_dw_wrdata_par_en_p0 => dfi_6_dw_wrdata_par_en_p0,
    dfi_6_aw_ck_p1 => dfi_6_aw_ck_p1,
    dfi_6_aw_cke_p1 => dfi_6_aw_cke_p1,
    dfi_6_aw_row_p1 => dfi_6_aw_row_p1,
    dfi_6_aw_col_p1 => dfi_6_aw_col_p1,
    dfi_6_dw_wrdata_p1 => dfi_6_dw_wrdata_p1,
    dfi_6_dw_wrdata_mask_p1 => dfi_6_dw_wrdata_mask_p1,
    dfi_6_dw_wrdata_dbi_p1 => dfi_6_dw_wrdata_dbi_p1,
    dfi_6_dw_wrdata_par_p1 => dfi_6_dw_wrdata_par_p1,
    dfi_6_dw_wrdata_dq_en_p1 => dfi_6_dw_wrdata_dq_en_p1,
    dfi_6_dw_wrdata_par_en_p1 => dfi_6_dw_wrdata_par_en_p1,
    dfi_6_aw_ck_dis => dfi_6_aw_ck_dis,
    dfi_6_lp_pwr_e_req => dfi_6_lp_pwr_e_req,
    dfi_6_lp_sr_e_req => dfi_6_lp_sr_e_req,
    dfi_6_lp_pwr_x_req => dfi_6_lp_pwr_x_req,
    dfi_6_aw_tx_indx_ld => dfi_6_aw_tx_indx_ld,
    dfi_6_dw_tx_indx_ld => dfi_6_dw_tx_indx_ld,
    dfi_6_dw_rx_indx_ld => dfi_6_dw_rx_indx_ld,
    dfi_6_ctrlupd_ack => dfi_6_ctrlupd_ack,
    dfi_6_phyupd_req => dfi_6_phyupd_req,
    dfi_6_dw_wrdata_dqs_p0 => dfi_6_dw_wrdata_dqs_p0,
    dfi_6_dw_wrdata_dqs_p1 => dfi_6_dw_wrdata_dqs_p1,
    dfi_7_clk => dfi_7_clk,
    dfi_7_rst_n => dfi_7_rst_n,
    dfi_7_init_start => dfi_7_init_start,
    dfi_7_aw_ck_p0 => dfi_7_aw_ck_p0,
    dfi_7_aw_cke_p0 => dfi_7_aw_cke_p0,
    dfi_7_aw_row_p0 => dfi_7_aw_row_p0,
    dfi_7_aw_col_p0 => dfi_7_aw_col_p0,
    dfi_7_dw_wrdata_p0 => dfi_7_dw_wrdata_p0,
    dfi_7_dw_wrdata_mask_p0 => dfi_7_dw_wrdata_mask_p0,
    dfi_7_dw_wrdata_dbi_p0 => dfi_7_dw_wrdata_dbi_p0,
    dfi_7_dw_wrdata_par_p0 => dfi_7_dw_wrdata_par_p0,
    dfi_7_dw_wrdata_dq_en_p0 => dfi_7_dw_wrdata_dq_en_p0,
    dfi_7_dw_wrdata_par_en_p0 => dfi_7_dw_wrdata_par_en_p0,
    dfi_7_aw_ck_p1 => dfi_7_aw_ck_p1,
    dfi_7_aw_cke_p1 => dfi_7_aw_cke_p1,
    dfi_7_aw_row_p1 => dfi_7_aw_row_p1,
    dfi_7_aw_col_p1 => dfi_7_aw_col_p1,
    dfi_7_dw_wrdata_p1 => dfi_7_dw_wrdata_p1,
    dfi_7_dw_wrdata_mask_p1 => dfi_7_dw_wrdata_mask_p1,
    dfi_7_dw_wrdata_dbi_p1 => dfi_7_dw_wrdata_dbi_p1,
    dfi_7_dw_wrdata_par_p1 => dfi_7_dw_wrdata_par_p1,
    dfi_7_dw_wrdata_dq_en_p1 => dfi_7_dw_wrdata_dq_en_p1,
    dfi_7_dw_wrdata_par_en_p1 => dfi_7_dw_wrdata_par_en_p1,
    dfi_7_aw_ck_dis => dfi_7_aw_ck_dis,
    dfi_7_lp_pwr_e_req => dfi_7_lp_pwr_e_req,
    dfi_7_lp_sr_e_req => dfi_7_lp_sr_e_req,
    dfi_7_lp_pwr_x_req => dfi_7_lp_pwr_x_req,
    dfi_7_aw_tx_indx_ld => dfi_7_aw_tx_indx_ld,
    dfi_7_dw_tx_indx_ld => dfi_7_dw_tx_indx_ld,
    dfi_7_dw_rx_indx_ld => dfi_7_dw_rx_indx_ld,
    dfi_7_ctrlupd_ack => dfi_7_ctrlupd_ack,
    dfi_7_phyupd_req => dfi_7_phyupd_req,
    dfi_7_dw_wrdata_dqs_p0 => dfi_7_dw_wrdata_dqs_p0,
    dfi_7_dw_wrdata_dqs_p1 => dfi_7_dw_wrdata_dqs_p1,
    dfi_8_clk => dfi_8_clk,
    dfi_8_rst_n => dfi_8_rst_n,
    dfi_8_init_start => dfi_8_init_start,
    dfi_8_aw_ck_p0 => dfi_8_aw_ck_p0,
    dfi_8_aw_cke_p0 => dfi_8_aw_cke_p0,
    dfi_8_aw_row_p0 => dfi_8_aw_row_p0,
    dfi_8_aw_col_p0 => dfi_8_aw_col_p0,
    dfi_8_dw_wrdata_p0 => dfi_8_dw_wrdata_p0,
    dfi_8_dw_wrdata_mask_p0 => dfi_8_dw_wrdata_mask_p0,
    dfi_8_dw_wrdata_dbi_p0 => dfi_8_dw_wrdata_dbi_p0,
    dfi_8_dw_wrdata_par_p0 => dfi_8_dw_wrdata_par_p0,
    dfi_8_dw_wrdata_dq_en_p0 => dfi_8_dw_wrdata_dq_en_p0,
    dfi_8_dw_wrdata_par_en_p0 => dfi_8_dw_wrdata_par_en_p0,
    dfi_8_aw_ck_p1 => dfi_8_aw_ck_p1,
    dfi_8_aw_cke_p1 => dfi_8_aw_cke_p1,
    dfi_8_aw_row_p1 => dfi_8_aw_row_p1,
    dfi_8_aw_col_p1 => dfi_8_aw_col_p1,
    dfi_8_dw_wrdata_p1 => dfi_8_dw_wrdata_p1,
    dfi_8_dw_wrdata_mask_p1 => dfi_8_dw_wrdata_mask_p1,
    dfi_8_dw_wrdata_dbi_p1 => dfi_8_dw_wrdata_dbi_p1,
    dfi_8_dw_wrdata_par_p1 => dfi_8_dw_wrdata_par_p1,
    dfi_8_dw_wrdata_dq_en_p1 => dfi_8_dw_wrdata_dq_en_p1,
    dfi_8_dw_wrdata_par_en_p1 => dfi_8_dw_wrdata_par_en_p1,
    dfi_8_aw_ck_dis => dfi_8_aw_ck_dis,
    dfi_8_lp_pwr_e_req => dfi_8_lp_pwr_e_req,
    dfi_8_lp_sr_e_req => dfi_8_lp_sr_e_req,
    dfi_8_lp_pwr_x_req => dfi_8_lp_pwr_x_req,
    dfi_8_aw_tx_indx_ld => dfi_8_aw_tx_indx_ld,
    dfi_8_dw_tx_indx_ld => dfi_8_dw_tx_indx_ld,
    dfi_8_dw_rx_indx_ld => dfi_8_dw_rx_indx_ld,
    dfi_8_ctrlupd_ack => dfi_8_ctrlupd_ack,
    dfi_8_phyupd_req => dfi_8_phyupd_req,
    dfi_8_dw_wrdata_dqs_p0 => dfi_8_dw_wrdata_dqs_p0,
    dfi_8_dw_wrdata_dqs_p1 => dfi_8_dw_wrdata_dqs_p1,
    dfi_9_clk => dfi_9_clk,
    dfi_9_rst_n => dfi_9_rst_n,
    dfi_9_init_start => dfi_9_init_start,
    dfi_9_aw_ck_p0 => dfi_9_aw_ck_p0,
    dfi_9_aw_cke_p0 => dfi_9_aw_cke_p0,
    dfi_9_aw_row_p0 => dfi_9_aw_row_p0,
    dfi_9_aw_col_p0 => dfi_9_aw_col_p0,
    dfi_9_dw_wrdata_p0 => dfi_9_dw_wrdata_p0,
    dfi_9_dw_wrdata_mask_p0 => dfi_9_dw_wrdata_mask_p0,
    dfi_9_dw_wrdata_dbi_p0 => dfi_9_dw_wrdata_dbi_p0,
    dfi_9_dw_wrdata_par_p0 => dfi_9_dw_wrdata_par_p0,
    dfi_9_dw_wrdata_dq_en_p0 => dfi_9_dw_wrdata_dq_en_p0,
    dfi_9_dw_wrdata_par_en_p0 => dfi_9_dw_wrdata_par_en_p0,
    dfi_9_aw_ck_p1 => dfi_9_aw_ck_p1,
    dfi_9_aw_cke_p1 => dfi_9_aw_cke_p1,
    dfi_9_aw_row_p1 => dfi_9_aw_row_p1,
    dfi_9_aw_col_p1 => dfi_9_aw_col_p1,
    dfi_9_dw_wrdata_p1 => dfi_9_dw_wrdata_p1,
    dfi_9_dw_wrdata_mask_p1 => dfi_9_dw_wrdata_mask_p1,
    dfi_9_dw_wrdata_dbi_p1 => dfi_9_dw_wrdata_dbi_p1,
    dfi_9_dw_wrdata_par_p1 => dfi_9_dw_wrdata_par_p1,
    dfi_9_dw_wrdata_dq_en_p1 => dfi_9_dw_wrdata_dq_en_p1,
    dfi_9_dw_wrdata_par_en_p1 => dfi_9_dw_wrdata_par_en_p1,
    dfi_9_aw_ck_dis => dfi_9_aw_ck_dis,
    dfi_9_lp_pwr_e_req => dfi_9_lp_pwr_e_req,
    dfi_9_lp_sr_e_req => dfi_9_lp_sr_e_req,
    dfi_9_lp_pwr_x_req => dfi_9_lp_pwr_x_req,
    dfi_9_aw_tx_indx_ld => dfi_9_aw_tx_indx_ld,
    dfi_9_dw_tx_indx_ld => dfi_9_dw_tx_indx_ld,
    dfi_9_dw_rx_indx_ld => dfi_9_dw_rx_indx_ld,
    dfi_9_ctrlupd_ack => dfi_9_ctrlupd_ack,
    dfi_9_phyupd_req => dfi_9_phyupd_req,
    dfi_9_dw_wrdata_dqs_p0 => dfi_9_dw_wrdata_dqs_p0,
    dfi_9_dw_wrdata_dqs_p1 => dfi_9_dw_wrdata_dqs_p1,
    dfi_10_clk => dfi_10_clk,
    dfi_10_rst_n => dfi_10_rst_n,
    dfi_10_init_start => dfi_10_init_start,
    dfi_10_aw_ck_p0 => dfi_10_aw_ck_p0,
    dfi_10_aw_cke_p0 => dfi_10_aw_cke_p0,
    dfi_10_aw_row_p0 => dfi_10_aw_row_p0,
    dfi_10_aw_col_p0 => dfi_10_aw_col_p0,
    dfi_10_dw_wrdata_p0 => dfi_10_dw_wrdata_p0,
    dfi_10_dw_wrdata_mask_p0 => dfi_10_dw_wrdata_mask_p0,
    dfi_10_dw_wrdata_dbi_p0 => dfi_10_dw_wrdata_dbi_p0,
    dfi_10_dw_wrdata_par_p0 => dfi_10_dw_wrdata_par_p0,
    dfi_10_dw_wrdata_dq_en_p0 => dfi_10_dw_wrdata_dq_en_p0,
    dfi_10_dw_wrdata_par_en_p0 => dfi_10_dw_wrdata_par_en_p0,
    dfi_10_aw_ck_p1 => dfi_10_aw_ck_p1,
    dfi_10_aw_cke_p1 => dfi_10_aw_cke_p1,
    dfi_10_aw_row_p1 => dfi_10_aw_row_p1,
    dfi_10_aw_col_p1 => dfi_10_aw_col_p1,
    dfi_10_dw_wrdata_p1 => dfi_10_dw_wrdata_p1,
    dfi_10_dw_wrdata_mask_p1 => dfi_10_dw_wrdata_mask_p1,
    dfi_10_dw_wrdata_dbi_p1 => dfi_10_dw_wrdata_dbi_p1,
    dfi_10_dw_wrdata_par_p1 => dfi_10_dw_wrdata_par_p1,
    dfi_10_dw_wrdata_dq_en_p1 => dfi_10_dw_wrdata_dq_en_p1,
    dfi_10_dw_wrdata_par_en_p1 => dfi_10_dw_wrdata_par_en_p1,
    dfi_10_aw_ck_dis => dfi_10_aw_ck_dis,
    dfi_10_lp_pwr_e_req => dfi_10_lp_pwr_e_req,
    dfi_10_lp_sr_e_req => dfi_10_lp_sr_e_req,
    dfi_10_lp_pwr_x_req => dfi_10_lp_pwr_x_req,
    dfi_10_aw_tx_indx_ld => dfi_10_aw_tx_indx_ld,
    dfi_10_dw_tx_indx_ld => dfi_10_dw_tx_indx_ld,
    dfi_10_dw_rx_indx_ld => dfi_10_dw_rx_indx_ld,
    dfi_10_ctrlupd_ack => dfi_10_ctrlupd_ack,
    dfi_10_phyupd_req => dfi_10_phyupd_req,
    dfi_10_dw_wrdata_dqs_p0 => dfi_10_dw_wrdata_dqs_p0,
    dfi_10_dw_wrdata_dqs_p1 => dfi_10_dw_wrdata_dqs_p1,
    dfi_11_clk => dfi_11_clk,
    dfi_11_rst_n => dfi_11_rst_n,
    dfi_11_init_start => dfi_11_init_start,
    dfi_11_aw_ck_p0 => dfi_11_aw_ck_p0,
    dfi_11_aw_cke_p0 => dfi_11_aw_cke_p0,
    dfi_11_aw_row_p0 => dfi_11_aw_row_p0,
    dfi_11_aw_col_p0 => dfi_11_aw_col_p0,
    dfi_11_dw_wrdata_p0 => dfi_11_dw_wrdata_p0,
    dfi_11_dw_wrdata_mask_p0 => dfi_11_dw_wrdata_mask_p0,
    dfi_11_dw_wrdata_dbi_p0 => dfi_11_dw_wrdata_dbi_p0,
    dfi_11_dw_wrdata_par_p0 => dfi_11_dw_wrdata_par_p0,
    dfi_11_dw_wrdata_dq_en_p0 => dfi_11_dw_wrdata_dq_en_p0,
    dfi_11_dw_wrdata_par_en_p0 => dfi_11_dw_wrdata_par_en_p0,
    dfi_11_aw_ck_p1 => dfi_11_aw_ck_p1,
    dfi_11_aw_cke_p1 => dfi_11_aw_cke_p1,
    dfi_11_aw_row_p1 => dfi_11_aw_row_p1,
    dfi_11_aw_col_p1 => dfi_11_aw_col_p1,
    dfi_11_dw_wrdata_p1 => dfi_11_dw_wrdata_p1,
    dfi_11_dw_wrdata_mask_p1 => dfi_11_dw_wrdata_mask_p1,
    dfi_11_dw_wrdata_dbi_p1 => dfi_11_dw_wrdata_dbi_p1,
    dfi_11_dw_wrdata_par_p1 => dfi_11_dw_wrdata_par_p1,
    dfi_11_dw_wrdata_dq_en_p1 => dfi_11_dw_wrdata_dq_en_p1,
    dfi_11_dw_wrdata_par_en_p1 => dfi_11_dw_wrdata_par_en_p1,
    dfi_11_aw_ck_dis => dfi_11_aw_ck_dis,
    dfi_11_lp_pwr_e_req => dfi_11_lp_pwr_e_req,
    dfi_11_lp_sr_e_req => dfi_11_lp_sr_e_req,
    dfi_11_lp_pwr_x_req => dfi_11_lp_pwr_x_req,
    dfi_11_aw_tx_indx_ld => dfi_11_aw_tx_indx_ld,
    dfi_11_dw_tx_indx_ld => dfi_11_dw_tx_indx_ld,
    dfi_11_dw_rx_indx_ld => dfi_11_dw_rx_indx_ld,
    dfi_11_ctrlupd_ack => dfi_11_ctrlupd_ack,
    dfi_11_phyupd_req => dfi_11_phyupd_req,
    dfi_11_dw_wrdata_dqs_p0 => dfi_11_dw_wrdata_dqs_p0,
    dfi_11_dw_wrdata_dqs_p1 => dfi_11_dw_wrdata_dqs_p1,
    dfi_12_clk => dfi_12_clk,
    dfi_12_rst_n => dfi_12_rst_n,
    dfi_12_init_start => dfi_12_init_start,
    dfi_12_aw_ck_p0 => dfi_12_aw_ck_p0,
    dfi_12_aw_cke_p0 => dfi_12_aw_cke_p0,
    dfi_12_aw_row_p0 => dfi_12_aw_row_p0,
    dfi_12_aw_col_p0 => dfi_12_aw_col_p0,
    dfi_12_dw_wrdata_p0 => dfi_12_dw_wrdata_p0,
    dfi_12_dw_wrdata_mask_p0 => dfi_12_dw_wrdata_mask_p0,
    dfi_12_dw_wrdata_dbi_p0 => dfi_12_dw_wrdata_dbi_p0,
    dfi_12_dw_wrdata_par_p0 => dfi_12_dw_wrdata_par_p0,
    dfi_12_dw_wrdata_dq_en_p0 => dfi_12_dw_wrdata_dq_en_p0,
    dfi_12_dw_wrdata_par_en_p0 => dfi_12_dw_wrdata_par_en_p0,
    dfi_12_aw_ck_p1 => dfi_12_aw_ck_p1,
    dfi_12_aw_cke_p1 => dfi_12_aw_cke_p1,
    dfi_12_aw_row_p1 => dfi_12_aw_row_p1,
    dfi_12_aw_col_p1 => dfi_12_aw_col_p1,
    dfi_12_dw_wrdata_p1 => dfi_12_dw_wrdata_p1,
    dfi_12_dw_wrdata_mask_p1 => dfi_12_dw_wrdata_mask_p1,
    dfi_12_dw_wrdata_dbi_p1 => dfi_12_dw_wrdata_dbi_p1,
    dfi_12_dw_wrdata_par_p1 => dfi_12_dw_wrdata_par_p1,
    dfi_12_dw_wrdata_dq_en_p1 => dfi_12_dw_wrdata_dq_en_p1,
    dfi_12_dw_wrdata_par_en_p1 => dfi_12_dw_wrdata_par_en_p1,
    dfi_12_aw_ck_dis => dfi_12_aw_ck_dis,
    dfi_12_lp_pwr_e_req => dfi_12_lp_pwr_e_req,
    dfi_12_lp_sr_e_req => dfi_12_lp_sr_e_req,
    dfi_12_lp_pwr_x_req => dfi_12_lp_pwr_x_req,
    dfi_12_aw_tx_indx_ld => dfi_12_aw_tx_indx_ld,
    dfi_12_dw_tx_indx_ld => dfi_12_dw_tx_indx_ld,
    dfi_12_dw_rx_indx_ld => dfi_12_dw_rx_indx_ld,
    dfi_12_ctrlupd_ack => dfi_12_ctrlupd_ack,
    dfi_12_phyupd_req => dfi_12_phyupd_req,
    dfi_12_dw_wrdata_dqs_p0 => dfi_12_dw_wrdata_dqs_p0,
    dfi_12_dw_wrdata_dqs_p1 => dfi_12_dw_wrdata_dqs_p1,
    dfi_13_clk => dfi_13_clk,
    dfi_13_rst_n => dfi_13_rst_n,
    dfi_13_init_start => dfi_13_init_start,
    dfi_13_aw_ck_p0 => dfi_13_aw_ck_p0,
    dfi_13_aw_cke_p0 => dfi_13_aw_cke_p0,
    dfi_13_aw_row_p0 => dfi_13_aw_row_p0,
    dfi_13_aw_col_p0 => dfi_13_aw_col_p0,
    dfi_13_dw_wrdata_p0 => dfi_13_dw_wrdata_p0,
    dfi_13_dw_wrdata_mask_p0 => dfi_13_dw_wrdata_mask_p0,
    dfi_13_dw_wrdata_dbi_p0 => dfi_13_dw_wrdata_dbi_p0,
    dfi_13_dw_wrdata_par_p0 => dfi_13_dw_wrdata_par_p0,
    dfi_13_dw_wrdata_dq_en_p0 => dfi_13_dw_wrdata_dq_en_p0,
    dfi_13_dw_wrdata_par_en_p0 => dfi_13_dw_wrdata_par_en_p0,
    dfi_13_aw_ck_p1 => dfi_13_aw_ck_p1,
    dfi_13_aw_cke_p1 => dfi_13_aw_cke_p1,
    dfi_13_aw_row_p1 => dfi_13_aw_row_p1,
    dfi_13_aw_col_p1 => dfi_13_aw_col_p1,
    dfi_13_dw_wrdata_p1 => dfi_13_dw_wrdata_p1,
    dfi_13_dw_wrdata_mask_p1 => dfi_13_dw_wrdata_mask_p1,
    dfi_13_dw_wrdata_dbi_p1 => dfi_13_dw_wrdata_dbi_p1,
    dfi_13_dw_wrdata_par_p1 => dfi_13_dw_wrdata_par_p1,
    dfi_13_dw_wrdata_dq_en_p1 => dfi_13_dw_wrdata_dq_en_p1,
    dfi_13_dw_wrdata_par_en_p1 => dfi_13_dw_wrdata_par_en_p1,
    dfi_13_aw_ck_dis => dfi_13_aw_ck_dis,
    dfi_13_lp_pwr_e_req => dfi_13_lp_pwr_e_req,
    dfi_13_lp_sr_e_req => dfi_13_lp_sr_e_req,
    dfi_13_lp_pwr_x_req => dfi_13_lp_pwr_x_req,
    dfi_13_aw_tx_indx_ld => dfi_13_aw_tx_indx_ld,
    dfi_13_dw_tx_indx_ld => dfi_13_dw_tx_indx_ld,
    dfi_13_dw_rx_indx_ld => dfi_13_dw_rx_indx_ld,
    dfi_13_ctrlupd_ack => dfi_13_ctrlupd_ack,
    dfi_13_phyupd_req => dfi_13_phyupd_req,
    dfi_13_dw_wrdata_dqs_p0 => dfi_13_dw_wrdata_dqs_p0,
    dfi_13_dw_wrdata_dqs_p1 => dfi_13_dw_wrdata_dqs_p1,
    dfi_14_clk => dfi_14_clk,
    dfi_14_rst_n => dfi_14_rst_n,
    dfi_14_init_start => dfi_14_init_start,
    dfi_14_aw_ck_p0 => dfi_14_aw_ck_p0,
    dfi_14_aw_cke_p0 => dfi_14_aw_cke_p0,
    dfi_14_aw_row_p0 => dfi_14_aw_row_p0,
    dfi_14_aw_col_p0 => dfi_14_aw_col_p0,
    dfi_14_dw_wrdata_p0 => dfi_14_dw_wrdata_p0,
    dfi_14_dw_wrdata_mask_p0 => dfi_14_dw_wrdata_mask_p0,
    dfi_14_dw_wrdata_dbi_p0 => dfi_14_dw_wrdata_dbi_p0,
    dfi_14_dw_wrdata_par_p0 => dfi_14_dw_wrdata_par_p0,
    dfi_14_dw_wrdata_dq_en_p0 => dfi_14_dw_wrdata_dq_en_p0,
    dfi_14_dw_wrdata_par_en_p0 => dfi_14_dw_wrdata_par_en_p0,
    dfi_14_aw_ck_p1 => dfi_14_aw_ck_p1,
    dfi_14_aw_cke_p1 => dfi_14_aw_cke_p1,
    dfi_14_aw_row_p1 => dfi_14_aw_row_p1,
    dfi_14_aw_col_p1 => dfi_14_aw_col_p1,
    dfi_14_dw_wrdata_p1 => dfi_14_dw_wrdata_p1,
    dfi_14_dw_wrdata_mask_p1 => dfi_14_dw_wrdata_mask_p1,
    dfi_14_dw_wrdata_dbi_p1 => dfi_14_dw_wrdata_dbi_p1,
    dfi_14_dw_wrdata_par_p1 => dfi_14_dw_wrdata_par_p1,
    dfi_14_dw_wrdata_dq_en_p1 => dfi_14_dw_wrdata_dq_en_p1,
    dfi_14_dw_wrdata_par_en_p1 => dfi_14_dw_wrdata_par_en_p1,
    dfi_14_aw_ck_dis => dfi_14_aw_ck_dis,
    dfi_14_lp_pwr_e_req => dfi_14_lp_pwr_e_req,
    dfi_14_lp_sr_e_req => dfi_14_lp_sr_e_req,
    dfi_14_lp_pwr_x_req => dfi_14_lp_pwr_x_req,
    dfi_14_aw_tx_indx_ld => dfi_14_aw_tx_indx_ld,
    dfi_14_dw_tx_indx_ld => dfi_14_dw_tx_indx_ld,
    dfi_14_dw_rx_indx_ld => dfi_14_dw_rx_indx_ld,
    dfi_14_ctrlupd_ack => dfi_14_ctrlupd_ack,
    dfi_14_phyupd_req => dfi_14_phyupd_req,
    dfi_14_dw_wrdata_dqs_p0 => dfi_14_dw_wrdata_dqs_p0,
    dfi_14_dw_wrdata_dqs_p1 => dfi_14_dw_wrdata_dqs_p1,
    dfi_15_clk => dfi_15_clk,
    dfi_15_rst_n => dfi_15_rst_n,
    dfi_15_init_start => dfi_15_init_start,
    dfi_15_aw_ck_p0 => dfi_15_aw_ck_p0,
    dfi_15_aw_cke_p0 => dfi_15_aw_cke_p0,
    dfi_15_aw_row_p0 => dfi_15_aw_row_p0,
    dfi_15_aw_col_p0 => dfi_15_aw_col_p0,
    dfi_15_dw_wrdata_p0 => dfi_15_dw_wrdata_p0,
    dfi_15_dw_wrdata_mask_p0 => dfi_15_dw_wrdata_mask_p0,
    dfi_15_dw_wrdata_dbi_p0 => dfi_15_dw_wrdata_dbi_p0,
    dfi_15_dw_wrdata_par_p0 => dfi_15_dw_wrdata_par_p0,
    dfi_15_dw_wrdata_dq_en_p0 => dfi_15_dw_wrdata_dq_en_p0,
    dfi_15_dw_wrdata_par_en_p0 => dfi_15_dw_wrdata_par_en_p0,
    dfi_15_aw_ck_p1 => dfi_15_aw_ck_p1,
    dfi_15_aw_cke_p1 => dfi_15_aw_cke_p1,
    dfi_15_aw_row_p1 => dfi_15_aw_row_p1,
    dfi_15_aw_col_p1 => dfi_15_aw_col_p1,
    dfi_15_dw_wrdata_p1 => dfi_15_dw_wrdata_p1,
    dfi_15_dw_wrdata_mask_p1 => dfi_15_dw_wrdata_mask_p1,
    dfi_15_dw_wrdata_dbi_p1 => dfi_15_dw_wrdata_dbi_p1,
    dfi_15_dw_wrdata_par_p1 => dfi_15_dw_wrdata_par_p1,
    dfi_15_dw_wrdata_dq_en_p1 => dfi_15_dw_wrdata_dq_en_p1,
    dfi_15_dw_wrdata_par_en_p1 => dfi_15_dw_wrdata_par_en_p1,
    dfi_15_aw_ck_dis => dfi_15_aw_ck_dis,
    dfi_15_lp_pwr_e_req => dfi_15_lp_pwr_e_req,
    dfi_15_lp_sr_e_req => dfi_15_lp_sr_e_req,
    dfi_15_lp_pwr_x_req => dfi_15_lp_pwr_x_req,
    dfi_15_aw_tx_indx_ld => dfi_15_aw_tx_indx_ld,
    dfi_15_dw_tx_indx_ld => dfi_15_dw_tx_indx_ld,
    dfi_15_dw_rx_indx_ld => dfi_15_dw_rx_indx_ld,
    dfi_15_ctrlupd_ack => dfi_15_ctrlupd_ack,
    dfi_15_phyupd_req => dfi_15_phyupd_req,
    dfi_15_dw_wrdata_dqs_p0 => dfi_15_dw_wrdata_dqs_p0,
    dfi_15_dw_wrdata_dqs_p1 => dfi_15_dw_wrdata_dqs_p1,
    APB_0_PCLK => APB_0_PCLK,
    APB_0_PRESET_N => APB_0_PRESET_N,
    APB_1_PCLK => APB_1_PCLK,
    APB_1_PRESET_N => APB_1_PRESET_N,
    dfi_0_dw_rddata_p0 => dfi_0_dw_rddata_p0,
    dfi_0_dw_rddata_dm_p0 => dfi_0_dw_rddata_dm_p0,
    dfi_0_dw_rddata_dbi_p0 => dfi_0_dw_rddata_dbi_p0,
    dfi_0_dw_rddata_par_p0 => dfi_0_dw_rddata_par_p0,
    dfi_0_dw_rddata_p1 => dfi_0_dw_rddata_p1,
    dfi_0_dw_rddata_dm_p1 => dfi_0_dw_rddata_dm_p1,
    dfi_0_dw_rddata_dbi_p1 => dfi_0_dw_rddata_dbi_p1,
    dfi_0_dw_rddata_par_p1 => dfi_0_dw_rddata_par_p1,
    dfi_0_dbi_byte_disable => dfi_0_dbi_byte_disable,
    dfi_0_dw_rddata_valid => dfi_0_dw_rddata_valid,
    dfi_0_dw_derr_n => dfi_0_dw_derr_n,
    dfi_0_aw_aerr_n => dfi_0_aw_aerr_n,
    dfi_0_ctrlupd_req => dfi_0_ctrlupd_req,
    dfi_0_phyupd_ack => dfi_0_phyupd_ack,
    dfi_0_clk_init => dfi_0_clk_init,
    dfi_0_init_complete => dfi_0_init_complete,
    dfi_0_out_rst_n => dfi_0_out_rst_n,
    dfi_1_dw_rddata_p0 => dfi_1_dw_rddata_p0,
    dfi_1_dw_rddata_dm_p0 => dfi_1_dw_rddata_dm_p0,
    dfi_1_dw_rddata_dbi_p0 => dfi_1_dw_rddata_dbi_p0,
    dfi_1_dw_rddata_par_p0 => dfi_1_dw_rddata_par_p0,
    dfi_1_dw_rddata_p1 => dfi_1_dw_rddata_p1,
    dfi_1_dw_rddata_dm_p1 => dfi_1_dw_rddata_dm_p1,
    dfi_1_dw_rddata_dbi_p1 => dfi_1_dw_rddata_dbi_p1,
    dfi_1_dw_rddata_par_p1 => dfi_1_dw_rddata_par_p1,
    dfi_1_dbi_byte_disable => dfi_1_dbi_byte_disable,
    dfi_1_dw_rddata_valid => dfi_1_dw_rddata_valid,
    dfi_1_dw_derr_n => dfi_1_dw_derr_n,
    dfi_1_aw_aerr_n => dfi_1_aw_aerr_n,
    dfi_1_ctrlupd_req => dfi_1_ctrlupd_req,
    dfi_1_phyupd_ack => dfi_1_phyupd_ack,
    dfi_1_clk_init => dfi_1_clk_init,
    dfi_1_init_complete => dfi_1_init_complete,
    dfi_1_out_rst_n => dfi_1_out_rst_n,
    dfi_2_dw_rddata_p0 => dfi_2_dw_rddata_p0,
    dfi_2_dw_rddata_dm_p0 => dfi_2_dw_rddata_dm_p0,
    dfi_2_dw_rddata_dbi_p0 => dfi_2_dw_rddata_dbi_p0,
    dfi_2_dw_rddata_par_p0 => dfi_2_dw_rddata_par_p0,
    dfi_2_dw_rddata_p1 => dfi_2_dw_rddata_p1,
    dfi_2_dw_rddata_dm_p1 => dfi_2_dw_rddata_dm_p1,
    dfi_2_dw_rddata_dbi_p1 => dfi_2_dw_rddata_dbi_p1,
    dfi_2_dw_rddata_par_p1 => dfi_2_dw_rddata_par_p1,
    dfi_2_dbi_byte_disable => dfi_2_dbi_byte_disable,
    dfi_2_dw_rddata_valid => dfi_2_dw_rddata_valid,
    dfi_2_dw_derr_n => dfi_2_dw_derr_n,
    dfi_2_aw_aerr_n => dfi_2_aw_aerr_n,
    dfi_2_ctrlupd_req => dfi_2_ctrlupd_req,
    dfi_2_phyupd_ack => dfi_2_phyupd_ack,
    dfi_2_clk_init => dfi_2_clk_init,
    dfi_2_init_complete => dfi_2_init_complete,
    dfi_2_out_rst_n => dfi_2_out_rst_n,
    dfi_3_dw_rddata_p0 => dfi_3_dw_rddata_p0,
    dfi_3_dw_rddata_dm_p0 => dfi_3_dw_rddata_dm_p0,
    dfi_3_dw_rddata_dbi_p0 => dfi_3_dw_rddata_dbi_p0,
    dfi_3_dw_rddata_par_p0 => dfi_3_dw_rddata_par_p0,
    dfi_3_dw_rddata_p1 => dfi_3_dw_rddata_p1,
    dfi_3_dw_rddata_dm_p1 => dfi_3_dw_rddata_dm_p1,
    dfi_3_dw_rddata_dbi_p1 => dfi_3_dw_rddata_dbi_p1,
    dfi_3_dw_rddata_par_p1 => dfi_3_dw_rddata_par_p1,
    dfi_3_dbi_byte_disable => dfi_3_dbi_byte_disable,
    dfi_3_dw_rddata_valid => dfi_3_dw_rddata_valid,
    dfi_3_dw_derr_n => dfi_3_dw_derr_n,
    dfi_3_aw_aerr_n => dfi_3_aw_aerr_n,
    dfi_3_ctrlupd_req => dfi_3_ctrlupd_req,
    dfi_3_phyupd_ack => dfi_3_phyupd_ack,
    dfi_3_clk_init => dfi_3_clk_init,
    dfi_3_init_complete => dfi_3_init_complete,
    dfi_3_out_rst_n => dfi_3_out_rst_n,
    dfi_4_dw_rddata_p0 => dfi_4_dw_rddata_p0,
    dfi_4_dw_rddata_dm_p0 => dfi_4_dw_rddata_dm_p0,
    dfi_4_dw_rddata_dbi_p0 => dfi_4_dw_rddata_dbi_p0,
    dfi_4_dw_rddata_par_p0 => dfi_4_dw_rddata_par_p0,
    dfi_4_dw_rddata_p1 => dfi_4_dw_rddata_p1,
    dfi_4_dw_rddata_dm_p1 => dfi_4_dw_rddata_dm_p1,
    dfi_4_dw_rddata_dbi_p1 => dfi_4_dw_rddata_dbi_p1,
    dfi_4_dw_rddata_par_p1 => dfi_4_dw_rddata_par_p1,
    dfi_4_dbi_byte_disable => dfi_4_dbi_byte_disable,
    dfi_4_dw_rddata_valid => dfi_4_dw_rddata_valid,
    dfi_4_dw_derr_n => dfi_4_dw_derr_n,
    dfi_4_aw_aerr_n => dfi_4_aw_aerr_n,
    dfi_4_ctrlupd_req => dfi_4_ctrlupd_req,
    dfi_4_phyupd_ack => dfi_4_phyupd_ack,
    dfi_4_clk_init => dfi_4_clk_init,
    dfi_4_init_complete => dfi_4_init_complete,
    dfi_4_out_rst_n => dfi_4_out_rst_n,
    dfi_5_dw_rddata_p0 => dfi_5_dw_rddata_p0,
    dfi_5_dw_rddata_dm_p0 => dfi_5_dw_rddata_dm_p0,
    dfi_5_dw_rddata_dbi_p0 => dfi_5_dw_rddata_dbi_p0,
    dfi_5_dw_rddata_par_p0 => dfi_5_dw_rddata_par_p0,
    dfi_5_dw_rddata_p1 => dfi_5_dw_rddata_p1,
    dfi_5_dw_rddata_dm_p1 => dfi_5_dw_rddata_dm_p1,
    dfi_5_dw_rddata_dbi_p1 => dfi_5_dw_rddata_dbi_p1,
    dfi_5_dw_rddata_par_p1 => dfi_5_dw_rddata_par_p1,
    dfi_5_dbi_byte_disable => dfi_5_dbi_byte_disable,
    dfi_5_dw_rddata_valid => dfi_5_dw_rddata_valid,
    dfi_5_dw_derr_n => dfi_5_dw_derr_n,
    dfi_5_aw_aerr_n => dfi_5_aw_aerr_n,
    dfi_5_ctrlupd_req => dfi_5_ctrlupd_req,
    dfi_5_phyupd_ack => dfi_5_phyupd_ack,
    dfi_5_clk_init => dfi_5_clk_init,
    dfi_5_init_complete => dfi_5_init_complete,
    dfi_5_out_rst_n => dfi_5_out_rst_n,
    dfi_6_dw_rddata_p0 => dfi_6_dw_rddata_p0,
    dfi_6_dw_rddata_dm_p0 => dfi_6_dw_rddata_dm_p0,
    dfi_6_dw_rddata_dbi_p0 => dfi_6_dw_rddata_dbi_p0,
    dfi_6_dw_rddata_par_p0 => dfi_6_dw_rddata_par_p0,
    dfi_6_dw_rddata_p1 => dfi_6_dw_rddata_p1,
    dfi_6_dw_rddata_dm_p1 => dfi_6_dw_rddata_dm_p1,
    dfi_6_dw_rddata_dbi_p1 => dfi_6_dw_rddata_dbi_p1,
    dfi_6_dw_rddata_par_p1 => dfi_6_dw_rddata_par_p1,
    dfi_6_dbi_byte_disable => dfi_6_dbi_byte_disable,
    dfi_6_dw_rddata_valid => dfi_6_dw_rddata_valid,
    dfi_6_dw_derr_n => dfi_6_dw_derr_n,
    dfi_6_aw_aerr_n => dfi_6_aw_aerr_n,
    dfi_6_ctrlupd_req => dfi_6_ctrlupd_req,
    dfi_6_phyupd_ack => dfi_6_phyupd_ack,
    dfi_6_clk_init => dfi_6_clk_init,
    dfi_6_init_complete => dfi_6_init_complete,
    dfi_6_out_rst_n => dfi_6_out_rst_n,
    dfi_7_dw_rddata_p0 => dfi_7_dw_rddata_p0,
    dfi_7_dw_rddata_dm_p0 => dfi_7_dw_rddata_dm_p0,
    dfi_7_dw_rddata_dbi_p0 => dfi_7_dw_rddata_dbi_p0,
    dfi_7_dw_rddata_par_p0 => dfi_7_dw_rddata_par_p0,
    dfi_7_dw_rddata_p1 => dfi_7_dw_rddata_p1,
    dfi_7_dw_rddata_dm_p1 => dfi_7_dw_rddata_dm_p1,
    dfi_7_dw_rddata_dbi_p1 => dfi_7_dw_rddata_dbi_p1,
    dfi_7_dw_rddata_par_p1 => dfi_7_dw_rddata_par_p1,
    dfi_7_dbi_byte_disable => dfi_7_dbi_byte_disable,
    dfi_7_dw_rddata_valid => dfi_7_dw_rddata_valid,
    dfi_7_dw_derr_n => dfi_7_dw_derr_n,
    dfi_7_aw_aerr_n => dfi_7_aw_aerr_n,
    dfi_7_ctrlupd_req => dfi_7_ctrlupd_req,
    dfi_7_phyupd_ack => dfi_7_phyupd_ack,
    dfi_7_clk_init => dfi_7_clk_init,
    dfi_7_init_complete => dfi_7_init_complete,
    dfi_7_out_rst_n => dfi_7_out_rst_n,
    dfi_8_dw_rddata_p0 => dfi_8_dw_rddata_p0,
    dfi_8_dw_rddata_dm_p0 => dfi_8_dw_rddata_dm_p0,
    dfi_8_dw_rddata_dbi_p0 => dfi_8_dw_rddata_dbi_p0,
    dfi_8_dw_rddata_par_p0 => dfi_8_dw_rddata_par_p0,
    dfi_8_dw_rddata_p1 => dfi_8_dw_rddata_p1,
    dfi_8_dw_rddata_dm_p1 => dfi_8_dw_rddata_dm_p1,
    dfi_8_dw_rddata_dbi_p1 => dfi_8_dw_rddata_dbi_p1,
    dfi_8_dw_rddata_par_p1 => dfi_8_dw_rddata_par_p1,
    dfi_8_dbi_byte_disable => dfi_8_dbi_byte_disable,
    dfi_8_dw_rddata_valid => dfi_8_dw_rddata_valid,
    dfi_8_dw_derr_n => dfi_8_dw_derr_n,
    dfi_8_aw_aerr_n => dfi_8_aw_aerr_n,
    dfi_8_ctrlupd_req => dfi_8_ctrlupd_req,
    dfi_8_phyupd_ack => dfi_8_phyupd_ack,
    dfi_8_clk_init => dfi_8_clk_init,
    dfi_8_init_complete => dfi_8_init_complete,
    dfi_8_out_rst_n => dfi_8_out_rst_n,
    dfi_9_dw_rddata_p0 => dfi_9_dw_rddata_p0,
    dfi_9_dw_rddata_dm_p0 => dfi_9_dw_rddata_dm_p0,
    dfi_9_dw_rddata_dbi_p0 => dfi_9_dw_rddata_dbi_p0,
    dfi_9_dw_rddata_par_p0 => dfi_9_dw_rddata_par_p0,
    dfi_9_dw_rddata_p1 => dfi_9_dw_rddata_p1,
    dfi_9_dw_rddata_dm_p1 => dfi_9_dw_rddata_dm_p1,
    dfi_9_dw_rddata_dbi_p1 => dfi_9_dw_rddata_dbi_p1,
    dfi_9_dw_rddata_par_p1 => dfi_9_dw_rddata_par_p1,
    dfi_9_dbi_byte_disable => dfi_9_dbi_byte_disable,
    dfi_9_dw_rddata_valid => dfi_9_dw_rddata_valid,
    dfi_9_dw_derr_n => dfi_9_dw_derr_n,
    dfi_9_aw_aerr_n => dfi_9_aw_aerr_n,
    dfi_9_ctrlupd_req => dfi_9_ctrlupd_req,
    dfi_9_phyupd_ack => dfi_9_phyupd_ack,
    dfi_9_clk_init => dfi_9_clk_init,
    dfi_9_init_complete => dfi_9_init_complete,
    dfi_9_out_rst_n => dfi_9_out_rst_n,
    dfi_10_dw_rddata_p0 => dfi_10_dw_rddata_p0,
    dfi_10_dw_rddata_dm_p0 => dfi_10_dw_rddata_dm_p0,
    dfi_10_dw_rddata_dbi_p0 => dfi_10_dw_rddata_dbi_p0,
    dfi_10_dw_rddata_par_p0 => dfi_10_dw_rddata_par_p0,
    dfi_10_dw_rddata_p1 => dfi_10_dw_rddata_p1,
    dfi_10_dw_rddata_dm_p1 => dfi_10_dw_rddata_dm_p1,
    dfi_10_dw_rddata_dbi_p1 => dfi_10_dw_rddata_dbi_p1,
    dfi_10_dw_rddata_par_p1 => dfi_10_dw_rddata_par_p1,
    dfi_10_dbi_byte_disable => dfi_10_dbi_byte_disable,
    dfi_10_dw_rddata_valid => dfi_10_dw_rddata_valid,
    dfi_10_dw_derr_n => dfi_10_dw_derr_n,
    dfi_10_aw_aerr_n => dfi_10_aw_aerr_n,
    dfi_10_ctrlupd_req => dfi_10_ctrlupd_req,
    dfi_10_phyupd_ack => dfi_10_phyupd_ack,
    dfi_10_clk_init => dfi_10_clk_init,
    dfi_10_init_complete => dfi_10_init_complete,
    dfi_10_out_rst_n => dfi_10_out_rst_n,
    dfi_11_dw_rddata_p0 => dfi_11_dw_rddata_p0,
    dfi_11_dw_rddata_dm_p0 => dfi_11_dw_rddata_dm_p0,
    dfi_11_dw_rddata_dbi_p0 => dfi_11_dw_rddata_dbi_p0,
    dfi_11_dw_rddata_par_p0 => dfi_11_dw_rddata_par_p0,
    dfi_11_dw_rddata_p1 => dfi_11_dw_rddata_p1,
    dfi_11_dw_rddata_dm_p1 => dfi_11_dw_rddata_dm_p1,
    dfi_11_dw_rddata_dbi_p1 => dfi_11_dw_rddata_dbi_p1,
    dfi_11_dw_rddata_par_p1 => dfi_11_dw_rddata_par_p1,
    dfi_11_dbi_byte_disable => dfi_11_dbi_byte_disable,
    dfi_11_dw_rddata_valid => dfi_11_dw_rddata_valid,
    dfi_11_dw_derr_n => dfi_11_dw_derr_n,
    dfi_11_aw_aerr_n => dfi_11_aw_aerr_n,
    dfi_11_ctrlupd_req => dfi_11_ctrlupd_req,
    dfi_11_phyupd_ack => dfi_11_phyupd_ack,
    dfi_11_clk_init => dfi_11_clk_init,
    dfi_11_init_complete => dfi_11_init_complete,
    dfi_11_out_rst_n => dfi_11_out_rst_n,
    dfi_12_dw_rddata_p0 => dfi_12_dw_rddata_p0,
    dfi_12_dw_rddata_dm_p0 => dfi_12_dw_rddata_dm_p0,
    dfi_12_dw_rddata_dbi_p0 => dfi_12_dw_rddata_dbi_p0,
    dfi_12_dw_rddata_par_p0 => dfi_12_dw_rddata_par_p0,
    dfi_12_dw_rddata_p1 => dfi_12_dw_rddata_p1,
    dfi_12_dw_rddata_dm_p1 => dfi_12_dw_rddata_dm_p1,
    dfi_12_dw_rddata_dbi_p1 => dfi_12_dw_rddata_dbi_p1,
    dfi_12_dw_rddata_par_p1 => dfi_12_dw_rddata_par_p1,
    dfi_12_dbi_byte_disable => dfi_12_dbi_byte_disable,
    dfi_12_dw_rddata_valid => dfi_12_dw_rddata_valid,
    dfi_12_dw_derr_n => dfi_12_dw_derr_n,
    dfi_12_aw_aerr_n => dfi_12_aw_aerr_n,
    dfi_12_ctrlupd_req => dfi_12_ctrlupd_req,
    dfi_12_phyupd_ack => dfi_12_phyupd_ack,
    dfi_12_clk_init => dfi_12_clk_init,
    dfi_12_init_complete => dfi_12_init_complete,
    dfi_12_out_rst_n => dfi_12_out_rst_n,
    dfi_13_dw_rddata_p0 => dfi_13_dw_rddata_p0,
    dfi_13_dw_rddata_dm_p0 => dfi_13_dw_rddata_dm_p0,
    dfi_13_dw_rddata_dbi_p0 => dfi_13_dw_rddata_dbi_p0,
    dfi_13_dw_rddata_par_p0 => dfi_13_dw_rddata_par_p0,
    dfi_13_dw_rddata_p1 => dfi_13_dw_rddata_p1,
    dfi_13_dw_rddata_dm_p1 => dfi_13_dw_rddata_dm_p1,
    dfi_13_dw_rddata_dbi_p1 => dfi_13_dw_rddata_dbi_p1,
    dfi_13_dw_rddata_par_p1 => dfi_13_dw_rddata_par_p1,
    dfi_13_dbi_byte_disable => dfi_13_dbi_byte_disable,
    dfi_13_dw_rddata_valid => dfi_13_dw_rddata_valid,
    dfi_13_dw_derr_n => dfi_13_dw_derr_n,
    dfi_13_aw_aerr_n => dfi_13_aw_aerr_n,
    dfi_13_ctrlupd_req => dfi_13_ctrlupd_req,
    dfi_13_phyupd_ack => dfi_13_phyupd_ack,
    dfi_13_clk_init => dfi_13_clk_init,
    dfi_13_init_complete => dfi_13_init_complete,
    dfi_13_out_rst_n => dfi_13_out_rst_n,
    dfi_14_dw_rddata_p0 => dfi_14_dw_rddata_p0,
    dfi_14_dw_rddata_dm_p0 => dfi_14_dw_rddata_dm_p0,
    dfi_14_dw_rddata_dbi_p0 => dfi_14_dw_rddata_dbi_p0,
    dfi_14_dw_rddata_par_p0 => dfi_14_dw_rddata_par_p0,
    dfi_14_dw_rddata_p1 => dfi_14_dw_rddata_p1,
    dfi_14_dw_rddata_dm_p1 => dfi_14_dw_rddata_dm_p1,
    dfi_14_dw_rddata_dbi_p1 => dfi_14_dw_rddata_dbi_p1,
    dfi_14_dw_rddata_par_p1 => dfi_14_dw_rddata_par_p1,
    dfi_14_dbi_byte_disable => dfi_14_dbi_byte_disable,
    dfi_14_dw_rddata_valid => dfi_14_dw_rddata_valid,
    dfi_14_dw_derr_n => dfi_14_dw_derr_n,
    dfi_14_aw_aerr_n => dfi_14_aw_aerr_n,
    dfi_14_ctrlupd_req => dfi_14_ctrlupd_req,
    dfi_14_phyupd_ack => dfi_14_phyupd_ack,
    dfi_14_clk_init => dfi_14_clk_init,
    dfi_14_init_complete => dfi_14_init_complete,
    dfi_14_out_rst_n => dfi_14_out_rst_n,
    dfi_15_dw_rddata_p0 => dfi_15_dw_rddata_p0,
    dfi_15_dw_rddata_dm_p0 => dfi_15_dw_rddata_dm_p0,
    dfi_15_dw_rddata_dbi_p0 => dfi_15_dw_rddata_dbi_p0,
    dfi_15_dw_rddata_par_p0 => dfi_15_dw_rddata_par_p0,
    dfi_15_dw_rddata_p1 => dfi_15_dw_rddata_p1,
    dfi_15_dw_rddata_dm_p1 => dfi_15_dw_rddata_dm_p1,
    dfi_15_dw_rddata_dbi_p1 => dfi_15_dw_rddata_dbi_p1,
    dfi_15_dw_rddata_par_p1 => dfi_15_dw_rddata_par_p1,
    dfi_15_dbi_byte_disable => dfi_15_dbi_byte_disable,
    dfi_15_dw_rddata_valid => dfi_15_dw_rddata_valid,
    dfi_15_dw_derr_n => dfi_15_dw_derr_n,
    dfi_15_aw_aerr_n => dfi_15_aw_aerr_n,
    dfi_15_ctrlupd_req => dfi_15_ctrlupd_req,
    dfi_15_phyupd_ack => dfi_15_phyupd_ack,
    dfi_15_clk_init => dfi_15_clk_init,
    dfi_15_init_complete => dfi_15_init_complete,
    dfi_15_out_rst_n => dfi_15_out_rst_n,
    apb_complete_0 => apb_complete_0,
    apb_complete_1 => apb_complete_1,
    DRAM_0_STAT_CATTRIP => DRAM_0_STAT_CATTRIP,
    DRAM_0_STAT_TEMP => DRAM_0_STAT_TEMP,
    DRAM_1_STAT_CATTRIP => DRAM_1_STAT_CATTRIP,
    DRAM_1_STAT_TEMP => DRAM_1_STAT_TEMP
  );
-- INST_TAG_END ------ End INSTANTIATION Template ---------

-- You must compile the wrapper file hbm_0.vhd when simulating
-- the core, hbm_0. When compiling the wrapper file, be sure to
-- reference the VHDL simulation library.

