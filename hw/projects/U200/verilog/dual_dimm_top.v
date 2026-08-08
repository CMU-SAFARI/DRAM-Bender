`include "project.vh"
`include "parameters.vh"

module dual_dimm_top(
  // common signals
  input c0_sys_clk_p,
  input c0_sys_clk_n,
  input c1_sys_clk_p,
  input c1_sys_clk_n,
  input sys_rst_l,
  
  // iob <> ddr4 sdram ip signals
  output             c0_ddr4_act_n,
  output [`ROW_ADDR_WIDTH-1:0]      c0_ddr4_adr,
  output [1:0]       c0_ddr4_ba,
  output [1:0]       c0_ddr4_bg,
  output [`CKE_WIDTH-1:0]       c0_ddr4_cke,
  output [`ODT_WIDTH-1:0]       c0_ddr4_odt,
  output [`CS_WIDTH-1:0]        c0_ddr4_cs_n,
  output [`CK_WIDTH-1:0]       c0_ddr4_ck_t,
  output [`CK_WIDTH-1:0]       c0_ddr4_ck_c,
  output             c0_ddr4_reset_n,
  
  // iob <> ddr4 sdram ip signals
  output             c1_ddr4_act_n,
  output [`ROW_ADDR_WIDTH-1:0]      c1_ddr4_adr,
  output [1:0]       c1_ddr4_ba,
  output [1:0]       c1_ddr4_bg,
  output [`CKE_WIDTH-1:0]       c1_ddr4_cke,
  output [`ODT_WIDTH-1:0]       c1_ddr4_odt,
  output [`CS_WIDTH-1:0]        c1_ddr4_cs_n,
  output [`CK_WIDTH-1:0]       c1_ddr4_ck_t,
  output [`CK_WIDTH-1:0]       c1_ddr4_ck_c,
  output             c1_ddr4_reset_n,  

  `ifdef RDIMM_x4
  inout  [17:0]      c0_ddr4_dqs_c,
  inout  [17:0]      c0_ddr4_dqs_t,
  inout  [71:0]      c0_ddr4_dq,
  output             c0_ddr4_parity,
  inout  [17:0]      c1_ddr4_dqs_c,
  inout  [17:0]      c1_ddr4_dqs_t,
  inout  [71:0]      c1_ddr4_dq,
  output             c1_ddr4_parity,
  `elsif UDIMM_x8
  inout  [7:0]      c0_ddr4_dqs_c,
  inout  [7:0]      c0_ddr4_dqs_t,
  inout  [63:0]     c0_ddr4_dq,
  inout  [7:0]      c0_ddr4_dm_dbi_n,  
  output            c0_ddr4_parity,
  inout  [7:0]      c1_ddr4_dqs_c,
  inout  [7:0]      c1_ddr4_dqs_t,
  inout  [63:0]     c1_ddr4_dq,
  inout  [7:0]      c1_ddr4_dm_dbi_n,  
  output            c1_ddr4_parity,
  `elsif RDIMM_x8
  inout  [8:0]      c0_ddr4_dqs_c,
  inout  [8:0]      c0_ddr4_dqs_t,
  inout  [71:0]     c0_ddr4_dq,
  inout  [8:0]      c0_ddr4_dm_dbi_n,
  output            c0_ddr4_parity,
  inout  [8:0]      c1_ddr4_dqs_c,
  inout  [8:0]      c1_ddr4_dqs_t,
  inout  [71:0]     c1_ddr4_dq,
  inout  [8:0]      c1_ddr4_dm_dbi_n,
  output            c1_ddr4_parity,
  `endif
  
  // xdma signals
  input clk_ref_p,
  input clk_ref_n,
  input pcie_rst,
  output  [7:0]    pci_exp_txp,
  output  [7:0]    pci_exp_txn,
  input   [7:0]    pci_exp_rxp,
  input   [7:0]    pci_exp_rxn
  
  );


  // AXI streaming ports
  wire [`XDMA_AXI_DATA_WIDTH-1:0]   h2c_tdata_0,xdma_h2c_tdata_0;
  wire                              h2c_tlast_0, xdma_h2c_tlast_0;
  wire                              h2c_tvalid_0, xdma_h2c_tvalid_0;
  wire                              h2c_tready_0, xdma_h2c_tready_0;
  wire [`XDMA_AXI_DATA_WIDTH/8-1:0] h2c_tkeep_0, xdma_h2c_tkeep_0;
  wire [`XDMA_AXI_DATA_WIDTH-1:0]   c2h_tdata_0, xdma_c2h_tdata_0; 
  wire                              c2h_tlast_0, xdma_c2h_tlast_0;
  wire                              c2h_tvalid_0, xdma_c2h_tvalid_0;
  wire                              c2h_tready_0, xdma_c2h_tready_0;
  wire [`XDMA_AXI_DATA_WIDTH/8-1:0] c2h_tkeep_0, xdma_c2h_tkeep_0;

  // AXI streaming ports
  wire [`XDMA_AXI_DATA_WIDTH-1:0]   h2c_tdata_1,xdma_h2c_tdata_1;
  wire                              h2c_tlast_1, xdma_h2c_tlast_1;
  wire                              h2c_tvalid_1, xdma_h2c_tvalid_1;
  wire                              h2c_tready_1, xdma_h2c_tready_1;
  wire [`XDMA_AXI_DATA_WIDTH/8-1:0] h2c_tkeep_1, xdma_h2c_tkeep_1;
  wire [`XDMA_AXI_DATA_WIDTH-1:0]   c2h_tdata_1, xdma_c2h_tdata_1; 
  wire                              c2h_tlast_1, xdma_c2h_tlast_1;
  wire                              c2h_tvalid_1, xdma_c2h_tvalid_1;
  wire                              c2h_tready_1, xdma_c2h_tready_1;
  wire [`XDMA_AXI_DATA_WIDTH/8-1:0] c2h_tkeep_1, xdma_c2h_tkeep_1;

  no_xdma_top smc1
  (
  // common signals
  .c0_sys_clk_p     (c0_sys_clk_p)       ,
  .c0_sys_clk_n     (c0_sys_clk_n)       ,
  .sys_rst_l        (sys_rst_l)          ,
  
  .ui_clk           (smc_ui_clk_0)       ,
  .ui_rst           (smc_ui_rst_0)       ,

  // iob <> ddr4 sdram ip signals
  .c0_ddr4_act_n    (c0_ddr4_act_n)      ,
  .c0_ddr4_adr      (c0_ddr4_adr)        ,
  .c0_ddr4_ba       (c0_ddr4_ba)         ,
  .c0_ddr4_bg       (c0_ddr4_bg)         ,
  .c0_ddr4_cke      (c0_ddr4_cke)        ,
  .c0_ddr4_odt      (c0_ddr4_odt)        ,
  .c0_ddr4_cs_n     (c0_ddr4_cs_n)       ,
  .c0_ddr4_ck_t     (c0_ddr4_ck_t)       ,
  .c0_ddr4_ck_c     (c0_ddr4_ck_c)       ,
  .c0_ddr4_reset_n  (c0_ddr4_reset_n)    ,

  `ifdef RDIMM_x4
  .c0_ddr4_dqs_c    (c0_ddr4_dqs_c)      ,
  .c0_ddr4_dqs_t    (c0_ddr4_dqs_t)      ,
  .c0_ddr4_dq       (c0_ddr4_dq)         ,
  .c0_ddr4_parity   (c0_ddr4_parity)     ,
  `elsif UDIMM_x8
  .c0_ddr4_dqs_c    (c0_ddr4_dqs_c)      ,
  .c0_ddr4_dqs_t    (c0_ddr4_dqs_t)      ,
  .c0_ddr4_dq       (c0_ddr4_dq)         ,
  .c0_ddr4_dm_dbi_n (c0_ddr4_dm_dbi_n)   ,  
  .c0_ddr4_parity   (c0_ddr4_parity)     ,
  `elsif RDIMM_x8
  .c0_ddr4_dqs_c    (c0_ddr4_dqs_c)      ,
  .c0_ddr4_dqs_t    (c0_ddr4_dqs_t)      ,
  .c0_ddr4_dq       (c0_ddr4_dq)         ,
  .c0_ddr4_dm_dbi_n (c0_ddr4_dm_dbi_n)   ,
  .c0_ddr4_parity   (c0_ddr4_parity)     ,
  `endif
  
  // frontend <-> xdma interface
  .h2c_tdata_0      (h2c_tdata_0)        ,
  .h2c_tlast_0      (h2c_tlast_0)        ,
  .h2c_tvalid_0     (h2c_tvalid_0)       ,
  .h2c_tready_0     (h2c_tready_0)       ,
  .h2c_tkeep_0      (h2c_tkeep_0)        ,
  .c2h_tdata_0      (c2h_tdata_0)        ,  
  .c2h_tlast_0      (c2h_tlast_0)        ,
  .c2h_tvalid_0     (c2h_tvalid_0)       ,
  .c2h_tready_0     (c2h_tready_0)       ,
  .c2h_tkeep_0      (c2h_tkeep_0)
  );
  
  no_xdma_top smc2
  (
  // common signals
  .c0_sys_clk_p     (c1_sys_clk_p)       ,
  .c0_sys_clk_n     (c1_sys_clk_n)       ,
  .sys_rst_l        (sys_rst_l)          ,
  
  .ui_clk           (smc_ui_clk_1)       ,
  .ui_rst           (smc_ui_rst_1)       ,
  
  // iob <> ddr4 sdram ip signals
  .c0_ddr4_act_n    (c1_ddr4_act_n)      ,
  .c0_ddr4_adr      (c1_ddr4_adr)        ,
  .c0_ddr4_ba       (c1_ddr4_ba)         ,
  .c0_ddr4_bg       (c1_ddr4_bg)         ,
  .c0_ddr4_cke      (c1_ddr4_cke)        ,
  .c0_ddr4_odt      (c1_ddr4_odt)        ,
  .c0_ddr4_cs_n     (c1_ddr4_cs_n)       ,
  .c0_ddr4_ck_t     (c1_ddr4_ck_t)       ,
  .c0_ddr4_ck_c     (c1_ddr4_ck_c)       ,
  .c0_ddr4_reset_n  (c1_ddr4_reset_n)    ,

  `ifdef RDIMM_x4
  .c0_ddr4_dqs_c    (c1_ddr4_dqs_c)      ,
  .c0_ddr4_dqs_t    (c1_ddr4_dqs_t)      ,
  .c0_ddr4_dq       (c1_ddr4_dq)         ,
  .c0_ddr4_parity   (c1_ddr4_parity)     ,
  `elsif UDIMM_x8
  .c0_ddr4_dqs_c    (c1_ddr4_dqs_c)      ,
  .c0_ddr4_dqs_t    (c1_ddr4_dqs_t)      ,
  .c0_ddr4_dq       (c1_ddr4_dq)         ,
  .c0_ddr4_dm_dbi_n (c1_ddr4_dm_dbi_n)   ,  
  .c0_ddr4_parity   (c1_ddr4_parity)     ,
  `elsif RDIMM_x8
  .c0_ddr4_dqs_c    (c1_ddr4_dqs_c)      ,
  .c0_ddr4_dqs_t    (c1_ddr4_dqs_t)      ,
  .c0_ddr4_dq       (c1_ddr4_dq)         ,
  .c0_ddr4_dm_dbi_n (c1_ddr4_dm_dbi_n)   ,
  .c0_ddr4_parity   (c1_ddr4_parity)     ,
  `endif
  
  // frontend <-> xdma interface
  .h2c_tdata_0      (h2c_tdata_1)        ,
  .h2c_tlast_0      (h2c_tlast_1)        ,
  .h2c_tvalid_0     (h2c_tvalid_1)       ,
  .h2c_tready_0     (h2c_tready_1)       ,
  .h2c_tkeep_0      (h2c_tkeep_1)        ,
  .c2h_tdata_0      (c2h_tdata_1)        ,  
  .c2h_tlast_0      (c2h_tlast_1)        ,
  .c2h_tvalid_0     (c2h_tvalid_1)       ,
  .c2h_tready_0     (c2h_tready_1)       ,
  .c2h_tkeep_0      (c2h_tkeep_1)  
  );
  
  wire sys_clk, sys_clk_gt;
  wire [2:0]    msi_vector_width;
  wire          msi_enable;
  wire          user_lnk_up, usr_irq_req, usr_irq_ack;

  IBUFDS_GTE4 refclk_ibuf (.O(sys_clk_gt), .ODIV2(sys_clk), .I(clk_ref_p), .CEB(1'b0), .IB(clk_ref_n));

  wire axi_clk, axi_rst;
  
  xdma_dual xdma_i 
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
    
    // AXI streaming ports
    .s_axis_c2h_tdata_1(xdma_c2h_tdata_1),  
    .s_axis_c2h_tlast_1(xdma_c2h_tlast_1),
    .s_axis_c2h_tvalid_1(xdma_c2h_tvalid_1), 
    .s_axis_c2h_tready_1(xdma_c2h_tready_1),
    .s_axis_c2h_tkeep_1(xdma_c2h_tkeep_1),
    .m_axis_h2c_tdata_1(xdma_h2c_tdata_1),
    .m_axis_h2c_tlast_1(xdma_h2c_tlast_1),
    .m_axis_h2c_tvalid_1(xdma_h2c_tvalid_1),
    .m_axis_h2c_tready_1(xdma_h2c_tready_1),
    .m_axis_h2c_tkeep_1(xdma_h2c_tkeep_1),
        
    
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

    
    //-- AXI Global
    .axi_aclk        (axi_clk), // AXI i-face clock driven from pcie clk
    .axi_aresetn     (axi_rst), // reset synchronous to axi_clk
    
    .user_lnk_up     ( user_lnk_up )
  );
  
    // Clock converter for the c2h interface
  axis_clock_converter axis_clk_conv_i0
  (
    .s_axis_tvalid(c2h_tvalid_0),
    .s_axis_tlast(c2h_tlast_0),
    .s_axis_tdata(c2h_tdata_0),
    .s_axis_tkeep(c2h_tkeep_0),
    .s_axis_tready(c2h_tready_0),
    .m_axis_tvalid(xdma_c2h_tvalid_0),
    .m_axis_tlast(xdma_c2h_tlast_0),
    .m_axis_tdata(xdma_c2h_tdata_0),
    .m_axis_tkeep(xdma_c2h_tkeep_0),
    .m_axis_tready(xdma_c2h_tready_0),
    .s_axis_aresetn(~smc_ui_rst_0),
    .s_axis_aclk(smc_ui_clk_0),
    .m_axis_aresetn(axi_rst),
    .m_axis_aclk(axi_clk)
  );
  
  // Clock converter for the h2c interface
  axis_clock_converter axis_clk_conv_i1
  (
    .m_axis_tvalid(h2c_tvalid_0),
    .m_axis_tlast(h2c_tlast_0),
    .m_axis_tdata(h2c_tdata_0),
    .m_axis_tkeep(h2c_tkeep_0),
    .m_axis_tready(h2c_tready_0),
    .s_axis_tvalid(xdma_h2c_tvalid_0),
    .s_axis_tlast(xdma_h2c_tlast_0),
    .s_axis_tdata(xdma_h2c_tdata_0),
    .s_axis_tkeep(xdma_h2c_tkeep_0),
    .s_axis_tready(xdma_h2c_tready_0),
    .m_axis_aresetn(~smc_ui_rst_0),
    .m_axis_aclk(smc_ui_clk_0),
    .s_axis_aresetn(axi_rst),
    .s_axis_aclk(axi_clk)
  );  
  
    // Clock converter for the c2h interface
  axis_clock_converter axis_clk_conv_i2
  (
    .s_axis_tvalid(c2h_tvalid_1),
    .s_axis_tlast(c2h_tlast_1),
    .s_axis_tdata(c2h_tdata_1),
    .s_axis_tkeep(c2h_tkeep_1),
    .s_axis_tready(c2h_tready_1),
    .m_axis_tvalid(xdma_c2h_tvalid_1),
    .m_axis_tlast(xdma_c2h_tlast_1),
    .m_axis_tdata(xdma_c2h_tdata_1),
    .m_axis_tkeep(xdma_c2h_tkeep_1),
    .m_axis_tready(xdma_c2h_tready_1),
    .s_axis_aresetn(~smc_ui_rst_1),
    .s_axis_aclk(smc_ui_clk_1),
    .m_axis_aresetn(axi_rst),
    .m_axis_aclk(axi_clk)
  );
  
  // Clock converter for the h2c interface
  axis_clock_converter axis_clk_conv_i3
  (
    .m_axis_tvalid(h2c_tvalid_1),
    .m_axis_tlast(h2c_tlast_1),
    .m_axis_tdata(h2c_tdata_1),
    .m_axis_tkeep(h2c_tkeep_1),
    .m_axis_tready(h2c_tready_1),
    .s_axis_tvalid(xdma_h2c_tvalid_1),
    .s_axis_tlast(xdma_h2c_tlast_1),
    .s_axis_tdata(xdma_h2c_tdata_1),
    .s_axis_tkeep(xdma_h2c_tkeep_1),
    .s_axis_tready(xdma_h2c_tready_1),
    .m_axis_aresetn(~smc_ui_rst_1),
    .m_axis_aclk(smc_ui_clk_1),
    .s_axis_aresetn(axi_rst),
    .s_axis_aclk(axi_clk)
  );    
  

endmodule
