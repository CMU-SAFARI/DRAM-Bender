onbreak {quit -f}
onerror {quit -f}

vsim -lib xil_defaultlib scratchpad_opt

do {wave.do}

view wave
view structure
view signals

do {scratchpad.udo}

run -all

quit -force
