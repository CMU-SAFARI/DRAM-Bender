onbreak {quit -f}
onerror {quit -f}

vsim -lib xil_defaultlib zq_calib_mem_opt

do {wave.do}

view wave
view structure
view signals

do {zq_calib_mem.udo}

run -all

quit -force
