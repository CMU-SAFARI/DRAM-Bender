// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
// Date        : Wed Jul 20 13:38:01 2022
// Host        : DESKTOP-4NLVFC8 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub -rename_top pcie_7x_0 -prefix
//               pcie_7x_0_ pcie_7x_0_stub.v
// Design      : pcie_7x_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7z045ffg900-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "pcie_7x_0_pcie2_top,Vivado 2020.2" *)
module pcie_7x_0(pci_exp_txp, pci_exp_txn, pci_exp_rxp, 
  pci_exp_rxn, pipe_pclk_in, pipe_rxusrclk_in, pipe_rxoutclk_in, pipe_dclk_in, 
  pipe_userclk1_in, pipe_userclk2_in, pipe_oobclk_in, pipe_mmcm_lock_in, pipe_txoutclk_out, 
  pipe_rxoutclk_out, pipe_pclk_sel_out, pipe_gen3_out, user_clk_out, user_reset_out, 
  user_lnk_up, user_app_rdy, tx_buf_av, tx_cfg_req, tx_err_drop, s_axis_tx_tready, 
  s_axis_tx_tdata, s_axis_tx_tkeep, s_axis_tx_tlast, s_axis_tx_tvalid, s_axis_tx_tuser, 
  tx_cfg_gnt, m_axis_rx_tdata, m_axis_rx_tkeep, m_axis_rx_tlast, m_axis_rx_tvalid, 
  m_axis_rx_tready, m_axis_rx_tuser, rx_np_ok, rx_np_req, fc_cpld, fc_cplh, fc_npd, fc_nph, fc_pd, 
  fc_ph, fc_sel, cfg_mgmt_do, cfg_mgmt_rd_wr_done, cfg_status, cfg_command, cfg_dstatus, 
  cfg_dcommand, cfg_lstatus, cfg_lcommand, cfg_dcommand2, cfg_pcie_link_state, 
  cfg_pmcsr_pme_en, cfg_pmcsr_powerstate, cfg_pmcsr_pme_status, 
  cfg_received_func_lvl_rst, cfg_mgmt_di, cfg_mgmt_byte_en, cfg_mgmt_dwaddr, 
  cfg_mgmt_wr_en, cfg_mgmt_rd_en, cfg_mgmt_wr_readonly, cfg_err_ecrc, cfg_err_ur, 
  cfg_err_cpl_timeout, cfg_err_cpl_unexpect, cfg_err_cpl_abort, cfg_err_posted, 
  cfg_err_cor, cfg_err_atomic_egress_blocked, cfg_err_internal_cor, cfg_err_malformed, 
  cfg_err_mc_blocked, cfg_err_poisoned, cfg_err_norecovery, cfg_err_tlp_cpl_header, 
  cfg_err_cpl_rdy, cfg_err_locked, cfg_err_acs, cfg_err_internal_uncor, cfg_trn_pending, 
  cfg_pm_halt_aspm_l0s, cfg_pm_halt_aspm_l1, cfg_pm_force_state_en, cfg_pm_force_state, 
  cfg_dsn, cfg_interrupt, cfg_interrupt_rdy, cfg_interrupt_assert, cfg_interrupt_di, 
  cfg_interrupt_do, cfg_interrupt_mmenable, cfg_interrupt_msienable, 
  cfg_interrupt_msixenable, cfg_interrupt_msixfm, cfg_interrupt_stat, 
  cfg_pciecap_interrupt_msgnum, cfg_to_turnoff, cfg_turnoff_ok, cfg_bus_number, 
  cfg_device_number, cfg_function_number, cfg_pm_wake, cfg_pm_send_pme_to, 
  cfg_ds_bus_number, cfg_ds_device_number, cfg_ds_function_number, 
  cfg_mgmt_wr_rw1c_as_rw, cfg_msg_received, cfg_msg_data, cfg_bridge_serr_en, 
  cfg_slot_control_electromech_il_ctl_pulse, cfg_root_control_syserr_corr_err_en, 
  cfg_root_control_syserr_non_fatal_err_en, cfg_root_control_syserr_fatal_err_en, 
  cfg_root_control_pme_int_en, cfg_aer_rooterr_corr_err_reporting_en, 
  cfg_aer_rooterr_non_fatal_err_reporting_en, cfg_aer_rooterr_fatal_err_reporting_en, 
  cfg_aer_rooterr_corr_err_received, cfg_aer_rooterr_non_fatal_err_received, 
  cfg_aer_rooterr_fatal_err_received, cfg_msg_received_err_cor, 
  cfg_msg_received_err_non_fatal, cfg_msg_received_err_fatal, 
  cfg_msg_received_pm_as_nak, cfg_msg_received_pm_pme, cfg_msg_received_pme_to_ack, 
  cfg_msg_received_assert_int_a, cfg_msg_received_assert_int_b, 
  cfg_msg_received_assert_int_c, cfg_msg_received_assert_int_d, 
  cfg_msg_received_deassert_int_a, cfg_msg_received_deassert_int_b, 
  cfg_msg_received_deassert_int_c, cfg_msg_received_deassert_int_d, 
  cfg_msg_received_setslotpowerlimit, pl_directed_link_change, pl_directed_link_width, 
  pl_directed_link_speed, pl_directed_link_auton, pl_upstream_prefer_deemph, 
  pl_sel_lnk_rate, pl_sel_lnk_width, pl_ltssm_state, pl_lane_reversal_mode, pl_phy_lnk_up, 
  pl_tx_pm_state, pl_rx_pm_state, pl_link_upcfg_cap, pl_link_gen2_cap, 
  pl_link_partner_gen2_supported, pl_initial_link_width, pl_directed_change_done, 
  pl_received_hot_rst, pl_transmit_hot_rst, pl_downstream_deemph_source, 
  cfg_err_aer_headerlog, cfg_aer_interrupt_msgnum, cfg_err_aer_headerlog_set, 
  cfg_aer_ecrc_check_en, cfg_aer_ecrc_gen_en, cfg_vc_tcvc_map, sys_clk, sys_rst_n, 
  pipe_mmcm_rst_n, pcie_drp_clk, pcie_drp_en, pcie_drp_we, pcie_drp_addr, pcie_drp_di, 
  pcie_drp_do, pcie_drp_rdy)
/* synthesis syn_black_box black_box_pad_pin="pci_exp_txp[3:0],pci_exp_txn[3:0],pci_exp_rxp[3:0],pci_exp_rxn[3:0],pipe_pclk_in,pipe_rxusrclk_in,pipe_rxoutclk_in[3:0],pipe_dclk_in,pipe_userclk1_in,pipe_userclk2_in,pipe_oobclk_in,pipe_mmcm_lock_in,pipe_txoutclk_out,pipe_rxoutclk_out[3:0],pipe_pclk_sel_out[3:0],pipe_gen3_out,user_clk_out,user_reset_out,user_lnk_up,user_app_rdy,tx_buf_av[5:0],tx_cfg_req,tx_err_drop,s_axis_tx_tready,s_axis_tx_tdata[63:0],s_axis_tx_tkeep[7:0],s_axis_tx_tlast,s_axis_tx_tvalid,s_axis_tx_tuser[3:0],tx_cfg_gnt,m_axis_rx_tdata[63:0],m_axis_rx_tkeep[7:0],m_axis_rx_tlast,m_axis_rx_tvalid,m_axis_rx_tready,m_axis_rx_tuser[21:0],rx_np_ok,rx_np_req,fc_cpld[11:0],fc_cplh[7:0],fc_npd[11:0],fc_nph[7:0],fc_pd[11:0],fc_ph[7:0],fc_sel[2:0],cfg_mgmt_do[31:0],cfg_mgmt_rd_wr_done,cfg_status[15:0],cfg_command[15:0],cfg_dstatus[15:0],cfg_dcommand[15:0],cfg_lstatus[15:0],cfg_lcommand[15:0],cfg_dcommand2[15:0],cfg_pcie_link_state[2:0],cfg_pmcsr_pme_en,cfg_pmcsr_powerstate[1:0],cfg_pmcsr_pme_status,cfg_received_func_lvl_rst,cfg_mgmt_di[31:0],cfg_mgmt_byte_en[3:0],cfg_mgmt_dwaddr[9:0],cfg_mgmt_wr_en,cfg_mgmt_rd_en,cfg_mgmt_wr_readonly,cfg_err_ecrc,cfg_err_ur,cfg_err_cpl_timeout,cfg_err_cpl_unexpect,cfg_err_cpl_abort,cfg_err_posted,cfg_err_cor,cfg_err_atomic_egress_blocked,cfg_err_internal_cor,cfg_err_malformed,cfg_err_mc_blocked,cfg_err_poisoned,cfg_err_norecovery,cfg_err_tlp_cpl_header[47:0],cfg_err_cpl_rdy,cfg_err_locked,cfg_err_acs,cfg_err_internal_uncor,cfg_trn_pending,cfg_pm_halt_aspm_l0s,cfg_pm_halt_aspm_l1,cfg_pm_force_state_en,cfg_pm_force_state[1:0],cfg_dsn[63:0],cfg_interrupt,cfg_interrupt_rdy,cfg_interrupt_assert,cfg_interrupt_di[7:0],cfg_interrupt_do[7:0],cfg_interrupt_mmenable[2:0],cfg_interrupt_msienable,cfg_interrupt_msixenable,cfg_interrupt_msixfm,cfg_interrupt_stat,cfg_pciecap_interrupt_msgnum[4:0],cfg_to_turnoff,cfg_turnoff_ok,cfg_bus_number[7:0],cfg_device_number[4:0],cfg_function_number[2:0],cfg_pm_wake,cfg_pm_send_pme_to,cfg_ds_bus_number[7:0],cfg_ds_device_number[4:0],cfg_ds_function_number[2:0],cfg_mgmt_wr_rw1c_as_rw,cfg_msg_received,cfg_msg_data[15:0],cfg_bridge_serr_en,cfg_slot_control_electromech_il_ctl_pulse,cfg_root_control_syserr_corr_err_en,cfg_root_control_syserr_non_fatal_err_en,cfg_root_control_syserr_fatal_err_en,cfg_root_control_pme_int_en,cfg_aer_rooterr_corr_err_reporting_en,cfg_aer_rooterr_non_fatal_err_reporting_en,cfg_aer_rooterr_fatal_err_reporting_en,cfg_aer_rooterr_corr_err_received,cfg_aer_rooterr_non_fatal_err_received,cfg_aer_rooterr_fatal_err_received,cfg_msg_received_err_cor,cfg_msg_received_err_non_fatal,cfg_msg_received_err_fatal,cfg_msg_received_pm_as_nak,cfg_msg_received_pm_pme,cfg_msg_received_pme_to_ack,cfg_msg_received_assert_int_a,cfg_msg_received_assert_int_b,cfg_msg_received_assert_int_c,cfg_msg_received_assert_int_d,cfg_msg_received_deassert_int_a,cfg_msg_received_deassert_int_b,cfg_msg_received_deassert_int_c,cfg_msg_received_deassert_int_d,cfg_msg_received_setslotpowerlimit,pl_directed_link_change[1:0],pl_directed_link_width[1:0],pl_directed_link_speed,pl_directed_link_auton,pl_upstream_prefer_deemph,pl_sel_lnk_rate,pl_sel_lnk_width[1:0],pl_ltssm_state[5:0],pl_lane_reversal_mode[1:0],pl_phy_lnk_up,pl_tx_pm_state[2:0],pl_rx_pm_state[1:0],pl_link_upcfg_cap,pl_link_gen2_cap,pl_link_partner_gen2_supported,pl_initial_link_width[2:0],pl_directed_change_done,pl_received_hot_rst,pl_transmit_hot_rst,pl_downstream_deemph_source,cfg_err_aer_headerlog[127:0],cfg_aer_interrupt_msgnum[4:0],cfg_err_aer_headerlog_set,cfg_aer_ecrc_check_en,cfg_aer_ecrc_gen_en,cfg_vc_tcvc_map[6:0],sys_clk,sys_rst_n,pipe_mmcm_rst_n,pcie_drp_clk,pcie_drp_en,pcie_drp_we,pcie_drp_addr[8:0],pcie_drp_di[15:0],pcie_drp_do[15:0],pcie_drp_rdy" */;
  output [3:0]pci_exp_txp;
  output [3:0]pci_exp_txn;
  input [3:0]pci_exp_rxp;
  input [3:0]pci_exp_rxn;
  input pipe_pclk_in;
  input pipe_rxusrclk_in;
  input [3:0]pipe_rxoutclk_in;
  input pipe_dclk_in;
  input pipe_userclk1_in;
  input pipe_userclk2_in;
  input pipe_oobclk_in;
  input pipe_mmcm_lock_in;
  output pipe_txoutclk_out;
  output [3:0]pipe_rxoutclk_out;
  output [3:0]pipe_pclk_sel_out;
  output pipe_gen3_out;
  output user_clk_out;
  output user_reset_out;
  output user_lnk_up;
  output user_app_rdy;
  output [5:0]tx_buf_av;
  output tx_cfg_req;
  output tx_err_drop;
  output s_axis_tx_tready;
  input [63:0]s_axis_tx_tdata;
  input [7:0]s_axis_tx_tkeep;
  input s_axis_tx_tlast;
  input s_axis_tx_tvalid;
  input [3:0]s_axis_tx_tuser;
  input tx_cfg_gnt;
  output [63:0]m_axis_rx_tdata;
  output [7:0]m_axis_rx_tkeep;
  output m_axis_rx_tlast;
  output m_axis_rx_tvalid;
  input m_axis_rx_tready;
  output [21:0]m_axis_rx_tuser;
  input rx_np_ok;
  input rx_np_req;
  output [11:0]fc_cpld;
  output [7:0]fc_cplh;
  output [11:0]fc_npd;
  output [7:0]fc_nph;
  output [11:0]fc_pd;
  output [7:0]fc_ph;
  input [2:0]fc_sel;
  output [31:0]cfg_mgmt_do;
  output cfg_mgmt_rd_wr_done;
  output [15:0]cfg_status;
  output [15:0]cfg_command;
  output [15:0]cfg_dstatus;
  output [15:0]cfg_dcommand;
  output [15:0]cfg_lstatus;
  output [15:0]cfg_lcommand;
  output [15:0]cfg_dcommand2;
  output [2:0]cfg_pcie_link_state;
  output cfg_pmcsr_pme_en;
  output [1:0]cfg_pmcsr_powerstate;
  output cfg_pmcsr_pme_status;
  output cfg_received_func_lvl_rst;
  input [31:0]cfg_mgmt_di;
  input [3:0]cfg_mgmt_byte_en;
  input [9:0]cfg_mgmt_dwaddr;
  input cfg_mgmt_wr_en;
  input cfg_mgmt_rd_en;
  input cfg_mgmt_wr_readonly;
  input cfg_err_ecrc;
  input cfg_err_ur;
  input cfg_err_cpl_timeout;
  input cfg_err_cpl_unexpect;
  input cfg_err_cpl_abort;
  input cfg_err_posted;
  input cfg_err_cor;
  input cfg_err_atomic_egress_blocked;
  input cfg_err_internal_cor;
  input cfg_err_malformed;
  input cfg_err_mc_blocked;
  input cfg_err_poisoned;
  input cfg_err_norecovery;
  input [47:0]cfg_err_tlp_cpl_header;
  output cfg_err_cpl_rdy;
  input cfg_err_locked;
  input cfg_err_acs;
  input cfg_err_internal_uncor;
  input cfg_trn_pending;
  input cfg_pm_halt_aspm_l0s;
  input cfg_pm_halt_aspm_l1;
  input cfg_pm_force_state_en;
  input [1:0]cfg_pm_force_state;
  input [63:0]cfg_dsn;
  input cfg_interrupt;
  output cfg_interrupt_rdy;
  input cfg_interrupt_assert;
  input [7:0]cfg_interrupt_di;
  output [7:0]cfg_interrupt_do;
  output [2:0]cfg_interrupt_mmenable;
  output cfg_interrupt_msienable;
  output cfg_interrupt_msixenable;
  output cfg_interrupt_msixfm;
  input cfg_interrupt_stat;
  input [4:0]cfg_pciecap_interrupt_msgnum;
  output cfg_to_turnoff;
  input cfg_turnoff_ok;
  output [7:0]cfg_bus_number;
  output [4:0]cfg_device_number;
  output [2:0]cfg_function_number;
  input cfg_pm_wake;
  input cfg_pm_send_pme_to;
  input [7:0]cfg_ds_bus_number;
  input [4:0]cfg_ds_device_number;
  input [2:0]cfg_ds_function_number;
  input cfg_mgmt_wr_rw1c_as_rw;
  output cfg_msg_received;
  output [15:0]cfg_msg_data;
  output cfg_bridge_serr_en;
  output cfg_slot_control_electromech_il_ctl_pulse;
  output cfg_root_control_syserr_corr_err_en;
  output cfg_root_control_syserr_non_fatal_err_en;
  output cfg_root_control_syserr_fatal_err_en;
  output cfg_root_control_pme_int_en;
  output cfg_aer_rooterr_corr_err_reporting_en;
  output cfg_aer_rooterr_non_fatal_err_reporting_en;
  output cfg_aer_rooterr_fatal_err_reporting_en;
  output cfg_aer_rooterr_corr_err_received;
  output cfg_aer_rooterr_non_fatal_err_received;
  output cfg_aer_rooterr_fatal_err_received;
  output cfg_msg_received_err_cor;
  output cfg_msg_received_err_non_fatal;
  output cfg_msg_received_err_fatal;
  output cfg_msg_received_pm_as_nak;
  output cfg_msg_received_pm_pme;
  output cfg_msg_received_pme_to_ack;
  output cfg_msg_received_assert_int_a;
  output cfg_msg_received_assert_int_b;
  output cfg_msg_received_assert_int_c;
  output cfg_msg_received_assert_int_d;
  output cfg_msg_received_deassert_int_a;
  output cfg_msg_received_deassert_int_b;
  output cfg_msg_received_deassert_int_c;
  output cfg_msg_received_deassert_int_d;
  output cfg_msg_received_setslotpowerlimit;
  input [1:0]pl_directed_link_change;
  input [1:0]pl_directed_link_width;
  input pl_directed_link_speed;
  input pl_directed_link_auton;
  input pl_upstream_prefer_deemph;
  output pl_sel_lnk_rate;
  output [1:0]pl_sel_lnk_width;
  output [5:0]pl_ltssm_state;
  output [1:0]pl_lane_reversal_mode;
  output pl_phy_lnk_up;
  output [2:0]pl_tx_pm_state;
  output [1:0]pl_rx_pm_state;
  output pl_link_upcfg_cap;
  output pl_link_gen2_cap;
  output pl_link_partner_gen2_supported;
  output [2:0]pl_initial_link_width;
  output pl_directed_change_done;
  output pl_received_hot_rst;
  input pl_transmit_hot_rst;
  input pl_downstream_deemph_source;
  input [127:0]cfg_err_aer_headerlog;
  input [4:0]cfg_aer_interrupt_msgnum;
  output cfg_err_aer_headerlog_set;
  output cfg_aer_ecrc_check_en;
  output cfg_aer_ecrc_gen_en;
  output [6:0]cfg_vc_tcvc_map;
  input sys_clk;
  input sys_rst_n;
  input pipe_mmcm_rst_n;
  input pcie_drp_clk;
  input pcie_drp_en;
  input pcie_drp_we;
  input [8:0]pcie_drp_addr;
  input [15:0]pcie_drp_di;
  output [15:0]pcie_drp_do;
  output pcie_drp_rdy;
endmodule
