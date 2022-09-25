##############################################
##########      Configuration       ##########
##############################################
set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property CONFIG_MODE SPIx4  [current_design]
set_property BITSTREAM.CONFIG.USR_ACCESS TIMESTAMP [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 85.0 [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
##############################################
##########          PCIe            ##########
##############################################
# set_property LOC PCIE_3_1_X0Y1 [get_cells xdma_i/inst/pcie3_ip_i/inst/pcie3_uscale_top_inst/pcie3_uscale_wrapper_inst/PCIE_3_1_inst]
set_property IOSTANDARD LVCMOS12 [get_ports pcie_rst]
set_property PACKAGE_PIN AR26 [get_ports pcie_rst]
set_property PULLUP true [get_ports pcie_rst]
set_property PACKAGE_PIN AT10 [get_ports clk_ref_n]
create_clock -period 10.000 -name refclk_100 [get_ports clk_ref_p]
##############################################
##########      Clocks/Reset        ##########
##############################################
create_clock -period 10.000 [get_ports c0_sys_clk_p]
set_clock_groups -asynchronous -group [get_clocks c0_sys_clk_p -include_generated_clocks]

set_property IOSTANDARD DIFF_SSTL12_DCI [get_ports c0_sys_clk_p]
set_property ODT RTT_48 [get_ports c0_sys_clk_p]
set_property PACKAGE_PIN AV18  [get_ports c0_sys_clk_p]
set_property IOSTANDARD DIFF_SSTL12_DCI [get_ports c0_sys_clk_n]
set_property ODT RTT_48 [get_ports c0_sys_clk_n]

set_property IOSTANDARD LVCMOS18 [get_ports sys_rst_l]
set_property PACKAGE_PIN AT23 [get_ports sys_rst_l]
##############################################
##########   DDR4 Pin Properties    ##########
##############################################
### RDIMM 1 - x4
set_property PACKAGE_PIN BE17 [ get_ports "c0_ddr4_dqs_t[17]" ]
set_property PACKAGE_PIN BF17 [ get_ports "c0_ddr4_dqs_c[17]" ]
set_property PACKAGE_PIN BF19 [ get_ports "c0_ddr4_dq[71]" ]
set_property PACKAGE_PIN BF18 [ get_ports "c0_ddr4_dq[70]" ]
set_property PACKAGE_PIN BD18 [ get_ports "c0_ddr4_dq[69]" ]
set_property PACKAGE_PIN BE18 [ get_ports "c0_ddr4_dq[68]" ]
set_property PACKAGE_PIN BC19 [ get_ports "c0_ddr4_dqs_t[16]" ]
set_property PACKAGE_PIN BD19 [ get_ports "c0_ddr4_dqs_c[16]" ]
set_property PACKAGE_PIN BB17 [ get_ports "c0_ddr4_dq[67]" ]
set_property PACKAGE_PIN BC17 [ get_ports "c0_ddr4_dq[66]" ]
set_property PACKAGE_PIN BB19 [ get_ports "c0_ddr4_dq[65]" ]
set_property PACKAGE_PIN BC18 [ get_ports "c0_ddr4_dq[64]" ]
set_property PACKAGE_PIN AY17 [ get_ports "c0_ddr4_reset_n" ]
#set_property PACKAGE_PIN BA17 [ get_ports "m0_ddr4_c[0]" ]
#set_property PACKAGE_PIN AY18 [ get_ports "m0_ddr4_c[1]" ]
set_property PACKAGE_PIN BA18 [ get_ports "c0_ddr4_cs_n[0]" ]
#set_property PACKAGE_PIN AW20 [ get_ports "m0_ddr4_cs_n[1]" ]
set_property PACKAGE_PIN AY20 [ get_ports "c0_ddr4_cke[0]" ]
#set_property PACKAGE_PIN AV21 [ get_ports "m0_ddr4_cke[1]" ]
set_property PACKAGE_PIN AW21 [ get_ports "c0_ddr4_odt[0]" ]
#set_property PACKAGE_PIN AV19 [ get_ports "m0_ddr4_odt[1]" ]
set_property PACKAGE_PIN AW19 [ get_ports "c0_ddr4_parity" ]
set_property PACKAGE_PIN AV17 [ get_ports "c0_ddr4_act_n" ]
set_property PACKAGE_PIN AT19 [ get_ports "c0_ddr4_ba[0]" ]
set_property PACKAGE_PIN AU19 [ get_ports "c0_ddr4_ba[1]" ]
set_property PACKAGE_PIN AT20 [ get_ports "c0_ddr4_bg[0]" ]
set_property PACKAGE_PIN AU20 [ get_ports "c0_ddr4_bg[1]" ]
set_property PACKAGE_PIN AT18 [ get_ports "c0_ddr4_adr[0]" ]
set_property PACKAGE_PIN AU17 [ get_ports "c0_ddr4_adr[1]" ]
set_property PACKAGE_PIN AR17 [ get_ports "c0_ddr4_ck_t" ]
set_property PACKAGE_PIN AT17 [ get_ports "c0_ddr4_ck_c" ]
set_property PACKAGE_PIN AP18 [ get_ports "c0_ddr4_adr[2]" ]
set_property PACKAGE_PIN AR18 [ get_ports "c0_ddr4_adr[3]" ]
set_property PACKAGE_PIN AP20 [ get_ports "c0_ddr4_adr[4]" ]
set_property PACKAGE_PIN AR20 [ get_ports "c0_ddr4_adr[5]" ]
set_property PACKAGE_PIN AU21 [ get_ports "c0_ddr4_adr[6]" ]
set_property PACKAGE_PIN AN18 [ get_ports "c0_ddr4_adr[7]" ]
set_property PACKAGE_PIN AN17 [ get_ports "c0_ddr4_adr[8]" ]
set_property PACKAGE_PIN AN19 [ get_ports "c0_ddr4_adr[9]" ]
set_property PACKAGE_PIN AP19 [ get_ports "c0_ddr4_adr[10]" ]
set_property PACKAGE_PIN AM16 [ get_ports "c0_ddr4_adr[11]" ]
set_property PACKAGE_PIN AN16 [ get_ports "c0_ddr4_adr[12]" ]
#set_property PACKAGE_PIN AM17 [ get_ports "m0_ddr4_c[2]" ]
set_property PACKAGE_PIN AL19 [ get_ports "c0_ddr4_adr[13]" ]
set_property PACKAGE_PIN AM19 [ get_ports "c0_ddr4_adr[14]" ]
set_property PACKAGE_PIN AL20 [ get_ports "c0_ddr4_adr[15]" ]
set_property PACKAGE_PIN AM20 [ get_ports "c0_ddr4_adr[16]" ]
#set_property PACKAGE_PIN AP16 [ get_ports "m0_ddr4_adr[17]" ]
set_property PACKAGE_PIN BF28 [ get_ports "c0_ddr4_dqs_t[7]" ]
set_property PACKAGE_PIN BF29 [ get_ports "c0_ddr4_dqs_c[7]" ]
set_property PACKAGE_PIN BE27 [ get_ports "c0_ddr4_dq[31]" ]
set_property PACKAGE_PIN BF27 [ get_ports "c0_ddr4_dq[30]" ]
set_property PACKAGE_PIN BD28 [ get_ports "c0_ddr4_dq[29]" ]
set_property PACKAGE_PIN BE28 [ get_ports "c0_ddr4_dq[28]" ]
set_property PACKAGE_PIN BD26 [ get_ports "c0_ddr4_dqs_t[6]" ]
set_property PACKAGE_PIN BE26 [ get_ports "c0_ddr4_dqs_c[6]" ]
set_property PACKAGE_PIN BE25 [ get_ports "c0_ddr4_dq[27]" ]
set_property PACKAGE_PIN BF25 [ get_ports "c0_ddr4_dq[26]" ]
set_property PACKAGE_PIN BC26 [ get_ports "c0_ddr4_dq[25]" ]
set_property PACKAGE_PIN BC27 [ get_ports "c0_ddr4_dq[24]" ]
set_property PACKAGE_PIN BA25 [ get_ports "c0_ddr4_dqs_t[5]" ]
set_property PACKAGE_PIN BB25 [ get_ports "c0_ddr4_dqs_c[5]" ]
set_property PACKAGE_PIN BB26 [ get_ports "c0_ddr4_dq[23]" ]
set_property PACKAGE_PIN BB27 [ get_ports "c0_ddr4_dq[22]" ]
set_property PACKAGE_PIN BA27 [ get_ports "c0_ddr4_dq[21]" ]
set_property PACKAGE_PIN BA28 [ get_ports "c0_ddr4_dq[20]" ]
set_property PACKAGE_PIN AW25 [ get_ports "c0_ddr4_dqs_t[4]" ]
set_property PACKAGE_PIN AY25 [ get_ports "c0_ddr4_dqs_c[4]" ]
set_property PACKAGE_PIN AY26 [ get_ports "c0_ddr4_dq[19]" ]
set_property PACKAGE_PIN AY27 [ get_ports "c0_ddr4_dq[18]" ]
set_property PACKAGE_PIN AW28 [ get_ports "c0_ddr4_dq[17]" ]
set_property PACKAGE_PIN AY28 [ get_ports "c0_ddr4_dq[16]" ]
set_property PACKAGE_PIN AV26 [ get_ports "c0_ddr4_dqs_t[3]" ]
set_property PACKAGE_PIN AW26 [ get_ports "c0_ddr4_dqs_c[3]" ]
set_property PACKAGE_PIN AV27 [ get_ports "c0_ddr4_dq[15]" ]
set_property PACKAGE_PIN AV28 [ get_ports "c0_ddr4_dq[14]" ]
set_property PACKAGE_PIN AU26 [ get_ports "c0_ddr4_dq[13]" ]
set_property PACKAGE_PIN AU27 [ get_ports "c0_ddr4_dq[12]" ]
set_property PACKAGE_PIN AR25 [ get_ports "c0_ddr4_dqs_t[2]" ]
set_property PACKAGE_PIN AT25 [ get_ports "c0_ddr4_dqs_c[2]" ]
set_property PACKAGE_PIN AR27 [ get_ports "c0_ddr4_dq[11]" ]
set_property PACKAGE_PIN AT27 [ get_ports "c0_ddr4_dq[10]" ]
set_property PACKAGE_PIN AR28 [ get_ports "c0_ddr4_dq[9]" ]
set_property PACKAGE_PIN AT28 [ get_ports "c0_ddr4_dq[8]" ]
#set_property PACKAGE_PIN AU25 [ get_ports "m0_ddr4_c[3]" ]
set_property PACKAGE_PIN AP25 [ get_ports "c0_ddr4_dqs_t[1]" ]
set_property PACKAGE_PIN AP26 [ get_ports "c0_ddr4_dqs_c[1]" ]
set_property PACKAGE_PIN AN28 [ get_ports "c0_ddr4_dq[7]" ]
set_property PACKAGE_PIN AP28 [ get_ports "c0_ddr4_dq[6]" ]
set_property PACKAGE_PIN AL25 [ get_ports "c0_ddr4_dq[5]" ]
set_property PACKAGE_PIN AM25 [ get_ports "c0_ddr4_dq[4]" ]
set_property PACKAGE_PIN AM26 [ get_ports "c0_ddr4_dqs_t[0]" ]
set_property PACKAGE_PIN AN26 [ get_ports "c0_ddr4_dqs_c[0]" ]
set_property PACKAGE_PIN AM27 [ get_ports "c0_ddr4_dq[3]" ]
set_property PACKAGE_PIN AN27 [ get_ports "c0_ddr4_dq[2]" ]
set_property PACKAGE_PIN AL27 [ get_ports "c0_ddr4_dq[1]" ]
set_property PACKAGE_PIN AL28 [ get_ports "c0_ddr4_dq[0]" ]
set_property PACKAGE_PIN BF14 [ get_ports "c0_ddr4_dqs_t[15]" ]
set_property PACKAGE_PIN BF13 [ get_ports "c0_ddr4_dqs_c[15]" ]
set_property PACKAGE_PIN BE15 [ get_ports "c0_ddr4_dq[63]" ]
set_property PACKAGE_PIN BF15 [ get_ports "c0_ddr4_dq[62]" ]
set_property PACKAGE_PIN BD16 [ get_ports "c0_ddr4_dq[61]" ]
set_property PACKAGE_PIN BE16 [ get_ports "c0_ddr4_dq[60]" ]
set_property PACKAGE_PIN BD13 [ get_ports "c0_ddr4_dqs_t[14]" ]
set_property PACKAGE_PIN BE13 [ get_ports "c0_ddr4_dqs_c[14]" ]
set_property PACKAGE_PIN BD15 [ get_ports "c0_ddr4_dq[59]" ]
set_property PACKAGE_PIN BD14 [ get_ports "c0_ddr4_dq[58]" ]
set_property PACKAGE_PIN BC14 [ get_ports "c0_ddr4_dq[57]" ]
set_property PACKAGE_PIN BC13 [ get_ports "c0_ddr4_dq[56]" ]
set_property PACKAGE_PIN BA12 [ get_ports "c0_ddr4_dqs_t[13]" ]
set_property PACKAGE_PIN BB12 [ get_ports "c0_ddr4_dqs_c[13]" ]
set_property PACKAGE_PIN AY12 [ get_ports "c0_ddr4_dq[55]" ]
set_property PACKAGE_PIN AY11 [ get_ports "c0_ddr4_dq[54]" ]
set_property PACKAGE_PIN AY16 [ get_ports "c0_ddr4_dq[53]" ]
set_property PACKAGE_PIN AY15 [ get_ports "c0_ddr4_dq[52]" ]
set_property PACKAGE_PIN BB15 [ get_ports "c0_ddr4_dqs_t[12]" ]
set_property PACKAGE_PIN BB14 [ get_ports "c0_ddr4_dqs_c[12]" ]
set_property PACKAGE_PIN BA15 [ get_ports "c0_ddr4_dq[51]" ]
set_property PACKAGE_PIN BA14 [ get_ports "c0_ddr4_dq[50]" ]
set_property PACKAGE_PIN AY13 [ get_ports "c0_ddr4_dq[49]" ]
set_property PACKAGE_PIN BA13 [ get_ports "c0_ddr4_dq[48]" ]
set_property PACKAGE_PIN AW14 [ get_ports "c0_ddr4_dqs_t[11]" ]
set_property PACKAGE_PIN AW13 [ get_ports "c0_ddr4_dqs_c[11]" ]
set_property PACKAGE_PIN AW16 [ get_ports "c0_ddr4_dq[47]" ]
set_property PACKAGE_PIN AW15 [ get_ports "c0_ddr4_dq[46]" ]
set_property PACKAGE_PIN AU13 [ get_ports "c0_ddr4_dq[45]" ]
set_property PACKAGE_PIN AV13 [ get_ports "c0_ddr4_dq[44]" ]
set_property PACKAGE_PIN AU14 [ get_ports "c0_ddr4_dqs_t[10]" ]
set_property PACKAGE_PIN AV14 [ get_ports "c0_ddr4_dqs_c[10]" ]
set_property PACKAGE_PIN AT15 [ get_ports "c0_ddr4_dq[43]" ]
set_property PACKAGE_PIN AU15 [ get_ports "c0_ddr4_dq[42]" ]
set_property PACKAGE_PIN AU16 [ get_ports "c0_ddr4_dq[41]" ]
set_property PACKAGE_PIN AV16 [ get_ports "c0_ddr4_dq[40]" ]
#set_property PACKAGE_PIN AT14 [ get_ports "m0_ddr4_c[4]" ]
set_property PACKAGE_PIN AR16 [ get_ports "c0_ddr4_dqs_t[9]" ]
set_property PACKAGE_PIN AR15 [ get_ports "c0_ddr4_dqs_c[9]" ]
set_property PACKAGE_PIN AP15 [ get_ports "c0_ddr4_dq[39]" ]
set_property PACKAGE_PIN AP14 [ get_ports "c0_ddr4_dq[38]" ]
set_property PACKAGE_PIN AN14 [ get_ports "c0_ddr4_dq[37]" ]
set_property PACKAGE_PIN AN13 [ get_ports "c0_ddr4_dq[36]" ]
set_property PACKAGE_PIN AP13 [ get_ports "c0_ddr4_dqs_t[8]" ]
set_property PACKAGE_PIN AR13 [ get_ports "c0_ddr4_dqs_c[8]" ]
set_property PACKAGE_PIN AL15 [ get_ports "c0_ddr4_dq[35]" ]
set_property PACKAGE_PIN AM15 [ get_ports "c0_ddr4_dq[34]" ]
set_property PACKAGE_PIN AL14 [ get_ports "c0_ddr4_dq[33]" ]
set_property PACKAGE_PIN AM14 [ get_ports "c0_ddr4_dq[32]" ]