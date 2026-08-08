onbreak {quit -f}
onerror {quit -f}

vsim -lib xil_defaultlib pr_read_mem_opt

do {wave.do}

view wave
view structure
view signals

do {pr_read_mem.udo}

run -all

quit -force
