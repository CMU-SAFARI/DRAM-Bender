onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib scratchpad_opt

do {wave.do}

view wave
view structure
view signals

do {scratchpad.udo}

run -all

quit -force
