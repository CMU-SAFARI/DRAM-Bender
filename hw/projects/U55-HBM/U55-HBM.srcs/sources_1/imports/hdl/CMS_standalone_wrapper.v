//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2024.2 (lin64) Build 5239630 Fri Nov 08 22:34:34 MST 2024
//Date        : Thu Jan  8 15:42:39 2026
//Host        : safari-desktop24 running 64-bit Ubuntu 22.04.5 LTS
//Command     : generate_target CMS_standalone_wrapper.bd
//Design      : CMS_standalone_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module CMS_standalone_wrapper
   (aclk_ctrl_0,
    aresetn_ctrl_0,
    hbm_temp_1_0,
    hbm_temp_2_0,
    interrupt_hbm_cattrip_0,
    interrupt_host_0,
    s_axi_ctrl_0_araddr,
    s_axi_ctrl_0_arprot,
    s_axi_ctrl_0_arready,
    s_axi_ctrl_0_arvalid,
    s_axi_ctrl_0_awaddr,
    s_axi_ctrl_0_awprot,
    s_axi_ctrl_0_awready,
    s_axi_ctrl_0_awvalid,
    s_axi_ctrl_0_bready,
    s_axi_ctrl_0_bresp,
    s_axi_ctrl_0_bvalid,
    s_axi_ctrl_0_rdata,
    s_axi_ctrl_0_rready,
    s_axi_ctrl_0_rresp,
    s_axi_ctrl_0_rvalid,
    s_axi_ctrl_0_wdata,
    s_axi_ctrl_0_wready,
    s_axi_ctrl_0_wstrb,
    s_axi_ctrl_0_wvalid,
    satellite_gpio_0,
    satellite_uart_0_rxd,
    satellite_uart_0_txd);
  input aclk_ctrl_0;
  input aresetn_ctrl_0;
  input [6:0]hbm_temp_1_0;
  input [6:0]hbm_temp_2_0;
  input [0:0]interrupt_hbm_cattrip_0;
  output interrupt_host_0;
  input [17:0]s_axi_ctrl_0_araddr;
  input [2:0]s_axi_ctrl_0_arprot;
  output [0:0]s_axi_ctrl_0_arready;
  input [0:0]s_axi_ctrl_0_arvalid;
  input [17:0]s_axi_ctrl_0_awaddr;
  input [2:0]s_axi_ctrl_0_awprot;
  output [0:0]s_axi_ctrl_0_awready;
  input [0:0]s_axi_ctrl_0_awvalid;
  input [0:0]s_axi_ctrl_0_bready;
  output [1:0]s_axi_ctrl_0_bresp;
  output [0:0]s_axi_ctrl_0_bvalid;
  output [31:0]s_axi_ctrl_0_rdata;
  input [0:0]s_axi_ctrl_0_rready;
  output [1:0]s_axi_ctrl_0_rresp;
  output [0:0]s_axi_ctrl_0_rvalid;
  input [31:0]s_axi_ctrl_0_wdata;
  output [0:0]s_axi_ctrl_0_wready;
  input [3:0]s_axi_ctrl_0_wstrb;
  input [0:0]s_axi_ctrl_0_wvalid;
  input [3:0]satellite_gpio_0;
  input satellite_uart_0_rxd;
  output satellite_uart_0_txd;

  wire aclk_ctrl_0;
  wire aresetn_ctrl_0;
  wire [6:0]hbm_temp_1_0;
  wire [6:0]hbm_temp_2_0;
  wire [0:0]interrupt_hbm_cattrip_0;
  wire interrupt_host_0;
  wire [17:0]s_axi_ctrl_0_araddr;
  wire [2:0]s_axi_ctrl_0_arprot;
  wire [0:0]s_axi_ctrl_0_arready;
  wire [0:0]s_axi_ctrl_0_arvalid;
  wire [17:0]s_axi_ctrl_0_awaddr;
  wire [2:0]s_axi_ctrl_0_awprot;
  wire [0:0]s_axi_ctrl_0_awready;
  wire [0:0]s_axi_ctrl_0_awvalid;
  wire [0:0]s_axi_ctrl_0_bready;
  wire [1:0]s_axi_ctrl_0_bresp;
  wire [0:0]s_axi_ctrl_0_bvalid;
  wire [31:0]s_axi_ctrl_0_rdata;
  wire [0:0]s_axi_ctrl_0_rready;
  wire [1:0]s_axi_ctrl_0_rresp;
  wire [0:0]s_axi_ctrl_0_rvalid;
  wire [31:0]s_axi_ctrl_0_wdata;
  wire [0:0]s_axi_ctrl_0_wready;
  wire [3:0]s_axi_ctrl_0_wstrb;
  wire [0:0]s_axi_ctrl_0_wvalid;
  wire [3:0]satellite_gpio_0;
  wire satellite_uart_0_rxd;
  wire satellite_uart_0_txd;

  CMS_standalone CMS_standalone_i
       (.aclk_ctrl_0(aclk_ctrl_0),
        .aresetn_ctrl_0(aresetn_ctrl_0),
        .hbm_temp_1_0(hbm_temp_1_0),
        .hbm_temp_2_0(hbm_temp_2_0),
        .interrupt_hbm_cattrip_0(interrupt_hbm_cattrip_0),
        .interrupt_host_0(interrupt_host_0),
        .s_axi_ctrl_0_araddr(s_axi_ctrl_0_araddr),
        .s_axi_ctrl_0_arprot(s_axi_ctrl_0_arprot),
        .s_axi_ctrl_0_arready(s_axi_ctrl_0_arready),
        .s_axi_ctrl_0_arvalid(s_axi_ctrl_0_arvalid),
        .s_axi_ctrl_0_awaddr(s_axi_ctrl_0_awaddr),
        .s_axi_ctrl_0_awprot(s_axi_ctrl_0_awprot),
        .s_axi_ctrl_0_awready(s_axi_ctrl_0_awready),
        .s_axi_ctrl_0_awvalid(s_axi_ctrl_0_awvalid),
        .s_axi_ctrl_0_bready(s_axi_ctrl_0_bready),
        .s_axi_ctrl_0_bresp(s_axi_ctrl_0_bresp),
        .s_axi_ctrl_0_bvalid(s_axi_ctrl_0_bvalid),
        .s_axi_ctrl_0_rdata(s_axi_ctrl_0_rdata),
        .s_axi_ctrl_0_rready(s_axi_ctrl_0_rready),
        .s_axi_ctrl_0_rresp(s_axi_ctrl_0_rresp),
        .s_axi_ctrl_0_rvalid(s_axi_ctrl_0_rvalid),
        .s_axi_ctrl_0_wdata(s_axi_ctrl_0_wdata),
        .s_axi_ctrl_0_wready(s_axi_ctrl_0_wready),
        .s_axi_ctrl_0_wstrb(s_axi_ctrl_0_wstrb),
        .s_axi_ctrl_0_wvalid(s_axi_ctrl_0_wvalid),
        .satellite_gpio_0(satellite_gpio_0),
        .satellite_uart_0_rxd(satellite_uart_0_rxd),
        .satellite_uart_0_txd(satellite_uart_0_txd));
endmodule
