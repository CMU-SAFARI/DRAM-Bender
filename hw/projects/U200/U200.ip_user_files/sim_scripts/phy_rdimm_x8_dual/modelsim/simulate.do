onbreak {quit -f}
onerror {quit -f}

vsim -voptargs="+acc" -L xilinx_vip -L xpm -L microblaze_v11_0_4 -L xil_defaultlib -L lib_cdc_v1_0_2 -L proc_sys_reset_v5_0_13 -L lmb_v10_v3_0_11 -L lmb_bram_if_cntlr_v4_0_19 -L blk_mem_gen_v8_4_4 -L iomodule_v3_1_6 -L unisims_ver -L unimacro_ver -L secureip -lib xil_defaultlib xil_defaultlib.phy_rdimm_x8_dual xil_defaultlib.glbl

do {wave.do}

view wave
view structure
view signals

do {phy_rdimm_x8_dual.udo}

run -all

quit -force
