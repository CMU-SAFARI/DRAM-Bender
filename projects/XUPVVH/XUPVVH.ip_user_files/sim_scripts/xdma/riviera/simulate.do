onbreak {quit -force}
onerror {quit -force}

asim -t 1ps +access +r +m+xdma -L xpm -L gtwizard_ultrascale_v1_7_7 -L xil_defaultlib -L blk_mem_gen_v8_4_4 -L xdma_v4_1_4 -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.xdma xil_defaultlib.glbl

do {wave.do}

view wave
view structure

do {xdma.udo}

run -all

endsim

quit -force
