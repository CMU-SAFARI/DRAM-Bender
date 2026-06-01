`timescale 1ps / 1ps

`include "project.vh"
`define PCI_EXP_EP_OUI                           24'h000A35
`define PCI_EXP_EP_DSN_1                         {{8'h1},`PCI_EXP_EP_OUI}
`define PCI_EXP_EP_DSN_2                         32'h00000001

module pcie_app_7x #(
    parameter C_DATA_WIDTH = 64,                        // RX/TX interface data width
    parameter KEEP_WIDTH = C_DATA_WIDTH / 8              // TSTRB width
)(
    input                                   user_clk,
    input                                   user_reset,
    input                                   user_lnk_up,

    // softmc <- host
	output	[`SOFTMC_STREAM_WIDTH-1:0]		softmc_h2c_tdata,
	output	[`SOFTMC_STREAM_KEEP-1:0]		softmc_h2c_tkeep,
	output									softmc_h2c_tvalid,
	input									softmc_h2c_tready,
	output									softmc_h2c_tlast,

    // softmc -> host
	input	[`SOFTMC_STREAM_WIDTH-1:0]      softmc_c2h_tdata,
	input	[`SOFTMC_STREAM_KEEP-1:0]      	softmc_c2h_tkeep,
	input									softmc_c2h_tvalid,
	output									softmc_c2h_tready,
	input									softmc_c2h_tlast,
    
    // Tx
    input                                   s_axis_tx_tready,
    output  [C_DATA_WIDTH-1:0]              s_axis_tx_tdata,
    output  [KEEP_WIDTH-1:0]                s_axis_tx_tkeep,
    output  [3:0]                           s_axis_tx_tuser,
    output                                  s_axis_tx_tlast,
    output                                  s_axis_tx_tvalid,

    // Rx           
    input   [C_DATA_WIDTH-1:0]              m_axis_rx_tdata,
    input   [KEEP_WIDTH-1:0]                m_axis_rx_tkeep,
    input                                   m_axis_rx_tlast,
    input                                   m_axis_rx_tvalid,
    output                                  m_axis_rx_tready,
    input   [21:0]                          m_axis_rx_tuser,

    input                                   cfg_to_turnoff,
    input   [7:0]                           cfg_bus_number,
    input   [4:0]                           cfg_device_number,
    input   [2:0]                           cfg_function_number,
    input   [15:0]                          cfg_dcommand,
    input   [15:0]                          cfg_command,

    output                                  tx_cfg_gnt,
    output                                  cfg_pm_halt_aspm_l0s,
    output                                  cfg_pm_halt_aspm_l1,
    output                                  cfg_pm_force_state_en,
    output  [1:0]                           cfg_pm_force_state,
    output                                  rx_np_ok,
    output                                  rx_np_req,
    output                                  cfg_turnoff_ok,
    output                                  cfg_trn_pending,
    output                                  cfg_pm_wake,
    output  [63:0]                          cfg_dsn,
    // Flow Control         
    output  [2:0]                           fc_sel,
    // CFG          
    output                                  cfg_err_cor,
    output                                  cfg_err_ur,
    output                                  cfg_err_ecrc,
    output                                  cfg_err_cpl_timeout,
    output                                  cfg_err_cpl_unexpect,
    output                                  cfg_err_cpl_abort,
    output                                  cfg_err_atomic_egress_blocked,
    output                                  cfg_err_internal_cor,
    output                                  cfg_err_malformed,
    output                                  cfg_err_mc_blocked,
    output                                  cfg_err_poisoned,
    output                                  cfg_err_norecovery,
    output                                  cfg_err_acs,
    output                                  cfg_err_internal_uncor,
    output                                  cfg_err_posted,
    output                                  cfg_err_locked,
    output  [47:0]                          cfg_err_tlp_cpl_header,
    output  [127:0]                         cfg_err_aer_headerlog,
    output  [4:0]                           cfg_aer_interrupt_msgnum,
    output  [1:0]                           pl_directed_link_change,
    output  [1:0]                           pl_directed_link_width,
    output                                  pl_directed_link_speed,
    output                                  pl_directed_link_auton,
    output                                  pl_upstream_prefer_deemph,
    input                                   cfg_mgmt_rd_wr_done,
    input   [31:0]                          cfg_mgmt_do,
    output  [31:0]                          cfg_mgmt_di,
    output  [3:0]                           cfg_mgmt_byte_en,
    output  [9:0]                           cfg_mgmt_dwaddr,
    output                                  cfg_mgmt_wr_en,
    output                                  cfg_mgmt_rd_en,
    output                                  cfg_mgmt_wr_readonly,
    input                                   cfg_interrupt_rdy,
    output                                  cfg_interrupt,
    output                                  cfg_interrupt_assert,
    output  [7:0]                           cfg_interrupt_di,
    output                                  cfg_interrupt_stat,
    input                                   cfg_interrupt_msienable,
    output  [4:0]                           cfg_pciecap_interrupt_msgnum
);

wire [15:0] cfg_completer_id;

assign fc_sel = 3'b0;
assign tx_cfg_gnt = 1'b1;                        // Always allow transmission of Config traffic within block
assign rx_np_ok = 1'b1;                          // Allow Reception of Non-posted Traffic
assign rx_np_req = 1'b1;                         // Always request Non-posted Traffic if available
assign cfg_pm_wake = 1'b0;                       // Never direct the core to send a PM_PME Message
assign cfg_trn_pending = 1'b0;                   // Never set the transaction pending bit in the Device Status Register
assign cfg_pm_halt_aspm_l0s = 1'b0;              // Allow entry into L0s
assign cfg_pm_halt_aspm_l1 = 1'b0;               // Allow entry into L1
assign cfg_pm_force_state_en  = 1'b0;            // Do not qualify cfg_pm_force_state
assign cfg_pm_force_state  = 2'b00;              // Do not move force core into specific PM state
assign cfg_dsn = {`PCI_EXP_EP_DSN_2, `PCI_EXP_EP_DSN_1};  // Assign the input DSN
assign s_axis_tx_tuser[0] = 1'b0;                // Unused for V6
assign s_axis_tx_tuser[1] = 1'b0;                // Error forward packet
assign s_axis_tx_tuser[2] = 1'b0;                // Stream packet
assign cfg_err_cor = 1'b0;                       // Never report Correctable Error
assign cfg_err_ur = 1'b0;                        // Never report UR
assign cfg_err_ecrc = 1'b0;                      // Never report ECRC Error
assign cfg_err_cpl_timeout = 1'b0;               // Never report Completion Timeout
assign cfg_err_cpl_abort = 1'b0;                 // Never report Completion Abort
assign cfg_err_cpl_unexpect = 1'b0;              // Never report unexpected completion
assign cfg_err_posted = 1'b0;                    // Never qualify cfg_err_* inputs
assign cfg_err_locked = 1'b0;                    // Never qualify cfg_err_ur or cfg_err_cpl_abort
assign cfg_err_atomic_egress_blocked = 1'b0;     // Never report Atomic TLP blocked
assign cfg_err_internal_cor = 1'b0;              // Never report internal error occurred
assign cfg_err_malformed = 1'b0;                 // Never report malformed error
assign cfg_err_mc_blocked = 1'b0;                // Never report multi-cast TLP blocked
assign cfg_err_poisoned = 1'b0;                  // Never report poisoned TLP received
assign cfg_err_norecovery = 1'b0;                // Never qualify cfg_err_poisoned or cfg_err_cpl_timeout
assign cfg_err_acs = 1'b0;                       // Never report an ACS violation
assign cfg_err_internal_uncor = 1'b0;            // Never report internal uncorrectable error
assign cfg_err_aer_headerlog = 128'h0;           // Zero out the AER Header Log
assign cfg_aer_interrupt_msgnum = 5'b00000;      // Zero out the AER Root Error Status Register
assign cfg_err_tlp_cpl_header = 48'h0;           // Zero out the header information

assign cfg_interrupt_stat = 1'b0;                // Never set the Interrupt Status bit
assign cfg_pciecap_interrupt_msgnum = 5'b00000;  // Zero out Interrupt Message Number

assign pl_directed_link_change = 2'b00;          // Never initiate link change
assign pl_directed_link_width = 2'b00;           // Zero out directed link width
assign pl_directed_link_speed = 1'b0;            // Zero out directed link speed
assign pl_directed_link_auton = 1'b0;            // Zero out link autonomous input
assign pl_upstream_prefer_deemph = 1'b1;         // Zero out preferred de-emphasis of upstream port

assign cfg_mgmt_di = 32'h0;                      // Zero out CFG MGMT input data bus
assign cfg_mgmt_byte_en = 4'h0;                  // Zero out CFG MGMT byte enables
assign cfg_mgmt_wr_en = 1'b0;                    // Do not write CFG space
assign cfg_mgmt_wr_readonly = 1'b0;              // Never treat RO bit as RW

assign cfg_completer_id = {cfg_bus_number, cfg_device_number, cfg_function_number};
assign softmc_h2c_tkeep = {`SOFTMC_STREAM_KEEP{1'b1}};

pcie_app_softmc  #(
    .C_DATA_WIDTH( C_DATA_WIDTH ),
    .KEEP_WIDTH( KEEP_WIDTH )
) softmc_app (
    .user_clk                   ( user_clk ),                   // I
    .user_reset                 ( user_reset ),                 // I
    .user_lnk_up                ( user_lnk_up ),                // I
	.softmc_h2c_tdata           ( softmc_h2c_tdata ),           // O
	.softmc_h2c_tvalid          ( softmc_h2c_tvalid ),          // O
	.softmc_h2c_tready          ( softmc_h2c_tready ),          // I
	.softmc_h2c_tlast           ( softmc_h2c_tlast ),           // O
	.softmc_c2h_tdata           ( softmc_c2h_tdata ),           // I
	.softmc_c2h_tvalid          ( softmc_c2h_tvalid ),          // I
	.softmc_c2h_tready          ( softmc_c2h_tready ),          // O
	.softmc_c2h_tlast           ( softmc_c2h_tlast ),           // I
    .cfg_bus_number             ( cfg_bus_number ),             // I
    .cfg_device_number          ( cfg_device_number ),          // I
    .cfg_function_number        ( cfg_function_number ),        // I
    .cfg_to_turnoff             ( cfg_to_turnoff ),             // I
    .cfg_completer_id           ( cfg_completer_id ),           // I
    .cfg_turnoff_ok             ( cfg_turnoff_ok ),             // O
    .cfg_dcommand               ( cfg_dcommand ),               // I 
    .cfg_command                ( cfg_command ),                // I 
    .cfg_interrupt              ( cfg_interrupt ),              // O
    .cfg_interrupt_assert       ( cfg_interrupt_assert ),       // O
    .cfg_interrupt_rdy          ( cfg_interrupt_rdy ),          // I    
    .cfg_interrupt_di           ( cfg_interrupt_di ),           // O    
    .cfg_interrupt_msienable    ( cfg_interrupt_msienable ),    // I
    .pci_cfg_dwaddr             ( cfg_mgmt_dwaddr ),            // O
    .pci_cfg_rd_en              ( cfg_mgmt_rd_en ),             // O
    .pci_cfg_dout               ( cfg_mgmt_do ),                // I
    .pci_cfg_rd_wr_done         ( cfg_mgmt_rd_wr_done ),        // I
    .s_axis_tx_tready           ( s_axis_tx_tready ),           // I
    .s_axis_tx_tdata            ( s_axis_tx_tdata ),            // O
    .s_axis_tx_tkeep            ( s_axis_tx_tkeep ),            // O
    .s_axis_tx_tlast            ( s_axis_tx_tlast ),            // O
    .s_axis_tx_tvalid           ( s_axis_tx_tvalid ),           // O
    .tx_src_dsc                 ( s_axis_tx_tuser[3] ),         // O
    .m_axis_rx_tdata            ( m_axis_rx_tdata ),            // I
    .m_axis_rx_tkeep            ( m_axis_rx_tkeep ),            // I
    .m_axis_rx_tlast            ( m_axis_rx_tlast ),            // I
    .m_axis_rx_tvalid           ( m_axis_rx_tvalid ),           // I
    .m_axis_rx_tready           ( m_axis_rx_tready ),           // O
    .m_axis_rx_tuser            ( m_axis_rx_tuser )             // I
);

endmodule
