onbreak {quit -force}
onerror {quit -force}

asim -t 1ps +access +r +m+axis_clock_converter -L xpm -L axis_infrastructure_v1_1_0 -L axis_clock_converter_v1_1_21 -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.axis_clock_converter xil_defaultlib.glbl

do {wave.do}

view wave
view structure

do {axis_clock_converter.udo}

run -all

endsim

quit -force
