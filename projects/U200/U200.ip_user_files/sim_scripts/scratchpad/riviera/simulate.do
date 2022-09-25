onbreak {quit -force}
onerror {quit -force}

asim +access +r +m+scratchpad -L xilinx_vip -L xpm -L blk_mem_gen_v8_4_4 -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.scratchpad xil_defaultlib.glbl

do {wave.do}

view wave
view structure

do {scratchpad.udo}

run -all

endsim

quit -force
