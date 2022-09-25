onbreak {quit -force}
onerror {quit -force}

asim +access +r +m+instr_blk_mem_sim -L xilinx_vip -L xpm -L blk_mem_gen_v8_4_4 -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.instr_blk_mem_sim xil_defaultlib.glbl

do {wave.do}

view wave
view structure

do {instr_blk_mem_sim.udo}

run -all

endsim

quit -force
