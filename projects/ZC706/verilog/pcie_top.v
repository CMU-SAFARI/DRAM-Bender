//-----------------------------------------------------------------------------
//
// (c) Copyright 2010-2011 Xilinx, Inc. All rights reserved.
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
//-----------------------------------------------------------------------------
// Project    : Series-7 Integrated Block for PCI Express
// File       : xilinx_pcie_2_1_ep_7x.v
// Version    : 3.2
//--
//-- Description:  PCI Express Endpoint example FPGA design
//--
//------------------------------------------------------------------------------

`include "project.vh"
// `define DEBUG
// `define ILA_CORES

`timescale 1ns / 1ps
(* DowngradeIPIdentifiedWarnings = "yes" *)
module pcie_top # (
    parameter PL_FAST_TRAIN       = "FALSE",			// Simulation Speedup
    parameter EXT_PIPE_SIM        = "FALSE",  			// This Parameter has effect on selecting Enable External PIPE Interface in GUI.	
    parameter PCIE_EXT_CLK        = "TRUE",    			// Use External Clocking Module
    parameter PCIE_EXT_GT_COMMON  = "FALSE",
    parameter REF_CLK_FREQ        = 0,     				// 0 - 100 MHz, 1 - 125 MHz, 2 - 250 MHz
    parameter C_DATA_WIDTH        = 64, 				// RX/TX interface data width
    parameter KEEP_WIDTH          = C_DATA_WIDTH / 8 	// TSTRB width
) (
    output  	[3:0]    						pci_exp_txp,
    output  	[3:0]    						pci_exp_txn,
    input   	[3:0]    						pci_exp_rxp,
    input   	[3:0]    						pci_exp_rxn,

    output                                      led_0,
    output                                      led_2,
    output                                      led_3,

`ifndef DEBUG
    output		[`SOFTMC_STREAM_WIDTH-1:0]		softmc_h2c_tdata,
    output		[`SOFTMC_STREAM_KEEP-1:0]		softmc_h2c_tkeep,
    output										softmc_h2c_tvalid,
    input										softmc_h2c_tready,
    output										softmc_h2c_tlast,

    input		[`SOFTMC_STREAM_WIDTH-1:0]      softmc_c2h_tdata,
    input		[`SOFTMC_STREAM_KEEP-1:0]      	softmc_c2h_tkeep,
    input										softmc_c2h_tvalid,
    output										softmc_c2h_tready,
    input										softmc_c2h_tlast,

    output										user_clk_o,
    output										user_reset_o,
`endif

    input                                       sys_clk_p,
    input                                       sys_clk_n,
    input                                       sys_rst_n
);

// Wire Declarations
    wire                                        pipe_mmcm_rst_n;

    wire                                        user_clk;
    wire                                        user_reset;
    wire                                        user_lnk_up;

    assign										user_clk_o = user_clk;
    assign										user_reset_o = user_reset;

    // Tx
    wire                                        s_axis_tx_tready;
    wire [3:0]                                  s_axis_tx_tuser;
    wire [C_DATA_WIDTH-1:0]                     s_axis_tx_tdata;
    wire [KEEP_WIDTH-1:0]                       s_axis_tx_tkeep;
    wire                                        s_axis_tx_tlast;
    wire                                        s_axis_tx_tvalid;

    // Rx
    wire [C_DATA_WIDTH-1:0]                     m_axis_rx_tdata;
    wire [KEEP_WIDTH-1:0]                       m_axis_rx_tkeep;
    wire                                        m_axis_rx_tlast;
    wire                                        m_axis_rx_tvalid;
    wire                                        m_axis_rx_tready;
    wire  [21:0]                                m_axis_rx_tuser;

    wire                                        tx_cfg_gnt;
    wire                                        rx_np_ok;
    wire                                        rx_np_req;
    wire                                        cfg_turnoff_ok;
    wire                                        cfg_trn_pending;
    wire                                        cfg_pm_halt_aspm_l0s;
    wire                                        cfg_pm_halt_aspm_l1;
    wire                                        cfg_pm_force_state_en;
    wire   [1:0]                                cfg_pm_force_state;
    wire                                        cfg_pm_wake;
    wire  [63:0]                                cfg_dsn;

    // Flow Control
    wire [2:0]                                  fc_sel;

    //-------------------------------------------------------
    // Configuration (CFG) Interface
    //-------------------------------------------------------
    wire                                        cfg_err_ecrc;
    wire                                        cfg_err_cor;
    wire                                        cfg_err_ur;
    wire                                        cfg_err_cpl_timeout;
    wire                                        cfg_err_cpl_abort;
    wire                                        cfg_err_cpl_unexpect;
    wire                                        cfg_err_posted;
    wire                                        cfg_err_locked;
    wire  [47:0]                                cfg_err_tlp_cpl_header;
    wire [127:0]                                cfg_err_aer_headerlog;
    wire   [4:0]                                cfg_aer_interrupt_msgnum;

    wire                                        cfg_interrupt;
    wire                                        cfg_interrupt_rdy;
    wire                                        cfg_interrupt_assert;
    wire   [7:0]                                cfg_interrupt_di;
    wire                                        cfg_interrupt_stat;
    wire   [4:0]                                cfg_pciecap_interrupt_msgnum;
    wire                                        cfg_interrupt_msienable;

    wire                                        cfg_to_turnoff;
    wire   [7:0]                                cfg_bus_number;
    wire   [4:0]                                cfg_device_number;
    wire   [2:0]                                cfg_function_number;

    wire  [31:0]                                cfg_mgmt_di;
    wire  [31:0]                                cfg_mgmt_do;
    wire   [3:0]                                cfg_mgmt_byte_en;
    wire   [9:0]                                cfg_mgmt_dwaddr;
    wire                                        cfg_mgmt_wr_en;
    wire                                        cfg_mgmt_rd_en;
    wire                                        cfg_mgmt_rd_wr_done;
    wire                                        cfg_mgmt_wr_readonly;

    wire  [15:0]                                cfg_dcommand;
    wire  [15:0]                                cfg_command;

    //-------------------------------------------------------
    // Physical Layer Control and Status (PL) Interface
    //-------------------------------------------------------
    wire                                        pl_directed_link_auton;
    wire [1:0]                                  pl_directed_link_change;
    wire                                        pl_directed_link_speed;
    wire [1:0]                                  pl_directed_link_width;
    wire                                        pl_upstream_prefer_deemph;

    wire                                        sys_rst_n_c;


// Register Declaration
    reg                                         user_reset_q;
    reg                                         user_lnk_up_q;
    reg    [25:0]                               user_clk_heartbeat = 'h0;

// Local Parameters
    localparam TCQ               = 1;
    localparam USER_CLK_FREQ     = 3;
    localparam USER_CLK2_DIV2    = "FALSE";
    localparam USERCLK2_FREQ     = (USER_CLK2_DIV2 == "TRUE") ? (USER_CLK_FREQ == 4) ? 3 : (USER_CLK_FREQ == 3) ? 2 : USER_CLK_FREQ: USER_CLK_FREQ;


 //-----------------------------I/O BUFFERS------------------------//

    IBUF   sys_reset_n_ibuf (.O(sys_rst_n_c), .I(sys_rst_n));

    IBUFDS_GTE2 refclk_ibuf (.O(sys_clk), .ODIV2(), .I(sys_clk_p), .CEB(1'b0), .IB(sys_clk_n));

    OBUF   led_0_obuf (.O(led_0), .I(!user_reset));
    OBUF   led_2_obuf (.O(led_2), .I(user_lnk_up));
    OBUF   led_3_obuf (.O(led_3), .I(user_clk_heartbeat[25]));

    always @(posedge user_clk) begin
        user_reset_q  <= user_reset;
        user_lnk_up_q <= user_lnk_up;
    end

    // Create a Clock Heartbeat on LED #3
    always @(posedge user_clk) begin
            user_clk_heartbeat <= #TCQ user_clk_heartbeat + 1'b1;
    end

    assign pipe_mmcm_rst_n                        = 1'b1;

`ifdef DEBUG
    localparam 							DATA_LIMIT = 'd1024;
    wire	[`SOFTMC_STREAM_WIDTH-1:0]	softmc_h2c_tdata;
    wire	[`SOFTMC_STREAM_KEEP-1:0]	softmc_h2c_tkeep;
    wire								softmc_h2c_tvalid;
    reg									softmc_h2c_tready;
    wire								softmc_h2c_tlast;
    
    reg		[`SOFTMC_STREAM_WIDTH-1:0]  softmc_c2h_tdata;
    reg		[`SOFTMC_STREAM_KEEP-1:0]   softmc_c2h_tkeep;
    reg									softmc_c2h_tvalid;
    wire								softmc_c2h_tready;
    reg									softmc_c2h_tlast;

    reg		[15:0]						data_count;
    reg		[7:0]						data_base;

    integer data_loop_i;
    always @(posedge user_clk) begin
        if (user_reset_q) begin
            softmc_c2h_tdata <= 0;
            softmc_c2h_tkeep <= 0;
            softmc_c2h_tvalid <= 0;
            softmc_c2h_tlast <= 0;
            softmc_h2c_tready <= 0;
            data_count <= 0;
            data_base <= 0;
        end
        else begin
            softmc_c2h_tkeep <= {`SOFTMC_STREAM_KEEP{1'b1}};
            softmc_c2h_tlast <= data_count == (DATA_LIMIT - 1);
            softmc_h2c_tready <= 1;
            if (softmc_c2h_tready && softmc_c2h_tvalid) begin
                for (data_loop_i = 0; data_loop_i < `SOFTMC_STREAM_KEEP; data_loop_i = data_loop_i + 1) begin
                    softmc_c2h_tdata[(`SOFTMC_STREAM_KEEP - data_loop_i - 1) * 8 +: 8] <= (data_base + `SOFTMC_STREAM_KEEP) + data_loop_i;
                end
                softmc_c2h_tvalid <= data_count < (DATA_LIMIT - 1);
                data_count <= data_count + (`SOFTMC_STREAM_WIDTH / 32);	// each data is 32 bits long
                data_base <= data_base + `SOFTMC_STREAM_KEEP;
            end
            else begin
                for (data_loop_i = 0; data_loop_i < `SOFTMC_STREAM_KEEP; data_loop_i = data_loop_i + 1) begin
                    softmc_c2h_tdata[(`SOFTMC_STREAM_KEEP - data_loop_i - 1) * 8 +: 8] <= data_base + data_loop_i;
                end
                softmc_c2h_tvalid <= data_count < DATA_LIMIT;
            end
        end
    end
`endif 

zc706_pcie_x4_gen2_support #
     (	 
        .LINK_CAP_MAX_LINK_WIDTH        ( 4 ),  // PCIe Lane Width
        .C_DATA_WIDTH                   ( C_DATA_WIDTH ),                       // RX/TX interface data width
        .KEEP_WIDTH                     ( KEEP_WIDTH ),                         // TSTRB width
        .PCIE_REFCLK_FREQ               ( REF_CLK_FREQ ),                       // PCIe reference clock frequency
        .PCIE_USERCLK1_FREQ             ( USER_CLK_FREQ +1 ),                   // PCIe user clock 1 frequency
        .PCIE_USERCLK2_FREQ             ( USERCLK2_FREQ +1 ),                   // PCIe user clock 2 frequency             
        .PCIE_USE_MODE                  ("3.0"),           // PCIe use mode
        .PCIE_GT_DEVICE                 ("GTX")              // PCIe GT device
     ) 
zc706_pcie_x4_gen2_support_i
    (

    //----------------------------------------------------------------------------------------------------------------//
    // PCI Express (pci_exp) Interface                                                                                //
    //----------------------------------------------------------------------------------------------------------------//
    // Tx
    .pci_exp_txn                               ( pci_exp_txn ),
    .pci_exp_txp                               ( pci_exp_txp ),

    // Rx
    .pci_exp_rxn                               ( pci_exp_rxn ),
    .pci_exp_rxp                               ( pci_exp_rxp ),

    //----------------------------------------------------------------------------------------------------------------//
    // Clocking Sharing Interface                                                                                     //
    //----------------------------------------------------------------------------------------------------------------//
    .pipe_pclk_out_slave                        ( ),
    .pipe_rxusrclk_out                          ( ),
    .pipe_rxoutclk_out                          ( ),
    .pipe_dclk_out                              ( ),
    .pipe_userclk1_out                          ( ),
    .pipe_oobclk_out                            ( ),
    .pipe_userclk2_out                          ( ),
    .pipe_mmcm_lock_out                         ( ),
    .pipe_pclk_sel_slave                        ( 4'b0),
    .pipe_mmcm_rst_n                            ( pipe_mmcm_rst_n ),        // Async      | Async


    //----------------------------------------------------------------------------------------------------------------//
    // AXI-S Interface                                                                                                //
    //----------------------------------------------------------------------------------------------------------------//

    // Common
    .user_clk_out                              ( user_clk ),
    .user_reset_out                            ( user_reset ),
    .user_lnk_up                               ( user_lnk_up ),
    .user_app_rdy                              ( ),

    // TX
    .s_axis_tx_tready                          ( s_axis_tx_tready ),
    .s_axis_tx_tdata                           ( s_axis_tx_tdata ),
    .s_axis_tx_tkeep                           ( s_axis_tx_tkeep ),
    .s_axis_tx_tuser                           ( s_axis_tx_tuser ),
    .s_axis_tx_tlast                           ( s_axis_tx_tlast ),
    .s_axis_tx_tvalid                          ( s_axis_tx_tvalid ),

    // Rx
    .m_axis_rx_tdata                           ( m_axis_rx_tdata ),
    .m_axis_rx_tkeep                           ( m_axis_rx_tkeep ),
    .m_axis_rx_tlast                           ( m_axis_rx_tlast ),
    .m_axis_rx_tvalid                          ( m_axis_rx_tvalid ),
    .m_axis_rx_tready                          ( m_axis_rx_tready ),
    .m_axis_rx_tuser                           ( m_axis_rx_tuser ),

    // Flow Control
    .fc_cpld                                   ( ),
    .fc_cplh                                   ( ),
    .fc_npd                                    ( ),
    .fc_nph                                    ( ),
    .fc_pd                                     ( ),
    .fc_ph                                     ( ),
    .fc_sel                                    ( fc_sel ),

    // Management Interface
    .cfg_mgmt_di                               ( cfg_mgmt_di ),
    .cfg_mgmt_byte_en                          ( cfg_mgmt_byte_en ),
    .cfg_mgmt_dwaddr                           ( cfg_mgmt_dwaddr ),
    .cfg_mgmt_wr_en                            ( cfg_mgmt_wr_en ),
    .cfg_mgmt_rd_en                            ( cfg_mgmt_rd_en ),
    .cfg_mgmt_wr_readonly                      ( cfg_mgmt_wr_readonly ),

    //------------------------------------------------//
    // EP and RP                                      //
    //------------------------------------------------//
    .cfg_mgmt_do                               ( cfg_mgmt_do ),
    .cfg_mgmt_rd_wr_done                       ( cfg_mgmt_rd_wr_done ),
    .cfg_mgmt_wr_rw1c_as_rw                    ( 1'b0 ),

    // Error Reporting Interface
    .cfg_err_ecrc                              ( cfg_err_ecrc ),
    .cfg_err_ur                                ( cfg_err_ur ),
    .cfg_err_cpl_timeout                       ( cfg_err_cpl_timeout ),
    .cfg_err_cpl_unexpect                      ( cfg_err_cpl_unexpect ),
    .cfg_err_cpl_abort                         ( cfg_err_cpl_abort ),
    .cfg_err_posted                            ( cfg_err_posted ),
    .cfg_err_cor                               ( cfg_err_cor ),
    .cfg_err_atomic_egress_blocked             ( cfg_err_atomic_egress_blocked ),
    .cfg_err_internal_cor                      ( cfg_err_internal_cor ),
    .cfg_err_malformed                         ( cfg_err_malformed ),
    .cfg_err_mc_blocked                        ( cfg_err_mc_blocked ),
    .cfg_err_poisoned                          ( cfg_err_poisoned ),
    .cfg_err_norecovery                        ( cfg_err_norecovery ),
    .cfg_err_tlp_cpl_header                    ( cfg_err_tlp_cpl_header ),
    .cfg_err_cpl_rdy                           ( ),
    .cfg_err_locked                            ( cfg_err_locked ),
    .cfg_err_acs                               ( cfg_err_acs ),
    .cfg_err_internal_uncor                    ( cfg_err_internal_uncor ),

    //----------------------------------------------------------------------------------------------------------------//
    // AER Interface                                                                                                  //
    //----------------------------------------------------------------------------------------------------------------//
    .cfg_err_aer_headerlog                     ( cfg_err_aer_headerlog ),
    .cfg_err_aer_headerlog_set                 ( ),
    .cfg_aer_ecrc_check_en                     ( ),
    .cfg_aer_ecrc_gen_en                       ( ),
    .cfg_aer_interrupt_msgnum                  ( cfg_aer_interrupt_msgnum ),

    .tx_cfg_gnt                                ( tx_cfg_gnt ),
    .rx_np_ok                                  ( rx_np_ok ),
    .rx_np_req                                 ( rx_np_req ),
    .cfg_trn_pending                           ( cfg_trn_pending ),
    .cfg_pm_halt_aspm_l0s                      ( cfg_pm_halt_aspm_l0s ),
    .cfg_pm_halt_aspm_l1                       ( cfg_pm_halt_aspm_l1 ),
    .cfg_pm_force_state_en                     ( cfg_pm_force_state_en ),
    .cfg_pm_force_state                        ( cfg_pm_force_state ),
    .cfg_dsn                                   ( cfg_dsn ),
    .cfg_turnoff_ok                            ( cfg_turnoff_ok ),
    .cfg_pm_wake                               ( cfg_pm_wake ),
    //------------------------------------------------//
    // RP Only                                        //
    //------------------------------------------------//
    .cfg_pm_send_pme_to                        ( 1'b0 ),
    .cfg_ds_bus_number                         ( 8'b0 ),
    .cfg_ds_device_number                      ( 5'b0 ),
    .cfg_ds_function_number                    ( 3'b0 ),

    //------------------------------------------------//
    // EP Only                                        //
    //------------------------------------------------//
    .cfg_interrupt                             ( cfg_interrupt ),
    .cfg_interrupt_rdy                         ( cfg_interrupt_rdy ),
    .cfg_interrupt_assert                      ( cfg_interrupt_assert ),
    .cfg_interrupt_di                          ( cfg_interrupt_di ),
    .cfg_interrupt_do                          ( ),
    .cfg_interrupt_mmenable                    ( ),
    .cfg_interrupt_msienable                   ( cfg_interrupt_msienable ),
    .cfg_interrupt_msixenable                  ( ),
    .cfg_interrupt_msixfm                      ( ),
    .cfg_interrupt_stat                        ( cfg_interrupt_stat ),
    .cfg_pciecap_interrupt_msgnum              ( cfg_pciecap_interrupt_msgnum ),

    //----------------------------------------------------------------------------------------------------------------//
    // Configuration (CFG) Interface                                                                                  //
    //----------------------------------------------------------------------------------------------------------------//
    .cfg_status                                ( ),
    .cfg_command                               ( cfg_command ),
    .cfg_dstatus                               ( ),
    .cfg_lstatus                               ( ),
    .cfg_pcie_link_state                       ( ),
    .cfg_dcommand                              ( cfg_dcommand ),
    .cfg_lcommand                              ( ),
    .cfg_dcommand2                             ( ),

    .cfg_pmcsr_pme_en                          ( ),
    .cfg_pmcsr_powerstate                      ( ),
    .cfg_pmcsr_pme_status                      ( ),
    .cfg_received_func_lvl_rst                 ( ),
    .tx_buf_av                                 ( ),
    .tx_err_drop                               ( ),
    .tx_cfg_req                                ( ),
    .cfg_to_turnoff                            ( cfg_to_turnoff ),
    .cfg_bus_number                            ( cfg_bus_number ),
    .cfg_device_number                         ( cfg_device_number ),
    .cfg_function_number                       ( cfg_function_number ),
    .cfg_bridge_serr_en                        ( ),
    .cfg_slot_control_electromech_il_ctl_pulse ( ),
    .cfg_root_control_syserr_corr_err_en       ( ),
    .cfg_root_control_syserr_non_fatal_err_en  ( ),
    .cfg_root_control_syserr_fatal_err_en      ( ),
    .cfg_root_control_pme_int_en               ( ),
    .cfg_aer_rooterr_corr_err_reporting_en     ( ),
    .cfg_aer_rooterr_non_fatal_err_reporting_en( ),
    .cfg_aer_rooterr_fatal_err_reporting_en    ( ),
    .cfg_aer_rooterr_corr_err_received         ( ),
    .cfg_aer_rooterr_non_fatal_err_received    ( ),
    .cfg_aer_rooterr_fatal_err_received        ( ),
    //----------------------------------------------------------------------------------------------------------------//
    // VC interface                                                                                                  //
    //---------------------------------------------------------------------------------------------------------------//
    .cfg_vc_tcvc_map                           ( ),

    .cfg_msg_received                          ( ),
    .cfg_msg_data                              ( ),
    .cfg_msg_received_err_cor                  ( ),
    .cfg_msg_received_err_non_fatal            ( ),
    .cfg_msg_received_err_fatal                ( ),
    .cfg_msg_received_pm_as_nak                ( ),
    .cfg_msg_received_pme_to_ack               ( ),
    .cfg_msg_received_assert_int_a             ( ),
    .cfg_msg_received_assert_int_b             ( ),
    .cfg_msg_received_assert_int_c             ( ),
    .cfg_msg_received_assert_int_d             ( ),
    .cfg_msg_received_deassert_int_a           ( ),
    .cfg_msg_received_deassert_int_b           ( ),
    .cfg_msg_received_deassert_int_c           ( ),
    .cfg_msg_received_deassert_int_d           ( ),
    .cfg_msg_received_pm_pme                  ( ),
    .cfg_msg_received_setslotpowerlimit       ( ),

    //----------------------------------------------------------------------------------------------------------------//
    // Physical Layer Control and Status (PL) Interface                                                               //
    //----------------------------------------------------------------------------------------------------------------//
    .pl_directed_link_change                   ( pl_directed_link_change ),
    .pl_directed_link_width                    ( pl_directed_link_width ),
    .pl_directed_link_speed                    ( pl_directed_link_speed ),
    .pl_directed_link_auton                    ( pl_directed_link_auton ),
    .pl_upstream_prefer_deemph                 ( pl_upstream_prefer_deemph ),

    .pl_sel_lnk_rate                           ( ),
    .pl_sel_lnk_width                          ( ),
    .pl_ltssm_state                            ( ),
    .pl_lane_reversal_mode                     ( ),

    .pl_phy_lnk_up                             ( ),
    .pl_tx_pm_state                            ( ),
    .pl_rx_pm_state                            ( ),

    .pl_link_upcfg_cap                         ( ),
    .pl_link_gen2_cap                          ( ),
    .pl_link_partner_gen2_supported            ( ),
    .pl_initial_link_width                     ( ),

    .pl_directed_change_done                   ( ),

    //------------------------------------------------//
    // EP Only                                        //
    //------------------------------------------------//
    .pl_received_hot_rst                       ( ),

    //------------------------------------------------//
    // RP Only                                        //
    //------------------------------------------------//
    .pl_transmit_hot_rst                       ( 1'b0 ),
    .pl_downstream_deemph_source               ( 1'b0 ),

    //----------------------------------------------------------------------------------------------------------------//
    // PCIe DRP (PCIe DRP) Interface                                                                                  //
    //----------------------------------------------------------------------------------------------------------------//
    .pcie_drp_clk                               ( 1'b1 ),
    .pcie_drp_en                                ( 1'b0 ),
    .pcie_drp_we                                ( 1'b0 ),
    .pcie_drp_addr                              ( 9'h0 ),
    .pcie_drp_di                                ( 16'h0 ),
    .pcie_drp_rdy                               ( ),
    .pcie_drp_do                                ( ),



    //----------------------------------------------------------------------------------------------------------------//
    // System  (SYS) Interface                                                                                        //
    //----------------------------------------------------------------------------------------------------------------//
    .sys_clk                                    ( sys_clk ),
    .sys_rst_n                                  ( sys_rst_n_c )

);

pcie_app_7x  #(
    .C_DATA_WIDTH( C_DATA_WIDTH )
) app (

    //----------------------------------------------------------------------------------------------------------------//
    // AXI-S Interface                                                                                                //
    //----------------------------------------------------------------------------------------------------------------//

    // Common
    .user_clk                       ( user_clk ),
    .user_reset                     ( user_reset_q ),
    .user_lnk_up                    ( user_lnk_up_q ),

    // Tx
    .s_axis_tx_tready               ( s_axis_tx_tready ),
    .s_axis_tx_tdata                ( s_axis_tx_tdata ),
    .s_axis_tx_tkeep                ( s_axis_tx_tkeep ),
    .s_axis_tx_tuser                ( s_axis_tx_tuser ),
    .s_axis_tx_tlast                ( s_axis_tx_tlast ),
    .s_axis_tx_tvalid               ( s_axis_tx_tvalid ),

    // Rx
    .m_axis_rx_tdata                ( m_axis_rx_tdata ),
    .m_axis_rx_tkeep                ( m_axis_rx_tkeep ),
    .m_axis_rx_tlast                ( m_axis_rx_tlast ),
    .m_axis_rx_tvalid               ( m_axis_rx_tvalid ),
    .m_axis_rx_tready               ( m_axis_rx_tready ),
    .m_axis_rx_tuser                ( m_axis_rx_tuser ),

    .tx_cfg_gnt                     ( tx_cfg_gnt ),
    .rx_np_ok                       ( rx_np_ok ),
    .rx_np_req                      ( rx_np_req ),
    .cfg_turnoff_ok                 ( cfg_turnoff_ok ),
    .cfg_trn_pending                ( cfg_trn_pending ),
    .cfg_pm_halt_aspm_l0s           ( cfg_pm_halt_aspm_l0s ),
    .cfg_pm_halt_aspm_l1            ( cfg_pm_halt_aspm_l1 ),
    .cfg_pm_force_state_en          ( cfg_pm_force_state_en ),
    .cfg_pm_force_state             ( cfg_pm_force_state ),
    .cfg_pm_wake                    ( cfg_pm_wake ),
    .cfg_dsn                        ( cfg_dsn ),
    .cfg_dcommand                   ( cfg_dcommand ),
    .cfg_command                    ( cfg_command ),

    // Flow Control
    .fc_sel                         ( fc_sel ),

    //----------------------------------------------------------------------------------------------------------------//
    // Configuration (CFG) Interface                                                                                  //
    //----------------------------------------------------------------------------------------------------------------//
    .cfg_err_cor                    ( cfg_err_cor ),
    .cfg_err_atomic_egress_blocked  ( cfg_err_atomic_egress_blocked ),
    .cfg_err_internal_cor           ( cfg_err_internal_cor ),
    .cfg_err_malformed              ( cfg_err_malformed ),
    .cfg_err_mc_blocked             ( cfg_err_mc_blocked ),
    .cfg_err_poisoned               ( cfg_err_poisoned ),
    .cfg_err_norecovery             ( cfg_err_norecovery ),
    .cfg_err_ur                     ( cfg_err_ur ),
    .cfg_err_ecrc                   ( cfg_err_ecrc ),
    .cfg_err_cpl_timeout            ( cfg_err_cpl_timeout ),
    .cfg_err_cpl_abort              ( cfg_err_cpl_abort ),
    .cfg_err_cpl_unexpect           ( cfg_err_cpl_unexpect ),
    .cfg_err_posted                 ( cfg_err_posted ),
    .cfg_err_locked                 ( cfg_err_locked ),
    .cfg_err_acs                    ( cfg_err_acs ), //1'b0 ),
    .cfg_err_internal_uncor         ( cfg_err_internal_uncor ), //1'b0 ),
    .cfg_err_tlp_cpl_header         ( cfg_err_tlp_cpl_header ),
    //----------------------------------------------------------------------------------------------------------------//
    // Advanced Error Reporting (AER) Interface                                                                       //
    //----------------------------------------------------------------------------------------------------------------//
    .cfg_err_aer_headerlog          ( cfg_err_aer_headerlog ),
    .cfg_aer_interrupt_msgnum       ( cfg_aer_interrupt_msgnum ),

    .cfg_to_turnoff                 ( cfg_to_turnoff ),
    .cfg_bus_number                 ( cfg_bus_number ),
    .cfg_device_number              ( cfg_device_number ),
    .cfg_function_number            ( cfg_function_number ),

    //----------------------------------------------------------------------------------------------------------------//
    // Management (MGMT) Interface                                                                                    //
    //----------------------------------------------------------------------------------------------------------------//
    .cfg_mgmt_di                    ( cfg_mgmt_di ),
    .cfg_mgmt_do                    ( cfg_mgmt_do ),
    .cfg_mgmt_byte_en               ( cfg_mgmt_byte_en ),
    .cfg_mgmt_dwaddr                ( cfg_mgmt_dwaddr ),
    .cfg_mgmt_wr_en                 ( cfg_mgmt_wr_en ),
    .cfg_mgmt_rd_en                 ( cfg_mgmt_rd_en ),
    .cfg_mgmt_wr_readonly           ( cfg_mgmt_wr_readonly ),
    .cfg_mgmt_rd_wr_done            ( cfg_mgmt_rd_wr_done ),

    //----------------------------------------------------------------------------------------------------------------//
    // Physical Layer Control and Status (PL) Interface                                                               //
    //----------------------------------------------------------------------------------------------------------------//
    .pl_directed_link_auton         ( pl_directed_link_auton ),
    .pl_directed_link_change        ( pl_directed_link_change ),
    .pl_directed_link_speed         ( pl_directed_link_speed ),
    .pl_directed_link_width         ( pl_directed_link_width ),
    .pl_upstream_prefer_deemph      ( pl_upstream_prefer_deemph ),

    .cfg_interrupt                  ( cfg_interrupt ),
    .cfg_interrupt_rdy              ( cfg_interrupt_rdy ),
    .cfg_interrupt_assert           ( cfg_interrupt_assert ),
    .cfg_interrupt_di               ( cfg_interrupt_di ),
    .cfg_interrupt_stat             ( cfg_interrupt_stat ),
    .cfg_pciecap_interrupt_msgnum   ( cfg_pciecap_interrupt_msgnum ),
    .cfg_interrupt_msienable        ( cfg_interrupt_msienable ),

    //--------------------------------------------------------------------------------------------------------------//
    // Streaming Data Transfer Interface																			//
    //--------------------------------------------------------------------------------------------------------------//
    .softmc_h2c_tdata				( softmc_h2c_tdata ),
    .softmc_h2c_tkeep				( softmc_h2c_tkeep ),
    .softmc_h2c_tvalid				( softmc_h2c_tvalid ),
    .softmc_h2c_tready				( softmc_h2c_tready ),
    .softmc_h2c_tlast				( softmc_h2c_tlast ),

    .softmc_c2h_tdata				( softmc_c2h_tdata ),
    .softmc_c2h_tkeep				( softmc_c2h_tkeep ),
    .softmc_c2h_tvalid				( softmc_c2h_tvalid ),
    .softmc_c2h_tready				( softmc_c2h_tready ),
    .softmc_c2h_tlast				( softmc_c2h_tlast )
);

`ifdef ILA_CORES
    ila_ms debug_maxis (
        .clk ( user_clk ),
        .probe0 ( m_axis_rx_tdata ),
        .probe1 ( m_axis_rx_tkeep ),
        .probe2 ( m_axis_rx_tvalid ),
        .probe3 ( m_axis_rx_tready ),
        .probe4 ( m_axis_rx_tlast )
    );

    ila_ms debug_saxis (
        .clk ( user_clk ),
        .probe0 ( s_axis_tx_tdata ),
        .probe1 ( s_axis_tx_tkeep ),
        .probe2 ( s_axis_tx_tvalid ),
        .probe3 ( s_axis_tx_tready ),
        .probe4 ( s_axis_tx_tlast )
    );

    ila_hc debug_c2h (
        .clk ( user_clk ),
        .probe0 ( softmc_c2h_tdata ),
        .probe1 ( softmc_c2h_tkeep ),
        .probe2 ( softmc_c2h_tvalid ),
        .probe3 ( softmc_c2h_tready ),
        .probe4 ( softmc_c2h_tlast )
    );

    ila_hc debug_h2c (
        .clk ( user_clk ),
        .probe0 ( softmc_h2c_tdata ),
        .probe1 ( softmc_h2c_tkeep ),
        .probe2 ( softmc_h2c_tvalid ),
        .probe3 ( softmc_h2c_tready ),
        .probe4 ( softmc_h2c_tlast )
    );
`endif

endmodule