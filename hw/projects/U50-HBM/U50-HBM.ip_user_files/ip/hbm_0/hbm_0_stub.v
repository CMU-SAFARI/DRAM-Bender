// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.2 (lin64) Build 3064766 Wed Nov 18 09:12:47 MST 2020
// Date        : Fri Mar 31 17:36:26 2023
// Host        : safari-aolgun0 running 64-bit Ubuntu 22.04.2 LTS
// Command     : write_verilog -force -mode synth_stub
//               /home/ataberk/DRAM-Bender/gitlab/projects/U50-HBM/U50-HBM.srcs/sources_1/ip/hbm_0/hbm_0_stub.v
// Design      : hbm_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xcu50-fsvh2104-2-e
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "hbm_v1_0_9,Vivado 2020.2" *)
module hbm_0(HBM_REF_CLK_0, HBM_REF_CLK_1, dfi_0_clk, 
  dfi_0_rst_n, dfi_0_init_start, dfi_0_aw_ck_p0, dfi_0_aw_cke_p0, dfi_0_aw_row_p0, 
  dfi_0_aw_col_p0, dfi_0_dw_wrdata_p0, dfi_0_dw_wrdata_mask_p0, dfi_0_dw_wrdata_dbi_p0, 
  dfi_0_dw_wrdata_par_p0, dfi_0_dw_wrdata_dq_en_p0, dfi_0_dw_wrdata_par_en_p0, 
  dfi_0_aw_ck_p1, dfi_0_aw_cke_p1, dfi_0_aw_row_p1, dfi_0_aw_col_p1, dfi_0_dw_wrdata_p1, 
  dfi_0_dw_wrdata_mask_p1, dfi_0_dw_wrdata_dbi_p1, dfi_0_dw_wrdata_par_p1, 
  dfi_0_dw_wrdata_dq_en_p1, dfi_0_dw_wrdata_par_en_p1, dfi_0_aw_ck_dis, 
  dfi_0_lp_pwr_e_req, dfi_0_lp_sr_e_req, dfi_0_lp_pwr_x_req, dfi_0_aw_tx_indx_ld, 
  dfi_0_dw_tx_indx_ld, dfi_0_dw_rx_indx_ld, dfi_0_ctrlupd_ack, dfi_0_phyupd_req, 
  dfi_0_dw_wrdata_dqs_p0, dfi_0_dw_wrdata_dqs_p1, dfi_1_clk, dfi_1_rst_n, dfi_1_init_start, 
  dfi_1_aw_ck_p0, dfi_1_aw_cke_p0, dfi_1_aw_row_p0, dfi_1_aw_col_p0, dfi_1_dw_wrdata_p0, 
  dfi_1_dw_wrdata_mask_p0, dfi_1_dw_wrdata_dbi_p0, dfi_1_dw_wrdata_par_p0, 
  dfi_1_dw_wrdata_dq_en_p0, dfi_1_dw_wrdata_par_en_p0, dfi_1_aw_ck_p1, dfi_1_aw_cke_p1, 
  dfi_1_aw_row_p1, dfi_1_aw_col_p1, dfi_1_dw_wrdata_p1, dfi_1_dw_wrdata_mask_p1, 
  dfi_1_dw_wrdata_dbi_p1, dfi_1_dw_wrdata_par_p1, dfi_1_dw_wrdata_dq_en_p1, 
  dfi_1_dw_wrdata_par_en_p1, dfi_1_aw_ck_dis, dfi_1_lp_pwr_e_req, dfi_1_lp_sr_e_req, 
  dfi_1_lp_pwr_x_req, dfi_1_aw_tx_indx_ld, dfi_1_dw_tx_indx_ld, dfi_1_dw_rx_indx_ld, 
  dfi_1_ctrlupd_ack, dfi_1_phyupd_req, dfi_1_dw_wrdata_dqs_p0, dfi_1_dw_wrdata_dqs_p1, 
  dfi_2_clk, dfi_2_rst_n, dfi_2_init_start, dfi_2_aw_ck_p0, dfi_2_aw_cke_p0, dfi_2_aw_row_p0, 
  dfi_2_aw_col_p0, dfi_2_dw_wrdata_p0, dfi_2_dw_wrdata_mask_p0, dfi_2_dw_wrdata_dbi_p0, 
  dfi_2_dw_wrdata_par_p0, dfi_2_dw_wrdata_dq_en_p0, dfi_2_dw_wrdata_par_en_p0, 
  dfi_2_aw_ck_p1, dfi_2_aw_cke_p1, dfi_2_aw_row_p1, dfi_2_aw_col_p1, dfi_2_dw_wrdata_p1, 
  dfi_2_dw_wrdata_mask_p1, dfi_2_dw_wrdata_dbi_p1, dfi_2_dw_wrdata_par_p1, 
  dfi_2_dw_wrdata_dq_en_p1, dfi_2_dw_wrdata_par_en_p1, dfi_2_aw_ck_dis, 
  dfi_2_lp_pwr_e_req, dfi_2_lp_sr_e_req, dfi_2_lp_pwr_x_req, dfi_2_aw_tx_indx_ld, 
  dfi_2_dw_tx_indx_ld, dfi_2_dw_rx_indx_ld, dfi_2_ctrlupd_ack, dfi_2_phyupd_req, 
  dfi_2_dw_wrdata_dqs_p0, dfi_2_dw_wrdata_dqs_p1, dfi_3_clk, dfi_3_rst_n, dfi_3_init_start, 
  dfi_3_aw_ck_p0, dfi_3_aw_cke_p0, dfi_3_aw_row_p0, dfi_3_aw_col_p0, dfi_3_dw_wrdata_p0, 
  dfi_3_dw_wrdata_mask_p0, dfi_3_dw_wrdata_dbi_p0, dfi_3_dw_wrdata_par_p0, 
  dfi_3_dw_wrdata_dq_en_p0, dfi_3_dw_wrdata_par_en_p0, dfi_3_aw_ck_p1, dfi_3_aw_cke_p1, 
  dfi_3_aw_row_p1, dfi_3_aw_col_p1, dfi_3_dw_wrdata_p1, dfi_3_dw_wrdata_mask_p1, 
  dfi_3_dw_wrdata_dbi_p1, dfi_3_dw_wrdata_par_p1, dfi_3_dw_wrdata_dq_en_p1, 
  dfi_3_dw_wrdata_par_en_p1, dfi_3_aw_ck_dis, dfi_3_lp_pwr_e_req, dfi_3_lp_sr_e_req, 
  dfi_3_lp_pwr_x_req, dfi_3_aw_tx_indx_ld, dfi_3_dw_tx_indx_ld, dfi_3_dw_rx_indx_ld, 
  dfi_3_ctrlupd_ack, dfi_3_phyupd_req, dfi_3_dw_wrdata_dqs_p0, dfi_3_dw_wrdata_dqs_p1, 
  dfi_4_clk, dfi_4_rst_n, dfi_4_init_start, dfi_4_aw_ck_p0, dfi_4_aw_cke_p0, dfi_4_aw_row_p0, 
  dfi_4_aw_col_p0, dfi_4_dw_wrdata_p0, dfi_4_dw_wrdata_mask_p0, dfi_4_dw_wrdata_dbi_p0, 
  dfi_4_dw_wrdata_par_p0, dfi_4_dw_wrdata_dq_en_p0, dfi_4_dw_wrdata_par_en_p0, 
  dfi_4_aw_ck_p1, dfi_4_aw_cke_p1, dfi_4_aw_row_p1, dfi_4_aw_col_p1, dfi_4_dw_wrdata_p1, 
  dfi_4_dw_wrdata_mask_p1, dfi_4_dw_wrdata_dbi_p1, dfi_4_dw_wrdata_par_p1, 
  dfi_4_dw_wrdata_dq_en_p1, dfi_4_dw_wrdata_par_en_p1, dfi_4_aw_ck_dis, 
  dfi_4_lp_pwr_e_req, dfi_4_lp_sr_e_req, dfi_4_lp_pwr_x_req, dfi_4_aw_tx_indx_ld, 
  dfi_4_dw_tx_indx_ld, dfi_4_dw_rx_indx_ld, dfi_4_ctrlupd_ack, dfi_4_phyupd_req, 
  dfi_4_dw_wrdata_dqs_p0, dfi_4_dw_wrdata_dqs_p1, dfi_5_clk, dfi_5_rst_n, dfi_5_init_start, 
  dfi_5_aw_ck_p0, dfi_5_aw_cke_p0, dfi_5_aw_row_p0, dfi_5_aw_col_p0, dfi_5_dw_wrdata_p0, 
  dfi_5_dw_wrdata_mask_p0, dfi_5_dw_wrdata_dbi_p0, dfi_5_dw_wrdata_par_p0, 
  dfi_5_dw_wrdata_dq_en_p0, dfi_5_dw_wrdata_par_en_p0, dfi_5_aw_ck_p1, dfi_5_aw_cke_p1, 
  dfi_5_aw_row_p1, dfi_5_aw_col_p1, dfi_5_dw_wrdata_p1, dfi_5_dw_wrdata_mask_p1, 
  dfi_5_dw_wrdata_dbi_p1, dfi_5_dw_wrdata_par_p1, dfi_5_dw_wrdata_dq_en_p1, 
  dfi_5_dw_wrdata_par_en_p1, dfi_5_aw_ck_dis, dfi_5_lp_pwr_e_req, dfi_5_lp_sr_e_req, 
  dfi_5_lp_pwr_x_req, dfi_5_aw_tx_indx_ld, dfi_5_dw_tx_indx_ld, dfi_5_dw_rx_indx_ld, 
  dfi_5_ctrlupd_ack, dfi_5_phyupd_req, dfi_5_dw_wrdata_dqs_p0, dfi_5_dw_wrdata_dqs_p1, 
  dfi_6_clk, dfi_6_rst_n, dfi_6_init_start, dfi_6_aw_ck_p0, dfi_6_aw_cke_p0, dfi_6_aw_row_p0, 
  dfi_6_aw_col_p0, dfi_6_dw_wrdata_p0, dfi_6_dw_wrdata_mask_p0, dfi_6_dw_wrdata_dbi_p0, 
  dfi_6_dw_wrdata_par_p0, dfi_6_dw_wrdata_dq_en_p0, dfi_6_dw_wrdata_par_en_p0, 
  dfi_6_aw_ck_p1, dfi_6_aw_cke_p1, dfi_6_aw_row_p1, dfi_6_aw_col_p1, dfi_6_dw_wrdata_p1, 
  dfi_6_dw_wrdata_mask_p1, dfi_6_dw_wrdata_dbi_p1, dfi_6_dw_wrdata_par_p1, 
  dfi_6_dw_wrdata_dq_en_p1, dfi_6_dw_wrdata_par_en_p1, dfi_6_aw_ck_dis, 
  dfi_6_lp_pwr_e_req, dfi_6_lp_sr_e_req, dfi_6_lp_pwr_x_req, dfi_6_aw_tx_indx_ld, 
  dfi_6_dw_tx_indx_ld, dfi_6_dw_rx_indx_ld, dfi_6_ctrlupd_ack, dfi_6_phyupd_req, 
  dfi_6_dw_wrdata_dqs_p0, dfi_6_dw_wrdata_dqs_p1, dfi_7_clk, dfi_7_rst_n, dfi_7_init_start, 
  dfi_7_aw_ck_p0, dfi_7_aw_cke_p0, dfi_7_aw_row_p0, dfi_7_aw_col_p0, dfi_7_dw_wrdata_p0, 
  dfi_7_dw_wrdata_mask_p0, dfi_7_dw_wrdata_dbi_p0, dfi_7_dw_wrdata_par_p0, 
  dfi_7_dw_wrdata_dq_en_p0, dfi_7_dw_wrdata_par_en_p0, dfi_7_aw_ck_p1, dfi_7_aw_cke_p1, 
  dfi_7_aw_row_p1, dfi_7_aw_col_p1, dfi_7_dw_wrdata_p1, dfi_7_dw_wrdata_mask_p1, 
  dfi_7_dw_wrdata_dbi_p1, dfi_7_dw_wrdata_par_p1, dfi_7_dw_wrdata_dq_en_p1, 
  dfi_7_dw_wrdata_par_en_p1, dfi_7_aw_ck_dis, dfi_7_lp_pwr_e_req, dfi_7_lp_sr_e_req, 
  dfi_7_lp_pwr_x_req, dfi_7_aw_tx_indx_ld, dfi_7_dw_tx_indx_ld, dfi_7_dw_rx_indx_ld, 
  dfi_7_ctrlupd_ack, dfi_7_phyupd_req, dfi_7_dw_wrdata_dqs_p0, dfi_7_dw_wrdata_dqs_p1, 
  dfi_8_clk, dfi_8_rst_n, dfi_8_init_start, dfi_8_aw_ck_p0, dfi_8_aw_cke_p0, dfi_8_aw_row_p0, 
  dfi_8_aw_col_p0, dfi_8_dw_wrdata_p0, dfi_8_dw_wrdata_mask_p0, dfi_8_dw_wrdata_dbi_p0, 
  dfi_8_dw_wrdata_par_p0, dfi_8_dw_wrdata_dq_en_p0, dfi_8_dw_wrdata_par_en_p0, 
  dfi_8_aw_ck_p1, dfi_8_aw_cke_p1, dfi_8_aw_row_p1, dfi_8_aw_col_p1, dfi_8_dw_wrdata_p1, 
  dfi_8_dw_wrdata_mask_p1, dfi_8_dw_wrdata_dbi_p1, dfi_8_dw_wrdata_par_p1, 
  dfi_8_dw_wrdata_dq_en_p1, dfi_8_dw_wrdata_par_en_p1, dfi_8_aw_ck_dis, 
  dfi_8_lp_pwr_e_req, dfi_8_lp_sr_e_req, dfi_8_lp_pwr_x_req, dfi_8_aw_tx_indx_ld, 
  dfi_8_dw_tx_indx_ld, dfi_8_dw_rx_indx_ld, dfi_8_ctrlupd_ack, dfi_8_phyupd_req, 
  dfi_8_dw_wrdata_dqs_p0, dfi_8_dw_wrdata_dqs_p1, dfi_9_clk, dfi_9_rst_n, dfi_9_init_start, 
  dfi_9_aw_ck_p0, dfi_9_aw_cke_p0, dfi_9_aw_row_p0, dfi_9_aw_col_p0, dfi_9_dw_wrdata_p0, 
  dfi_9_dw_wrdata_mask_p0, dfi_9_dw_wrdata_dbi_p0, dfi_9_dw_wrdata_par_p0, 
  dfi_9_dw_wrdata_dq_en_p0, dfi_9_dw_wrdata_par_en_p0, dfi_9_aw_ck_p1, dfi_9_aw_cke_p1, 
  dfi_9_aw_row_p1, dfi_9_aw_col_p1, dfi_9_dw_wrdata_p1, dfi_9_dw_wrdata_mask_p1, 
  dfi_9_dw_wrdata_dbi_p1, dfi_9_dw_wrdata_par_p1, dfi_9_dw_wrdata_dq_en_p1, 
  dfi_9_dw_wrdata_par_en_p1, dfi_9_aw_ck_dis, dfi_9_lp_pwr_e_req, dfi_9_lp_sr_e_req, 
  dfi_9_lp_pwr_x_req, dfi_9_aw_tx_indx_ld, dfi_9_dw_tx_indx_ld, dfi_9_dw_rx_indx_ld, 
  dfi_9_ctrlupd_ack, dfi_9_phyupd_req, dfi_9_dw_wrdata_dqs_p0, dfi_9_dw_wrdata_dqs_p1, 
  dfi_10_clk, dfi_10_rst_n, dfi_10_init_start, dfi_10_aw_ck_p0, dfi_10_aw_cke_p0, 
  dfi_10_aw_row_p0, dfi_10_aw_col_p0, dfi_10_dw_wrdata_p0, dfi_10_dw_wrdata_mask_p0, 
  dfi_10_dw_wrdata_dbi_p0, dfi_10_dw_wrdata_par_p0, dfi_10_dw_wrdata_dq_en_p0, 
  dfi_10_dw_wrdata_par_en_p0, dfi_10_aw_ck_p1, dfi_10_aw_cke_p1, dfi_10_aw_row_p1, 
  dfi_10_aw_col_p1, dfi_10_dw_wrdata_p1, dfi_10_dw_wrdata_mask_p1, 
  dfi_10_dw_wrdata_dbi_p1, dfi_10_dw_wrdata_par_p1, dfi_10_dw_wrdata_dq_en_p1, 
  dfi_10_dw_wrdata_par_en_p1, dfi_10_aw_ck_dis, dfi_10_lp_pwr_e_req, dfi_10_lp_sr_e_req, 
  dfi_10_lp_pwr_x_req, dfi_10_aw_tx_indx_ld, dfi_10_dw_tx_indx_ld, dfi_10_dw_rx_indx_ld, 
  dfi_10_ctrlupd_ack, dfi_10_phyupd_req, dfi_10_dw_wrdata_dqs_p0, 
  dfi_10_dw_wrdata_dqs_p1, dfi_11_clk, dfi_11_rst_n, dfi_11_init_start, dfi_11_aw_ck_p0, 
  dfi_11_aw_cke_p0, dfi_11_aw_row_p0, dfi_11_aw_col_p0, dfi_11_dw_wrdata_p0, 
  dfi_11_dw_wrdata_mask_p0, dfi_11_dw_wrdata_dbi_p0, dfi_11_dw_wrdata_par_p0, 
  dfi_11_dw_wrdata_dq_en_p0, dfi_11_dw_wrdata_par_en_p0, dfi_11_aw_ck_p1, 
  dfi_11_aw_cke_p1, dfi_11_aw_row_p1, dfi_11_aw_col_p1, dfi_11_dw_wrdata_p1, 
  dfi_11_dw_wrdata_mask_p1, dfi_11_dw_wrdata_dbi_p1, dfi_11_dw_wrdata_par_p1, 
  dfi_11_dw_wrdata_dq_en_p1, dfi_11_dw_wrdata_par_en_p1, dfi_11_aw_ck_dis, 
  dfi_11_lp_pwr_e_req, dfi_11_lp_sr_e_req, dfi_11_lp_pwr_x_req, dfi_11_aw_tx_indx_ld, 
  dfi_11_dw_tx_indx_ld, dfi_11_dw_rx_indx_ld, dfi_11_ctrlupd_ack, dfi_11_phyupd_req, 
  dfi_11_dw_wrdata_dqs_p0, dfi_11_dw_wrdata_dqs_p1, dfi_12_clk, dfi_12_rst_n, 
  dfi_12_init_start, dfi_12_aw_ck_p0, dfi_12_aw_cke_p0, dfi_12_aw_row_p0, dfi_12_aw_col_p0, 
  dfi_12_dw_wrdata_p0, dfi_12_dw_wrdata_mask_p0, dfi_12_dw_wrdata_dbi_p0, 
  dfi_12_dw_wrdata_par_p0, dfi_12_dw_wrdata_dq_en_p0, dfi_12_dw_wrdata_par_en_p0, 
  dfi_12_aw_ck_p1, dfi_12_aw_cke_p1, dfi_12_aw_row_p1, dfi_12_aw_col_p1, 
  dfi_12_dw_wrdata_p1, dfi_12_dw_wrdata_mask_p1, dfi_12_dw_wrdata_dbi_p1, 
  dfi_12_dw_wrdata_par_p1, dfi_12_dw_wrdata_dq_en_p1, dfi_12_dw_wrdata_par_en_p1, 
  dfi_12_aw_ck_dis, dfi_12_lp_pwr_e_req, dfi_12_lp_sr_e_req, dfi_12_lp_pwr_x_req, 
  dfi_12_aw_tx_indx_ld, dfi_12_dw_tx_indx_ld, dfi_12_dw_rx_indx_ld, dfi_12_ctrlupd_ack, 
  dfi_12_phyupd_req, dfi_12_dw_wrdata_dqs_p0, dfi_12_dw_wrdata_dqs_p1, dfi_13_clk, 
  dfi_13_rst_n, dfi_13_init_start, dfi_13_aw_ck_p0, dfi_13_aw_cke_p0, dfi_13_aw_row_p0, 
  dfi_13_aw_col_p0, dfi_13_dw_wrdata_p0, dfi_13_dw_wrdata_mask_p0, 
  dfi_13_dw_wrdata_dbi_p0, dfi_13_dw_wrdata_par_p0, dfi_13_dw_wrdata_dq_en_p0, 
  dfi_13_dw_wrdata_par_en_p0, dfi_13_aw_ck_p1, dfi_13_aw_cke_p1, dfi_13_aw_row_p1, 
  dfi_13_aw_col_p1, dfi_13_dw_wrdata_p1, dfi_13_dw_wrdata_mask_p1, 
  dfi_13_dw_wrdata_dbi_p1, dfi_13_dw_wrdata_par_p1, dfi_13_dw_wrdata_dq_en_p1, 
  dfi_13_dw_wrdata_par_en_p1, dfi_13_aw_ck_dis, dfi_13_lp_pwr_e_req, dfi_13_lp_sr_e_req, 
  dfi_13_lp_pwr_x_req, dfi_13_aw_tx_indx_ld, dfi_13_dw_tx_indx_ld, dfi_13_dw_rx_indx_ld, 
  dfi_13_ctrlupd_ack, dfi_13_phyupd_req, dfi_13_dw_wrdata_dqs_p0, 
  dfi_13_dw_wrdata_dqs_p1, dfi_14_clk, dfi_14_rst_n, dfi_14_init_start, dfi_14_aw_ck_p0, 
  dfi_14_aw_cke_p0, dfi_14_aw_row_p0, dfi_14_aw_col_p0, dfi_14_dw_wrdata_p0, 
  dfi_14_dw_wrdata_mask_p0, dfi_14_dw_wrdata_dbi_p0, dfi_14_dw_wrdata_par_p0, 
  dfi_14_dw_wrdata_dq_en_p0, dfi_14_dw_wrdata_par_en_p0, dfi_14_aw_ck_p1, 
  dfi_14_aw_cke_p1, dfi_14_aw_row_p1, dfi_14_aw_col_p1, dfi_14_dw_wrdata_p1, 
  dfi_14_dw_wrdata_mask_p1, dfi_14_dw_wrdata_dbi_p1, dfi_14_dw_wrdata_par_p1, 
  dfi_14_dw_wrdata_dq_en_p1, dfi_14_dw_wrdata_par_en_p1, dfi_14_aw_ck_dis, 
  dfi_14_lp_pwr_e_req, dfi_14_lp_sr_e_req, dfi_14_lp_pwr_x_req, dfi_14_aw_tx_indx_ld, 
  dfi_14_dw_tx_indx_ld, dfi_14_dw_rx_indx_ld, dfi_14_ctrlupd_ack, dfi_14_phyupd_req, 
  dfi_14_dw_wrdata_dqs_p0, dfi_14_dw_wrdata_dqs_p1, dfi_15_clk, dfi_15_rst_n, 
  dfi_15_init_start, dfi_15_aw_ck_p0, dfi_15_aw_cke_p0, dfi_15_aw_row_p0, dfi_15_aw_col_p0, 
  dfi_15_dw_wrdata_p0, dfi_15_dw_wrdata_mask_p0, dfi_15_dw_wrdata_dbi_p0, 
  dfi_15_dw_wrdata_par_p0, dfi_15_dw_wrdata_dq_en_p0, dfi_15_dw_wrdata_par_en_p0, 
  dfi_15_aw_ck_p1, dfi_15_aw_cke_p1, dfi_15_aw_row_p1, dfi_15_aw_col_p1, 
  dfi_15_dw_wrdata_p1, dfi_15_dw_wrdata_mask_p1, dfi_15_dw_wrdata_dbi_p1, 
  dfi_15_dw_wrdata_par_p1, dfi_15_dw_wrdata_dq_en_p1, dfi_15_dw_wrdata_par_en_p1, 
  dfi_15_aw_ck_dis, dfi_15_lp_pwr_e_req, dfi_15_lp_sr_e_req, dfi_15_lp_pwr_x_req, 
  dfi_15_aw_tx_indx_ld, dfi_15_dw_tx_indx_ld, dfi_15_dw_rx_indx_ld, dfi_15_ctrlupd_ack, 
  dfi_15_phyupd_req, dfi_15_dw_wrdata_dqs_p0, dfi_15_dw_wrdata_dqs_p1, APB_0_PCLK, 
  APB_0_PRESET_N, APB_1_PCLK, APB_1_PRESET_N, dfi_0_dw_rddata_p0, dfi_0_dw_rddata_dm_p0, 
  dfi_0_dw_rddata_dbi_p0, dfi_0_dw_rddata_par_p0, dfi_0_dw_rddata_p1, 
  dfi_0_dw_rddata_dm_p1, dfi_0_dw_rddata_dbi_p1, dfi_0_dw_rddata_par_p1, 
  dfi_0_dbi_byte_disable, dfi_0_dw_rddata_valid, dfi_0_dw_derr_n, dfi_0_aw_aerr_n, 
  dfi_0_ctrlupd_req, dfi_0_phyupd_ack, dfi_0_clk_init, dfi_0_init_complete, 
  dfi_0_out_rst_n, dfi_1_dw_rddata_p0, dfi_1_dw_rddata_dm_p0, dfi_1_dw_rddata_dbi_p0, 
  dfi_1_dw_rddata_par_p0, dfi_1_dw_rddata_p1, dfi_1_dw_rddata_dm_p1, 
  dfi_1_dw_rddata_dbi_p1, dfi_1_dw_rddata_par_p1, dfi_1_dbi_byte_disable, 
  dfi_1_dw_rddata_valid, dfi_1_dw_derr_n, dfi_1_aw_aerr_n, dfi_1_ctrlupd_req, 
  dfi_1_phyupd_ack, dfi_1_clk_init, dfi_1_init_complete, dfi_1_out_rst_n, 
  dfi_2_dw_rddata_p0, dfi_2_dw_rddata_dm_p0, dfi_2_dw_rddata_dbi_p0, 
  dfi_2_dw_rddata_par_p0, dfi_2_dw_rddata_p1, dfi_2_dw_rddata_dm_p1, 
  dfi_2_dw_rddata_dbi_p1, dfi_2_dw_rddata_par_p1, dfi_2_dbi_byte_disable, 
  dfi_2_dw_rddata_valid, dfi_2_dw_derr_n, dfi_2_aw_aerr_n, dfi_2_ctrlupd_req, 
  dfi_2_phyupd_ack, dfi_2_clk_init, dfi_2_init_complete, dfi_2_out_rst_n, 
  dfi_3_dw_rddata_p0, dfi_3_dw_rddata_dm_p0, dfi_3_dw_rddata_dbi_p0, 
  dfi_3_dw_rddata_par_p0, dfi_3_dw_rddata_p1, dfi_3_dw_rddata_dm_p1, 
  dfi_3_dw_rddata_dbi_p1, dfi_3_dw_rddata_par_p1, dfi_3_dbi_byte_disable, 
  dfi_3_dw_rddata_valid, dfi_3_dw_derr_n, dfi_3_aw_aerr_n, dfi_3_ctrlupd_req, 
  dfi_3_phyupd_ack, dfi_3_clk_init, dfi_3_init_complete, dfi_3_out_rst_n, 
  dfi_4_dw_rddata_p0, dfi_4_dw_rddata_dm_p0, dfi_4_dw_rddata_dbi_p0, 
  dfi_4_dw_rddata_par_p0, dfi_4_dw_rddata_p1, dfi_4_dw_rddata_dm_p1, 
  dfi_4_dw_rddata_dbi_p1, dfi_4_dw_rddata_par_p1, dfi_4_dbi_byte_disable, 
  dfi_4_dw_rddata_valid, dfi_4_dw_derr_n, dfi_4_aw_aerr_n, dfi_4_ctrlupd_req, 
  dfi_4_phyupd_ack, dfi_4_clk_init, dfi_4_init_complete, dfi_4_out_rst_n, 
  dfi_5_dw_rddata_p0, dfi_5_dw_rddata_dm_p0, dfi_5_dw_rddata_dbi_p0, 
  dfi_5_dw_rddata_par_p0, dfi_5_dw_rddata_p1, dfi_5_dw_rddata_dm_p1, 
  dfi_5_dw_rddata_dbi_p1, dfi_5_dw_rddata_par_p1, dfi_5_dbi_byte_disable, 
  dfi_5_dw_rddata_valid, dfi_5_dw_derr_n, dfi_5_aw_aerr_n, dfi_5_ctrlupd_req, 
  dfi_5_phyupd_ack, dfi_5_clk_init, dfi_5_init_complete, dfi_5_out_rst_n, 
  dfi_6_dw_rddata_p0, dfi_6_dw_rddata_dm_p0, dfi_6_dw_rddata_dbi_p0, 
  dfi_6_dw_rddata_par_p0, dfi_6_dw_rddata_p1, dfi_6_dw_rddata_dm_p1, 
  dfi_6_dw_rddata_dbi_p1, dfi_6_dw_rddata_par_p1, dfi_6_dbi_byte_disable, 
  dfi_6_dw_rddata_valid, dfi_6_dw_derr_n, dfi_6_aw_aerr_n, dfi_6_ctrlupd_req, 
  dfi_6_phyupd_ack, dfi_6_clk_init, dfi_6_init_complete, dfi_6_out_rst_n, 
  dfi_7_dw_rddata_p0, dfi_7_dw_rddata_dm_p0, dfi_7_dw_rddata_dbi_p0, 
  dfi_7_dw_rddata_par_p0, dfi_7_dw_rddata_p1, dfi_7_dw_rddata_dm_p1, 
  dfi_7_dw_rddata_dbi_p1, dfi_7_dw_rddata_par_p1, dfi_7_dbi_byte_disable, 
  dfi_7_dw_rddata_valid, dfi_7_dw_derr_n, dfi_7_aw_aerr_n, dfi_7_ctrlupd_req, 
  dfi_7_phyupd_ack, dfi_7_clk_init, dfi_7_init_complete, dfi_7_out_rst_n, 
  dfi_8_dw_rddata_p0, dfi_8_dw_rddata_dm_p0, dfi_8_dw_rddata_dbi_p0, 
  dfi_8_dw_rddata_par_p0, dfi_8_dw_rddata_p1, dfi_8_dw_rddata_dm_p1, 
  dfi_8_dw_rddata_dbi_p1, dfi_8_dw_rddata_par_p1, dfi_8_dbi_byte_disable, 
  dfi_8_dw_rddata_valid, dfi_8_dw_derr_n, dfi_8_aw_aerr_n, dfi_8_ctrlupd_req, 
  dfi_8_phyupd_ack, dfi_8_clk_init, dfi_8_init_complete, dfi_8_out_rst_n, 
  dfi_9_dw_rddata_p0, dfi_9_dw_rddata_dm_p0, dfi_9_dw_rddata_dbi_p0, 
  dfi_9_dw_rddata_par_p0, dfi_9_dw_rddata_p1, dfi_9_dw_rddata_dm_p1, 
  dfi_9_dw_rddata_dbi_p1, dfi_9_dw_rddata_par_p1, dfi_9_dbi_byte_disable, 
  dfi_9_dw_rddata_valid, dfi_9_dw_derr_n, dfi_9_aw_aerr_n, dfi_9_ctrlupd_req, 
  dfi_9_phyupd_ack, dfi_9_clk_init, dfi_9_init_complete, dfi_9_out_rst_n, 
  dfi_10_dw_rddata_p0, dfi_10_dw_rddata_dm_p0, dfi_10_dw_rddata_dbi_p0, 
  dfi_10_dw_rddata_par_p0, dfi_10_dw_rddata_p1, dfi_10_dw_rddata_dm_p1, 
  dfi_10_dw_rddata_dbi_p1, dfi_10_dw_rddata_par_p1, dfi_10_dbi_byte_disable, 
  dfi_10_dw_rddata_valid, dfi_10_dw_derr_n, dfi_10_aw_aerr_n, dfi_10_ctrlupd_req, 
  dfi_10_phyupd_ack, dfi_10_clk_init, dfi_10_init_complete, dfi_10_out_rst_n, 
  dfi_11_dw_rddata_p0, dfi_11_dw_rddata_dm_p0, dfi_11_dw_rddata_dbi_p0, 
  dfi_11_dw_rddata_par_p0, dfi_11_dw_rddata_p1, dfi_11_dw_rddata_dm_p1, 
  dfi_11_dw_rddata_dbi_p1, dfi_11_dw_rddata_par_p1, dfi_11_dbi_byte_disable, 
  dfi_11_dw_rddata_valid, dfi_11_dw_derr_n, dfi_11_aw_aerr_n, dfi_11_ctrlupd_req, 
  dfi_11_phyupd_ack, dfi_11_clk_init, dfi_11_init_complete, dfi_11_out_rst_n, 
  dfi_12_dw_rddata_p0, dfi_12_dw_rddata_dm_p0, dfi_12_dw_rddata_dbi_p0, 
  dfi_12_dw_rddata_par_p0, dfi_12_dw_rddata_p1, dfi_12_dw_rddata_dm_p1, 
  dfi_12_dw_rddata_dbi_p1, dfi_12_dw_rddata_par_p1, dfi_12_dbi_byte_disable, 
  dfi_12_dw_rddata_valid, dfi_12_dw_derr_n, dfi_12_aw_aerr_n, dfi_12_ctrlupd_req, 
  dfi_12_phyupd_ack, dfi_12_clk_init, dfi_12_init_complete, dfi_12_out_rst_n, 
  dfi_13_dw_rddata_p0, dfi_13_dw_rddata_dm_p0, dfi_13_dw_rddata_dbi_p0, 
  dfi_13_dw_rddata_par_p0, dfi_13_dw_rddata_p1, dfi_13_dw_rddata_dm_p1, 
  dfi_13_dw_rddata_dbi_p1, dfi_13_dw_rddata_par_p1, dfi_13_dbi_byte_disable, 
  dfi_13_dw_rddata_valid, dfi_13_dw_derr_n, dfi_13_aw_aerr_n, dfi_13_ctrlupd_req, 
  dfi_13_phyupd_ack, dfi_13_clk_init, dfi_13_init_complete, dfi_13_out_rst_n, 
  dfi_14_dw_rddata_p0, dfi_14_dw_rddata_dm_p0, dfi_14_dw_rddata_dbi_p0, 
  dfi_14_dw_rddata_par_p0, dfi_14_dw_rddata_p1, dfi_14_dw_rddata_dm_p1, 
  dfi_14_dw_rddata_dbi_p1, dfi_14_dw_rddata_par_p1, dfi_14_dbi_byte_disable, 
  dfi_14_dw_rddata_valid, dfi_14_dw_derr_n, dfi_14_aw_aerr_n, dfi_14_ctrlupd_req, 
  dfi_14_phyupd_ack, dfi_14_clk_init, dfi_14_init_complete, dfi_14_out_rst_n, 
  dfi_15_dw_rddata_p0, dfi_15_dw_rddata_dm_p0, dfi_15_dw_rddata_dbi_p0, 
  dfi_15_dw_rddata_par_p0, dfi_15_dw_rddata_p1, dfi_15_dw_rddata_dm_p1, 
  dfi_15_dw_rddata_dbi_p1, dfi_15_dw_rddata_par_p1, dfi_15_dbi_byte_disable, 
  dfi_15_dw_rddata_valid, dfi_15_dw_derr_n, dfi_15_aw_aerr_n, dfi_15_ctrlupd_req, 
  dfi_15_phyupd_ack, dfi_15_clk_init, dfi_15_init_complete, dfi_15_out_rst_n, 
  apb_complete_0, apb_complete_1, DRAM_0_STAT_CATTRIP, DRAM_0_STAT_TEMP, 
  DRAM_1_STAT_CATTRIP, DRAM_1_STAT_TEMP)
/* synthesis syn_black_box black_box_pad_pin="HBM_REF_CLK_0,HBM_REF_CLK_1,dfi_0_clk,dfi_0_rst_n,dfi_0_init_start,dfi_0_aw_ck_p0[1:0],dfi_0_aw_cke_p0[1:0],dfi_0_aw_row_p0[11:0],dfi_0_aw_col_p0[15:0],dfi_0_dw_wrdata_p0[255:0],dfi_0_dw_wrdata_mask_p0[31:0],dfi_0_dw_wrdata_dbi_p0[31:0],dfi_0_dw_wrdata_par_p0[7:0],dfi_0_dw_wrdata_dq_en_p0[7:0],dfi_0_dw_wrdata_par_en_p0[7:0],dfi_0_aw_ck_p1[1:0],dfi_0_aw_cke_p1[1:0],dfi_0_aw_row_p1[11:0],dfi_0_aw_col_p1[15:0],dfi_0_dw_wrdata_p1[255:0],dfi_0_dw_wrdata_mask_p1[31:0],dfi_0_dw_wrdata_dbi_p1[31:0],dfi_0_dw_wrdata_par_p1[7:0],dfi_0_dw_wrdata_dq_en_p1[7:0],dfi_0_dw_wrdata_par_en_p1[7:0],dfi_0_aw_ck_dis,dfi_0_lp_pwr_e_req,dfi_0_lp_sr_e_req,dfi_0_lp_pwr_x_req,dfi_0_aw_tx_indx_ld,dfi_0_dw_tx_indx_ld,dfi_0_dw_rx_indx_ld,dfi_0_ctrlupd_ack,dfi_0_phyupd_req,dfi_0_dw_wrdata_dqs_p0[7:0],dfi_0_dw_wrdata_dqs_p1[7:0],dfi_1_clk,dfi_1_rst_n,dfi_1_init_start,dfi_1_aw_ck_p0[1:0],dfi_1_aw_cke_p0[1:0],dfi_1_aw_row_p0[11:0],dfi_1_aw_col_p0[15:0],dfi_1_dw_wrdata_p0[255:0],dfi_1_dw_wrdata_mask_p0[31:0],dfi_1_dw_wrdata_dbi_p0[31:0],dfi_1_dw_wrdata_par_p0[7:0],dfi_1_dw_wrdata_dq_en_p0[7:0],dfi_1_dw_wrdata_par_en_p0[7:0],dfi_1_aw_ck_p1[1:0],dfi_1_aw_cke_p1[1:0],dfi_1_aw_row_p1[11:0],dfi_1_aw_col_p1[15:0],dfi_1_dw_wrdata_p1[255:0],dfi_1_dw_wrdata_mask_p1[31:0],dfi_1_dw_wrdata_dbi_p1[31:0],dfi_1_dw_wrdata_par_p1[7:0],dfi_1_dw_wrdata_dq_en_p1[7:0],dfi_1_dw_wrdata_par_en_p1[7:0],dfi_1_aw_ck_dis,dfi_1_lp_pwr_e_req,dfi_1_lp_sr_e_req,dfi_1_lp_pwr_x_req,dfi_1_aw_tx_indx_ld,dfi_1_dw_tx_indx_ld,dfi_1_dw_rx_indx_ld,dfi_1_ctrlupd_ack,dfi_1_phyupd_req,dfi_1_dw_wrdata_dqs_p0[7:0],dfi_1_dw_wrdata_dqs_p1[7:0],dfi_2_clk,dfi_2_rst_n,dfi_2_init_start,dfi_2_aw_ck_p0[1:0],dfi_2_aw_cke_p0[1:0],dfi_2_aw_row_p0[11:0],dfi_2_aw_col_p0[15:0],dfi_2_dw_wrdata_p0[255:0],dfi_2_dw_wrdata_mask_p0[31:0],dfi_2_dw_wrdata_dbi_p0[31:0],dfi_2_dw_wrdata_par_p0[7:0],dfi_2_dw_wrdata_dq_en_p0[7:0],dfi_2_dw_wrdata_par_en_p0[7:0],dfi_2_aw_ck_p1[1:0],dfi_2_aw_cke_p1[1:0],dfi_2_aw_row_p1[11:0],dfi_2_aw_col_p1[15:0],dfi_2_dw_wrdata_p1[255:0],dfi_2_dw_wrdata_mask_p1[31:0],dfi_2_dw_wrdata_dbi_p1[31:0],dfi_2_dw_wrdata_par_p1[7:0],dfi_2_dw_wrdata_dq_en_p1[7:0],dfi_2_dw_wrdata_par_en_p1[7:0],dfi_2_aw_ck_dis,dfi_2_lp_pwr_e_req,dfi_2_lp_sr_e_req,dfi_2_lp_pwr_x_req,dfi_2_aw_tx_indx_ld,dfi_2_dw_tx_indx_ld,dfi_2_dw_rx_indx_ld,dfi_2_ctrlupd_ack,dfi_2_phyupd_req,dfi_2_dw_wrdata_dqs_p0[7:0],dfi_2_dw_wrdata_dqs_p1[7:0],dfi_3_clk,dfi_3_rst_n,dfi_3_init_start,dfi_3_aw_ck_p0[1:0],dfi_3_aw_cke_p0[1:0],dfi_3_aw_row_p0[11:0],dfi_3_aw_col_p0[15:0],dfi_3_dw_wrdata_p0[255:0],dfi_3_dw_wrdata_mask_p0[31:0],dfi_3_dw_wrdata_dbi_p0[31:0],dfi_3_dw_wrdata_par_p0[7:0],dfi_3_dw_wrdata_dq_en_p0[7:0],dfi_3_dw_wrdata_par_en_p0[7:0],dfi_3_aw_ck_p1[1:0],dfi_3_aw_cke_p1[1:0],dfi_3_aw_row_p1[11:0],dfi_3_aw_col_p1[15:0],dfi_3_dw_wrdata_p1[255:0],dfi_3_dw_wrdata_mask_p1[31:0],dfi_3_dw_wrdata_dbi_p1[31:0],dfi_3_dw_wrdata_par_p1[7:0],dfi_3_dw_wrdata_dq_en_p1[7:0],dfi_3_dw_wrdata_par_en_p1[7:0],dfi_3_aw_ck_dis,dfi_3_lp_pwr_e_req,dfi_3_lp_sr_e_req,dfi_3_lp_pwr_x_req,dfi_3_aw_tx_indx_ld,dfi_3_dw_tx_indx_ld,dfi_3_dw_rx_indx_ld,dfi_3_ctrlupd_ack,dfi_3_phyupd_req,dfi_3_dw_wrdata_dqs_p0[7:0],dfi_3_dw_wrdata_dqs_p1[7:0],dfi_4_clk,dfi_4_rst_n,dfi_4_init_start,dfi_4_aw_ck_p0[1:0],dfi_4_aw_cke_p0[1:0],dfi_4_aw_row_p0[11:0],dfi_4_aw_col_p0[15:0],dfi_4_dw_wrdata_p0[255:0],dfi_4_dw_wrdata_mask_p0[31:0],dfi_4_dw_wrdata_dbi_p0[31:0],dfi_4_dw_wrdata_par_p0[7:0],dfi_4_dw_wrdata_dq_en_p0[7:0],dfi_4_dw_wrdata_par_en_p0[7:0],dfi_4_aw_ck_p1[1:0],dfi_4_aw_cke_p1[1:0],dfi_4_aw_row_p1[11:0],dfi_4_aw_col_p1[15:0],dfi_4_dw_wrdata_p1[255:0],dfi_4_dw_wrdata_mask_p1[31:0],dfi_4_dw_wrdata_dbi_p1[31:0],dfi_4_dw_wrdata_par_p1[7:0],dfi_4_dw_wrdata_dq_en_p1[7:0],dfi_4_dw_wrdata_par_en_p1[7:0],dfi_4_aw_ck_dis,dfi_4_lp_pwr_e_req,dfi_4_lp_sr_e_req,dfi_4_lp_pwr_x_req,dfi_4_aw_tx_indx_ld,dfi_4_dw_tx_indx_ld,dfi_4_dw_rx_indx_ld,dfi_4_ctrlupd_ack,dfi_4_phyupd_req,dfi_4_dw_wrdata_dqs_p0[7:0],dfi_4_dw_wrdata_dqs_p1[7:0],dfi_5_clk,dfi_5_rst_n,dfi_5_init_start,dfi_5_aw_ck_p0[1:0],dfi_5_aw_cke_p0[1:0],dfi_5_aw_row_p0[11:0],dfi_5_aw_col_p0[15:0],dfi_5_dw_wrdata_p0[255:0],dfi_5_dw_wrdata_mask_p0[31:0],dfi_5_dw_wrdata_dbi_p0[31:0],dfi_5_dw_wrdata_par_p0[7:0],dfi_5_dw_wrdata_dq_en_p0[7:0],dfi_5_dw_wrdata_par_en_p0[7:0],dfi_5_aw_ck_p1[1:0],dfi_5_aw_cke_p1[1:0],dfi_5_aw_row_p1[11:0],dfi_5_aw_col_p1[15:0],dfi_5_dw_wrdata_p1[255:0],dfi_5_dw_wrdata_mask_p1[31:0],dfi_5_dw_wrdata_dbi_p1[31:0],dfi_5_dw_wrdata_par_p1[7:0],dfi_5_dw_wrdata_dq_en_p1[7:0],dfi_5_dw_wrdata_par_en_p1[7:0],dfi_5_aw_ck_dis,dfi_5_lp_pwr_e_req,dfi_5_lp_sr_e_req,dfi_5_lp_pwr_x_req,dfi_5_aw_tx_indx_ld,dfi_5_dw_tx_indx_ld,dfi_5_dw_rx_indx_ld,dfi_5_ctrlupd_ack,dfi_5_phyupd_req,dfi_5_dw_wrdata_dqs_p0[7:0],dfi_5_dw_wrdata_dqs_p1[7:0],dfi_6_clk,dfi_6_rst_n,dfi_6_init_start,dfi_6_aw_ck_p0[1:0],dfi_6_aw_cke_p0[1:0],dfi_6_aw_row_p0[11:0],dfi_6_aw_col_p0[15:0],dfi_6_dw_wrdata_p0[255:0],dfi_6_dw_wrdata_mask_p0[31:0],dfi_6_dw_wrdata_dbi_p0[31:0],dfi_6_dw_wrdata_par_p0[7:0],dfi_6_dw_wrdata_dq_en_p0[7:0],dfi_6_dw_wrdata_par_en_p0[7:0],dfi_6_aw_ck_p1[1:0],dfi_6_aw_cke_p1[1:0],dfi_6_aw_row_p1[11:0],dfi_6_aw_col_p1[15:0],dfi_6_dw_wrdata_p1[255:0],dfi_6_dw_wrdata_mask_p1[31:0],dfi_6_dw_wrdata_dbi_p1[31:0],dfi_6_dw_wrdata_par_p1[7:0],dfi_6_dw_wrdata_dq_en_p1[7:0],dfi_6_dw_wrdata_par_en_p1[7:0],dfi_6_aw_ck_dis,dfi_6_lp_pwr_e_req,dfi_6_lp_sr_e_req,dfi_6_lp_pwr_x_req,dfi_6_aw_tx_indx_ld,dfi_6_dw_tx_indx_ld,dfi_6_dw_rx_indx_ld,dfi_6_ctrlupd_ack,dfi_6_phyupd_req,dfi_6_dw_wrdata_dqs_p0[7:0],dfi_6_dw_wrdata_dqs_p1[7:0],dfi_7_clk,dfi_7_rst_n,dfi_7_init_start,dfi_7_aw_ck_p0[1:0],dfi_7_aw_cke_p0[1:0],dfi_7_aw_row_p0[11:0],dfi_7_aw_col_p0[15:0],dfi_7_dw_wrdata_p0[255:0],dfi_7_dw_wrdata_mask_p0[31:0],dfi_7_dw_wrdata_dbi_p0[31:0],dfi_7_dw_wrdata_par_p0[7:0],dfi_7_dw_wrdata_dq_en_p0[7:0],dfi_7_dw_wrdata_par_en_p0[7:0],dfi_7_aw_ck_p1[1:0],dfi_7_aw_cke_p1[1:0],dfi_7_aw_row_p1[11:0],dfi_7_aw_col_p1[15:0],dfi_7_dw_wrdata_p1[255:0],dfi_7_dw_wrdata_mask_p1[31:0],dfi_7_dw_wrdata_dbi_p1[31:0],dfi_7_dw_wrdata_par_p1[7:0],dfi_7_dw_wrdata_dq_en_p1[7:0],dfi_7_dw_wrdata_par_en_p1[7:0],dfi_7_aw_ck_dis,dfi_7_lp_pwr_e_req,dfi_7_lp_sr_e_req,dfi_7_lp_pwr_x_req,dfi_7_aw_tx_indx_ld,dfi_7_dw_tx_indx_ld,dfi_7_dw_rx_indx_ld,dfi_7_ctrlupd_ack,dfi_7_phyupd_req,dfi_7_dw_wrdata_dqs_p0[7:0],dfi_7_dw_wrdata_dqs_p1[7:0],dfi_8_clk,dfi_8_rst_n,dfi_8_init_start,dfi_8_aw_ck_p0[1:0],dfi_8_aw_cke_p0[1:0],dfi_8_aw_row_p0[11:0],dfi_8_aw_col_p0[15:0],dfi_8_dw_wrdata_p0[255:0],dfi_8_dw_wrdata_mask_p0[31:0],dfi_8_dw_wrdata_dbi_p0[31:0],dfi_8_dw_wrdata_par_p0[7:0],dfi_8_dw_wrdata_dq_en_p0[7:0],dfi_8_dw_wrdata_par_en_p0[7:0],dfi_8_aw_ck_p1[1:0],dfi_8_aw_cke_p1[1:0],dfi_8_aw_row_p1[11:0],dfi_8_aw_col_p1[15:0],dfi_8_dw_wrdata_p1[255:0],dfi_8_dw_wrdata_mask_p1[31:0],dfi_8_dw_wrdata_dbi_p1[31:0],dfi_8_dw_wrdata_par_p1[7:0],dfi_8_dw_wrdata_dq_en_p1[7:0],dfi_8_dw_wrdata_par_en_p1[7:0],dfi_8_aw_ck_dis,dfi_8_lp_pwr_e_req,dfi_8_lp_sr_e_req,dfi_8_lp_pwr_x_req,dfi_8_aw_tx_indx_ld,dfi_8_dw_tx_indx_ld,dfi_8_dw_rx_indx_ld,dfi_8_ctrlupd_ack,dfi_8_phyupd_req,dfi_8_dw_wrdata_dqs_p0[7:0],dfi_8_dw_wrdata_dqs_p1[7:0],dfi_9_clk,dfi_9_rst_n,dfi_9_init_start,dfi_9_aw_ck_p0[1:0],dfi_9_aw_cke_p0[1:0],dfi_9_aw_row_p0[11:0],dfi_9_aw_col_p0[15:0],dfi_9_dw_wrdata_p0[255:0],dfi_9_dw_wrdata_mask_p0[31:0],dfi_9_dw_wrdata_dbi_p0[31:0],dfi_9_dw_wrdata_par_p0[7:0],dfi_9_dw_wrdata_dq_en_p0[7:0],dfi_9_dw_wrdata_par_en_p0[7:0],dfi_9_aw_ck_p1[1:0],dfi_9_aw_cke_p1[1:0],dfi_9_aw_row_p1[11:0],dfi_9_aw_col_p1[15:0],dfi_9_dw_wrdata_p1[255:0],dfi_9_dw_wrdata_mask_p1[31:0],dfi_9_dw_wrdata_dbi_p1[31:0],dfi_9_dw_wrdata_par_p1[7:0],dfi_9_dw_wrdata_dq_en_p1[7:0],dfi_9_dw_wrdata_par_en_p1[7:0],dfi_9_aw_ck_dis,dfi_9_lp_pwr_e_req,dfi_9_lp_sr_e_req,dfi_9_lp_pwr_x_req,dfi_9_aw_tx_indx_ld,dfi_9_dw_tx_indx_ld,dfi_9_dw_rx_indx_ld,dfi_9_ctrlupd_ack,dfi_9_phyupd_req,dfi_9_dw_wrdata_dqs_p0[7:0],dfi_9_dw_wrdata_dqs_p1[7:0],dfi_10_clk,dfi_10_rst_n,dfi_10_init_start,dfi_10_aw_ck_p0[1:0],dfi_10_aw_cke_p0[1:0],dfi_10_aw_row_p0[11:0],dfi_10_aw_col_p0[15:0],dfi_10_dw_wrdata_p0[255:0],dfi_10_dw_wrdata_mask_p0[31:0],dfi_10_dw_wrdata_dbi_p0[31:0],dfi_10_dw_wrdata_par_p0[7:0],dfi_10_dw_wrdata_dq_en_p0[7:0],dfi_10_dw_wrdata_par_en_p0[7:0],dfi_10_aw_ck_p1[1:0],dfi_10_aw_cke_p1[1:0],dfi_10_aw_row_p1[11:0],dfi_10_aw_col_p1[15:0],dfi_10_dw_wrdata_p1[255:0],dfi_10_dw_wrdata_mask_p1[31:0],dfi_10_dw_wrdata_dbi_p1[31:0],dfi_10_dw_wrdata_par_p1[7:0],dfi_10_dw_wrdata_dq_en_p1[7:0],dfi_10_dw_wrdata_par_en_p1[7:0],dfi_10_aw_ck_dis,dfi_10_lp_pwr_e_req,dfi_10_lp_sr_e_req,dfi_10_lp_pwr_x_req,dfi_10_aw_tx_indx_ld,dfi_10_dw_tx_indx_ld,dfi_10_dw_rx_indx_ld,dfi_10_ctrlupd_ack,dfi_10_phyupd_req,dfi_10_dw_wrdata_dqs_p0[7:0],dfi_10_dw_wrdata_dqs_p1[7:0],dfi_11_clk,dfi_11_rst_n,dfi_11_init_start,dfi_11_aw_ck_p0[1:0],dfi_11_aw_cke_p0[1:0],dfi_11_aw_row_p0[11:0],dfi_11_aw_col_p0[15:0],dfi_11_dw_wrdata_p0[255:0],dfi_11_dw_wrdata_mask_p0[31:0],dfi_11_dw_wrdata_dbi_p0[31:0],dfi_11_dw_wrdata_par_p0[7:0],dfi_11_dw_wrdata_dq_en_p0[7:0],dfi_11_dw_wrdata_par_en_p0[7:0],dfi_11_aw_ck_p1[1:0],dfi_11_aw_cke_p1[1:0],dfi_11_aw_row_p1[11:0],dfi_11_aw_col_p1[15:0],dfi_11_dw_wrdata_p1[255:0],dfi_11_dw_wrdata_mask_p1[31:0],dfi_11_dw_wrdata_dbi_p1[31:0],dfi_11_dw_wrdata_par_p1[7:0],dfi_11_dw_wrdata_dq_en_p1[7:0],dfi_11_dw_wrdata_par_en_p1[7:0],dfi_11_aw_ck_dis,dfi_11_lp_pwr_e_req,dfi_11_lp_sr_e_req,dfi_11_lp_pwr_x_req,dfi_11_aw_tx_indx_ld,dfi_11_dw_tx_indx_ld,dfi_11_dw_rx_indx_ld,dfi_11_ctrlupd_ack,dfi_11_phyupd_req,dfi_11_dw_wrdata_dqs_p0[7:0],dfi_11_dw_wrdata_dqs_p1[7:0],dfi_12_clk,dfi_12_rst_n,dfi_12_init_start,dfi_12_aw_ck_p0[1:0],dfi_12_aw_cke_p0[1:0],dfi_12_aw_row_p0[11:0],dfi_12_aw_col_p0[15:0],dfi_12_dw_wrdata_p0[255:0],dfi_12_dw_wrdata_mask_p0[31:0],dfi_12_dw_wrdata_dbi_p0[31:0],dfi_12_dw_wrdata_par_p0[7:0],dfi_12_dw_wrdata_dq_en_p0[7:0],dfi_12_dw_wrdata_par_en_p0[7:0],dfi_12_aw_ck_p1[1:0],dfi_12_aw_cke_p1[1:0],dfi_12_aw_row_p1[11:0],dfi_12_aw_col_p1[15:0],dfi_12_dw_wrdata_p1[255:0],dfi_12_dw_wrdata_mask_p1[31:0],dfi_12_dw_wrdata_dbi_p1[31:0],dfi_12_dw_wrdata_par_p1[7:0],dfi_12_dw_wrdata_dq_en_p1[7:0],dfi_12_dw_wrdata_par_en_p1[7:0],dfi_12_aw_ck_dis,dfi_12_lp_pwr_e_req,dfi_12_lp_sr_e_req,dfi_12_lp_pwr_x_req,dfi_12_aw_tx_indx_ld,dfi_12_dw_tx_indx_ld,dfi_12_dw_rx_indx_ld,dfi_12_ctrlupd_ack,dfi_12_phyupd_req,dfi_12_dw_wrdata_dqs_p0[7:0],dfi_12_dw_wrdata_dqs_p1[7:0],dfi_13_clk,dfi_13_rst_n,dfi_13_init_start,dfi_13_aw_ck_p0[1:0],dfi_13_aw_cke_p0[1:0],dfi_13_aw_row_p0[11:0],dfi_13_aw_col_p0[15:0],dfi_13_dw_wrdata_p0[255:0],dfi_13_dw_wrdata_mask_p0[31:0],dfi_13_dw_wrdata_dbi_p0[31:0],dfi_13_dw_wrdata_par_p0[7:0],dfi_13_dw_wrdata_dq_en_p0[7:0],dfi_13_dw_wrdata_par_en_p0[7:0],dfi_13_aw_ck_p1[1:0],dfi_13_aw_cke_p1[1:0],dfi_13_aw_row_p1[11:0],dfi_13_aw_col_p1[15:0],dfi_13_dw_wrdata_p1[255:0],dfi_13_dw_wrdata_mask_p1[31:0],dfi_13_dw_wrdata_dbi_p1[31:0],dfi_13_dw_wrdata_par_p1[7:0],dfi_13_dw_wrdata_dq_en_p1[7:0],dfi_13_dw_wrdata_par_en_p1[7:0],dfi_13_aw_ck_dis,dfi_13_lp_pwr_e_req,dfi_13_lp_sr_e_req,dfi_13_lp_pwr_x_req,dfi_13_aw_tx_indx_ld,dfi_13_dw_tx_indx_ld,dfi_13_dw_rx_indx_ld,dfi_13_ctrlupd_ack,dfi_13_phyupd_req,dfi_13_dw_wrdata_dqs_p0[7:0],dfi_13_dw_wrdata_dqs_p1[7:0],dfi_14_clk,dfi_14_rst_n,dfi_14_init_start,dfi_14_aw_ck_p0[1:0],dfi_14_aw_cke_p0[1:0],dfi_14_aw_row_p0[11:0],dfi_14_aw_col_p0[15:0],dfi_14_dw_wrdata_p0[255:0],dfi_14_dw_wrdata_mask_p0[31:0],dfi_14_dw_wrdata_dbi_p0[31:0],dfi_14_dw_wrdata_par_p0[7:0],dfi_14_dw_wrdata_dq_en_p0[7:0],dfi_14_dw_wrdata_par_en_p0[7:0],dfi_14_aw_ck_p1[1:0],dfi_14_aw_cke_p1[1:0],dfi_14_aw_row_p1[11:0],dfi_14_aw_col_p1[15:0],dfi_14_dw_wrdata_p1[255:0],dfi_14_dw_wrdata_mask_p1[31:0],dfi_14_dw_wrdata_dbi_p1[31:0],dfi_14_dw_wrdata_par_p1[7:0],dfi_14_dw_wrdata_dq_en_p1[7:0],dfi_14_dw_wrdata_par_en_p1[7:0],dfi_14_aw_ck_dis,dfi_14_lp_pwr_e_req,dfi_14_lp_sr_e_req,dfi_14_lp_pwr_x_req,dfi_14_aw_tx_indx_ld,dfi_14_dw_tx_indx_ld,dfi_14_dw_rx_indx_ld,dfi_14_ctrlupd_ack,dfi_14_phyupd_req,dfi_14_dw_wrdata_dqs_p0[7:0],dfi_14_dw_wrdata_dqs_p1[7:0],dfi_15_clk,dfi_15_rst_n,dfi_15_init_start,dfi_15_aw_ck_p0[1:0],dfi_15_aw_cke_p0[1:0],dfi_15_aw_row_p0[11:0],dfi_15_aw_col_p0[15:0],dfi_15_dw_wrdata_p0[255:0],dfi_15_dw_wrdata_mask_p0[31:0],dfi_15_dw_wrdata_dbi_p0[31:0],dfi_15_dw_wrdata_par_p0[7:0],dfi_15_dw_wrdata_dq_en_p0[7:0],dfi_15_dw_wrdata_par_en_p0[7:0],dfi_15_aw_ck_p1[1:0],dfi_15_aw_cke_p1[1:0],dfi_15_aw_row_p1[11:0],dfi_15_aw_col_p1[15:0],dfi_15_dw_wrdata_p1[255:0],dfi_15_dw_wrdata_mask_p1[31:0],dfi_15_dw_wrdata_dbi_p1[31:0],dfi_15_dw_wrdata_par_p1[7:0],dfi_15_dw_wrdata_dq_en_p1[7:0],dfi_15_dw_wrdata_par_en_p1[7:0],dfi_15_aw_ck_dis,dfi_15_lp_pwr_e_req,dfi_15_lp_sr_e_req,dfi_15_lp_pwr_x_req,dfi_15_aw_tx_indx_ld,dfi_15_dw_tx_indx_ld,dfi_15_dw_rx_indx_ld,dfi_15_ctrlupd_ack,dfi_15_phyupd_req,dfi_15_dw_wrdata_dqs_p0[7:0],dfi_15_dw_wrdata_dqs_p1[7:0],APB_0_PCLK,APB_0_PRESET_N,APB_1_PCLK,APB_1_PRESET_N,dfi_0_dw_rddata_p0[255:0],dfi_0_dw_rddata_dm_p0[31:0],dfi_0_dw_rddata_dbi_p0[31:0],dfi_0_dw_rddata_par_p0[7:0],dfi_0_dw_rddata_p1[255:0],dfi_0_dw_rddata_dm_p1[31:0],dfi_0_dw_rddata_dbi_p1[31:0],dfi_0_dw_rddata_par_p1[7:0],dfi_0_dbi_byte_disable[15:0],dfi_0_dw_rddata_valid[3:0],dfi_0_dw_derr_n[7:0],dfi_0_aw_aerr_n[1:0],dfi_0_ctrlupd_req,dfi_0_phyupd_ack,dfi_0_clk_init,dfi_0_init_complete,dfi_0_out_rst_n,dfi_1_dw_rddata_p0[255:0],dfi_1_dw_rddata_dm_p0[31:0],dfi_1_dw_rddata_dbi_p0[31:0],dfi_1_dw_rddata_par_p0[7:0],dfi_1_dw_rddata_p1[255:0],dfi_1_dw_rddata_dm_p1[31:0],dfi_1_dw_rddata_dbi_p1[31:0],dfi_1_dw_rddata_par_p1[7:0],dfi_1_dbi_byte_disable[15:0],dfi_1_dw_rddata_valid[3:0],dfi_1_dw_derr_n[7:0],dfi_1_aw_aerr_n[1:0],dfi_1_ctrlupd_req,dfi_1_phyupd_ack,dfi_1_clk_init,dfi_1_init_complete,dfi_1_out_rst_n,dfi_2_dw_rddata_p0[255:0],dfi_2_dw_rddata_dm_p0[31:0],dfi_2_dw_rddata_dbi_p0[31:0],dfi_2_dw_rddata_par_p0[7:0],dfi_2_dw_rddata_p1[255:0],dfi_2_dw_rddata_dm_p1[31:0],dfi_2_dw_rddata_dbi_p1[31:0],dfi_2_dw_rddata_par_p1[7:0],dfi_2_dbi_byte_disable[15:0],dfi_2_dw_rddata_valid[3:0],dfi_2_dw_derr_n[7:0],dfi_2_aw_aerr_n[1:0],dfi_2_ctrlupd_req,dfi_2_phyupd_ack,dfi_2_clk_init,dfi_2_init_complete,dfi_2_out_rst_n,dfi_3_dw_rddata_p0[255:0],dfi_3_dw_rddata_dm_p0[31:0],dfi_3_dw_rddata_dbi_p0[31:0],dfi_3_dw_rddata_par_p0[7:0],dfi_3_dw_rddata_p1[255:0],dfi_3_dw_rddata_dm_p1[31:0],dfi_3_dw_rddata_dbi_p1[31:0],dfi_3_dw_rddata_par_p1[7:0],dfi_3_dbi_byte_disable[15:0],dfi_3_dw_rddata_valid[3:0],dfi_3_dw_derr_n[7:0],dfi_3_aw_aerr_n[1:0],dfi_3_ctrlupd_req,dfi_3_phyupd_ack,dfi_3_clk_init,dfi_3_init_complete,dfi_3_out_rst_n,dfi_4_dw_rddata_p0[255:0],dfi_4_dw_rddata_dm_p0[31:0],dfi_4_dw_rddata_dbi_p0[31:0],dfi_4_dw_rddata_par_p0[7:0],dfi_4_dw_rddata_p1[255:0],dfi_4_dw_rddata_dm_p1[31:0],dfi_4_dw_rddata_dbi_p1[31:0],dfi_4_dw_rddata_par_p1[7:0],dfi_4_dbi_byte_disable[15:0],dfi_4_dw_rddata_valid[3:0],dfi_4_dw_derr_n[7:0],dfi_4_aw_aerr_n[1:0],dfi_4_ctrlupd_req,dfi_4_phyupd_ack,dfi_4_clk_init,dfi_4_init_complete,dfi_4_out_rst_n,dfi_5_dw_rddata_p0[255:0],dfi_5_dw_rddata_dm_p0[31:0],dfi_5_dw_rddata_dbi_p0[31:0],dfi_5_dw_rddata_par_p0[7:0],dfi_5_dw_rddata_p1[255:0],dfi_5_dw_rddata_dm_p1[31:0],dfi_5_dw_rddata_dbi_p1[31:0],dfi_5_dw_rddata_par_p1[7:0],dfi_5_dbi_byte_disable[15:0],dfi_5_dw_rddata_valid[3:0],dfi_5_dw_derr_n[7:0],dfi_5_aw_aerr_n[1:0],dfi_5_ctrlupd_req,dfi_5_phyupd_ack,dfi_5_clk_init,dfi_5_init_complete,dfi_5_out_rst_n,dfi_6_dw_rddata_p0[255:0],dfi_6_dw_rddata_dm_p0[31:0],dfi_6_dw_rddata_dbi_p0[31:0],dfi_6_dw_rddata_par_p0[7:0],dfi_6_dw_rddata_p1[255:0],dfi_6_dw_rddata_dm_p1[31:0],dfi_6_dw_rddata_dbi_p1[31:0],dfi_6_dw_rddata_par_p1[7:0],dfi_6_dbi_byte_disable[15:0],dfi_6_dw_rddata_valid[3:0],dfi_6_dw_derr_n[7:0],dfi_6_aw_aerr_n[1:0],dfi_6_ctrlupd_req,dfi_6_phyupd_ack,dfi_6_clk_init,dfi_6_init_complete,dfi_6_out_rst_n,dfi_7_dw_rddata_p0[255:0],dfi_7_dw_rddata_dm_p0[31:0],dfi_7_dw_rddata_dbi_p0[31:0],dfi_7_dw_rddata_par_p0[7:0],dfi_7_dw_rddata_p1[255:0],dfi_7_dw_rddata_dm_p1[31:0],dfi_7_dw_rddata_dbi_p1[31:0],dfi_7_dw_rddata_par_p1[7:0],dfi_7_dbi_byte_disable[15:0],dfi_7_dw_rddata_valid[3:0],dfi_7_dw_derr_n[7:0],dfi_7_aw_aerr_n[1:0],dfi_7_ctrlupd_req,dfi_7_phyupd_ack,dfi_7_clk_init,dfi_7_init_complete,dfi_7_out_rst_n,dfi_8_dw_rddata_p0[255:0],dfi_8_dw_rddata_dm_p0[31:0],dfi_8_dw_rddata_dbi_p0[31:0],dfi_8_dw_rddata_par_p0[7:0],dfi_8_dw_rddata_p1[255:0],dfi_8_dw_rddata_dm_p1[31:0],dfi_8_dw_rddata_dbi_p1[31:0],dfi_8_dw_rddata_par_p1[7:0],dfi_8_dbi_byte_disable[15:0],dfi_8_dw_rddata_valid[3:0],dfi_8_dw_derr_n[7:0],dfi_8_aw_aerr_n[1:0],dfi_8_ctrlupd_req,dfi_8_phyupd_ack,dfi_8_clk_init,dfi_8_init_complete,dfi_8_out_rst_n,dfi_9_dw_rddata_p0[255:0],dfi_9_dw_rddata_dm_p0[31:0],dfi_9_dw_rddata_dbi_p0[31:0],dfi_9_dw_rddata_par_p0[7:0],dfi_9_dw_rddata_p1[255:0],dfi_9_dw_rddata_dm_p1[31:0],dfi_9_dw_rddata_dbi_p1[31:0],dfi_9_dw_rddata_par_p1[7:0],dfi_9_dbi_byte_disable[15:0],dfi_9_dw_rddata_valid[3:0],dfi_9_dw_derr_n[7:0],dfi_9_aw_aerr_n[1:0],dfi_9_ctrlupd_req,dfi_9_phyupd_ack,dfi_9_clk_init,dfi_9_init_complete,dfi_9_out_rst_n,dfi_10_dw_rddata_p0[255:0],dfi_10_dw_rddata_dm_p0[31:0],dfi_10_dw_rddata_dbi_p0[31:0],dfi_10_dw_rddata_par_p0[7:0],dfi_10_dw_rddata_p1[255:0],dfi_10_dw_rddata_dm_p1[31:0],dfi_10_dw_rddata_dbi_p1[31:0],dfi_10_dw_rddata_par_p1[7:0],dfi_10_dbi_byte_disable[15:0],dfi_10_dw_rddata_valid[3:0],dfi_10_dw_derr_n[7:0],dfi_10_aw_aerr_n[1:0],dfi_10_ctrlupd_req,dfi_10_phyupd_ack,dfi_10_clk_init,dfi_10_init_complete,dfi_10_out_rst_n,dfi_11_dw_rddata_p0[255:0],dfi_11_dw_rddata_dm_p0[31:0],dfi_11_dw_rddata_dbi_p0[31:0],dfi_11_dw_rddata_par_p0[7:0],dfi_11_dw_rddata_p1[255:0],dfi_11_dw_rddata_dm_p1[31:0],dfi_11_dw_rddata_dbi_p1[31:0],dfi_11_dw_rddata_par_p1[7:0],dfi_11_dbi_byte_disable[15:0],dfi_11_dw_rddata_valid[3:0],dfi_11_dw_derr_n[7:0],dfi_11_aw_aerr_n[1:0],dfi_11_ctrlupd_req,dfi_11_phyupd_ack,dfi_11_clk_init,dfi_11_init_complete,dfi_11_out_rst_n,dfi_12_dw_rddata_p0[255:0],dfi_12_dw_rddata_dm_p0[31:0],dfi_12_dw_rddata_dbi_p0[31:0],dfi_12_dw_rddata_par_p0[7:0],dfi_12_dw_rddata_p1[255:0],dfi_12_dw_rddata_dm_p1[31:0],dfi_12_dw_rddata_dbi_p1[31:0],dfi_12_dw_rddata_par_p1[7:0],dfi_12_dbi_byte_disable[15:0],dfi_12_dw_rddata_valid[3:0],dfi_12_dw_derr_n[7:0],dfi_12_aw_aerr_n[1:0],dfi_12_ctrlupd_req,dfi_12_phyupd_ack,dfi_12_clk_init,dfi_12_init_complete,dfi_12_out_rst_n,dfi_13_dw_rddata_p0[255:0],dfi_13_dw_rddata_dm_p0[31:0],dfi_13_dw_rddata_dbi_p0[31:0],dfi_13_dw_rddata_par_p0[7:0],dfi_13_dw_rddata_p1[255:0],dfi_13_dw_rddata_dm_p1[31:0],dfi_13_dw_rddata_dbi_p1[31:0],dfi_13_dw_rddata_par_p1[7:0],dfi_13_dbi_byte_disable[15:0],dfi_13_dw_rddata_valid[3:0],dfi_13_dw_derr_n[7:0],dfi_13_aw_aerr_n[1:0],dfi_13_ctrlupd_req,dfi_13_phyupd_ack,dfi_13_clk_init,dfi_13_init_complete,dfi_13_out_rst_n,dfi_14_dw_rddata_p0[255:0],dfi_14_dw_rddata_dm_p0[31:0],dfi_14_dw_rddata_dbi_p0[31:0],dfi_14_dw_rddata_par_p0[7:0],dfi_14_dw_rddata_p1[255:0],dfi_14_dw_rddata_dm_p1[31:0],dfi_14_dw_rddata_dbi_p1[31:0],dfi_14_dw_rddata_par_p1[7:0],dfi_14_dbi_byte_disable[15:0],dfi_14_dw_rddata_valid[3:0],dfi_14_dw_derr_n[7:0],dfi_14_aw_aerr_n[1:0],dfi_14_ctrlupd_req,dfi_14_phyupd_ack,dfi_14_clk_init,dfi_14_init_complete,dfi_14_out_rst_n,dfi_15_dw_rddata_p0[255:0],dfi_15_dw_rddata_dm_p0[31:0],dfi_15_dw_rddata_dbi_p0[31:0],dfi_15_dw_rddata_par_p0[7:0],dfi_15_dw_rddata_p1[255:0],dfi_15_dw_rddata_dm_p1[31:0],dfi_15_dw_rddata_dbi_p1[31:0],dfi_15_dw_rddata_par_p1[7:0],dfi_15_dbi_byte_disable[15:0],dfi_15_dw_rddata_valid[3:0],dfi_15_dw_derr_n[7:0],dfi_15_aw_aerr_n[1:0],dfi_15_ctrlupd_req,dfi_15_phyupd_ack,dfi_15_clk_init,dfi_15_init_complete,dfi_15_out_rst_n,apb_complete_0,apb_complete_1,DRAM_0_STAT_CATTRIP,DRAM_0_STAT_TEMP[6:0],DRAM_1_STAT_CATTRIP,DRAM_1_STAT_TEMP[6:0]" */;
  input HBM_REF_CLK_0;
  input HBM_REF_CLK_1;
  input dfi_0_clk;
  input dfi_0_rst_n;
  input dfi_0_init_start;
  input [1:0]dfi_0_aw_ck_p0;
  input [1:0]dfi_0_aw_cke_p0;
  input [11:0]dfi_0_aw_row_p0;
  input [15:0]dfi_0_aw_col_p0;
  input [255:0]dfi_0_dw_wrdata_p0;
  input [31:0]dfi_0_dw_wrdata_mask_p0;
  input [31:0]dfi_0_dw_wrdata_dbi_p0;
  input [7:0]dfi_0_dw_wrdata_par_p0;
  input [7:0]dfi_0_dw_wrdata_dq_en_p0;
  input [7:0]dfi_0_dw_wrdata_par_en_p0;
  input [1:0]dfi_0_aw_ck_p1;
  input [1:0]dfi_0_aw_cke_p1;
  input [11:0]dfi_0_aw_row_p1;
  input [15:0]dfi_0_aw_col_p1;
  input [255:0]dfi_0_dw_wrdata_p1;
  input [31:0]dfi_0_dw_wrdata_mask_p1;
  input [31:0]dfi_0_dw_wrdata_dbi_p1;
  input [7:0]dfi_0_dw_wrdata_par_p1;
  input [7:0]dfi_0_dw_wrdata_dq_en_p1;
  input [7:0]dfi_0_dw_wrdata_par_en_p1;
  input dfi_0_aw_ck_dis;
  input dfi_0_lp_pwr_e_req;
  input dfi_0_lp_sr_e_req;
  input dfi_0_lp_pwr_x_req;
  input dfi_0_aw_tx_indx_ld;
  input dfi_0_dw_tx_indx_ld;
  input dfi_0_dw_rx_indx_ld;
  input dfi_0_ctrlupd_ack;
  input dfi_0_phyupd_req;
  input [7:0]dfi_0_dw_wrdata_dqs_p0;
  input [7:0]dfi_0_dw_wrdata_dqs_p1;
  input dfi_1_clk;
  input dfi_1_rst_n;
  input dfi_1_init_start;
  input [1:0]dfi_1_aw_ck_p0;
  input [1:0]dfi_1_aw_cke_p0;
  input [11:0]dfi_1_aw_row_p0;
  input [15:0]dfi_1_aw_col_p0;
  input [255:0]dfi_1_dw_wrdata_p0;
  input [31:0]dfi_1_dw_wrdata_mask_p0;
  input [31:0]dfi_1_dw_wrdata_dbi_p0;
  input [7:0]dfi_1_dw_wrdata_par_p0;
  input [7:0]dfi_1_dw_wrdata_dq_en_p0;
  input [7:0]dfi_1_dw_wrdata_par_en_p0;
  input [1:0]dfi_1_aw_ck_p1;
  input [1:0]dfi_1_aw_cke_p1;
  input [11:0]dfi_1_aw_row_p1;
  input [15:0]dfi_1_aw_col_p1;
  input [255:0]dfi_1_dw_wrdata_p1;
  input [31:0]dfi_1_dw_wrdata_mask_p1;
  input [31:0]dfi_1_dw_wrdata_dbi_p1;
  input [7:0]dfi_1_dw_wrdata_par_p1;
  input [7:0]dfi_1_dw_wrdata_dq_en_p1;
  input [7:0]dfi_1_dw_wrdata_par_en_p1;
  input dfi_1_aw_ck_dis;
  input dfi_1_lp_pwr_e_req;
  input dfi_1_lp_sr_e_req;
  input dfi_1_lp_pwr_x_req;
  input dfi_1_aw_tx_indx_ld;
  input dfi_1_dw_tx_indx_ld;
  input dfi_1_dw_rx_indx_ld;
  input dfi_1_ctrlupd_ack;
  input dfi_1_phyupd_req;
  input [7:0]dfi_1_dw_wrdata_dqs_p0;
  input [7:0]dfi_1_dw_wrdata_dqs_p1;
  input dfi_2_clk;
  input dfi_2_rst_n;
  input dfi_2_init_start;
  input [1:0]dfi_2_aw_ck_p0;
  input [1:0]dfi_2_aw_cke_p0;
  input [11:0]dfi_2_aw_row_p0;
  input [15:0]dfi_2_aw_col_p0;
  input [255:0]dfi_2_dw_wrdata_p0;
  input [31:0]dfi_2_dw_wrdata_mask_p0;
  input [31:0]dfi_2_dw_wrdata_dbi_p0;
  input [7:0]dfi_2_dw_wrdata_par_p0;
  input [7:0]dfi_2_dw_wrdata_dq_en_p0;
  input [7:0]dfi_2_dw_wrdata_par_en_p0;
  input [1:0]dfi_2_aw_ck_p1;
  input [1:0]dfi_2_aw_cke_p1;
  input [11:0]dfi_2_aw_row_p1;
  input [15:0]dfi_2_aw_col_p1;
  input [255:0]dfi_2_dw_wrdata_p1;
  input [31:0]dfi_2_dw_wrdata_mask_p1;
  input [31:0]dfi_2_dw_wrdata_dbi_p1;
  input [7:0]dfi_2_dw_wrdata_par_p1;
  input [7:0]dfi_2_dw_wrdata_dq_en_p1;
  input [7:0]dfi_2_dw_wrdata_par_en_p1;
  input dfi_2_aw_ck_dis;
  input dfi_2_lp_pwr_e_req;
  input dfi_2_lp_sr_e_req;
  input dfi_2_lp_pwr_x_req;
  input dfi_2_aw_tx_indx_ld;
  input dfi_2_dw_tx_indx_ld;
  input dfi_2_dw_rx_indx_ld;
  input dfi_2_ctrlupd_ack;
  input dfi_2_phyupd_req;
  input [7:0]dfi_2_dw_wrdata_dqs_p0;
  input [7:0]dfi_2_dw_wrdata_dqs_p1;
  input dfi_3_clk;
  input dfi_3_rst_n;
  input dfi_3_init_start;
  input [1:0]dfi_3_aw_ck_p0;
  input [1:0]dfi_3_aw_cke_p0;
  input [11:0]dfi_3_aw_row_p0;
  input [15:0]dfi_3_aw_col_p0;
  input [255:0]dfi_3_dw_wrdata_p0;
  input [31:0]dfi_3_dw_wrdata_mask_p0;
  input [31:0]dfi_3_dw_wrdata_dbi_p0;
  input [7:0]dfi_3_dw_wrdata_par_p0;
  input [7:0]dfi_3_dw_wrdata_dq_en_p0;
  input [7:0]dfi_3_dw_wrdata_par_en_p0;
  input [1:0]dfi_3_aw_ck_p1;
  input [1:0]dfi_3_aw_cke_p1;
  input [11:0]dfi_3_aw_row_p1;
  input [15:0]dfi_3_aw_col_p1;
  input [255:0]dfi_3_dw_wrdata_p1;
  input [31:0]dfi_3_dw_wrdata_mask_p1;
  input [31:0]dfi_3_dw_wrdata_dbi_p1;
  input [7:0]dfi_3_dw_wrdata_par_p1;
  input [7:0]dfi_3_dw_wrdata_dq_en_p1;
  input [7:0]dfi_3_dw_wrdata_par_en_p1;
  input dfi_3_aw_ck_dis;
  input dfi_3_lp_pwr_e_req;
  input dfi_3_lp_sr_e_req;
  input dfi_3_lp_pwr_x_req;
  input dfi_3_aw_tx_indx_ld;
  input dfi_3_dw_tx_indx_ld;
  input dfi_3_dw_rx_indx_ld;
  input dfi_3_ctrlupd_ack;
  input dfi_3_phyupd_req;
  input [7:0]dfi_3_dw_wrdata_dqs_p0;
  input [7:0]dfi_3_dw_wrdata_dqs_p1;
  input dfi_4_clk;
  input dfi_4_rst_n;
  input dfi_4_init_start;
  input [1:0]dfi_4_aw_ck_p0;
  input [1:0]dfi_4_aw_cke_p0;
  input [11:0]dfi_4_aw_row_p0;
  input [15:0]dfi_4_aw_col_p0;
  input [255:0]dfi_4_dw_wrdata_p0;
  input [31:0]dfi_4_dw_wrdata_mask_p0;
  input [31:0]dfi_4_dw_wrdata_dbi_p0;
  input [7:0]dfi_4_dw_wrdata_par_p0;
  input [7:0]dfi_4_dw_wrdata_dq_en_p0;
  input [7:0]dfi_4_dw_wrdata_par_en_p0;
  input [1:0]dfi_4_aw_ck_p1;
  input [1:0]dfi_4_aw_cke_p1;
  input [11:0]dfi_4_aw_row_p1;
  input [15:0]dfi_4_aw_col_p1;
  input [255:0]dfi_4_dw_wrdata_p1;
  input [31:0]dfi_4_dw_wrdata_mask_p1;
  input [31:0]dfi_4_dw_wrdata_dbi_p1;
  input [7:0]dfi_4_dw_wrdata_par_p1;
  input [7:0]dfi_4_dw_wrdata_dq_en_p1;
  input [7:0]dfi_4_dw_wrdata_par_en_p1;
  input dfi_4_aw_ck_dis;
  input dfi_4_lp_pwr_e_req;
  input dfi_4_lp_sr_e_req;
  input dfi_4_lp_pwr_x_req;
  input dfi_4_aw_tx_indx_ld;
  input dfi_4_dw_tx_indx_ld;
  input dfi_4_dw_rx_indx_ld;
  input dfi_4_ctrlupd_ack;
  input dfi_4_phyupd_req;
  input [7:0]dfi_4_dw_wrdata_dqs_p0;
  input [7:0]dfi_4_dw_wrdata_dqs_p1;
  input dfi_5_clk;
  input dfi_5_rst_n;
  input dfi_5_init_start;
  input [1:0]dfi_5_aw_ck_p0;
  input [1:0]dfi_5_aw_cke_p0;
  input [11:0]dfi_5_aw_row_p0;
  input [15:0]dfi_5_aw_col_p0;
  input [255:0]dfi_5_dw_wrdata_p0;
  input [31:0]dfi_5_dw_wrdata_mask_p0;
  input [31:0]dfi_5_dw_wrdata_dbi_p0;
  input [7:0]dfi_5_dw_wrdata_par_p0;
  input [7:0]dfi_5_dw_wrdata_dq_en_p0;
  input [7:0]dfi_5_dw_wrdata_par_en_p0;
  input [1:0]dfi_5_aw_ck_p1;
  input [1:0]dfi_5_aw_cke_p1;
  input [11:0]dfi_5_aw_row_p1;
  input [15:0]dfi_5_aw_col_p1;
  input [255:0]dfi_5_dw_wrdata_p1;
  input [31:0]dfi_5_dw_wrdata_mask_p1;
  input [31:0]dfi_5_dw_wrdata_dbi_p1;
  input [7:0]dfi_5_dw_wrdata_par_p1;
  input [7:0]dfi_5_dw_wrdata_dq_en_p1;
  input [7:0]dfi_5_dw_wrdata_par_en_p1;
  input dfi_5_aw_ck_dis;
  input dfi_5_lp_pwr_e_req;
  input dfi_5_lp_sr_e_req;
  input dfi_5_lp_pwr_x_req;
  input dfi_5_aw_tx_indx_ld;
  input dfi_5_dw_tx_indx_ld;
  input dfi_5_dw_rx_indx_ld;
  input dfi_5_ctrlupd_ack;
  input dfi_5_phyupd_req;
  input [7:0]dfi_5_dw_wrdata_dqs_p0;
  input [7:0]dfi_5_dw_wrdata_dqs_p1;
  input dfi_6_clk;
  input dfi_6_rst_n;
  input dfi_6_init_start;
  input [1:0]dfi_6_aw_ck_p0;
  input [1:0]dfi_6_aw_cke_p0;
  input [11:0]dfi_6_aw_row_p0;
  input [15:0]dfi_6_aw_col_p0;
  input [255:0]dfi_6_dw_wrdata_p0;
  input [31:0]dfi_6_dw_wrdata_mask_p0;
  input [31:0]dfi_6_dw_wrdata_dbi_p0;
  input [7:0]dfi_6_dw_wrdata_par_p0;
  input [7:0]dfi_6_dw_wrdata_dq_en_p0;
  input [7:0]dfi_6_dw_wrdata_par_en_p0;
  input [1:0]dfi_6_aw_ck_p1;
  input [1:0]dfi_6_aw_cke_p1;
  input [11:0]dfi_6_aw_row_p1;
  input [15:0]dfi_6_aw_col_p1;
  input [255:0]dfi_6_dw_wrdata_p1;
  input [31:0]dfi_6_dw_wrdata_mask_p1;
  input [31:0]dfi_6_dw_wrdata_dbi_p1;
  input [7:0]dfi_6_dw_wrdata_par_p1;
  input [7:0]dfi_6_dw_wrdata_dq_en_p1;
  input [7:0]dfi_6_dw_wrdata_par_en_p1;
  input dfi_6_aw_ck_dis;
  input dfi_6_lp_pwr_e_req;
  input dfi_6_lp_sr_e_req;
  input dfi_6_lp_pwr_x_req;
  input dfi_6_aw_tx_indx_ld;
  input dfi_6_dw_tx_indx_ld;
  input dfi_6_dw_rx_indx_ld;
  input dfi_6_ctrlupd_ack;
  input dfi_6_phyupd_req;
  input [7:0]dfi_6_dw_wrdata_dqs_p0;
  input [7:0]dfi_6_dw_wrdata_dqs_p1;
  input dfi_7_clk;
  input dfi_7_rst_n;
  input dfi_7_init_start;
  input [1:0]dfi_7_aw_ck_p0;
  input [1:0]dfi_7_aw_cke_p0;
  input [11:0]dfi_7_aw_row_p0;
  input [15:0]dfi_7_aw_col_p0;
  input [255:0]dfi_7_dw_wrdata_p0;
  input [31:0]dfi_7_dw_wrdata_mask_p0;
  input [31:0]dfi_7_dw_wrdata_dbi_p0;
  input [7:0]dfi_7_dw_wrdata_par_p0;
  input [7:0]dfi_7_dw_wrdata_dq_en_p0;
  input [7:0]dfi_7_dw_wrdata_par_en_p0;
  input [1:0]dfi_7_aw_ck_p1;
  input [1:0]dfi_7_aw_cke_p1;
  input [11:0]dfi_7_aw_row_p1;
  input [15:0]dfi_7_aw_col_p1;
  input [255:0]dfi_7_dw_wrdata_p1;
  input [31:0]dfi_7_dw_wrdata_mask_p1;
  input [31:0]dfi_7_dw_wrdata_dbi_p1;
  input [7:0]dfi_7_dw_wrdata_par_p1;
  input [7:0]dfi_7_dw_wrdata_dq_en_p1;
  input [7:0]dfi_7_dw_wrdata_par_en_p1;
  input dfi_7_aw_ck_dis;
  input dfi_7_lp_pwr_e_req;
  input dfi_7_lp_sr_e_req;
  input dfi_7_lp_pwr_x_req;
  input dfi_7_aw_tx_indx_ld;
  input dfi_7_dw_tx_indx_ld;
  input dfi_7_dw_rx_indx_ld;
  input dfi_7_ctrlupd_ack;
  input dfi_7_phyupd_req;
  input [7:0]dfi_7_dw_wrdata_dqs_p0;
  input [7:0]dfi_7_dw_wrdata_dqs_p1;
  input dfi_8_clk;
  input dfi_8_rst_n;
  input dfi_8_init_start;
  input [1:0]dfi_8_aw_ck_p0;
  input [1:0]dfi_8_aw_cke_p0;
  input [11:0]dfi_8_aw_row_p0;
  input [15:0]dfi_8_aw_col_p0;
  input [255:0]dfi_8_dw_wrdata_p0;
  input [31:0]dfi_8_dw_wrdata_mask_p0;
  input [31:0]dfi_8_dw_wrdata_dbi_p0;
  input [7:0]dfi_8_dw_wrdata_par_p0;
  input [7:0]dfi_8_dw_wrdata_dq_en_p0;
  input [7:0]dfi_8_dw_wrdata_par_en_p0;
  input [1:0]dfi_8_aw_ck_p1;
  input [1:0]dfi_8_aw_cke_p1;
  input [11:0]dfi_8_aw_row_p1;
  input [15:0]dfi_8_aw_col_p1;
  input [255:0]dfi_8_dw_wrdata_p1;
  input [31:0]dfi_8_dw_wrdata_mask_p1;
  input [31:0]dfi_8_dw_wrdata_dbi_p1;
  input [7:0]dfi_8_dw_wrdata_par_p1;
  input [7:0]dfi_8_dw_wrdata_dq_en_p1;
  input [7:0]dfi_8_dw_wrdata_par_en_p1;
  input dfi_8_aw_ck_dis;
  input dfi_8_lp_pwr_e_req;
  input dfi_8_lp_sr_e_req;
  input dfi_8_lp_pwr_x_req;
  input dfi_8_aw_tx_indx_ld;
  input dfi_8_dw_tx_indx_ld;
  input dfi_8_dw_rx_indx_ld;
  input dfi_8_ctrlupd_ack;
  input dfi_8_phyupd_req;
  input [7:0]dfi_8_dw_wrdata_dqs_p0;
  input [7:0]dfi_8_dw_wrdata_dqs_p1;
  input dfi_9_clk;
  input dfi_9_rst_n;
  input dfi_9_init_start;
  input [1:0]dfi_9_aw_ck_p0;
  input [1:0]dfi_9_aw_cke_p0;
  input [11:0]dfi_9_aw_row_p0;
  input [15:0]dfi_9_aw_col_p0;
  input [255:0]dfi_9_dw_wrdata_p0;
  input [31:0]dfi_9_dw_wrdata_mask_p0;
  input [31:0]dfi_9_dw_wrdata_dbi_p0;
  input [7:0]dfi_9_dw_wrdata_par_p0;
  input [7:0]dfi_9_dw_wrdata_dq_en_p0;
  input [7:0]dfi_9_dw_wrdata_par_en_p0;
  input [1:0]dfi_9_aw_ck_p1;
  input [1:0]dfi_9_aw_cke_p1;
  input [11:0]dfi_9_aw_row_p1;
  input [15:0]dfi_9_aw_col_p1;
  input [255:0]dfi_9_dw_wrdata_p1;
  input [31:0]dfi_9_dw_wrdata_mask_p1;
  input [31:0]dfi_9_dw_wrdata_dbi_p1;
  input [7:0]dfi_9_dw_wrdata_par_p1;
  input [7:0]dfi_9_dw_wrdata_dq_en_p1;
  input [7:0]dfi_9_dw_wrdata_par_en_p1;
  input dfi_9_aw_ck_dis;
  input dfi_9_lp_pwr_e_req;
  input dfi_9_lp_sr_e_req;
  input dfi_9_lp_pwr_x_req;
  input dfi_9_aw_tx_indx_ld;
  input dfi_9_dw_tx_indx_ld;
  input dfi_9_dw_rx_indx_ld;
  input dfi_9_ctrlupd_ack;
  input dfi_9_phyupd_req;
  input [7:0]dfi_9_dw_wrdata_dqs_p0;
  input [7:0]dfi_9_dw_wrdata_dqs_p1;
  input dfi_10_clk;
  input dfi_10_rst_n;
  input dfi_10_init_start;
  input [1:0]dfi_10_aw_ck_p0;
  input [1:0]dfi_10_aw_cke_p0;
  input [11:0]dfi_10_aw_row_p0;
  input [15:0]dfi_10_aw_col_p0;
  input [255:0]dfi_10_dw_wrdata_p0;
  input [31:0]dfi_10_dw_wrdata_mask_p0;
  input [31:0]dfi_10_dw_wrdata_dbi_p0;
  input [7:0]dfi_10_dw_wrdata_par_p0;
  input [7:0]dfi_10_dw_wrdata_dq_en_p0;
  input [7:0]dfi_10_dw_wrdata_par_en_p0;
  input [1:0]dfi_10_aw_ck_p1;
  input [1:0]dfi_10_aw_cke_p1;
  input [11:0]dfi_10_aw_row_p1;
  input [15:0]dfi_10_aw_col_p1;
  input [255:0]dfi_10_dw_wrdata_p1;
  input [31:0]dfi_10_dw_wrdata_mask_p1;
  input [31:0]dfi_10_dw_wrdata_dbi_p1;
  input [7:0]dfi_10_dw_wrdata_par_p1;
  input [7:0]dfi_10_dw_wrdata_dq_en_p1;
  input [7:0]dfi_10_dw_wrdata_par_en_p1;
  input dfi_10_aw_ck_dis;
  input dfi_10_lp_pwr_e_req;
  input dfi_10_lp_sr_e_req;
  input dfi_10_lp_pwr_x_req;
  input dfi_10_aw_tx_indx_ld;
  input dfi_10_dw_tx_indx_ld;
  input dfi_10_dw_rx_indx_ld;
  input dfi_10_ctrlupd_ack;
  input dfi_10_phyupd_req;
  input [7:0]dfi_10_dw_wrdata_dqs_p0;
  input [7:0]dfi_10_dw_wrdata_dqs_p1;
  input dfi_11_clk;
  input dfi_11_rst_n;
  input dfi_11_init_start;
  input [1:0]dfi_11_aw_ck_p0;
  input [1:0]dfi_11_aw_cke_p0;
  input [11:0]dfi_11_aw_row_p0;
  input [15:0]dfi_11_aw_col_p0;
  input [255:0]dfi_11_dw_wrdata_p0;
  input [31:0]dfi_11_dw_wrdata_mask_p0;
  input [31:0]dfi_11_dw_wrdata_dbi_p0;
  input [7:0]dfi_11_dw_wrdata_par_p0;
  input [7:0]dfi_11_dw_wrdata_dq_en_p0;
  input [7:0]dfi_11_dw_wrdata_par_en_p0;
  input [1:0]dfi_11_aw_ck_p1;
  input [1:0]dfi_11_aw_cke_p1;
  input [11:0]dfi_11_aw_row_p1;
  input [15:0]dfi_11_aw_col_p1;
  input [255:0]dfi_11_dw_wrdata_p1;
  input [31:0]dfi_11_dw_wrdata_mask_p1;
  input [31:0]dfi_11_dw_wrdata_dbi_p1;
  input [7:0]dfi_11_dw_wrdata_par_p1;
  input [7:0]dfi_11_dw_wrdata_dq_en_p1;
  input [7:0]dfi_11_dw_wrdata_par_en_p1;
  input dfi_11_aw_ck_dis;
  input dfi_11_lp_pwr_e_req;
  input dfi_11_lp_sr_e_req;
  input dfi_11_lp_pwr_x_req;
  input dfi_11_aw_tx_indx_ld;
  input dfi_11_dw_tx_indx_ld;
  input dfi_11_dw_rx_indx_ld;
  input dfi_11_ctrlupd_ack;
  input dfi_11_phyupd_req;
  input [7:0]dfi_11_dw_wrdata_dqs_p0;
  input [7:0]dfi_11_dw_wrdata_dqs_p1;
  input dfi_12_clk;
  input dfi_12_rst_n;
  input dfi_12_init_start;
  input [1:0]dfi_12_aw_ck_p0;
  input [1:0]dfi_12_aw_cke_p0;
  input [11:0]dfi_12_aw_row_p0;
  input [15:0]dfi_12_aw_col_p0;
  input [255:0]dfi_12_dw_wrdata_p0;
  input [31:0]dfi_12_dw_wrdata_mask_p0;
  input [31:0]dfi_12_dw_wrdata_dbi_p0;
  input [7:0]dfi_12_dw_wrdata_par_p0;
  input [7:0]dfi_12_dw_wrdata_dq_en_p0;
  input [7:0]dfi_12_dw_wrdata_par_en_p0;
  input [1:0]dfi_12_aw_ck_p1;
  input [1:0]dfi_12_aw_cke_p1;
  input [11:0]dfi_12_aw_row_p1;
  input [15:0]dfi_12_aw_col_p1;
  input [255:0]dfi_12_dw_wrdata_p1;
  input [31:0]dfi_12_dw_wrdata_mask_p1;
  input [31:0]dfi_12_dw_wrdata_dbi_p1;
  input [7:0]dfi_12_dw_wrdata_par_p1;
  input [7:0]dfi_12_dw_wrdata_dq_en_p1;
  input [7:0]dfi_12_dw_wrdata_par_en_p1;
  input dfi_12_aw_ck_dis;
  input dfi_12_lp_pwr_e_req;
  input dfi_12_lp_sr_e_req;
  input dfi_12_lp_pwr_x_req;
  input dfi_12_aw_tx_indx_ld;
  input dfi_12_dw_tx_indx_ld;
  input dfi_12_dw_rx_indx_ld;
  input dfi_12_ctrlupd_ack;
  input dfi_12_phyupd_req;
  input [7:0]dfi_12_dw_wrdata_dqs_p0;
  input [7:0]dfi_12_dw_wrdata_dqs_p1;
  input dfi_13_clk;
  input dfi_13_rst_n;
  input dfi_13_init_start;
  input [1:0]dfi_13_aw_ck_p0;
  input [1:0]dfi_13_aw_cke_p0;
  input [11:0]dfi_13_aw_row_p0;
  input [15:0]dfi_13_aw_col_p0;
  input [255:0]dfi_13_dw_wrdata_p0;
  input [31:0]dfi_13_dw_wrdata_mask_p0;
  input [31:0]dfi_13_dw_wrdata_dbi_p0;
  input [7:0]dfi_13_dw_wrdata_par_p0;
  input [7:0]dfi_13_dw_wrdata_dq_en_p0;
  input [7:0]dfi_13_dw_wrdata_par_en_p0;
  input [1:0]dfi_13_aw_ck_p1;
  input [1:0]dfi_13_aw_cke_p1;
  input [11:0]dfi_13_aw_row_p1;
  input [15:0]dfi_13_aw_col_p1;
  input [255:0]dfi_13_dw_wrdata_p1;
  input [31:0]dfi_13_dw_wrdata_mask_p1;
  input [31:0]dfi_13_dw_wrdata_dbi_p1;
  input [7:0]dfi_13_dw_wrdata_par_p1;
  input [7:0]dfi_13_dw_wrdata_dq_en_p1;
  input [7:0]dfi_13_dw_wrdata_par_en_p1;
  input dfi_13_aw_ck_dis;
  input dfi_13_lp_pwr_e_req;
  input dfi_13_lp_sr_e_req;
  input dfi_13_lp_pwr_x_req;
  input dfi_13_aw_tx_indx_ld;
  input dfi_13_dw_tx_indx_ld;
  input dfi_13_dw_rx_indx_ld;
  input dfi_13_ctrlupd_ack;
  input dfi_13_phyupd_req;
  input [7:0]dfi_13_dw_wrdata_dqs_p0;
  input [7:0]dfi_13_dw_wrdata_dqs_p1;
  input dfi_14_clk;
  input dfi_14_rst_n;
  input dfi_14_init_start;
  input [1:0]dfi_14_aw_ck_p0;
  input [1:0]dfi_14_aw_cke_p0;
  input [11:0]dfi_14_aw_row_p0;
  input [15:0]dfi_14_aw_col_p0;
  input [255:0]dfi_14_dw_wrdata_p0;
  input [31:0]dfi_14_dw_wrdata_mask_p0;
  input [31:0]dfi_14_dw_wrdata_dbi_p0;
  input [7:0]dfi_14_dw_wrdata_par_p0;
  input [7:0]dfi_14_dw_wrdata_dq_en_p0;
  input [7:0]dfi_14_dw_wrdata_par_en_p0;
  input [1:0]dfi_14_aw_ck_p1;
  input [1:0]dfi_14_aw_cke_p1;
  input [11:0]dfi_14_aw_row_p1;
  input [15:0]dfi_14_aw_col_p1;
  input [255:0]dfi_14_dw_wrdata_p1;
  input [31:0]dfi_14_dw_wrdata_mask_p1;
  input [31:0]dfi_14_dw_wrdata_dbi_p1;
  input [7:0]dfi_14_dw_wrdata_par_p1;
  input [7:0]dfi_14_dw_wrdata_dq_en_p1;
  input [7:0]dfi_14_dw_wrdata_par_en_p1;
  input dfi_14_aw_ck_dis;
  input dfi_14_lp_pwr_e_req;
  input dfi_14_lp_sr_e_req;
  input dfi_14_lp_pwr_x_req;
  input dfi_14_aw_tx_indx_ld;
  input dfi_14_dw_tx_indx_ld;
  input dfi_14_dw_rx_indx_ld;
  input dfi_14_ctrlupd_ack;
  input dfi_14_phyupd_req;
  input [7:0]dfi_14_dw_wrdata_dqs_p0;
  input [7:0]dfi_14_dw_wrdata_dqs_p1;
  input dfi_15_clk;
  input dfi_15_rst_n;
  input dfi_15_init_start;
  input [1:0]dfi_15_aw_ck_p0;
  input [1:0]dfi_15_aw_cke_p0;
  input [11:0]dfi_15_aw_row_p0;
  input [15:0]dfi_15_aw_col_p0;
  input [255:0]dfi_15_dw_wrdata_p0;
  input [31:0]dfi_15_dw_wrdata_mask_p0;
  input [31:0]dfi_15_dw_wrdata_dbi_p0;
  input [7:0]dfi_15_dw_wrdata_par_p0;
  input [7:0]dfi_15_dw_wrdata_dq_en_p0;
  input [7:0]dfi_15_dw_wrdata_par_en_p0;
  input [1:0]dfi_15_aw_ck_p1;
  input [1:0]dfi_15_aw_cke_p1;
  input [11:0]dfi_15_aw_row_p1;
  input [15:0]dfi_15_aw_col_p1;
  input [255:0]dfi_15_dw_wrdata_p1;
  input [31:0]dfi_15_dw_wrdata_mask_p1;
  input [31:0]dfi_15_dw_wrdata_dbi_p1;
  input [7:0]dfi_15_dw_wrdata_par_p1;
  input [7:0]dfi_15_dw_wrdata_dq_en_p1;
  input [7:0]dfi_15_dw_wrdata_par_en_p1;
  input dfi_15_aw_ck_dis;
  input dfi_15_lp_pwr_e_req;
  input dfi_15_lp_sr_e_req;
  input dfi_15_lp_pwr_x_req;
  input dfi_15_aw_tx_indx_ld;
  input dfi_15_dw_tx_indx_ld;
  input dfi_15_dw_rx_indx_ld;
  input dfi_15_ctrlupd_ack;
  input dfi_15_phyupd_req;
  input [7:0]dfi_15_dw_wrdata_dqs_p0;
  input [7:0]dfi_15_dw_wrdata_dqs_p1;
  input APB_0_PCLK;
  input APB_0_PRESET_N;
  input APB_1_PCLK;
  input APB_1_PRESET_N;
  output [255:0]dfi_0_dw_rddata_p0;
  output [31:0]dfi_0_dw_rddata_dm_p0;
  output [31:0]dfi_0_dw_rddata_dbi_p0;
  output [7:0]dfi_0_dw_rddata_par_p0;
  output [255:0]dfi_0_dw_rddata_p1;
  output [31:0]dfi_0_dw_rddata_dm_p1;
  output [31:0]dfi_0_dw_rddata_dbi_p1;
  output [7:0]dfi_0_dw_rddata_par_p1;
  output [15:0]dfi_0_dbi_byte_disable;
  output [3:0]dfi_0_dw_rddata_valid;
  output [7:0]dfi_0_dw_derr_n;
  output [1:0]dfi_0_aw_aerr_n;
  output dfi_0_ctrlupd_req;
  output dfi_0_phyupd_ack;
  output dfi_0_clk_init;
  output dfi_0_init_complete;
  output dfi_0_out_rst_n;
  output [255:0]dfi_1_dw_rddata_p0;
  output [31:0]dfi_1_dw_rddata_dm_p0;
  output [31:0]dfi_1_dw_rddata_dbi_p0;
  output [7:0]dfi_1_dw_rddata_par_p0;
  output [255:0]dfi_1_dw_rddata_p1;
  output [31:0]dfi_1_dw_rddata_dm_p1;
  output [31:0]dfi_1_dw_rddata_dbi_p1;
  output [7:0]dfi_1_dw_rddata_par_p1;
  output [15:0]dfi_1_dbi_byte_disable;
  output [3:0]dfi_1_dw_rddata_valid;
  output [7:0]dfi_1_dw_derr_n;
  output [1:0]dfi_1_aw_aerr_n;
  output dfi_1_ctrlupd_req;
  output dfi_1_phyupd_ack;
  output dfi_1_clk_init;
  output dfi_1_init_complete;
  output dfi_1_out_rst_n;
  output [255:0]dfi_2_dw_rddata_p0;
  output [31:0]dfi_2_dw_rddata_dm_p0;
  output [31:0]dfi_2_dw_rddata_dbi_p0;
  output [7:0]dfi_2_dw_rddata_par_p0;
  output [255:0]dfi_2_dw_rddata_p1;
  output [31:0]dfi_2_dw_rddata_dm_p1;
  output [31:0]dfi_2_dw_rddata_dbi_p1;
  output [7:0]dfi_2_dw_rddata_par_p1;
  output [15:0]dfi_2_dbi_byte_disable;
  output [3:0]dfi_2_dw_rddata_valid;
  output [7:0]dfi_2_dw_derr_n;
  output [1:0]dfi_2_aw_aerr_n;
  output dfi_2_ctrlupd_req;
  output dfi_2_phyupd_ack;
  output dfi_2_clk_init;
  output dfi_2_init_complete;
  output dfi_2_out_rst_n;
  output [255:0]dfi_3_dw_rddata_p0;
  output [31:0]dfi_3_dw_rddata_dm_p0;
  output [31:0]dfi_3_dw_rddata_dbi_p0;
  output [7:0]dfi_3_dw_rddata_par_p0;
  output [255:0]dfi_3_dw_rddata_p1;
  output [31:0]dfi_3_dw_rddata_dm_p1;
  output [31:0]dfi_3_dw_rddata_dbi_p1;
  output [7:0]dfi_3_dw_rddata_par_p1;
  output [15:0]dfi_3_dbi_byte_disable;
  output [3:0]dfi_3_dw_rddata_valid;
  output [7:0]dfi_3_dw_derr_n;
  output [1:0]dfi_3_aw_aerr_n;
  output dfi_3_ctrlupd_req;
  output dfi_3_phyupd_ack;
  output dfi_3_clk_init;
  output dfi_3_init_complete;
  output dfi_3_out_rst_n;
  output [255:0]dfi_4_dw_rddata_p0;
  output [31:0]dfi_4_dw_rddata_dm_p0;
  output [31:0]dfi_4_dw_rddata_dbi_p0;
  output [7:0]dfi_4_dw_rddata_par_p0;
  output [255:0]dfi_4_dw_rddata_p1;
  output [31:0]dfi_4_dw_rddata_dm_p1;
  output [31:0]dfi_4_dw_rddata_dbi_p1;
  output [7:0]dfi_4_dw_rddata_par_p1;
  output [15:0]dfi_4_dbi_byte_disable;
  output [3:0]dfi_4_dw_rddata_valid;
  output [7:0]dfi_4_dw_derr_n;
  output [1:0]dfi_4_aw_aerr_n;
  output dfi_4_ctrlupd_req;
  output dfi_4_phyupd_ack;
  output dfi_4_clk_init;
  output dfi_4_init_complete;
  output dfi_4_out_rst_n;
  output [255:0]dfi_5_dw_rddata_p0;
  output [31:0]dfi_5_dw_rddata_dm_p0;
  output [31:0]dfi_5_dw_rddata_dbi_p0;
  output [7:0]dfi_5_dw_rddata_par_p0;
  output [255:0]dfi_5_dw_rddata_p1;
  output [31:0]dfi_5_dw_rddata_dm_p1;
  output [31:0]dfi_5_dw_rddata_dbi_p1;
  output [7:0]dfi_5_dw_rddata_par_p1;
  output [15:0]dfi_5_dbi_byte_disable;
  output [3:0]dfi_5_dw_rddata_valid;
  output [7:0]dfi_5_dw_derr_n;
  output [1:0]dfi_5_aw_aerr_n;
  output dfi_5_ctrlupd_req;
  output dfi_5_phyupd_ack;
  output dfi_5_clk_init;
  output dfi_5_init_complete;
  output dfi_5_out_rst_n;
  output [255:0]dfi_6_dw_rddata_p0;
  output [31:0]dfi_6_dw_rddata_dm_p0;
  output [31:0]dfi_6_dw_rddata_dbi_p0;
  output [7:0]dfi_6_dw_rddata_par_p0;
  output [255:0]dfi_6_dw_rddata_p1;
  output [31:0]dfi_6_dw_rddata_dm_p1;
  output [31:0]dfi_6_dw_rddata_dbi_p1;
  output [7:0]dfi_6_dw_rddata_par_p1;
  output [15:0]dfi_6_dbi_byte_disable;
  output [3:0]dfi_6_dw_rddata_valid;
  output [7:0]dfi_6_dw_derr_n;
  output [1:0]dfi_6_aw_aerr_n;
  output dfi_6_ctrlupd_req;
  output dfi_6_phyupd_ack;
  output dfi_6_clk_init;
  output dfi_6_init_complete;
  output dfi_6_out_rst_n;
  output [255:0]dfi_7_dw_rddata_p0;
  output [31:0]dfi_7_dw_rddata_dm_p0;
  output [31:0]dfi_7_dw_rddata_dbi_p0;
  output [7:0]dfi_7_dw_rddata_par_p0;
  output [255:0]dfi_7_dw_rddata_p1;
  output [31:0]dfi_7_dw_rddata_dm_p1;
  output [31:0]dfi_7_dw_rddata_dbi_p1;
  output [7:0]dfi_7_dw_rddata_par_p1;
  output [15:0]dfi_7_dbi_byte_disable;
  output [3:0]dfi_7_dw_rddata_valid;
  output [7:0]dfi_7_dw_derr_n;
  output [1:0]dfi_7_aw_aerr_n;
  output dfi_7_ctrlupd_req;
  output dfi_7_phyupd_ack;
  output dfi_7_clk_init;
  output dfi_7_init_complete;
  output dfi_7_out_rst_n;
  output [255:0]dfi_8_dw_rddata_p0;
  output [31:0]dfi_8_dw_rddata_dm_p0;
  output [31:0]dfi_8_dw_rddata_dbi_p0;
  output [7:0]dfi_8_dw_rddata_par_p0;
  output [255:0]dfi_8_dw_rddata_p1;
  output [31:0]dfi_8_dw_rddata_dm_p1;
  output [31:0]dfi_8_dw_rddata_dbi_p1;
  output [7:0]dfi_8_dw_rddata_par_p1;
  output [15:0]dfi_8_dbi_byte_disable;
  output [3:0]dfi_8_dw_rddata_valid;
  output [7:0]dfi_8_dw_derr_n;
  output [1:0]dfi_8_aw_aerr_n;
  output dfi_8_ctrlupd_req;
  output dfi_8_phyupd_ack;
  output dfi_8_clk_init;
  output dfi_8_init_complete;
  output dfi_8_out_rst_n;
  output [255:0]dfi_9_dw_rddata_p0;
  output [31:0]dfi_9_dw_rddata_dm_p0;
  output [31:0]dfi_9_dw_rddata_dbi_p0;
  output [7:0]dfi_9_dw_rddata_par_p0;
  output [255:0]dfi_9_dw_rddata_p1;
  output [31:0]dfi_9_dw_rddata_dm_p1;
  output [31:0]dfi_9_dw_rddata_dbi_p1;
  output [7:0]dfi_9_dw_rddata_par_p1;
  output [15:0]dfi_9_dbi_byte_disable;
  output [3:0]dfi_9_dw_rddata_valid;
  output [7:0]dfi_9_dw_derr_n;
  output [1:0]dfi_9_aw_aerr_n;
  output dfi_9_ctrlupd_req;
  output dfi_9_phyupd_ack;
  output dfi_9_clk_init;
  output dfi_9_init_complete;
  output dfi_9_out_rst_n;
  output [255:0]dfi_10_dw_rddata_p0;
  output [31:0]dfi_10_dw_rddata_dm_p0;
  output [31:0]dfi_10_dw_rddata_dbi_p0;
  output [7:0]dfi_10_dw_rddata_par_p0;
  output [255:0]dfi_10_dw_rddata_p1;
  output [31:0]dfi_10_dw_rddata_dm_p1;
  output [31:0]dfi_10_dw_rddata_dbi_p1;
  output [7:0]dfi_10_dw_rddata_par_p1;
  output [15:0]dfi_10_dbi_byte_disable;
  output [3:0]dfi_10_dw_rddata_valid;
  output [7:0]dfi_10_dw_derr_n;
  output [1:0]dfi_10_aw_aerr_n;
  output dfi_10_ctrlupd_req;
  output dfi_10_phyupd_ack;
  output dfi_10_clk_init;
  output dfi_10_init_complete;
  output dfi_10_out_rst_n;
  output [255:0]dfi_11_dw_rddata_p0;
  output [31:0]dfi_11_dw_rddata_dm_p0;
  output [31:0]dfi_11_dw_rddata_dbi_p0;
  output [7:0]dfi_11_dw_rddata_par_p0;
  output [255:0]dfi_11_dw_rddata_p1;
  output [31:0]dfi_11_dw_rddata_dm_p1;
  output [31:0]dfi_11_dw_rddata_dbi_p1;
  output [7:0]dfi_11_dw_rddata_par_p1;
  output [15:0]dfi_11_dbi_byte_disable;
  output [3:0]dfi_11_dw_rddata_valid;
  output [7:0]dfi_11_dw_derr_n;
  output [1:0]dfi_11_aw_aerr_n;
  output dfi_11_ctrlupd_req;
  output dfi_11_phyupd_ack;
  output dfi_11_clk_init;
  output dfi_11_init_complete;
  output dfi_11_out_rst_n;
  output [255:0]dfi_12_dw_rddata_p0;
  output [31:0]dfi_12_dw_rddata_dm_p0;
  output [31:0]dfi_12_dw_rddata_dbi_p0;
  output [7:0]dfi_12_dw_rddata_par_p0;
  output [255:0]dfi_12_dw_rddata_p1;
  output [31:0]dfi_12_dw_rddata_dm_p1;
  output [31:0]dfi_12_dw_rddata_dbi_p1;
  output [7:0]dfi_12_dw_rddata_par_p1;
  output [15:0]dfi_12_dbi_byte_disable;
  output [3:0]dfi_12_dw_rddata_valid;
  output [7:0]dfi_12_dw_derr_n;
  output [1:0]dfi_12_aw_aerr_n;
  output dfi_12_ctrlupd_req;
  output dfi_12_phyupd_ack;
  output dfi_12_clk_init;
  output dfi_12_init_complete;
  output dfi_12_out_rst_n;
  output [255:0]dfi_13_dw_rddata_p0;
  output [31:0]dfi_13_dw_rddata_dm_p0;
  output [31:0]dfi_13_dw_rddata_dbi_p0;
  output [7:0]dfi_13_dw_rddata_par_p0;
  output [255:0]dfi_13_dw_rddata_p1;
  output [31:0]dfi_13_dw_rddata_dm_p1;
  output [31:0]dfi_13_dw_rddata_dbi_p1;
  output [7:0]dfi_13_dw_rddata_par_p1;
  output [15:0]dfi_13_dbi_byte_disable;
  output [3:0]dfi_13_dw_rddata_valid;
  output [7:0]dfi_13_dw_derr_n;
  output [1:0]dfi_13_aw_aerr_n;
  output dfi_13_ctrlupd_req;
  output dfi_13_phyupd_ack;
  output dfi_13_clk_init;
  output dfi_13_init_complete;
  output dfi_13_out_rst_n;
  output [255:0]dfi_14_dw_rddata_p0;
  output [31:0]dfi_14_dw_rddata_dm_p0;
  output [31:0]dfi_14_dw_rddata_dbi_p0;
  output [7:0]dfi_14_dw_rddata_par_p0;
  output [255:0]dfi_14_dw_rddata_p1;
  output [31:0]dfi_14_dw_rddata_dm_p1;
  output [31:0]dfi_14_dw_rddata_dbi_p1;
  output [7:0]dfi_14_dw_rddata_par_p1;
  output [15:0]dfi_14_dbi_byte_disable;
  output [3:0]dfi_14_dw_rddata_valid;
  output [7:0]dfi_14_dw_derr_n;
  output [1:0]dfi_14_aw_aerr_n;
  output dfi_14_ctrlupd_req;
  output dfi_14_phyupd_ack;
  output dfi_14_clk_init;
  output dfi_14_init_complete;
  output dfi_14_out_rst_n;
  output [255:0]dfi_15_dw_rddata_p0;
  output [31:0]dfi_15_dw_rddata_dm_p0;
  output [31:0]dfi_15_dw_rddata_dbi_p0;
  output [7:0]dfi_15_dw_rddata_par_p0;
  output [255:0]dfi_15_dw_rddata_p1;
  output [31:0]dfi_15_dw_rddata_dm_p1;
  output [31:0]dfi_15_dw_rddata_dbi_p1;
  output [7:0]dfi_15_dw_rddata_par_p1;
  output [15:0]dfi_15_dbi_byte_disable;
  output [3:0]dfi_15_dw_rddata_valid;
  output [7:0]dfi_15_dw_derr_n;
  output [1:0]dfi_15_aw_aerr_n;
  output dfi_15_ctrlupd_req;
  output dfi_15_phyupd_ack;
  output dfi_15_clk_init;
  output dfi_15_init_complete;
  output dfi_15_out_rst_n;
  output apb_complete_0;
  output apb_complete_1;
  output DRAM_0_STAT_CATTRIP;
  output [6:0]DRAM_0_STAT_TEMP;
  output DRAM_1_STAT_CATTRIP;
  output [6:0]DRAM_1_STAT_TEMP;
endmodule
