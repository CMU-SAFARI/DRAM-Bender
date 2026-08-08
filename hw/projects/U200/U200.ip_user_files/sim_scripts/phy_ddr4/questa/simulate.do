onbreak {quit -f}
onerror {quit -f}

vsim -lib xil_defaultlib phy_ddr4_opt

do {wave.do}

view wave
view structure
view signals

do {phy_ddr4.udo}

run -all

quit -force
