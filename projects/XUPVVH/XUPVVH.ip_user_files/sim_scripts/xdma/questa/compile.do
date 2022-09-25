vlib questa_lib/work
vlib questa_lib/msim

vlib questa_lib/msim/xpm
vlib questa_lib/msim/gtwizard_ultrascale_v1_7_7
vlib questa_lib/msim/xil_defaultlib
vlib questa_lib/msim/blk_mem_gen_v8_4_4
vlib questa_lib/msim/xdma_v4_1_4

vmap xpm questa_lib/msim/xpm
vmap gtwizard_ultrascale_v1_7_7 questa_lib/msim/gtwizard_ultrascale_v1_7_7
vmap xil_defaultlib questa_lib/msim/xil_defaultlib
vmap blk_mem_gen_v8_4_4 questa_lib/msim/blk_mem_gen_v8_4_4
vmap xdma_v4_1_4 questa_lib/msim/xdma_v4_1_4

vlog -work xpm -64 -sv "+incdir+../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/source" "+incdir+../../../ipstatic/hdl/verilog" \
"/tools/Xilinx/Vivado/2019.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"/tools/Xilinx/Vivado/2019.2/data/ip/xpm/xpm_fifo/hdl/xpm_fifo.sv" \
"/tools/Xilinx/Vivado/2019.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -64 -93 \
"/tools/Xilinx/Vivado/2019.2/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work gtwizard_ultrascale_v1_7_7 -64 "+incdir+../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/source" "+incdir+../../../ipstatic/hdl/verilog" \
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

vlog -work xil_defaultlib -64 "+incdir+../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/source" "+incdir+../../../ipstatic/hdl/verilog" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/ip_0/sim/gtwizard_ultrascale_v1_7_gtye4_channel.v" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/ip_0/sim/xdma_pcie4c_ip_gt_gtye4_channel_wrapper.v" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/ip_0/sim/gtwizard_ultrascale_v1_7_gtye4_common.v" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/ip_0/sim/xdma_pcie4c_ip_gt_gtye4_common_wrapper.v" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/ip_0/sim/xdma_pcie4c_ip_gt_gtwizard_gtye4.v" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/ip_0/sim/xdma_pcie4c_ip_gt_gtwizard_top.v" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/ip_0/sim/xdma_pcie4c_ip_gt.v" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4c_ip_cxs_remap.v" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4c_ip_bram_16k_int.v" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4c_ip_bram_16k.v" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4c_ip_bram_32k.v" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4c_ip_bram_4k_int.v" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4c_ip_bram_msix.v" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4c_ip_bram_rep_int.v" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4c_ip_bram_rep.v" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4c_ip_bram_tph.v" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4c_ip_bram.v" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4c_ip_gtwizard_top.v" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4c_ip_phy_ff_chain.v" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4c_ip_phy_pipeline.v" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4c_ip_gt_gt_channel.v" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4c_ip_gt_gt_common.v" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4c_ip_gt_phy_clk.v" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4c_ip_gt_phy_rst.v" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4c_ip_gt_phy_rxeq.v" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4c_ip_gt_phy_txeq.v" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4c_ip_sync_cell.v" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4c_ip_sync.v" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4c_ip_gt_cdr_ctrl_on_eidle.v" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4c_ip_gt_receiver_detect_rxterm.v" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4c_ip_gt_phy_wrapper.v" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4c_ip_phy_top.v" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4c_ip_init_ctrl.v" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4c_ip_pl_eq.v" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4c_ip_vf_decode.v" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4c_ip_vf_decode_attr.v" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4c_ip_pipe.v" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4c_ip_seqnum_fifo.v" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4c_ip_sys_clk_gen_ps.v" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/source/xdma_pcie4c_ip_pcie4c_uscale_core_top.v" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/sim/xdma_pcie4c_ip.v" \

vlog -work blk_mem_gen_v8_4_4 -64 "+incdir+../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/source" "+incdir+../../../ipstatic/hdl/verilog" \
"../../../ipstatic/simulation/blk_mem_gen_v8_4.v" \

vlog -work xil_defaultlib -64 "+incdir+../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/source" "+incdir+../../../ipstatic/hdl/verilog" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_1/sim/xdma_v4_1_4_blk_mem_64_reg_be.v" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_2/sim/xdma_v4_1_4_blk_mem_64_noreg_be.v" \

vlog -work xdma_v4_1_4 -64 -sv "+incdir+../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/source" "+incdir+../../../ipstatic/hdl/verilog" \
"../../../ipstatic/hdl/xdma_v4_1_vl_rfs.sv" \

vlog -work xil_defaultlib -64 -sv "+incdir+../../../../XUPVVH.srcs/sources_1/ip/xdma/ip_0/source" "+incdir+../../../ipstatic/hdl/verilog" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/xdma_v4_1/hdl/verilog/xdma_dma_bram_wrap.sv" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/xdma_v4_1/hdl/verilog/xdma_dma_bram_wrap_1024.sv" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/xdma_v4_1/hdl/verilog/xdma_core_top.sv" \
"../../../../XUPVVH.srcs/sources_1/ip/xdma/sim/xdma.sv" \

vlog -work xil_defaultlib \
"glbl.v"

