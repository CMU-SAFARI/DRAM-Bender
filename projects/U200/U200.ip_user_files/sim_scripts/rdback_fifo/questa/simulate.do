onbreak {quit -f}
onerror {quit -f}

vsim -lib xil_defaultlib rdback_fifo_opt

do {wave.do}

view wave
view structure
view signals

do {rdback_fifo.udo}

run -all

quit -force
