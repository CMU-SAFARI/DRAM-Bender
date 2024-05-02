######################################################################
#
# File name : sim_tb_top_compile.do
# Created on: Wed Aug 31 17:31:20 CEST 2022
#
# Auto generated by Vivado for 'behavioral' simulation
#
######################################################################
vlib questa_lib/work
vlib questa_lib/msim

vlib questa_lib/msim/xil_defaultlib

vmap xil_defaultlib questa_lib/msim/xil_defaultlib

vlog -64 -incr +notimingchecks -work xil_defaultlib  "+incdir+../../../../verilog" "+incdir+../../../../../../sources/hdl/header_verilog" "+incdir+../../../../XUPVVH.srcs/sources_1/ip/hbm_0/hdl/rtl" "+incdir+../../../../XUPVVH.ip_user_files/ipstatic/verif/model" "+incdir+/usr/pack/vitis-2020.2-kgf/Vivado/2020.2/data/xilinx_vip/include" \
"../../../../XUPVVH.srcs/sources_1/ip/rdback_fifo/sim/rdback_fifo.v" \
"../../../../XUPVVH.srcs/sources_1/ip/instr_blk_mem/sim/instr_blk_mem.v" \
"../../../../XUPVVH.srcs/sources_1/ip/instr_blk_mem_sim/sim/instr_blk_mem_sim.v" \
"../../../../XUPVVH.srcs/sources_1/ip/pr_ref_mem/sim/pr_ref_mem.v" \
"../../../../XUPVVH.srcs/sources_1/ip/zq_calib_mem/sim/zq_calib_mem.v" \
"../../../../XUPVVH.srcs/sources_1/ip/pr_read_mem/sim/pr_read_mem.v" \
"../../../../XUPVVH.srcs/sources_1/ip/scratchpad/sim/scratchpad.v" \
"../../../../XUPVVH.srcs/sources_1/ip/cdc_fifo/sim/cdc_fifo.v" \

vlog -64 -incr +notimingchecks -sv -L hbm_v1_0_9 -work xil_defaultlib  "+incdir+../../../../verilog" "+incdir+../../../../../../sources/hdl/header_verilog" "+incdir+../../../../XUPVVH.srcs/sources_1/ip/hbm_0/hdl/rtl" "+incdir+../../../../XUPVVH.ip_user_files/ipstatic/verif/model" "+incdir+/usr/pack/vitis-2020.2-kgf/Vivado/2020.2/data/xilinx_vip/include" \
"../../../../XUPVVH.srcs/sources_1/ip/hbm_0/hdl/rtl/hbm_v1_0_9.sv" \
"../../../../XUPVVH.srcs/sources_1/ip/hbm_0/verif/model/hbm_model.sv" \
"../../../../XUPVVH.srcs/sources_1/ip/hbm_0/sim/hbm_0.sv" \

vlog -64 -incr +notimingchecks -work xil_defaultlib  "+incdir+../../../../verilog" "+incdir+../../../../../../sources/hdl/header_verilog" "+incdir+../../../../XUPVVH.srcs/sources_1/ip/hbm_0/hdl/rtl" "+incdir+../../../../XUPVVH.ip_user_files/ipstatic/verif/model" "+incdir+/usr/pack/vitis-2020.2-kgf/Vivado/2020.2/data/xilinx_vip/include" \
"../../../../XUPVVH.srcs/sources_1/new/HBM_adapter.v" \
"../../../../XUPVVH.srcs/sources_1/new/HBM_interface.v" \
"../../../../XUPVVH.srcs/sources_1/new/cdc_HBM_to_rbe.v" \
"../../../../XUPVVH.srcs/sources_1/new/cmd_buf.v" \
"../../../../XUPVVH.srcs/sources_1/imports/new/cmd_gen.v" \
"../../../../XUPVVH.srcs/sources_1/imports/new/controller_top.v" \
"../../../../../../sources/hdl/verilog/ddr_pipeline.v" \
"../../../../../../sources/hdl/verilog/decode_stage.v" \
"../../../../../../sources/hdl/verilog/diff_shift_reg.v" \
"../../../../../../sources/hdl/verilog/exe_pipeline.v" \
"../../../../../../sources/hdl/verilog/execute_stage.v" \
"../../../../../../sources/hdl/verilog/fetch_stage.v" \
"../../../../../../sources/hdl/verilog/frontend.v" \
"../../../../../../sources/hdl/verilog/maintenance_controller.v" \
"../../../../../../sources/hdl/verilog/pop_count4.v" \
"../../../../../../sources/hdl/verilog/pre_decode.v" \
"../../../../../../sources/hdl/verilog/readback_engine.v" \
"../../../../../../sources/hdl/verilog/register_file.v" \
"../../../../../../sources/hdl/verilog/softmc_pipeline.v" \
"../../../../verilog/softmc_top.v" \
"../../../../XUPVVH.srcs/sim_1/new/sim_tb_top.v" \

# compile glbl module
vlog -work xil_defaultlib "glbl.v"

