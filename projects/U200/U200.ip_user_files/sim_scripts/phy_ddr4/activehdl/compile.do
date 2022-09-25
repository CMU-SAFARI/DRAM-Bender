vlib work
vlib activehdl

vlib activehdl/xilinx_vip
vlib activehdl/xpm
vlib activehdl/microblaze_v11_0_4
vlib activehdl/xil_defaultlib
vlib activehdl/lib_cdc_v1_0_2
vlib activehdl/proc_sys_reset_v5_0_13
vlib activehdl/lmb_v10_v3_0_11
vlib activehdl/lmb_bram_if_cntlr_v4_0_19
vlib activehdl/blk_mem_gen_v8_4_4
vlib activehdl/iomodule_v3_1_6

vmap xilinx_vip activehdl/xilinx_vip
vmap xpm activehdl/xpm
vmap microblaze_v11_0_4 activehdl/microblaze_v11_0_4
vmap xil_defaultlib activehdl/xil_defaultlib
vmap lib_cdc_v1_0_2 activehdl/lib_cdc_v1_0_2
vmap proc_sys_reset_v5_0_13 activehdl/proc_sys_reset_v5_0_13
vmap lmb_v10_v3_0_11 activehdl/lmb_v10_v3_0_11
vmap lmb_bram_if_cntlr_v4_0_19 activehdl/lmb_bram_if_cntlr_v4_0_19
vmap blk_mem_gen_v8_4_4 activehdl/blk_mem_gen_v8_4_4
vmap iomodule_v3_1_6 activehdl/iomodule_v3_1_6

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

vlog -work xpm  -sv2k12 "+incdir+../../../../U200.srcs/sources_1/ip/phy_ddr4/ip_1/rtl/map" "+incdir+../../../../U200.srcs/sources_1/ip/phy_ddr4/rtl/ip_top" "+incdir+../../../../U200.srcs/sources_1/ip/phy_ddr4/rtl/cal" "+incdir+/tools/Xilinx/Vivado/2020.2/data/xilinx_vip/include" \
"/tools/Xilinx/Vivado/2020.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"/tools/Xilinx/Vivado/2020.2/data/ip/xpm/xpm_fifo/hdl/xpm_fifo.sv" \
"/tools/Xilinx/Vivado/2020.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -93 \
"/tools/Xilinx/Vivado/2020.2/data/ip/xpm/xpm_VCOMP.vhd" \

vcom -work microblaze_v11_0_4 -93 \
"../../../ipstatic/hdl/microblaze_v11_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -93 \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/bd_0/ip/ip_0/sim/bd_9f2c_microblaze_I_0.vhd" \

vcom -work lib_cdc_v1_0_2 -93 \
"../../../ipstatic/hdl/lib_cdc_v1_0_rfs.vhd" \

vcom -work proc_sys_reset_v5_0_13 -93 \
"../../../ipstatic/hdl/proc_sys_reset_v5_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -93 \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/bd_0/ip/ip_1/sim/bd_9f2c_rst_0_0.vhd" \

vcom -work lmb_v10_v3_0_11 -93 \
"../../../ipstatic/hdl/lmb_v10_v3_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -93 \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/bd_0/ip/ip_2/sim/bd_9f2c_ilmb_0.vhd" \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/bd_0/ip/ip_3/sim/bd_9f2c_dlmb_0.vhd" \

vcom -work lmb_bram_if_cntlr_v4_0_19 -93 \
"../../../ipstatic/hdl/lmb_bram_if_cntlr_v4_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -93 \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/bd_0/ip/ip_4/sim/bd_9f2c_dlmb_cntlr_0.vhd" \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/bd_0/ip/ip_5/sim/bd_9f2c_ilmb_cntlr_0.vhd" \

vlog -work blk_mem_gen_v8_4_4  -v2k5 "+incdir+../../../../U200.srcs/sources_1/ip/phy_ddr4/ip_1/rtl/map" "+incdir+../../../../U200.srcs/sources_1/ip/phy_ddr4/rtl/ip_top" "+incdir+../../../../U200.srcs/sources_1/ip/phy_ddr4/rtl/cal" "+incdir+/tools/Xilinx/Vivado/2020.2/data/xilinx_vip/include" \
"../../../ipstatic/simulation/blk_mem_gen_v8_4.v" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../U200.srcs/sources_1/ip/phy_ddr4/ip_1/rtl/map" "+incdir+../../../../U200.srcs/sources_1/ip/phy_ddr4/rtl/ip_top" "+incdir+../../../../U200.srcs/sources_1/ip/phy_ddr4/rtl/cal" "+incdir+/tools/Xilinx/Vivado/2020.2/data/xilinx_vip/include" \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/bd_0/ip/ip_6/sim/bd_9f2c_lmb_bram_I_0.v" \

vcom -work xil_defaultlib -93 \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/bd_0/ip/ip_7/sim/bd_9f2c_second_dlmb_cntlr_0.vhd" \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/bd_0/ip/ip_8/sim/bd_9f2c_second_ilmb_cntlr_0.vhd" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../U200.srcs/sources_1/ip/phy_ddr4/ip_1/rtl/map" "+incdir+../../../../U200.srcs/sources_1/ip/phy_ddr4/rtl/ip_top" "+incdir+../../../../U200.srcs/sources_1/ip/phy_ddr4/rtl/cal" "+incdir+/tools/Xilinx/Vivado/2020.2/data/xilinx_vip/include" \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/bd_0/ip/ip_9/sim/bd_9f2c_second_lmb_bram_I_0.v" \

vcom -work iomodule_v3_1_6 -93 \
"../../../ipstatic/hdl/iomodule_v3_1_vh_rfs.vhd" \

vcom -work xil_defaultlib -93 \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/bd_0/ip/ip_10/sim/bd_9f2c_iomodule_0_0.vhd" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../U200.srcs/sources_1/ip/phy_ddr4/ip_1/rtl/map" "+incdir+../../../../U200.srcs/sources_1/ip/phy_ddr4/rtl/ip_top" "+incdir+../../../../U200.srcs/sources_1/ip/phy_ddr4/rtl/cal" "+incdir+/tools/Xilinx/Vivado/2020.2/data/xilinx_vip/include" \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/bd_0/sim/bd_9f2c.v" \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/ip_0/sim/phy_ddr4_microblaze_mcs.v" \

vlog -work xil_defaultlib  -sv2k12 "+incdir+../../../../U200.srcs/sources_1/ip/phy_ddr4/ip_1/rtl/map" "+incdir+../../../../U200.srcs/sources_1/ip/phy_ddr4/rtl/ip_top" "+incdir+../../../../U200.srcs/sources_1/ip/phy_ddr4/rtl/cal" "+incdir+/tools/Xilinx/Vivado/2020.2/data/xilinx_vip/include" \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/ip_1/rtl/phy/phy_ddr4_phy_ddr4.sv" \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/ip_1/rtl/phy/ddr4_phy_v2_2_xiphy_behav.sv" \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/ip_1/rtl/phy/ddr4_phy_v2_2_xiphy.sv" \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/ip_1/rtl/iob/ddr4_phy_v2_2_iob_byte.sv" \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/ip_1/rtl/iob/ddr4_phy_v2_2_iob.sv" \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/ip_1/rtl/clocking/ddr4_phy_v2_2_pll.sv" \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/ip_1/rtl/xiphy_files/ddr4_phy_v2_2_xiphy_tristate_wrapper.sv" \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/ip_1/rtl/xiphy_files/ddr4_phy_v2_2_xiphy_riuor_wrapper.sv" \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/ip_1/rtl/xiphy_files/ddr4_phy_v2_2_xiphy_control_wrapper.sv" \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/ip_1/rtl/xiphy_files/ddr4_phy_v2_2_xiphy_byte_wrapper.sv" \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/ip_1/rtl/xiphy_files/ddr4_phy_v2_2_xiphy_bitslice_wrapper.sv" \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/ip_1/rtl/ip_top/phy_ddr4_phy.sv" \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/rtl/clocking/ddr4_v2_2_infrastructure.sv" \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/rtl/cal/ddr4_v2_2_cal_xsdb_bram.sv" \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/rtl/cal/ddr4_v2_2_cal_write.sv" \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/rtl/cal/ddr4_v2_2_cal_wr_byte.sv" \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/rtl/cal/ddr4_v2_2_cal_wr_bit.sv" \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/rtl/cal/ddr4_v2_2_cal_sync.sv" \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/rtl/cal/ddr4_v2_2_cal_read.sv" \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/rtl/cal/ddr4_v2_2_cal_rd_en.sv" \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/rtl/cal/ddr4_v2_2_cal_pi.sv" \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/rtl/cal/ddr4_v2_2_cal_mc_odt.sv" \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/rtl/cal/ddr4_v2_2_cal_debug_microblaze.sv" \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/rtl/cal/ddr4_v2_2_cal_cplx_data.sv" \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/rtl/cal/ddr4_v2_2_cal_cplx.sv" \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/rtl/cal/ddr4_v2_2_cal_config_rom.sv" \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/rtl/cal/ddr4_v2_2_cal_addr_decode.sv" \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/rtl/cal/ddr4_v2_2_cal_top.sv" \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/rtl/cal/ddr4_v2_2_cal_xsdb_arbiter.sv" \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/rtl/cal/ddr4_v2_2_cal.sv" \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/rtl/cal/ddr4_v2_2_chipscope_xsdb_slave.sv" \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/rtl/cal/ddr4_v2_2_dp_AB9.sv" \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/rtl/ip_top/phy_ddr4_ddr4.sv" \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/rtl/cal/phy_ddr4_ddr4_cal_riu.sv" \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/rtl/ip_top/phy_ddr4.sv" \
"../../../../U200.srcs/sources_1/ip/phy_ddr4/tb/microblaze_mcs_0.sv" \

vlog -work xil_defaultlib \
"glbl.v"

