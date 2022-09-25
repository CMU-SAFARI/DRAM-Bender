onbreak {quit -f}
onerror {quit -f}

vsim -voptargs="+acc" -t 1ps -L xpm -L gtwizard_ultrascale_v1_7_7 -L xil_defaultlib -L blk_mem_gen_v8_4_4 -L xdma_v4_1_4 -L unisims_ver -L unimacro_ver -L secureip -lib xil_defaultlib xil_defaultlib.xdma xil_defaultlib.glbl

do {wave.do}

view wave
view structure
view signals

do {xdma.udo}

run -all

quit -force
