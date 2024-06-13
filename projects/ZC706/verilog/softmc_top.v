`include "parameters.vh"
`include "project.vh"


module softmc_top #(parameter tCK = 1500, SIM = "false")
  (
`ifdef SIMULATION
  input clk,
  input rst,
`else
  // common signals
  input c0_sys_clk_p,
  input c0_sys_clk_n,
  input sys_rst,
`endif

  // iob <> ddr4 sdram ip signals
  output [13:0]      ddr3_addr,
  output [2:0]       ddr3_ba,
  output             ddr3_ras_n,
  output             ddr3_cas_n,
  output             ddr3_we_n,
  output [`CKE_WIDTH-1:0]       ddr3_cke,
  output [`ODT_WIDTH-1:0]       ddr3_odt,
  output [`CS_WIDTH-1:0]        ddr3_cs_n,
  output [`CK_WIDTH-1:0]       ddr3_ck_p,
  output [`CK_WIDTH-1:0]       ddr3_ck_n,
  output             ddr3_reset_n,

  inout  [7:0]       ddr3_dm,
  inout  [63:0]      ddr3_dq,
  inout  [7:0]       ddr3_dqs_p,
  inout  [7:0]       ddr3_dqs_n
  //output  init_calib_complete

`ifndef SIMULATION
  ,
  // xdma signals
  input clk_ref_p,
  input clk_ref_n,
  output  [3:0]    pci_exp_txp,
  output  [3:0]    pci_exp_txn,
  input   [3:0]    pci_exp_rxp,
  input   [3:0]    pci_exp_rxn,
  input pcie_rst_n
`endif
  );
    
  wire ui_rst_n;
  wire ui_clk, ui_rst;

`ifdef SIMULATION
  // Generate differantial clock from single edge input clock and assign resets.
  wire c0_sys_clk_p;
  wire c0_sys_clk_n;
  wire sys_rst;
  reg [6:0] sim_rst_r;

  assign c0_sys_clk_p = clk;
  assign c0_sys_clk_n = ~clk;
  assign sys_rst = rst;
  assign ui_rst = ~ui_rst_n || (|sim_rst_r);

  always @(posedge clk) begin
    if (rst) begin
      sim_rst_r <= 'hFFFFFFFF; 
    end
    else if (sim_rst_r > 0) begin
      sim_rst_r <= sim_rst_r - 1;
    end
  end
`else
  assign ui_rst = ~ui_rst_n;
`endif

    
  // Frontend control signals
  wire softmc_fin;
  wire user_rst;  
  
  // Frontend <-> Fetch signals
  wire [`IMEM_ADDR_WIDTH-1:0] fr_addr_in;
  wire                        fr_valid_in;
  wire [`INSTR_WIDTH-1:0]     fr_data_out;
  wire                        fr_valid_out;
  wire [`IMEM_ADDR_WIDTH-1:0] fr_addr_out;
  wire                        fr_ready_out;

  // Frontend <-> misc. control signals
  wire                        per_rd_init;
  wire                        per_zq_init;
  wire                        per_ref_init;
  wire                        rbe_switch_mode;
  wire                        toggle_dll;  

  // AXI streaming ports
  wire [`XDMA_AXI_DATA_WIDTH-1:0]   m_axis_h2c_tdata_0,xdma_h2c_tdata_0;
  wire                              m_axis_h2c_tlast_0, xdma_h2c_tlast_0;
  wire                              m_axis_h2c_tvalid_0, xdma_h2c_tvalid_0;
  wire                              m_axis_h2c_tready_0, xdma_h2c_tready_0;
  wire [`XDMA_AXI_DATA_WIDTH/8-1:0] m_axis_h2c_tkeep_0, xdma_h2c_tkeep_0;
  wire [`XDMA_AXI_DATA_WIDTH-1:0]   s_axis_c2h_tdata_0, xdma_c2h_tdata_0; 
  wire                              s_axis_c2h_tlast_0, xdma_c2h_tlast_0;
  wire                              s_axis_c2h_tvalid_0, xdma_c2h_tvalid_0;
  wire                              s_axis_c2h_tready_0, xdma_c2h_tready_0;
  wire [`XDMA_AXI_DATA_WIDTH/8-1:0] s_axis_c2h_tkeep_0, xdma_c2h_tkeep_0;
 
  // ddr_pipeline <-> outer module if
  wire [3:0]                ddr_write;
  wire [3:0]                ddr_read;
  wire [3:0]                ddr_pre;
  wire [3:0]                ddr_act;
  wire [3:0]                ddr_ref;
  wire [3:0]                ddr_sre;
  wire [3:0]                ddr_srx;
  wire [3:0]                ddr_zq;
  wire [3:0]                ddr_nop;
  wire [3:0]                ddr_ap;
  wire [3:0]                ddr_pall;
  wire [3:0]                ddr_half_bl;
  wire [4*`BG_WIDTH-1:0]    ddr_bg;
  wire [4*`BANK_WIDTH-1:0]  ddr_bank;
  wire [4*`COL_WIDTH-1:0]   ddr_col;
  wire [4*`ROW_WIDTH-1:0]   ddr_row;
  wire [511:0]              ddr_wdata;
 
  // periodic maintenance signals
  wire                      ddr_maint_read;
 

  // ddr adapter 
  // MC <-> PHY Interface
  wire [3:0]                mc_ras_n; // DDR Row access strobe
  wire [3:0]                mc_cas_n; // DDR Column access strobe
  wire [3:0]                mc_we_n;  // DDR Write enable
  wire [55:0]               mc_address; // row address for activates / column address for read&writes
  wire [11:0]               mc_bank; // bank address
  wire [3:0]                mc_cs_n; // chip select, probably used to deselect in NOP cycles
  wire                      mc_reset_n; // Have no idea, probably need to keep HIGH
  wire [1:0]                mc_odt; // Need some logic to drive this
  wire [3:0]                mc_cke; // This should be HIGH all the time
  wire [3:0]                mc_aux_out0; 
  wire [3:0]                mc_aux_out1;
  wire                      mc_cmd_wren;       // Enqueue new command
  wire                      mc_ctl_wren;       // Enqueue new control singal
  wire [2:0]                mc_cmd;            // The command to enqueue
  wire [1:0]                mc_cas_slot;       // Which CAS slot we issued this command from 0-2
  wire [5:0]                mc_data_offset;    
  wire [5:0]                mc_data_offset_1;
  wire [5:0]                mc_data_offset_2;
  wire [1:0]                mc_rank_cnt;
  // Write
  wire                      mc_wrdata_en;                // Asserted for DDR-WRITEs
  wire  [511:0]             mc_wrdata;
  wire  [63:0]              mc_wrdata_mask; // Should be 0xff if we don't want to mask out bits
  wire                      idle;
  wire                      phy_mc_ctl_full;     // CTL interface is full
  wire                      phy_mc_cmd_full;     // CMD interface is full
  wire                      phy_mc_data_full;    // ?????????
  (*dont_touch = "true"*) reg pmcctlf;
  (*dont_touch = "true"*) reg pmccmdf;
  (*dont_touch = "true"*) reg pmcdf;
  wire [5:0]                calib_rd_data_offset_0;
  wire [5:0]                calib_rd_data_offset_1;
  wire [5:0]                calib_rd_data_offset_2;
  wire                      phy_rddata_valid;    // Next cycle will have a valid read
  wire [511:0]              phy_rd_data;         
  
  wire         read_seq_incoming; // next few instructions will read from DRAM
  wire [11:0]  incoming_reads;    // how many reads next few instructions will issue
  wire [11:0]  buffer_space;      // remaining buffer size
 
  wire c0_init_calib_complete;
  
  // There is a possibility that these signals are on
  // the critical path as observed in 
  // the previous iteration of SoftMC
  reg c0_init_calib_complete_r, sys_rst_r;
  wire iq_full, processing_iseq, rdback_fifo_empty;
  
  //assign init_calib_complete = c0_init_calib_complete_r;
  
  always @(posedge ui_clk) begin
    c0_init_calib_complete_r <= c0_init_calib_complete;
    sys_rst_r <= sys_rst;  
  end

  memctl_mig phy_ddr3_i(
    // DDR Interface
    .ddr3_dq                       (ddr3_dq),
    .ddr3_dqs_n                    (ddr3_dqs_n),
    .ddr3_dqs_p                    (ddr3_dqs_p),
    .ddr3_addr                     (ddr3_addr),
    .ddr3_ba                       (ddr3_ba),
    .ddr3_ras_n                    (ddr3_ras_n),
    .ddr3_cas_n                    (ddr3_cas_n),
    .ddr3_we_n                     (ddr3_we_n),
    .ddr3_reset_n                  (ddr3_reset_n),
    .ddr3_ck_p                     (ddr3_ck_p),
    .ddr3_ck_n                     (ddr3_ck_n),
    .ddr3_cke                      (ddr3_cke),
    .ddr3_cs_n                     (ddr3_cs_n),
    .ddr3_dm                       (ddr3_dm),
    .ddr3_odt                      (ddr3_odt),

    // MC <-> PHY Interface
    .mc_ras_n                      (mc_ras_n),
    .mc_cas_n                      (mc_cas_n),
    .mc_we_n                       (mc_we_n),
    .mc_address                    (mc_address),
    .mc_bank                       (mc_bank),
    .mc_cs_n                       (mc_cs_n),
    .mc_reset_n                    (mc_reset_n),
    .mc_odt                        (mc_odt),
    .mc_cke                        (mc_cke),
    // AUX - For ODT and CKE assertion during reads and writes
    .mc_aux_out0                   (mc_aux_out0),
    .mc_aux_out1                   (mc_aux_out1),
    .mc_cmd_wren                   (mc_cmd_wren),
    .mc_ctl_wren                   (mc_ctl_wren),
    .mc_cmd                        (mc_cmd),
    .mc_cas_slot                   (mc_cas_slot),
    .mc_data_offset                (mc_data_offset),
    .mc_data_offset_1              (mc_data_offset_1),
    .mc_data_offset_2              (mc_data_offset_2),
    .mc_rank_cnt                   (mc_rank_cnt),
    
    .mc_wrdata_en                  (mc_wrdata_en),
    .mc_wrdata                     (mc_wrdata),
    .mc_wrdata_mask                (mc_wrdata_mask),
    .idle                          (idle),
    .phy_mc_ctl_full               (phy_mc_ctl_full),
    .phy_mc_cmd_full               (phy_mc_cmd_full),
    .phy_mc_data_full              (phy_mc_data_full),
    .calib_rd_data_offset_0        (calib_rd_data_offset_0),
    .calib_rd_data_offset_1        (calib_rd_data_offset_1),
    .calib_rd_data_offset_2        (calib_rd_data_offset_2),
    .phy_rddata_valid              (phy_rddata_valid),
    .phy_rd_data                   (phy_rd_data),
    
    
    .sys_clk_p                     (c0_sys_clk_p),
    .sys_clk_n                     (c0_sys_clk_n),
    
    .ui_clk                        (ui_clk),
    .ui_clk_sync_rst               (ui_rst_n),
                                  
    .init_calib_complete           (c0_init_calib_complete),
    
    // System reset - Default polarity of sys_rst pin is Active Low.
    // System reset polarity will change based on the option 
    // selected in GUI.
    .sys_rst                       (sys_rst)                                   
  );
    
  softmc_pipeline pipeline(
    .clk(ui_clk),
    .rst(ui_rst || user_rst),
   
    .softmc_end(softmc_fin),
    .read_size(incoming_reads),
    .read_seq_incoming(read_seq_incoming),
    .buffer_space(buffer_space),
    
    .addr_out(fr_addr_in),
    .valid_out(fr_valid_in),
    .data_in(fr_data_out),
    .valid_in(fr_valid_out),
    .addr_in(fr_addr_out),
    .ready_out(fr_ready_out),
   
    .ddr_write(ddr_write),  
    .ddr_read(ddr_read),  
    .ddr_pre(ddr_pre),    
    .ddr_act(ddr_act),    
    .ddr_ref(ddr_ref),    
    .ddr_sre(ddr_sre),    
    .ddr_srx(ddr_srx),    
    .ddr_zq(ddr_zq),    
    .ddr_nop(ddr_nop),    
    .ddr_ap(ddr_ap),    
    .ddr_pall(ddr_pall),    
    .ddr_half_bl(ddr_half_bl),
    .ddr_bg(ddr_bg),    
    .ddr_bank(ddr_bank),  
    .ddr_col(ddr_col),    
    .ddr_row(ddr_row),    
    .ddr_wdata(ddr_wdata)
  ); 
 
  wire frontend_ready;
  
  frontend #(.SIM_MEM(SIM)) frontend(
    .clk(ui_clk),
    .rst(ui_rst),
    
    .init_calib_complete(c0_init_calib_complete_r),
    .softmc_fin(softmc_fin),
    .user_rst(user_rst),
   
    .dllt_begin(toggle_dll),
   
    // indicates read_back unit is ready for the next iseq
    .frontend_ready(frontend_ready),
       
    // frontend <-> fetch stage if
    .addr_in(fr_addr_in),
    .valid_in(fr_valid_in),
    .data_out(fr_data_out),
    .valid_out(fr_valid_out),
    .addr_out(fr_addr_out),
    .ready_in(fr_ready_out),
    
    // frontend <-> xdma interface
    .h2c_tdata_0(m_axis_h2c_tdata_0),
    .h2c_tlast_0(m_axis_h2c_tlast_0),
    .h2c_tvalid_0(m_axis_h2c_tvalid_0),
    .h2c_tready_0(m_axis_h2c_tready_0),
    .h2c_tkeep_0(m_axis_h2c_tkeep_0),
    
    .per_rd_init(per_rd_init),
    .per_zq_init(per_zq_init),
    .per_ref_init(per_ref_init),
    .rbe_switch_mode(rbe_switch_mode)
  );

  ddr3_adapter ddr3_adapter
  (
  .clk(ui_clk),
  .rst(ui_rst || user_rst),
  .init_calib_complete(c0_init_calib_complete_r),
   //.io_config_strobe,
   //.io_config,
  // MC <-> PHY Interface
  .mc_ras_n                      (mc_ras_n),
  .mc_cas_n                      (mc_cas_n),
  .mc_we_n                       (mc_we_n),
  .mc_address                    (mc_address),
  .mc_bank                       (mc_bank),
  .mc_cs_n                       (mc_cs_n),
  .mc_reset_n                    (mc_reset_n),
  .mc_odt                        (mc_odt),
  .mc_cke                        (mc_cke),
  // AUX - For ODT and CKE assertion during reads and writes
  .mc_aux_out0                   (mc_aux_out0),
  .mc_aux_out1                   (mc_aux_out1),
  .mc_cmd_wren                   (mc_cmd_wren),
  .mc_ctl_wren                   (mc_ctl_wren),
  .mc_cmd                        (mc_cmd),
  .mc_cas_slot                   (mc_cas_slot),
  .mc_data_offset                (mc_data_offset),
  .mc_data_offset_1              (mc_data_offset_1),
  .mc_data_offset_2              (mc_data_offset_2),
  .mc_rank_cnt                   (mc_rank_cnt),
  
  .mc_wrdata_en                  (mc_wrdata_en),
  .mc_wrdata                     (mc_wrdata),
  .mc_wrdata_mask                (mc_wrdata_mask),
  .idle                          (idle),
  .phy_mc_ctl_full               (phy_mc_ctl_full),
  .phy_mc_cmd_full               (phy_mc_cmd_full),
  .phy_mc_data_full              (phy_mc_data_full),
  .calib_rd_data_offset_0        (calib_rd_data_offset_0),
  .calib_rd_data_offset_1        (calib_rd_data_offset_1),
  .calib_rd_data_offset_2        (calib_rd_data_offset_2),
  
  .ddr_write(ddr_write),  
  .ddr_read(ddr_read),  
  .ddr_pre(ddr_pre),    
  .ddr_act(ddr_act),    
  .ddr_ref(ddr_ref),    
  .ddr_zq(ddr_zq),    
  .ddr_nop(ddr_nop),    
  .ddr_ap(ddr_ap),    
  .ddr_pall(ddr_pall),    
  .ddr_half_bl(ddr_half_bl),
  .ddr_bg(ddr_bg),    
  .ddr_bank(ddr_bank),  
  .ddr_col(ddr_col),    
  .ddr_row(ddr_row),    
  .ddr_wdata(ddr_wdata),
  
  .ddr_maint_read(per_rd_init)
  );
  
`ifndef SIMULATION
  wire sys_clk, sys_clk_gt;
  wire [2:0]    msi_vector_width;
  wire          msi_enable;
  wire          user_lnk_up, usr_irq_req, usr_irq_ack;
  wire pci_user_clk, pci_user_reset;

  pcie_top zc706_pcie (
    .pci_exp_txn     ( pci_exp_txn ),
    .pci_exp_txp     ( pci_exp_txp ),
    .pci_exp_rxn     ( pci_exp_rxn ),
    .pci_exp_rxp     ( pci_exp_rxp ),

    .sys_rst_n        ( pcie_rst_n ),

    .sys_clk_p          ( clk_ref_p ),
    .sys_clk_n          ( clk_ref_n ),

    .softmc_c2h_tdata(xdma_c2h_tdata_0),  
    .softmc_c2h_tlast(xdma_c2h_tlast_0),
    .softmc_c2h_tvalid(xdma_c2h_tvalid_0), 
    .softmc_c2h_tready(xdma_c2h_tready_0),
    .softmc_c2h_tkeep(xdma_c2h_tkeep_0),
    
    .softmc_h2c_tdata(xdma_h2c_tdata_0),
    .softmc_h2c_tlast(xdma_h2c_tlast_0),
    .softmc_h2c_tvalid(xdma_h2c_tvalid_0),
    .softmc_h2c_tready(xdma_h2c_tready_0),
    .softmc_h2c_tkeep(xdma_h2c_tkeep_0),

    .user_clk_o       ( pci_user_clk ),
    .user_reset_o     ( pci_user_reset )
  );
  
  assign clk_200mhz = pci_user_clk;

    // Clock converter for the c2h interface
  axis_clock_converter axis_clk_conv_i0
  (
    .s_axis_tvalid(s_axis_c2h_tvalid_0),
    .s_axis_tlast(s_axis_c2h_tlast_0),
    .s_axis_tdata(s_axis_c2h_tdata_0),
    .s_axis_tkeep(s_axis_c2h_tkeep_0),
    .s_axis_tready(s_axis_c2h_tready_0),
    .m_axis_tvalid(xdma_c2h_tvalid_0),
    .m_axis_tlast(xdma_c2h_tlast_0),
    .m_axis_tdata(xdma_c2h_tdata_0),
    .m_axis_tkeep(xdma_c2h_tkeep_0),
    .m_axis_tready(xdma_c2h_tready_0),
    .s_axis_aresetn(~ui_rst),
    .s_axis_aclk(ui_clk),
    .m_axis_aresetn(~pci_user_reset),
    .m_axis_aclk(pci_user_clk)
  );
  
  // Clock converter for the h2c interface
  axis_clock_converter axis_clk_conv_i1
  (
    .m_axis_tvalid(m_axis_h2c_tvalid_0),
    .m_axis_tlast(m_axis_h2c_tlast_0),
    .m_axis_tdata(m_axis_h2c_tdata_0),
    .m_axis_tkeep(m_axis_h2c_tkeep_0),
    .m_axis_tready(m_axis_h2c_tready_0),
    .s_axis_tvalid(xdma_h2c_tvalid_0),
    .s_axis_tlast(xdma_h2c_tlast_0),
    .s_axis_tdata(xdma_h2c_tdata_0),
    .s_axis_tkeep(xdma_h2c_tkeep_0),
    .s_axis_tready(xdma_h2c_tready_0),
    .m_axis_aresetn(~ui_rst),
    .m_axis_aclk(ui_clk),
    .s_axis_aresetn(~pci_user_reset),
    .s_axis_aclk(pci_user_clk)
  );

  // ila_hc debug_c2h_ui_clk (
  //   .clk ( ui_clk ),
  //   .probe0 ( s_axis_c2h_tdata_0 ),
  //   .probe1 ( s_axis_c2h_tkeep_0 ),
  //   .probe2 ( s_axis_c2h_tvalid_0 ),
  //   .probe3 ( c0_init_calib_complete_r ),
  //   .probe4 ( s_axis_c2h_tlast_0 )
  // );

  // ila_hc debug_h2c_ui_clk (
  //   .clk ( ui_clk ),
  //   .probe0 ( m_axis_h2c_tdata_0 ),
  //   .probe1 ( m_axis_h2c_tkeep_0 ),
  //   .probe2 ( m_axis_h2c_tvalid_0 ),
  //   .probe3 ( m_axis_h2c_tready_0 ),
  //   .probe4 ( m_axis_h2c_tlast_0 )
  // );
`endif
  
  readback_engine rbe(
    
  // common signals
  .clk(ui_clk),
  .rst(ui_rst || user_rst),
  
  // other ctrl signals
  .flush(frontend_ready),
  .switch_mode(rbe_switch_mode),
  .read_seq_incoming(read_seq_incoming), // next few instructions will read from DRAM
  .incoming_reads(incoming_reads),    // how many reads next few instructions will issue
  .buffer_space(buffer_space),      // remaining buffer size
  // DRAM <-> engine if
  .rd_data(phy_rd_data),
  .rd_valid(phy_rddata_valid),
   
  // rbe <-> rf interface  
  .ddr_wdata(ddr_wdata),
  
  .per_rd_init(per_rd_init),
  .per_zq_init(per_zq_init),
  .per_ref_init(per_ref_init),
  
  // rbe <-> xdma if
  .c2h_tdata_0(s_axis_c2h_tdata_0),  
  .c2h_tlast_0(s_axis_c2h_tlast_0),
  .c2h_tvalid_0(s_axis_c2h_tvalid_0),
  .c2h_tready_0(s_axis_c2h_tready_0),
  .c2h_tkeep_0(s_axis_c2h_tkeep_0)
  
  );

endmodule
