`include "parameters.vh"
`include "project.vh"

module softmc_top #(parameter tCK = 1500, SIM = "false")
(
  // common signals
  input c0_sys_clk_p,
  input c0_sys_clk_n,
  input sys_rst_l,
  
  // xdma signals
  input clk_ref_p,
  input clk_ref_n,
  input pcie_rst,
  output  [7:0]    pci_exp_txp,
  output  [7:0]    pci_exp_txn,
  input   [7:0]    pci_exp_rxp,
  input   [7:0]    pci_exp_rxn,
  
  output icc
);
  
  // clock signals
  wire fab_clk;
  wire dfi_clk;
  wire main_clk;
  
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
  wire [3:0]                  ddr_write;
  wire [3:0]                  ddr_read;
  wire [3:0]                  ddr_pre;
  wire [3:0]                  ddr_act;
  wire [3:0]                  ddr_ref;
  wire [3:0]                  hbm_sel_ch;
  wire [3:0]                  ddr_nop;
  wire [3:0]                  ddr_ap;
  wire [3:0]                  ddr_pall;
  wire [3:0]                  ddr_rank;
  wire [3:0]                  ddr_half_bl;
  wire [4*`HBM_CH_WIDTH-1:0]  hbm_ch;
  wire [4*`BG_WIDTH-1:0]      ddr_bg;
  wire [4*`BANK_WIDTH-1:0]    ddr_bank;
  wire [4*`COL_WIDTH-1:0]     ddr_col;
  wire [4*`ROW_WIDTH-1:0]     ddr_row;
  wire [511:0]                ddr_wdata;
 
  // periodic maintenance signals
  wire                      ddr_maint_read;
  
  wire         read_seq_incoming; // next few instructions will read from DRAM
  wire [11:0]  incoming_reads;    // how many reads next few instructions will issue
  wire [11:0]  buffer_space;      // remaining buffer size
 
  wire sys_rst = ~sys_rst_l; // low active signal
  
  // HBM PHY signals
  wire dfi_0_init_complete;
  wire HBM_ready;
  wire dfi_0_dw_rddata_valid;
  wire [255:0] dfi_0_dw_rddata_p0;
  wire [255:0] dfi_0_dw_rddata_p1;
  wire hbm_ref_clk_buf;
  
  // There is a possibility that these signals are on
  // the critical path as observed in 
  // the previous iteration of SoftMC
  reg dfi_0_init_complete_r, sys_rst_r;
  wire iq_full, processing_iseq, rdback_fifo_empty;  
  
  wire [6:0] hbm0_temp;
  wire [6:0] hbm1_temp;

  IBUFDS hbm_ref_clk_ibuf (.O(hbm_ref_clk_buf), .I(c0_sys_clk_p), .IB((c0_sys_clk_n)));
  
  // clock generation
  clk_wiz_0 clk_gen (
    .clk_150MHz(fab_clk),
    .clk_300MHz(dfi_clk),
    .clk_in1(hbm_ref_clk_buf)
  );

  
  always @(posedge fab_clk) begin
    dfi_0_init_complete_r <= dfi_0_init_complete;
    sys_rst_r <= sys_rst;  
  end
  
  reg dllt_active = 1'b0;
  
  `ifdef ENABLE_DLL_TOGGLER
  always @(posedge fab_clk) begin
    if(toggle_dll) begin
      dllt_active <= ~dllt_active;
    end
    if(dllt_done) begin
      dllt_active <= ~dllt_active;
    end
  end
  `endif
    
  
  softmc_pipeline pipeline(
    .clk(fab_clk),
    .rst(~HBM_ready || user_rst),
   
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
    .ddr_rank(ddr_rank),  
    .ddr_ref(ddr_ref),    
    .ddr_zq(hbm_sel_ch),
    .ddr_nop(ddr_nop),    
    .ddr_ap(ddr_ap),
    .ddr_pall(ddr_pall),    
    //.ddr_half_bl(ddr_half_bl),
    .hbm_ch(hbm_ch),   
    .ddr_bg(ddr_bg),    
    .ddr_bank(ddr_bank),  
    .ddr_col(ddr_col),    
    .ddr_row(ddr_row),    
    .ddr_wdata(ddr_wdata)
  );

 
  assign icc = dfi_0_init_complete_r;
 
  wire frontend_ready;
  
  wire hbm_temp_rd;
  
  frontend #(.SIM_MEM(SIM)) frontend(
    .clk(fab_clk),
    .rst(~HBM_ready),
    
    .init_calib_complete(dfi_0_init_complete_r),
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
    
    .hbm_temp_rd(hbm_temp_rd),
    
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

  wire sys_clk, sys_clk_gt;
  wire [2:0]    msi_vector_width;
  wire          msi_enable;
  wire          user_lnk_up, usr_irq_req, usr_irq_ack;
  `ifdef XUPVVH_HBM
  IBUFDS_GTE4 refclk_ibuf (.O(sys_clk_gt), .ODIV2(sys_clk), .I(clk_ref_p), .CEB(1'b0), .IB(clk_ref_n));
  `else
  IBUFDS_GTE3 # (.REFCLK_HROW_CK_SEL(2'b01)) refclk_ibuf (.O(sys_clk_gt), .ODIV2(sys_clk), .I(clk_ref_p), .CEB(1'b0), .IB(clk_ref_n));
  `endif
  wire axi_clk, axi_rst;
  
  
  xdma xdma_i 
  (
    //---------------------------------------------------------------------------------------//
    //  PCI Express (pci_exp) Interface                                                      //
    //---------------------------------------------------------------------------------------//
    .sys_rst_n       ( pcie_rst ),
    .sys_clk         ( sys_clk ),
    .sys_clk_gt      ( sys_clk_gt),
    
    // Tx
    .pci_exp_txn     ( pci_exp_txn ),
    .pci_exp_txp     ( pci_exp_txp ),
    
    // Rx
    .pci_exp_rxn     ( pci_exp_rxn ),
    .pci_exp_rxp     ( pci_exp_rxp ),
    
    // AXI streaming ports
    .s_axis_c2h_tdata_0(xdma_c2h_tdata_0),  
    .s_axis_c2h_tlast_0(xdma_c2h_tlast_0),
    .s_axis_c2h_tvalid_0(xdma_c2h_tvalid_0), 
    .s_axis_c2h_tready_0(xdma_c2h_tready_0),
    .s_axis_c2h_tkeep_0(xdma_c2h_tkeep_0),
    .m_axis_h2c_tdata_0(xdma_h2c_tdata_0),
    .m_axis_h2c_tlast_0(xdma_h2c_tlast_0),
    .m_axis_h2c_tvalid_0(xdma_h2c_tvalid_0),
    .m_axis_h2c_tready_0(xdma_h2c_tready_0),
    .m_axis_h2c_tkeep_0(xdma_h2c_tkeep_0),
    
    .usr_irq_req       (1'b0),
    .usr_irq_ack       (usr_irq_ack),
    .msi_enable        (msi_enable),
    .msi_vector_width  (msi_vector_width),
    
    
    // Config managemnet interface
    .cfg_mgmt_addr  ( 19'b0 ),
    .cfg_mgmt_write ( 1'b0 ),
    .cfg_mgmt_write_data ( 32'b0 ),
    .cfg_mgmt_byte_enable ( 4'b0 ),
    .cfg_mgmt_read  ( 1'b0 ),
    .cfg_mgmt_read_data (),
    .cfg_mgmt_read_write_done (),
    `ifndef XUPVVH_HBM
    .cfg_mgmt_type1_cfg_reg_access ( 1'b0 ),
    //---------- Shared Logic Internal -------------------------
    .int_qpll1lock_out          (  ),   
    .int_qpll1outrefclk_out     (  ),
    .int_qpll1outclk_out        (  ),
    `endif
    
    //-- AXI Global
    .axi_aclk        (axi_clk), // AXI i-face clock driven from pcie clk
    .axi_aresetn     (axi_rst), // reset synchronous to axi_clk
    
    .user_lnk_up     ( user_lnk_up )
  );
  
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
    .s_axis_aresetn(HBM_ready),
    .s_axis_aclk(fab_clk),
    .m_axis_aresetn(axi_rst),
    .m_axis_aclk(axi_clk)
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
    .m_axis_aresetn(HBM_ready),
    .m_axis_aclk(fab_clk),
    .s_axis_aresetn(axi_rst),
    .s_axis_aclk(axi_clk)
  );
  
  
  readback_engine rbe(     
    // common signals
    .clk(fab_clk),
    .rst(~HBM_ready || user_rst),
    
    // other ctrl signals
    .flush(frontend_ready),
    .switch_mode(rbe_switch_mode),
    .read_seq_incoming(read_seq_incoming), // next few instructions will read from DRAM
    .incoming_reads(incoming_reads),    // how many reads next few instructions will issue
    .buffer_space(buffer_space),      // remaining buffer size
    // DRAM <-> engine if
    
    // We make sure to retrieve the data following our convention
    // wr/rddata[255:0] corresponds to PC0, and wr/rddata[511:256] corresponds to PC1
    .rd_data({dfi_0_dw_rddata_p1, dfi_0_dw_rddata_p0}),
              
     // Data is valid when dfi_0_dw_rddata_valid = 0011 (else 1100 or 0000), for now we can just use dfi_0_dw_rddata_valid[0]
    .rd_valid(dfi_0_dw_rddata_valid),
     
    // rbe <-> rf interface  
    .ddr_wdata(ddr_wdata),
    
    .per_rd_init(per_rd_init),
    .per_zq_init(per_zq_init),
    .per_ref_init(per_ref_init),
    
    `ifdef HBM_BENDER
    .hbm_temp_rd(hbm_temp_rd),
    .hbm0_temp(hbm0_temp),
    .hbm1_temp(hbm1_temp),
    `endif
    
    // rbe <-> xdma if
    .c2h_tdata_0(s_axis_c2h_tdata_0),  
    .c2h_tlast_0(s_axis_c2h_tlast_0),
    .c2h_tvalid_0(s_axis_c2h_tvalid_0),
    .c2h_tready_0(s_axis_c2h_tready_0), // use this when not simulating: s_axis_c2h_tready_0
    .c2h_tkeep_0(s_axis_c2h_tkeep_0)  
  );
  
  HBM_adapter HBM_adapter (
    .c0_sys_clk_p(hbm_ref_clk_buf),
    .sys_rst(~sys_rst),
    .fab_clk(fab_clk),
    .dfi_clk(dfi_clk),
    .dfi_rst_n(~sys_rst),
    
    .ddr_write(ddr_write),  
    .ddr_read(ddr_read),  
    .ddr_pre(ddr_pre),    
    .ddr_act(ddr_act),    
    .ddr_ref(ddr_ref),    
    .ddr_rank(ddr_rank),  
    .hbm_sel_ch(hbm_sel_ch),  
    .hbm_ch(hbm_ch),
    .ddr_nop(ddr_nop),    
    .ddr_ap(ddr_ap),    
    .ddr_pall(ddr_pall), 
    .ddr_bg(ddr_bg),    
    .ddr_bank(ddr_bank),  
    .ddr_col(ddr_col),    
    .ddr_row(ddr_row),    
    .ddr_wdata(ddr_wdata),
    
    .o_dfi_0_init_complete(dfi_0_init_complete),
    .o_HBM_ready(HBM_ready),
    
    // Received by readback engine
    .o_dfi_0_dw_rddata_p0(dfi_0_dw_rddata_p0),
    .o_dfi_0_dw_rddata_p1(dfi_0_dw_rddata_p1),
    .o_dfi_0_dw_rddata_valid(dfi_0_dw_rddata_valid),
    
    .hbm0_temp(hbm0_temp),
    .hbm1_temp(hbm1_temp)
  );
  
   
endmodule
