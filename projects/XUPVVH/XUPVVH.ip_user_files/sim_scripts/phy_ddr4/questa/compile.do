vlib questa_lib/work
vlib questa_lib/msim

vlib questa_lib/msim/xpm
vlib questa_lib/msim/microblaze_v11_0_2
vlib questa_lib/msim/xil_defaultlib
vlib questa_lib/msim/lib_cdc_v1_0_2
vlib questa_lib/msim/proc_sys_reset_v5_0_13
vlib questa_lib/msim/lmb_v10_v3_0_10
vlib questa_lib/msim/lmb_bram_if_cntlr_v4_0_17
vlib questa_lib/msim/blk_mem_gen_v8_4_4
vlib questa_lib/msim/iomodule_v3_1_5

vmap xpm questa_lib/msim/xpm
vmap microblaze_v11_0_2 questa_lib/msim/microblaze_v11_0_2
vmap xil_defaultlib questa_lib/msim/xil_defaultlib
vmap lib_cdc_v1_0_2 questa_lib/msim/lib_cdc_v1_0_2
vmap proc_sys_reset_v5_0_13 questa_lib/msim/proc_sys_reset_v5_0_13
vmap lmb_v10_v3_0_10 questa_lib/msim/lmb_v10_v3_0_10
vmap lmb_bram_if_cntlr_v4_0_17 questa_lib/msim/lmb_bram_if_cntlr_v4_0_17
vmap blk_mem_gen_v8_4_4 questa_lib/msim/blk_mem_gen_v8_4_4
vmap iomodule_v3_1_5 questa_lib/msim/iomodule_v3_1_5

vlog -work xpm -64 -sv "+incdir+../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/ip_1/rtl/map" "+incdir+../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/rtl/ip_top" "+incdir+../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/rtl/cal" \
"/tools/Xilinx/Vivado/2019.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"/tools/Xilinx/Vivado/2019.2/data/ip/xpm/xpm_fifo/hdl/xpm_fifo.sv" \
"/tools/Xilinx/Vivado/2019.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -64 -93 \
"/tools/Xilinx/Vivado/2019.2/data/ip/xpm/xpm_VCOMP.vhd" \

vcom -work microblaze_v11_0_2 -64 -93 \
"../../../ipstatic/hdl/microblaze_v11_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -64 -93 \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/bd_0/ip/ip_0/sim/bd_9f2c_microblaze_I_0.vhd" \

vcom -work lib_cdc_v1_0_2 -64 -93 \
"../../../ipstatic/hdl/lib_cdc_v1_0_rfs.vhd" \

vcom -work proc_sys_reset_v5_0_13 -64 -93 \
"../../../ipstatic/hdl/proc_sys_reset_v5_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -64 -93 \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/bd_0/ip/ip_1/sim/bd_9f2c_rst_0_0.vhd" \

vcom -work lmb_v10_v3_0_10 -64 -93 \
"../../../ipstatic/hdl/lmb_v10_v3_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -64 -93 \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/bd_0/ip/ip_2/sim/bd_9f2c_ilmb_0.vhd" \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/bd_0/ip/ip_3/sim/bd_9f2c_dlmb_0.vhd" \

vcom -work lmb_bram_if_cntlr_v4_0_17 -64 -93 \
"../../../ipstatic/hdl/lmb_bram_if_cntlr_v4_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -64 -93 \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/bd_0/ip/ip_4/sim/bd_9f2c_dlmb_cntlr_0.vhd" \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/bd_0/ip/ip_5/sim/bd_9f2c_ilmb_cntlr_0.vhd" \

vlog -work blk_mem_gen_v8_4_4 -64 "+incdir+../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/ip_1/rtl/map" "+incdir+../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/rtl/ip_top" "+incdir+../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/rtl/cal" \
"../../../ipstatic/simulation/blk_mem_gen_v8_4.v" \

vlog -work xil_defaultlib -64 "+incdir+../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/ip_1/rtl/map" "+incdir+../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/rtl/ip_top" "+incdir+../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/rtl/cal" \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/bd_0/ip/ip_6/sim/bd_9f2c_lmb_bram_I_0.v" \

vcom -work xil_defaultlib -64 -93 \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/bd_0/ip/ip_7/sim/bd_9f2c_second_dlmb_cntlr_0.vhd" \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/bd_0/ip/ip_8/sim/bd_9f2c_second_ilmb_cntlr_0.vhd" \

vlog -work xil_defaultlib -64 "+incdir+../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/ip_1/rtl/map" "+incdir+../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/rtl/ip_top" "+incdir+../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/rtl/cal" \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/bd_0/ip/ip_9/sim/bd_9f2c_second_lmb_bram_I_0.v" \

vcom -work iomodule_v3_1_5 -64 -93 \
"../../../ipstatic/hdl/iomodule_v3_1_vh_rfs.vhd" \

vcom -work xil_defaultlib -64 -93 \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/bd_0/ip/ip_10/sim/bd_9f2c_iomodule_0_0.vhd" \

vlog -work xil_defaultlib -64 "+incdir+../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/ip_1/rtl/map" "+incdir+../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/rtl/ip_top" "+incdir+../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/rtl/cal" \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/bd_0/sim/bd_9f2c.v" \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/ip_0/sim/phy_ddr4_microblaze_mcs.v" \

vlog -work xil_defaultlib -64 -sv "+incdir+../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/ip_1/rtl/map" "+incdir+../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/rtl/ip_top" "+incdir+../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/rtl/cal" \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/ip_1/rtl/phy/phy_ddr4_phy_ddr4.sv" \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/ip_1/rtl/phy/ddr4_phy_v2_2_xiphy_behav.sv" \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/ip_1/rtl/phy/ddr4_phy_v2_2_xiphy.sv" \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/ip_1/rtl/iob/ddr4_phy_v2_2_iob_byte.sv" \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/ip_1/rtl/iob/ddr4_phy_v2_2_iob.sv" \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/ip_1/rtl/clocking/ddr4_phy_v2_2_pll.sv" \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/ip_1/rtl/xiphy_files/ddr4_phy_v2_2_xiphy_tristate_wrapper.sv" \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/ip_1/rtl/xiphy_files/ddr4_phy_v2_2_xiphy_riuor_wrapper.sv" \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/ip_1/rtl/xiphy_files/ddr4_phy_v2_2_xiphy_control_wrapper.sv" \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/ip_1/rtl/xiphy_files/ddr4_phy_v2_2_xiphy_byte_wrapper.sv" \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/ip_1/rtl/xiphy_files/ddr4_phy_v2_2_xiphy_bitslice_wrapper.sv" \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/ip_1/rtl/ip_top/phy_ddr4_phy.sv" \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/rtl/clocking/ddr4_v2_2_infrastructure.sv" \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/rtl/cal/ddr4_v2_2_cal_xsdb_bram.sv" \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/rtl/cal/ddr4_v2_2_cal_write.sv" \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/rtl/cal/ddr4_v2_2_cal_wr_byte.sv" \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/rtl/cal/ddr4_v2_2_cal_wr_bit.sv" \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/rtl/cal/ddr4_v2_2_cal_sync.sv" \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/rtl/cal/ddr4_v2_2_cal_read.sv" \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/rtl/cal/ddr4_v2_2_cal_rd_en.sv" \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/rtl/cal/ddr4_v2_2_cal_pi.sv" \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/rtl/cal/ddr4_v2_2_cal_mc_odt.sv" \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/rtl/cal/ddr4_v2_2_cal_debug_microblaze.sv" \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/rtl/cal/ddr4_v2_2_cal_cplx_data.sv" \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/rtl/cal/ddr4_v2_2_cal_cplx.sv" \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/rtl/cal/ddr4_v2_2_cal_config_rom.sv" \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/rtl/cal/ddr4_v2_2_cal_addr_decode.sv" \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/rtl/cal/ddr4_v2_2_cal_top.sv" \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/rtl/cal/ddr4_v2_2_cal_xsdb_arbiter.sv" \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/rtl/cal/ddr4_v2_2_cal.sv" \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/rtl/cal/ddr4_v2_2_chipscope_xsdb_slave.sv" \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/rtl/cal/ddr4_v2_2_dp_AB9.sv" \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/rtl/ip_top/phy_ddr4_ddr4.sv" \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/rtl/cal/phy_ddr4_ddr4_cal_riu.sv" \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/rtl/ip_top/phy_ddr4.sv" \
"../../../../XUPVVH.srcs/sources_1/ip/phy_ddr4/tb/microblaze_mcs_0.sv" \

vlog -work xil_defaultlib \
"glbl.v"

