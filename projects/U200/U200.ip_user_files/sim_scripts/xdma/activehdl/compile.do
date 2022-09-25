vlib work
vlib activehdl

vlib activehdl/xilinx_vip
vlib activehdl/xpm
vlib activehdl/gtwizard_ultrascale_v1_7_9
vlib activehdl/xil_defaultlib
vlib activehdl/blk_mem_gen_v8_4_4
vlib activehdl/xdma_v4_1_8

vmap xilinx_vip activehdl/xilinx_vip
vmap xpm activehdl/xpm
vmap gtwizard_ultrascale_v1_7_9 activehdl/gtwizard_ultrascale_v1_7_9
vmap xil_defaultlib activehdl/xil_defaultlib
vmap blk_mem_gen_v8_4_4 activehdl/blk_mem_gen_v8_4_4
vmap xdma_v4_1_8 activehdl/xdma_v4_1_8

vlog -work xilinx_vip  -sv2k12 "+incdir+/tools/Xilinx/Vivado/2020.2/data/xilinx_vip/include" \
"/tools/Xilinx/Vivado/2020.2/data/xilinx_vip/hdl/axi4stream_vip_axi4streampc.sv" \
"/tools/Xilinx/Vivado/2020.2/data/xilinx_vip/hdl/axi_vip_axi4pc.sv" \
"/tools/Xilinx/Vivado/2020.2/data/xilinx_vip/hdl/xil_common_vip_pkg.sv" \
"/tools/Xilinx/Vivado/2020.2/data/xilinx_vip/hdl/axi4stream_vip_pkg.sv" \
"/tools/Xilinx/Vivado/2020.2/data/xilinx_vip/hdl/axi_vip_pkg.sv" \
"/tools/Xilinx/Vivado/2020.2/data/xilinx_vip/hdl/axi4stream_vip_if.sv" \
"/tools/Xilinx/Vivado/2020.2/data/xilinx_vip/hdl/axi_vip_if.sv" \
"/tools/Xilinx/Vivado/2020.2/data/xilinx_vip/hdl/clk_vip_if.sv" \
"/tools/Xilinx/Vivado/2020.2/data/xilinx_vip/hdl/rst_vip_if.sv" \

vlog -work xpm  -sv2k12 "+incdir+../../../../U200.srcs/sources_1/ip/xdma/ip_0/source" "+incdir+../../../ipstatic/hdl/verilog" "+incdir+/tools/Xilinx/Vivado/2020.2/data/xilinx_vip/include" \
"/tools/Xilinx/Vivado/2020.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"/tools/Xilinx/Vivado/2020.2/data/ip/xpm/xpm_fifo/hdl/xpm_fifo.sv" \
"/tools/Xilinx/Vivado/2020.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -93 \
"/tools/Xilinx/Vivado/2020.2/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work gtwizard_ultrascale_v1_7_9  -v2k5 "+incdir+../../../../U200.srcs/sources_1/ip/xdma/ip_0/source" "+incdir+../../../ipstatic/hdl/verilog" "+incdir+/tools/Xilinx/Vivado/2020.2/data/xilinx_vip/include" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_bit_sync.v" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gte4_drp_arb.v" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gthe4_delay_powergood.v" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gtye4_delay_powergood.v" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gthe3_cpll_cal.v" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gthe3_cal_freqcnt.v" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gthe4_cpll_cal.v" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gthe4_cpll_cal_rx.v" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gthe4_cpll_cal_tx.v" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gthe4_cal_freqcnt.v" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gtye4_cpll_cal.v" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gtye4_cpll_cal_rx.v" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gtye4_cpll_cal_tx.v" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gtye4_cal_freqcnt.v" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gtwiz_buffbypass_rx.v" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gtwiz_buffbypass_tx.v" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gtwiz_reset.v" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gtwiz_userclk_rx.v" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gtwiz_userclk_tx.v" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gtwiz_userdata_rx.v" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gtwiz_userdata_tx.v" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_reset_sync.v" \
"../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_reset_inv_sync.v" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../U200.srcs/sources_1/ip/xdma/ip_0/source" "+incdir+../../../ipstatic/hdl/verilog" "+incdir+/tools/Xilinx/Vivado/2020.2/data/xilinx_vip/include" \
"../../../../U200.srcs/sources_1/ip/xdma/ip_0/ip_0/sim/gtwizard_ultrascale_v1_7_gtye4_channel.v" \
"../../../../U200.srcs/sources_1/ip/xdma/ip_0/ip_0/sim/xdma_pcie4_ip_gt_gtye4_channel_wrapper.v" \
"../../../../U200.srcs/sources_1/ip/xdma/ip_0/ip_0/sim/gtwizard_ultrascale_v1_7_gtye4_common.v" \
"../../../../U200.srcs/sources_1/ip/xdma/ip_0/ip_0/sim/xdma_pcie4_ip_gt_gtye4_common_wrapper.v" \
"../../../../U200.srcs/sources_1/ip/xdma/ip_0/ip_0/sim/xdma_pcie4_ip_gt_gtwizard_gtye4.v" \
"../../../../U200.srcs/sources_1/ip/xdma/ip_0/ip_0/sim/xdma_pcie4_ip_gt_gtwizard_top.v" \
"../../../../U200.srcs/sources_1/ip/xdma/ip_0/ip_0/sim/xdma_pcie4_ip_gt.v" \
"../../../../U200.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4_ip_gtwizard_top.v" \
"../../../../U200.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4_ip_phy_ff_chain.v" \
"../../../../U200.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4_ip_phy_pipeline.v" \
"../../../../U200.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4_ip_bram_16k_int.v" \
"../../../../U200.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4_ip_bram_16k.v" \
"../../../../U200.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4_ip_bram_32k.v" \
"../../../../U200.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4_ip_bram_4k_int.v" \
"../../../../U200.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4_ip_bram_msix.v" \
"../../../../U200.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4_ip_bram_rep_int.v" \
"../../../../U200.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4_ip_bram_rep.v" \
"../../../../U200.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4_ip_bram_tph.v" \
"../../../../U200.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4_ip_bram.v" \
"../../../../U200.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4_ip_gt_gt_channel.v" \
"../../../../U200.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4_ip_gt_gt_common.v" \
"../../../../U200.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4_ip_gt_phy_clk.v" \
"../../../../U200.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4_ip_gt_phy_rst.v" \
"../../../../U200.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4_ip_gt_phy_rxeq.v" \
"../../../../U200.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4_ip_gt_phy_txeq.v" \
"../../../../U200.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4_ip_sync_cell.v" \
"../../../../U200.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4_ip_sync.v" \
"../../../../U200.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4_ip_gt_cdr_ctrl_on_eidle.v" \
"../../../../U200.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4_ip_gt_receiver_detect_rxterm.v" \
"../../../../U200.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4_ip_gt_phy_wrapper.v" \
"../../../../U200.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4_ip_init_ctrl.v" \
"../../../../U200.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4_ip_pl_eq.v" \
"../../../../U200.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4_ip_vf_decode.v" \
"../../../../U200.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4_ip_pipe.v" \
"../../../../U200.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4_ip_phy_top.v" \
"../../../../U200.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4_ip_seqnum_fifo.v" \
"../../../../U200.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4_ip_sys_clk_gen_ps.v" \
"../../../../U200.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4_ip_pcie4_uscale_core_top.v" \
"../../../../U200.srcs/sources_1/ip/xdma/ip_0/sim/xdma_pcie4_ip.v" \

vlog -work blk_mem_gen_v8_4_4  -v2k5 "+incdir+../../../../U200.srcs/sources_1/ip/xdma/ip_0/source" "+incdir+../../../ipstatic/hdl/verilog" "+incdir+/tools/Xilinx/Vivado/2020.2/data/xilinx_vip/include" \
"../../../ipstatic/simulation/blk_mem_gen_v8_4.v" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../U200.srcs/sources_1/ip/xdma/ip_0/source" "+incdir+../../../ipstatic/hdl/verilog" "+incdir+/tools/Xilinx/Vivado/2020.2/data/xilinx_vip/include" \
"../../../../U200.srcs/sources_1/ip/xdma/ip_1/sim/xdma_v4_1_8_blk_mem_64_reg_be.v" \
"../../../../U200.srcs/sources_1/ip/xdma/ip_2/sim/xdma_v4_1_8_blk_mem_64_noreg_be.v" \

vlog -work xdma_v4_1_8  -sv2k12 "+incdir+../../../../U200.srcs/sources_1/ip/xdma/ip_0/source" "+incdir+../../../ipstatic/hdl/verilog" "+incdir+/tools/Xilinx/Vivado/2020.2/data/xilinx_vip/include" \
"../../../ipstatic/hdl/xdma_v4_1_vl_rfs.sv" \

vlog -work xil_defaultlib  -sv2k12 "+incdir+../../../../U200.srcs/sources_1/ip/xdma/ip_0/source" "+incdir+../../../ipstatic/hdl/verilog" "+incdir+/tools/Xilinx/Vivado/2020.2/data/xilinx_vip/include" \
"../../../../U200.srcs/sources_1/ip/xdma/xdma_v4_1/hdl/verilog/xdma_dma_bram_wrap.sv" \
"../../../../U200.srcs/sources_1/ip/xdma/xdma_v4_1/hdl/verilog/xdma_dma_bram_wrap_1024.sv" \
"../../../../U200.srcs/sources_1/ip/xdma/xdma_v4_1/hdl/verilog/xdma_dma_bram_wrap_2048.sv" \
"../../../../U200.srcs/sources_1/ip/xdma/xdma_v4_1/hdl/verilog/xdma_core_top.sv" \
"../../../../U200.srcs/sources_1/ip/xdma/sim/xdma.sv" \

vlog -work xil_defaultlib \
"glbl.v"

