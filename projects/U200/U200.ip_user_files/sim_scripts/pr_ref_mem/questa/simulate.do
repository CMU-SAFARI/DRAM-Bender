onbreak {quit -f}
onerror {quit -f}

vsim -lib xil_defaultlib pr_ref_mem_opt

do {wave.do}

view wave
view structure
view signals

do {pr_ref_mem.udo}

run -all

quit -force
