onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib instr_blk_mem_sim_opt

do {wave.do}

view wave
view structure
view signals

do {instr_blk_mem_sim.udo}

run -all

quit -force
