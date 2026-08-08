onbreak {quit -f}
onerror {quit -f}

vsim -lib xil_defaultlib phy_rdimm_x8_dual_opt

do {wave.do}

view wave
view structure
view signals

do {phy_rdimm_x8_dual.udo}

run -all

quit -force
