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

// IP VLNV: xilinx.com:ip:pcie_7x:3.3
// IP Revision: 14

// The following must be inserted into your Verilog file for this
// core to be instantiated. Change the instance name and port connections
// (in parentheses) to your own signal names.

//----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
pcie_7x_0 your_instance_name (
  .pci_exp_txp(pci_exp_txp),                                                                // output wire [3 : 0] pci_exp_txp
  .pci_exp_txn(pci_exp_txn),                                                                // output wire [3 : 0] pci_exp_txn
  .pci_exp_rxp(pci_exp_rxp),                                                                // input wire [3 : 0] pci_exp_rxp
  .pci_exp_rxn(pci_exp_rxn),                                                                // input wire [3 : 0] pci_exp_rxn
  .pipe_pclk_in(pipe_pclk_in),                                                              // input wire pipe_pclk_in
  .pipe_rxusrclk_in(pipe_rxusrclk_in),                                                      // input wire pipe_rxusrclk_in
  .pipe_rxoutclk_in(pipe_rxoutclk_in),                                                      // input wire [3 : 0] pipe_rxoutclk_in
  .pipe_dclk_in(pipe_dclk_in),                                                              // input wire pipe_dclk_in
  .pipe_userclk1_in(pipe_userclk1_in),                                                      // input wire pipe_userclk1_in
  .pipe_userclk2_in(pipe_userclk2_in),                                                      // input wire pipe_userclk2_in
  .pipe_oobclk_in(pipe_oobclk_in),                                                          // input wire pipe_oobclk_in
  .pipe_mmcm_lock_in(pipe_mmcm_lock_in),                                                    // input wire pipe_mmcm_lock_in
  .pipe_txoutclk_out(pipe_txoutclk_out),                                                    // output wire pipe_txoutclk_out
  .pipe_rxoutclk_out(pipe_rxoutclk_out),                                                    // output wire [3 : 0] pipe_rxoutclk_out
  .pipe_pclk_sel_out(pipe_pclk_sel_out),                                                    // output wire [3 : 0] pipe_pclk_sel_out
  .pipe_gen3_out(pipe_gen3_out),                                                            // output wire pipe_gen3_out
  .user_clk_out(user_clk_out),                                                              // output wire user_clk_out
  .user_reset_out(user_reset_out),                                                          // output wire user_reset_out
  .user_lnk_up(user_lnk_up),                                                                // output wire user_lnk_up
  .user_app_rdy(user_app_rdy),                                                              // output wire user_app_rdy
  .tx_buf_av(tx_buf_av),                                                                    // output wire [5 : 0] tx_buf_av
  .tx_cfg_req(tx_cfg_req),                                                                  // output wire tx_cfg_req
  .tx_err_drop(tx_err_drop),                                                                // output wire tx_err_drop
  .s_axis_tx_tready(s_axis_tx_tready),                                                      // output wire s_axis_tx_tready
  .s_axis_tx_tdata(s_axis_tx_tdata),                                                        // input wire [63 : 0] s_axis_tx_tdata
  .s_axis_tx_tkeep(s_axis_tx_tkeep),                                                        // input wire [7 : 0] s_axis_tx_tkeep
  .s_axis_tx_tlast(s_axis_tx_tlast),                                                        // input wire s_axis_tx_tlast
  .s_axis_tx_tvalid(s_axis_tx_tvalid),                                                      // input wire s_axis_tx_tvalid
  .s_axis_tx_tuser(s_axis_tx_tuser),                                                        // input wire [3 : 0] s_axis_tx_tuser
  .tx_cfg_gnt(tx_cfg_gnt),                                                                  // input wire tx_cfg_gnt
  .m_axis_rx_tdata(m_axis_rx_tdata),                                                        // output wire [63 : 0] m_axis_rx_tdata
  .m_axis_rx_tkeep(m_axis_rx_tkeep),                                                        // output wire [7 : 0] m_axis_rx_tkeep
  .m_axis_rx_tlast(m_axis_rx_tlast),                                                        // output wire m_axis_rx_tlast
  .m_axis_rx_tvalid(m_axis_rx_tvalid),                                                      // output wire m_axis_rx_tvalid
  .m_axis_rx_tready(m_axis_rx_tready),                                                      // input wire m_axis_rx_tready
  .m_axis_rx_tuser(m_axis_rx_tuser),                                                        // output wire [21 : 0] m_axis_rx_tuser
  .rx_np_ok(rx_np_ok),                                                                      // input wire rx_np_ok
  .rx_np_req(rx_np_req),                                                                    // input wire rx_np_req
  .fc_cpld(fc_cpld),                                                                        // output wire [11 : 0] fc_cpld
  .fc_cplh(fc_cplh),                                                                        // output wire [7 : 0] fc_cplh
  .fc_npd(fc_npd),                                                                          // output wire [11 : 0] fc_npd
  .fc_nph(fc_nph),                                                                          // output wire [7 : 0] fc_nph
  .fc_pd(fc_pd),                                                                            // output wire [11 : 0] fc_pd
  .fc_ph(fc_ph),                                                                            // output wire [7 : 0] fc_ph
  .fc_sel(fc_sel),                                                                          // input wire [2 : 0] fc_sel
  .cfg_mgmt_do(cfg_mgmt_do),                                                                // output wire [31 : 0] cfg_mgmt_do
  .cfg_mgmt_rd_wr_done(cfg_mgmt_rd_wr_done),                                                // output wire cfg_mgmt_rd_wr_done
  .cfg_status(cfg_status),                                                                  // output wire [15 : 0] cfg_status
  .cfg_command(cfg_command),                                                                // output wire [15 : 0] cfg_command
  .cfg_dstatus(cfg_dstatus),                                                                // output wire [15 : 0] cfg_dstatus
  .cfg_dcommand(cfg_dcommand),                                                              // output wire [15 : 0] cfg_dcommand
  .cfg_lstatus(cfg_lstatus),                                                                // output wire [15 : 0] cfg_lstatus
  .cfg_lcommand(cfg_lcommand),                                                              // output wire [15 : 0] cfg_lcommand
  .cfg_dcommand2(cfg_dcommand2),                                                            // output wire [15 : 0] cfg_dcommand2
  .cfg_pcie_link_state(cfg_pcie_link_state),                                                // output wire [2 : 0] cfg_pcie_link_state
  .cfg_pmcsr_pme_en(cfg_pmcsr_pme_en),                                                      // output wire cfg_pmcsr_pme_en
  .cfg_pmcsr_powerstate(cfg_pmcsr_powerstate),                                              // output wire [1 : 0] cfg_pmcsr_powerstate
  .cfg_pmcsr_pme_status(cfg_pmcsr_pme_status),                                              // output wire cfg_pmcsr_pme_status
  .cfg_received_func_lvl_rst(cfg_received_func_lvl_rst),                                    // output wire cfg_received_func_lvl_rst
  .cfg_mgmt_di(cfg_mgmt_di),                                                                // input wire [31 : 0] cfg_mgmt_di
  .cfg_mgmt_byte_en(cfg_mgmt_byte_en),                                                      // input wire [3 : 0] cfg_mgmt_byte_en
  .cfg_mgmt_dwaddr(cfg_mgmt_dwaddr),                                                        // input wire [9 : 0] cfg_mgmt_dwaddr
  .cfg_mgmt_wr_en(cfg_mgmt_wr_en),                                                          // input wire cfg_mgmt_wr_en
  .cfg_mgmt_rd_en(cfg_mgmt_rd_en),                                                          // input wire cfg_mgmt_rd_en
  .cfg_mgmt_wr_readonly(cfg_mgmt_wr_readonly),                                              // input wire cfg_mgmt_wr_readonly
  .cfg_err_ecrc(cfg_err_ecrc),                                                              // input wire cfg_err_ecrc
  .cfg_err_ur(cfg_err_ur),                                                                  // input wire cfg_err_ur
  .cfg_err_cpl_timeout(cfg_err_cpl_timeout),                                                // input wire cfg_err_cpl_timeout
  .cfg_err_cpl_unexpect(cfg_err_cpl_unexpect),                                              // input wire cfg_err_cpl_unexpect
  .cfg_err_cpl_abort(cfg_err_cpl_abort),                                                    // input wire cfg_err_cpl_abort
  .cfg_err_posted(cfg_err_posted),                                                          // input wire cfg_err_posted
  .cfg_err_cor(cfg_err_cor),                                                                // input wire cfg_err_cor
  .cfg_err_atomic_egress_blocked(cfg_err_atomic_egress_blocked),                            // input wire cfg_err_atomic_egress_blocked
  .cfg_err_internal_cor(cfg_err_internal_cor),                                              // input wire cfg_err_internal_cor
  .cfg_err_malformed(cfg_err_malformed),                                                    // input wire cfg_err_malformed
  .cfg_err_mc_blocked(cfg_err_mc_blocked),                                                  // input wire cfg_err_mc_blocked
  .cfg_err_poisoned(cfg_err_poisoned),                                                      // input wire cfg_err_poisoned
  .cfg_err_norecovery(cfg_err_norecovery),                                                  // input wire cfg_err_norecovery
  .cfg_err_tlp_cpl_header(cfg_err_tlp_cpl_header),                                          // input wire [47 : 0] cfg_err_tlp_cpl_header
  .cfg_err_cpl_rdy(cfg_err_cpl_rdy),                                                        // output wire cfg_err_cpl_rdy
  .cfg_err_locked(cfg_err_locked),                                                          // input wire cfg_err_locked
  .cfg_err_acs(cfg_err_acs),                                                                // input wire cfg_err_acs
  .cfg_err_internal_uncor(cfg_err_internal_uncor),                                          // input wire cfg_err_internal_uncor
  .cfg_trn_pending(cfg_trn_pending),                                                        // input wire cfg_trn_pending
  .cfg_pm_halt_aspm_l0s(cfg_pm_halt_aspm_l0s),                                              // input wire cfg_pm_halt_aspm_l0s
  .cfg_pm_halt_aspm_l1(cfg_pm_halt_aspm_l1),                                                // input wire cfg_pm_halt_aspm_l1
  .cfg_pm_force_state_en(cfg_pm_force_state_en),                                            // input wire cfg_pm_force_state_en
  .cfg_pm_force_state(cfg_pm_force_state),                                                  // input wire [1 : 0] cfg_pm_force_state
  .cfg_dsn(cfg_dsn),                                                                        // input wire [63 : 0] cfg_dsn
  .cfg_interrupt(cfg_interrupt),                                                            // input wire cfg_interrupt
  .cfg_interrupt_rdy(cfg_interrupt_rdy),                                                    // output wire cfg_interrupt_rdy
  .cfg_interrupt_assert(cfg_interrupt_assert),                                              // input wire cfg_interrupt_assert
  .cfg_interrupt_di(cfg_interrupt_di),                                                      // input wire [7 : 0] cfg_interrupt_di
  .cfg_interrupt_do(cfg_interrupt_do),                                                      // output wire [7 : 0] cfg_interrupt_do
  .cfg_interrupt_mmenable(cfg_interrupt_mmenable),                                          // output wire [2 : 0] cfg_interrupt_mmenable
  .cfg_interrupt_msienable(cfg_interrupt_msienable),                                        // output wire cfg_interrupt_msienable
  .cfg_interrupt_msixenable(cfg_interrupt_msixenable),                                      // output wire cfg_interrupt_msixenable
  .cfg_interrupt_msixfm(cfg_interrupt_msixfm),                                              // output wire cfg_interrupt_msixfm
  .cfg_interrupt_stat(cfg_interrupt_stat),                                                  // input wire cfg_interrupt_stat
  .cfg_pciecap_interrupt_msgnum(cfg_pciecap_interrupt_msgnum),                              // input wire [4 : 0] cfg_pciecap_interrupt_msgnum
  .cfg_to_turnoff(cfg_to_turnoff),                                                          // output wire cfg_to_turnoff
  .cfg_turnoff_ok(cfg_turnoff_ok),                                                          // input wire cfg_turnoff_ok
  .cfg_bus_number(cfg_bus_number),                                                          // output wire [7 : 0] cfg_bus_number
  .cfg_device_number(cfg_device_number),                                                    // output wire [4 : 0] cfg_device_number
  .cfg_function_number(cfg_function_number),                                                // output wire [2 : 0] cfg_function_number
  .cfg_pm_wake(cfg_pm_wake),                                                                // input wire cfg_pm_wake
  .cfg_pm_send_pme_to(cfg_pm_send_pme_to),                                                  // input wire cfg_pm_send_pme_to
  .cfg_ds_bus_number(cfg_ds_bus_number),                                                    // input wire [7 : 0] cfg_ds_bus_number
  .cfg_ds_device_number(cfg_ds_device_number),                                              // input wire [4 : 0] cfg_ds_device_number
  .cfg_ds_function_number(cfg_ds_function_number),                                          // input wire [2 : 0] cfg_ds_function_number
  .cfg_mgmt_wr_rw1c_as_rw(cfg_mgmt_wr_rw1c_as_rw),                                          // input wire cfg_mgmt_wr_rw1c_as_rw
  .cfg_msg_received(cfg_msg_received),                                                      // output wire cfg_msg_received
  .cfg_msg_data(cfg_msg_data),                                                              // output wire [15 : 0] cfg_msg_data
  .cfg_bridge_serr_en(cfg_bridge_serr_en),                                                  // output wire cfg_bridge_serr_en
  .cfg_slot_control_electromech_il_ctl_pulse(cfg_slot_control_electromech_il_ctl_pulse),    // output wire cfg_slot_control_electromech_il_ctl_pulse
  .cfg_root_control_syserr_corr_err_en(cfg_root_control_syserr_corr_err_en),                // output wire cfg_root_control_syserr_corr_err_en
  .cfg_root_control_syserr_non_fatal_err_en(cfg_root_control_syserr_non_fatal_err_en),      // output wire cfg_root_control_syserr_non_fatal_err_en
  .cfg_root_control_syserr_fatal_err_en(cfg_root_control_syserr_fatal_err_en),              // output wire cfg_root_control_syserr_fatal_err_en
  .cfg_root_control_pme_int_en(cfg_root_control_pme_int_en),                                // output wire cfg_root_control_pme_int_en
  .cfg_aer_rooterr_corr_err_reporting_en(cfg_aer_rooterr_corr_err_reporting_en),            // output wire cfg_aer_rooterr_corr_err_reporting_en
  .cfg_aer_rooterr_non_fatal_err_reporting_en(cfg_aer_rooterr_non_fatal_err_reporting_en),  // output wire cfg_aer_rooterr_non_fatal_err_reporting_en
  .cfg_aer_rooterr_fatal_err_reporting_en(cfg_aer_rooterr_fatal_err_reporting_en),          // output wire cfg_aer_rooterr_fatal_err_reporting_en
  .cfg_aer_rooterr_corr_err_received(cfg_aer_rooterr_corr_err_received),                    // output wire cfg_aer_rooterr_corr_err_received
  .cfg_aer_rooterr_non_fatal_err_received(cfg_aer_rooterr_non_fatal_err_received),          // output wire cfg_aer_rooterr_non_fatal_err_received
  .cfg_aer_rooterr_fatal_err_received(cfg_aer_rooterr_fatal_err_received),                  // output wire cfg_aer_rooterr_fatal_err_received
  .cfg_msg_received_err_cor(cfg_msg_received_err_cor),                                      // output wire cfg_msg_received_err_cor
  .cfg_msg_received_err_non_fatal(cfg_msg_received_err_non_fatal),                          // output wire cfg_msg_received_err_non_fatal
  .cfg_msg_received_err_fatal(cfg_msg_received_err_fatal),                                  // output wire cfg_msg_received_err_fatal
  .cfg_msg_received_pm_as_nak(cfg_msg_received_pm_as_nak),                                  // output wire cfg_msg_received_pm_as_nak
  .cfg_msg_received_pm_pme(cfg_msg_received_pm_pme),                                        // output wire cfg_msg_received_pm_pme
  .cfg_msg_received_pme_to_ack(cfg_msg_received_pme_to_ack),                                // output wire cfg_msg_received_pme_to_ack
  .cfg_msg_received_assert_int_a(cfg_msg_received_assert_int_a),                            // output wire cfg_msg_received_assert_int_a
  .cfg_msg_received_assert_int_b(cfg_msg_received_assert_int_b),                            // output wire cfg_msg_received_assert_int_b
  .cfg_msg_received_assert_int_c(cfg_msg_received_assert_int_c),                            // output wire cfg_msg_received_assert_int_c
  .cfg_msg_received_assert_int_d(cfg_msg_received_assert_int_d),                            // output wire cfg_msg_received_assert_int_d
  .cfg_msg_received_deassert_int_a(cfg_msg_received_deassert_int_a),                        // output wire cfg_msg_received_deassert_int_a
  .cfg_msg_received_deassert_int_b(cfg_msg_received_deassert_int_b),                        // output wire cfg_msg_received_deassert_int_b
  .cfg_msg_received_deassert_int_c(cfg_msg_received_deassert_int_c),                        // output wire cfg_msg_received_deassert_int_c
  .cfg_msg_received_deassert_int_d(cfg_msg_received_deassert_int_d),                        // output wire cfg_msg_received_deassert_int_d
  .cfg_msg_received_setslotpowerlimit(cfg_msg_received_setslotpowerlimit),                  // output wire cfg_msg_received_setslotpowerlimit
  .pl_directed_link_change(pl_directed_link_change),                                        // input wire [1 : 0] pl_directed_link_change
  .pl_directed_link_width(pl_directed_link_width),                                          // input wire [1 : 0] pl_directed_link_width
  .pl_directed_link_speed(pl_directed_link_speed),                                          // input wire pl_directed_link_speed
  .pl_directed_link_auton(pl_directed_link_auton),                                          // input wire pl_directed_link_auton
  .pl_upstream_prefer_deemph(pl_upstream_prefer_deemph),                                    // input wire pl_upstream_prefer_deemph
  .pl_sel_lnk_rate(pl_sel_lnk_rate),                                                        // output wire pl_sel_lnk_rate
  .pl_sel_lnk_width(pl_sel_lnk_width),                                                      // output wire [1 : 0] pl_sel_lnk_width
  .pl_ltssm_state(pl_ltssm_state),                                                          // output wire [5 : 0] pl_ltssm_state
  .pl_lane_reversal_mode(pl_lane_reversal_mode),                                            // output wire [1 : 0] pl_lane_reversal_mode
  .pl_phy_lnk_up(pl_phy_lnk_up),                                                            // output wire pl_phy_lnk_up
  .pl_tx_pm_state(pl_tx_pm_state),                                                          // output wire [2 : 0] pl_tx_pm_state
  .pl_rx_pm_state(pl_rx_pm_state),                                                          // output wire [1 : 0] pl_rx_pm_state
  .pl_link_upcfg_cap(pl_link_upcfg_cap),                                                    // output wire pl_link_upcfg_cap
  .pl_link_gen2_cap(pl_link_gen2_cap),                                                      // output wire pl_link_gen2_cap
  .pl_link_partner_gen2_supported(pl_link_partner_gen2_supported),                          // output wire pl_link_partner_gen2_supported
  .pl_initial_link_width(pl_initial_link_width),                                            // output wire [2 : 0] pl_initial_link_width
  .pl_directed_change_done(pl_directed_change_done),                                        // output wire pl_directed_change_done
  .pl_received_hot_rst(pl_received_hot_rst),                                                // output wire pl_received_hot_rst
  .pl_transmit_hot_rst(pl_transmit_hot_rst),                                                // input wire pl_transmit_hot_rst
  .pl_downstream_deemph_source(pl_downstream_deemph_source),                                // input wire pl_downstream_deemph_source
  .cfg_err_aer_headerlog(cfg_err_aer_headerlog),                                            // input wire [127 : 0] cfg_err_aer_headerlog
  .cfg_aer_interrupt_msgnum(cfg_aer_interrupt_msgnum),                                      // input wire [4 : 0] cfg_aer_interrupt_msgnum
  .cfg_err_aer_headerlog_set(cfg_err_aer_headerlog_set),                                    // output wire cfg_err_aer_headerlog_set
  .cfg_aer_ecrc_check_en(cfg_aer_ecrc_check_en),                                            // output wire cfg_aer_ecrc_check_en
  .cfg_aer_ecrc_gen_en(cfg_aer_ecrc_gen_en),                                                // output wire cfg_aer_ecrc_gen_en
  .cfg_vc_tcvc_map(cfg_vc_tcvc_map),                                                        // output wire [6 : 0] cfg_vc_tcvc_map
  .sys_clk(sys_clk),                                                                        // input wire sys_clk
  .sys_rst_n(sys_rst_n),                                                                    // input wire sys_rst_n
  .pipe_mmcm_rst_n(pipe_mmcm_rst_n),                                                        // input wire pipe_mmcm_rst_n
  .pcie_drp_clk(pcie_drp_clk),                                                              // input wire pcie_drp_clk
  .pcie_drp_en(pcie_drp_en),                                                                // input wire pcie_drp_en
  .pcie_drp_we(pcie_drp_we),                                                                // input wire pcie_drp_we
  .pcie_drp_addr(pcie_drp_addr),                                                            // input wire [8 : 0] pcie_drp_addr
  .pcie_drp_di(pcie_drp_di),                                                                // input wire [15 : 0] pcie_drp_di
  .pcie_drp_do(pcie_drp_do),                                                                // output wire [15 : 0] pcie_drp_do
  .pcie_drp_rdy(pcie_drp_rdy)                                                              // output wire pcie_drp_rdy
);
// INST_TAG_END ------ End INSTANTIATION Template ---------

// You must compile the wrapper file pcie_7x_0.v when simulating
// the core, pcie_7x_0. When compiling the wrapper file, be sure to
// reference the Verilog simulation library.

