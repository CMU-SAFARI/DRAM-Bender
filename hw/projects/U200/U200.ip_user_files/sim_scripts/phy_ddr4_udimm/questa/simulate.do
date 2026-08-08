onbreak {quit -f}
onerror {quit -f}

vsim -lib xil_defaultlib phy_ddr4_udimm_opt

do {wave.do}

view wave
view structure
view signals

do {phy_ddr4_udimm.udo}

run -all

quit -force
