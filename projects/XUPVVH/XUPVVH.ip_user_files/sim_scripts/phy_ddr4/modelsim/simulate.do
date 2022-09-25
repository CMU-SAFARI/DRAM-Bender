onbreak {quit -f}
onerror {quit -f}

vsim -voptargs="+acc" -t 1ps -L xpm -L microblaze_v11_0_2 -L xil_defaultlib -L lib_cdc_v1_0_2 -L proc_sys_reset_v5_0_13 -L lmb_v10_v3_0_10 -L lmb_bram_if_cntlr_v4_0_17 -L blk_mem_gen_v8_4_4 -L iomodule_v3_1_5 -L unisims_ver -L unimacro_ver -L secureip -lib xil_defaultlib xil_defaultlib.phy_ddr4 xil_defaultlib.glbl

do {wave.do}

view wave
view structure
view signals

do {phy_ddr4.udo}

run -all

quit -force
