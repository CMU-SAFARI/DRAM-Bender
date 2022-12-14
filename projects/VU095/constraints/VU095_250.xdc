##############################################
##########      Configuration       ##########
##############################################
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.CONFIG.USR_ACCESS TIMESTAMP [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR NO [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 90 [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]

##############################################
##########            PCIe          ##########
##############################################
set_property PACKAGE_PIN AT10 [get_ports clk_ref_n]

set_property LOC PCIE_3_1_X0Y0 [get_cells xdma_i/inst/pcie3_ip_i/inst/pcie3_uscale_top_inst/pcie3_uscale_wrapper_inst/PCIE_3_1_inst]
set_property PACKAGE_PIN AR26 [get_ports pcie_rst]
set_property IOSTANDARD LVCMOS12 [get_ports pcie_rst]
set_property PULLUP true [get_ports pcie_rst]

create_clock -period 10.000 -name refclk_100 [get_ports clk_ref_p]
set_clock_groups -asynchronous -group [get_clocks refclk_100 -include_generated_clocks]

set_false_path -to [get_pins -hier {*sync_reg[0]/D}]

set_false_path -to [get_cells {xdma_i/inst/pcie3_ip_i/inst/gt_top_i/phy_rst_i/sync_phystatus/sync_vec[*].sync_cell_i/sync_reg[0]}]
set_false_path -to [get_cells {xdma_i/inst/pcie3_ip_i/inst/gt_top_i/phy_rst_i/sync_rxresetdone/sync_vec[*].sync_cell_i/sync_reg[0]}]
set_false_path -to [get_cells {xdma_i/inst/pcie3_ip_i/inst/gt_top_i/phy_rst_i/sync_txresetdone/sync_vec[*].sync_cell_i/sync_reg[0]}]
set_false_path -from [get_pins xdma_i/inst/pcie3_ip_i/inst/gt_top_i/phy_rst_i/idle_reg/C] -to [get_pins {pcie_xdma_sub_i/xdma_0/inst/pcie3_ip_i/inst/pcie3_uscale_top_inst/init_ctrl_inst/reg_reset_timer_reg[*]/CLR}]
set_false_path -from [get_pins xdma_i/inst/pcie3_ip_i/inst/gt_top_i/phy_rst_i/idle_reg/C] -to [get_pins {pcie_xdma_sub_i/xdma_0/inst/pcie3_ip_i/inst/pcie3_uscale_top_inst/init_ctrl_inst/reg_phy_rdy_reg[*]/PRE}]

##############################################
##########      Clocks/Reset        ##########
##############################################
create_clock -period 10.000 [get_ports c0_sys_clk_p]
set_clock_groups -asynchronous -group [get_clocks c0_sys_clk_p -include_generated_clocks]

set_property IOSTANDARD DIFF_SSTL12_DCI [get_ports c0_sys_clk_p]
set_property IOSTANDARD DIFF_SSTL12_DCI [get_ports c0_sys_clk_n]
set_property ODT RTT_48 [get_ports c0_sys_clk_p]
set_property PACKAGE_PIN K18 [get_ports c0_sys_clk_p]

set_property PACKAGE_PIN AT23 [get_ports sys_rst_l]
set_property IOSTANDARD LVCMOS33 [get_ports sys_rst_l]

##############################################
##########   DDR4 Pin Properties    ##########
##############################################
### SODIMM - 1

set_property OUTPUT_IMPEDANCE RDRV_NONE_NONE [get_ports c0_ddr4_reset_n]
set_property IOSTANDARD LVCMOS12 [get_ports c0_ddr4_reset_n]
set_property DRIVE 8 [get_ports c0_ddr4_reset_n]
set_property PACKAGE_PIN AT18 [get_ports {c0_ddr4_adr[0]}]
set_property PACKAGE_PIN AU17 [get_ports {c0_ddr4_adr[1]}]
set_property PACKAGE_PIN AP19 [get_ports {c0_ddr4_adr[10]}]
set_property PACKAGE_PIN AM16 [get_ports {c0_ddr4_adr[11]}]
set_property PACKAGE_PIN AN16 [get_ports {c0_ddr4_adr[12]}]
set_property PACKAGE_PIN AL19 [get_ports {c0_ddr4_adr[13]}]
set_property PACKAGE_PIN AM19 [get_ports {c0_ddr4_adr[14]}]
set_property PACKAGE_PIN AL20 [get_ports {c0_ddr4_adr[15]}]
set_property PACKAGE_PIN AM20 [get_ports {c0_ddr4_adr[16]}]
set_property PACKAGE_PIN AP18 [get_ports {c0_ddr4_adr[2]}]
set_property PACKAGE_PIN AR18 [get_ports {c0_ddr4_adr[3]}]
set_property PACKAGE_PIN AP20 [get_ports {c0_ddr4_adr[4]}]
set_property PACKAGE_PIN AR20 [get_ports {c0_ddr4_adr[5]}]
set_property PACKAGE_PIN AU21 [get_ports {c0_ddr4_adr[6]}]
set_property PACKAGE_PIN AN18 [get_ports {c0_ddr4_adr[7]}]
set_property PACKAGE_PIN AN17 [get_ports {c0_ddr4_adr[8]}]
set_property PACKAGE_PIN AN19 [get_ports {c0_ddr4_adr[9]}]
set_property PACKAGE_PIN AV17 [get_ports c0_ddr4_act_n]
set_property PACKAGE_PIN AT19 [get_ports {c0_ddr4_ba[0]}]
set_property PACKAGE_PIN AU19 [get_ports {c0_ddr4_ba[1]}]
set_property PACKAGE_PIN AT20 [get_ports {c0_ddr4_bg[0]}]
set_property PACKAGE_PIN AU20 [get_ports {c0_ddr4_bg[1]}]
set_property PACKAGE_PIN AR17 [get_ports {c0_ddr4_ck_t[0]}]
set_property PACKAGE_PIN AT17 [get_ports {c0_ddr4_ck_c[0]}]
set_property PACKAGE_PIN AM17 [ get_ports "c0_ddr4_ck_c[1]" ]
set_property PACKAGE_PIN AL17 [ get_ports "c0_ddr4_ck_t[1]" ]
set_property PACKAGE_PIN AY20 [get_ports {c0_ddr4_cke[0]}]
set_property PACKAGE_PIN AV21 [ get_ports "c0_ddr4_cke[1]" ]
set_property PACKAGE_PIN BA18 [get_ports {c0_ddr4_cs_n[0]}]
set_property PACKAGE_PIN AW20 [ get_ports "c0_ddr4_cs_n[1]" ]
set_property PACKAGE_PIN AR16 [get_ports {c0_ddr4_dm_dbi_n[0]}]
set_property PACKAGE_PIN AW14 [get_ports {c0_ddr4_dm_dbi_n[1]}]
set_property PACKAGE_PIN BA12 [get_ports {c0_ddr4_dm_dbi_n[2]}]
set_property PACKAGE_PIN BF14 [get_ports {c0_ddr4_dm_dbi_n[3]}]
set_property PACKAGE_PIN AP25 [get_ports {c0_ddr4_dm_dbi_n[4]}]
set_property PACKAGE_PIN AV26 [get_ports {c0_ddr4_dm_dbi_n[5]}]
set_property PACKAGE_PIN BA25 [get_ports {c0_ddr4_dm_dbi_n[6]}]
set_property PACKAGE_PIN BF28 [get_ports {c0_ddr4_dm_dbi_n[7]}]
set_property PACKAGE_PIN BE17 [ get_ports "c0_ddr4_dm_dbi_n[8]" ]
set_property PACKAGE_PIN AM14 [get_ports {c0_ddr4_dq[0]}]
set_property PACKAGE_PIN AL14 [get_ports {c0_ddr4_dq[1]}]
set_property PACKAGE_PIN AU15 [get_ports {c0_ddr4_dq[10]}]
set_property PACKAGE_PIN AT15 [get_ports {c0_ddr4_dq[11]}]
set_property PACKAGE_PIN AV13 [get_ports {c0_ddr4_dq[12]}]
set_property PACKAGE_PIN AU13 [get_ports {c0_ddr4_dq[13]}]
set_property PACKAGE_PIN AW15 [get_ports {c0_ddr4_dq[14]}]
set_property PACKAGE_PIN AW16 [get_ports {c0_ddr4_dq[15]}]
set_property PACKAGE_PIN BA13 [get_ports {c0_ddr4_dq[16]}]
set_property PACKAGE_PIN AY13 [get_ports {c0_ddr4_dq[17]}]
set_property PACKAGE_PIN BA14 [get_ports {c0_ddr4_dq[18]}]
set_property PACKAGE_PIN BA15 [get_ports {c0_ddr4_dq[19]}]
set_property PACKAGE_PIN AM15 [get_ports {c0_ddr4_dq[2]}]
set_property PACKAGE_PIN AY15 [get_ports {c0_ddr4_dq[20]}]
set_property PACKAGE_PIN AY16 [get_ports {c0_ddr4_dq[21]}]
set_property PACKAGE_PIN AY11 [get_ports {c0_ddr4_dq[22]}]
set_property PACKAGE_PIN AY12 [get_ports {c0_ddr4_dq[23]}]
set_property PACKAGE_PIN BC13 [get_ports {c0_ddr4_dq[24]}]
set_property PACKAGE_PIN BC14 [get_ports {c0_ddr4_dq[25]}]
set_property PACKAGE_PIN BD14 [get_ports {c0_ddr4_dq[26]}]
set_property PACKAGE_PIN BD15 [get_ports {c0_ddr4_dq[27]}]
set_property PACKAGE_PIN BE16 [get_ports {c0_ddr4_dq[28]}]
set_property PACKAGE_PIN BD16 [get_ports {c0_ddr4_dq[29]}]
set_property PACKAGE_PIN AL15 [get_ports {c0_ddr4_dq[3]}]
set_property PACKAGE_PIN BF15 [get_ports {c0_ddr4_dq[30]}]
set_property PACKAGE_PIN BE15 [get_ports {c0_ddr4_dq[31]}]
set_property PACKAGE_PIN AL28 [get_ports {c0_ddr4_dq[32]}]
set_property PACKAGE_PIN AL27 [get_ports {c0_ddr4_dq[33]}]
set_property PACKAGE_PIN AN27 [get_ports {c0_ddr4_dq[34]}]
set_property PACKAGE_PIN AM27 [get_ports {c0_ddr4_dq[35]}]
set_property PACKAGE_PIN AM25 [get_ports {c0_ddr4_dq[36]}]
set_property PACKAGE_PIN AL25 [get_ports {c0_ddr4_dq[37]}]
set_property PACKAGE_PIN AP28 [get_ports {c0_ddr4_dq[38]}]
set_property PACKAGE_PIN AN28 [get_ports {c0_ddr4_dq[39]}]
set_property PACKAGE_PIN AN13 [get_ports {c0_ddr4_dq[4]}]
set_property PACKAGE_PIN AT28 [get_ports {c0_ddr4_dq[40]}]
set_property PACKAGE_PIN AR28 [get_ports {c0_ddr4_dq[41]}]
set_property PACKAGE_PIN AT27 [get_ports {c0_ddr4_dq[42]}]
set_property PACKAGE_PIN AR27 [get_ports {c0_ddr4_dq[43]}]
set_property PACKAGE_PIN AU27 [get_ports {c0_ddr4_dq[44]}]
set_property PACKAGE_PIN AU26 [get_ports {c0_ddr4_dq[45]}]
set_property PACKAGE_PIN AV28 [get_ports {c0_ddr4_dq[46]}]
set_property PACKAGE_PIN AV27 [get_ports {c0_ddr4_dq[47]}]
set_property PACKAGE_PIN AY28 [get_ports {c0_ddr4_dq[48]}]
set_property PACKAGE_PIN AW28 [get_ports {c0_ddr4_dq[49]}]
set_property PACKAGE_PIN AN14 [get_ports {c0_ddr4_dq[5]}]
set_property PACKAGE_PIN AY27 [get_ports {c0_ddr4_dq[50]}]
set_property PACKAGE_PIN AY26 [get_ports {c0_ddr4_dq[51]}]
set_property PACKAGE_PIN BA28 [get_ports {c0_ddr4_dq[52]}]
set_property PACKAGE_PIN BA27 [get_ports {c0_ddr4_dq[53]}]
set_property PACKAGE_PIN BB27 [get_ports {c0_ddr4_dq[54]}]
set_property PACKAGE_PIN BB26 [get_ports {c0_ddr4_dq[55]}]
set_property PACKAGE_PIN BC27 [get_ports {c0_ddr4_dq[56]}]
set_property PACKAGE_PIN BC26 [get_ports {c0_ddr4_dq[57]}]
set_property PACKAGE_PIN BF25 [get_ports {c0_ddr4_dq[58]}]
set_property PACKAGE_PIN BE25 [get_ports {c0_ddr4_dq[59]}]
set_property PACKAGE_PIN AP14 [get_ports {c0_ddr4_dq[6]}]
set_property PACKAGE_PIN BE28 [get_ports {c0_ddr4_dq[60]}]
set_property PACKAGE_PIN BD28 [get_ports {c0_ddr4_dq[61]}]
set_property PACKAGE_PIN BF27 [get_ports {c0_ddr4_dq[62]}]
set_property PACKAGE_PIN BE27 [get_ports {c0_ddr4_dq[63]}]
set_property PACKAGE_PIN BC18 [ get_ports "c0_ddr4_dq[64]" ]
set_property PACKAGE_PIN BB19 [ get_ports "c0_ddr4_dq[65]" ]
set_property PACKAGE_PIN BC17 [ get_ports "c0_ddr4_dq[66]" ]
set_property PACKAGE_PIN BB17 [ get_ports "c0_ddr4_dq[67]" ]
set_property PACKAGE_PIN BE18 [ get_ports "c0_ddr4_dq[68]" ]
set_property PACKAGE_PIN BD18 [ get_ports "c0_ddr4_dq[69]" ]
set_property PACKAGE_PIN AP15 [get_ports {c0_ddr4_dq[7]}]
set_property PACKAGE_PIN BF18 [ get_ports "c0_ddr4_dq[70]" ]
set_property PACKAGE_PIN BF19 [ get_ports "c0_ddr4_dq[71]" ]
set_property PACKAGE_PIN AV16 [get_ports {c0_ddr4_dq[8]}]
set_property PACKAGE_PIN AU16 [get_ports {c0_ddr4_dq[9]}]
set_property PACKAGE_PIN BD19 [ get_ports "c0_ddr4_dqs_c[8]" ]
set_property PACKAGE_PIN AP13 [get_ports {c0_ddr4_dqs_t[0]}]
set_property PACKAGE_PIN AR13 [get_ports {c0_ddr4_dqs_c[0]}]
set_property PACKAGE_PIN AU14 [get_ports {c0_ddr4_dqs_t[1]}]
set_property PACKAGE_PIN AV14 [get_ports {c0_ddr4_dqs_c[1]}]
set_property PACKAGE_PIN BB15 [get_ports {c0_ddr4_dqs_t[2]}]
set_property PACKAGE_PIN BB14 [get_ports {c0_ddr4_dqs_c[2]}]
set_property PACKAGE_PIN BD13 [get_ports {c0_ddr4_dqs_t[3]}]
set_property PACKAGE_PIN BE13 [get_ports {c0_ddr4_dqs_c[3]}]
set_property PACKAGE_PIN AM26 [get_ports {c0_ddr4_dqs_t[4]}]
set_property PACKAGE_PIN AN26 [get_ports {c0_ddr4_dqs_c[4]}]
set_property PACKAGE_PIN AR25 [get_ports {c0_ddr4_dqs_t[5]}]
set_property PACKAGE_PIN AT25 [get_ports {c0_ddr4_dqs_c[5]}]
set_property PACKAGE_PIN AW25 [get_ports {c0_ddr4_dqs_t[6]}]
set_property PACKAGE_PIN AY25 [get_ports {c0_ddr4_dqs_c[6]}]
set_property PACKAGE_PIN BD26 [get_ports {c0_ddr4_dqs_t[7]}]
set_property PACKAGE_PIN BE26 [get_ports {c0_ddr4_dqs_c[7]}]
set_property PACKAGE_PIN BC19 [ get_ports "c0_ddr4_dqs_t[8]" ]
set_property PACKAGE_PIN AW21 [get_ports {c0_ddr4_odt[0]}]
set_property PACKAGE_PIN AV19 [ get_ports "c0_ddr4_odt[1]" ]
set_property PACKAGE_PIN BA17 [get_ports c0_ddr4_reset_n]


#### SODIMM - 2
#set_property OUTPUT_IMPEDANCE RDRV_NONE_NONE [get_ports c0_ddr4_reset_n]
#set_property IOSTANDARD LVCMOS12 [get_ports c0_ddr4_reset_n]
#set_property DRIVE 8 [get_ports c0_ddr4_reset_n]
#set_property PACKAGE_PIN F20 [get_ports {c0_ddr4_adr[0]}]
#set_property PACKAGE_PIN F19 [get_ports {c0_ddr4_adr[1]}]
#set_property PACKAGE_PIN D20 [get_ports {c0_ddr4_adr[10]}]
#set_property PACKAGE_PIN C21 [get_ports {c0_ddr4_adr[11]}]
#set_property PACKAGE_PIN B21 [get_ports {c0_ddr4_adr[12]}]
#set_property PACKAGE_PIN B19 [get_ports {c0_ddr4_adr[13]}]
#set_property PACKAGE_PIN A19 [get_ports {c0_ddr4_adr[14]}]
#set_property PACKAGE_PIN B20 [get_ports {c0_ddr4_adr[15]}]
#set_property PACKAGE_PIN A20 [get_ports {c0_ddr4_adr[16]}]
#set_property PACKAGE_PIN E21 [get_ports {c0_ddr4_adr[2]}]
#set_property PACKAGE_PIN E20 [get_ports {c0_ddr4_adr[3]}]
#set_property PACKAGE_PIN F18 [get_ports {c0_ddr4_adr[4]}]
#set_property PACKAGE_PIN F17 [get_ports {c0_ddr4_adr[5]}]
#set_property PACKAGE_PIN G21 [get_ports {c0_ddr4_adr[6]}]
#set_property PACKAGE_PIN D19 [get_ports {c0_ddr4_adr[7]}]
#set_property PACKAGE_PIN C19 [get_ports {c0_ddr4_adr[8]}]
#set_property PACKAGE_PIN D21 [get_ports {c0_ddr4_adr[9]}]
#set_property PACKAGE_PIN K21 [get_ports c0_ddr4_act_n]
#set_property PACKAGE_PIN H19 [get_ports {c0_ddr4_ba[0]}]
#set_property PACKAGE_PIN H18 [get_ports {c0_ddr4_ba[1]}]
#set_property PACKAGE_PIN G20 [get_ports {c0_ddr4_bg[0]}]
#set_property PACKAGE_PIN G19 [get_ports {c0_ddr4_bg[1]}]
#set_property PACKAGE_PIN E18 [get_ports {c0_ddr4_ck_t[0]}]
#set_property PACKAGE_PIN E17 [get_ports {c0_ddr4_ck_c[0]}]
#set_property PACKAGE_PIN K20 [get_ports {c0_ddr4_cke[0]}]
#set_property PACKAGE_PIN L18 [get_ports {c0_ddr4_cs_n[0]}]
#set_property PACKAGE_PIN C22 [get_ports {c0_ddr4_dm_dbi_n[0]}]
#set_property PACKAGE_PIN G25 [get_ports {c0_ddr4_dm_dbi_n[1]}]
#set_property PACKAGE_PIN L25 [get_ports {c0_ddr4_dm_dbi_n[2]}]
#set_property PACKAGE_PIN R21 [get_ports {c0_ddr4_dm_dbi_n[3]}]
#set_property PACKAGE_PIN D13 [get_ports {c0_ddr4_dm_dbi_n[4]}]
#set_property PACKAGE_PIN G14 [get_ports {c0_ddr4_dm_dbi_n[5]}]
#set_property PACKAGE_PIN L13 [get_ports {c0_ddr4_dm_dbi_n[6]}]
#set_property PACKAGE_PIN P13 [get_ports {c0_ddr4_dm_dbi_n[7]}]
#set_property PACKAGE_PIN A25 [get_ports {c0_ddr4_dq[0]}]
#set_property PACKAGE_PIN B25 [get_ports {c0_ddr4_dq[1]}]
#set_property PACKAGE_PIN D23 [get_ports {c0_ddr4_dq[10]}]
#set_property PACKAGE_PIN D24 [get_ports {c0_ddr4_dq[11]}]
#set_property PACKAGE_PIN F22 [get_ports {c0_ddr4_dq[12]}]
#set_property PACKAGE_PIN G22 [get_ports {c0_ddr4_dq[13]}]
#set_property PACKAGE_PIN F23 [get_ports {c0_ddr4_dq[14]}]
#set_property PACKAGE_PIN F24 [get_ports {c0_ddr4_dq[15]}]
#set_property PACKAGE_PIN H24 [get_ports {c0_ddr4_dq[16]}]
#set_property PACKAGE_PIN J24 [get_ports {c0_ddr4_dq[17]}]
#set_property PACKAGE_PIN H23 [get_ports {c0_ddr4_dq[18]}]
#set_property PACKAGE_PIN J23 [get_ports {c0_ddr4_dq[19]}]
#set_property PACKAGE_PIN A24 [get_ports {c0_ddr4_dq[2]}]
#set_property PACKAGE_PIN K23 [get_ports {c0_ddr4_dq[20]}]
#set_property PACKAGE_PIN L23 [get_ports {c0_ddr4_dq[21]}]
#set_property PACKAGE_PIN K22 [get_ports {c0_ddr4_dq[22]}]
#set_property PACKAGE_PIN L22 [get_ports {c0_ddr4_dq[23]}]
#set_property PACKAGE_PIN P25 [get_ports {c0_ddr4_dq[24]}]
#set_property PACKAGE_PIN R25 [get_ports {c0_ddr4_dq[25]}]
#set_property PACKAGE_PIN M24 [get_ports {c0_ddr4_dq[26]}]
#set_property PACKAGE_PIN M25 [get_ports {c0_ddr4_dq[27]}]
#set_property PACKAGE_PIN N23 [get_ports {c0_ddr4_dq[28]}]
#set_property PACKAGE_PIN P23 [get_ports {c0_ddr4_dq[29]}]
#set_property PACKAGE_PIN B24 [get_ports {c0_ddr4_dq[3]}]
#set_property PACKAGE_PIN M22 [get_ports {c0_ddr4_dq[30]}]
#set_property PACKAGE_PIN N22 [get_ports {c0_ddr4_dq[31]}]
#set_property PACKAGE_PIN A17 [get_ports {c0_ddr4_dq[32]}]
#set_property PACKAGE_PIN B17 [get_ports {c0_ddr4_dq[33]}]
#set_property PACKAGE_PIN B16 [get_ports {c0_ddr4_dq[34]}]
#set_property PACKAGE_PIN C16 [get_ports {c0_ddr4_dq[35]}]
#set_property PACKAGE_PIN A13 [get_ports {c0_ddr4_dq[36]}]
#set_property PACKAGE_PIN A14 [get_ports {c0_ddr4_dq[37]}]
#set_property PACKAGE_PIN B14 [get_ports {c0_ddr4_dq[38]}]
#set_property PACKAGE_PIN C14 [get_ports {c0_ddr4_dq[39]}]
#set_property PACKAGE_PIN B26 [get_ports {c0_ddr4_dq[4]}]
#set_property PACKAGE_PIN D16 [get_ports {c0_ddr4_dq[40]}]
#set_property PACKAGE_PIN E16 [get_ports {c0_ddr4_dq[41]}]
#set_property PACKAGE_PIN D15 [get_ports {c0_ddr4_dq[42]}]
#set_property PACKAGE_PIN E15 [get_ports {c0_ddr4_dq[43]}]
#set_property PACKAGE_PIN E13 [get_ports {c0_ddr4_dq[44]}]
#set_property PACKAGE_PIN F13 [get_ports {c0_ddr4_dq[45]}]
#set_property PACKAGE_PIN F15 [get_ports {c0_ddr4_dq[46]}]
#set_property PACKAGE_PIN G15 [get_ports {c0_ddr4_dq[47]}]
#set_property PACKAGE_PIN J15 [get_ports {c0_ddr4_dq[48]}]
#set_property PACKAGE_PIN J16 [get_ports {c0_ddr4_dq[49]}]
#set_property PACKAGE_PIN C26 [get_ports {c0_ddr4_dq[5]}]
#set_property PACKAGE_PIN H14 [get_ports {c0_ddr4_dq[50]}]
#set_property PACKAGE_PIN J14 [get_ports {c0_ddr4_dq[51]}]
#set_property PACKAGE_PIN H13 [get_ports {c0_ddr4_dq[52]}]
#set_property PACKAGE_PIN J13 [get_ports {c0_ddr4_dq[53]}]
#set_property PACKAGE_PIN K15 [get_ports {c0_ddr4_dq[54]}]
#set_property PACKAGE_PIN K16 [get_ports {c0_ddr4_dq[55]}]
#set_property PACKAGE_PIN M16 [get_ports {c0_ddr4_dq[56]}]
#set_property PACKAGE_PIN N16 [get_ports {c0_ddr4_dq[57]}]
#set_property PACKAGE_PIN L14 [get_ports {c0_ddr4_dq[58]}]
#set_property PACKAGE_PIN M14 [get_ports {c0_ddr4_dq[59]}]
#set_property PACKAGE_PIN C23 [get_ports {c0_ddr4_dq[6]}]
#set_property PACKAGE_PIN P15 [get_ports {c0_ddr4_dq[60]}]
#set_property PACKAGE_PIN R15 [get_ports {c0_ddr4_dq[61]}]
#set_property PACKAGE_PIN N14 [get_ports {c0_ddr4_dq[62]}]
#set_property PACKAGE_PIN P14 [get_ports {c0_ddr4_dq[63]}]
#set_property PACKAGE_PIN C24 [get_ports {c0_ddr4_dq[7]}]
#set_property PACKAGE_PIN D25 [get_ports {c0_ddr4_dq[8]}]
#set_property PACKAGE_PIN E25 [get_ports {c0_ddr4_dq[9]}]
#set_property PACKAGE_PIN A23 [get_ports {c0_ddr4_dqs_t[0]}]
#set_property PACKAGE_PIN A22 [get_ports {c0_ddr4_dqs_c[0]}]
#set_property PACKAGE_PIN E23 [get_ports {c0_ddr4_dqs_t[1]}]
#set_property PACKAGE_PIN E22 [get_ports {c0_ddr4_dqs_c[1]}]
#set_property PACKAGE_PIN K25 [get_ports {c0_ddr4_dqs_t[2]}]
#set_property PACKAGE_PIN J25 [get_ports {c0_ddr4_dqs_c[2]}]
#set_property PACKAGE_PIN P24 [get_ports {c0_ddr4_dqs_t[3]}]
#set_property PACKAGE_PIN N24 [get_ports {c0_ddr4_dqs_c[3]}]
#set_property PACKAGE_PIN B15 [get_ports {c0_ddr4_dqs_t[4]}]
#set_property PACKAGE_PIN A15 [get_ports {c0_ddr4_dqs_c[4]}]
#set_property PACKAGE_PIN G17 [get_ports {c0_ddr4_dqs_t[5]}]
#set_property PACKAGE_PIN G16 [get_ports {c0_ddr4_dqs_c[5]}]
#set_property PACKAGE_PIN H17 [get_ports {c0_ddr4_dqs_t[6]}]
#set_property PACKAGE_PIN H16 [get_ports {c0_ddr4_dqs_c[6]}]
#set_property PACKAGE_PIN R16 [get_ports {c0_ddr4_dqs_t[7]}]
#set_property PACKAGE_PIN P16 [get_ports {c0_ddr4_dqs_c[7]}]
#set_property PACKAGE_PIN H21 [get_ports {c0_ddr4_odt[0]}]
#set_property PACKAGE_PIN K17 [get_ports c0_ddr4_reset_n]

connect_debug_port u_ila_0/probe1 [get_nets [list {rbe/incoming_reads[0]} {rbe/incoming_reads[1]} {rbe/incoming_reads[2]} {rbe/incoming_reads[3]} {rbe/incoming_reads[4]} {rbe/incoming_reads[5]} {rbe/incoming_reads[6]} {rbe/incoming_reads[7]} {rbe/incoming_reads[8]} {rbe/incoming_reads[9]}]]



create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list phy_ddr4_i/inst/u_ddr4_infrastructure/c0_ddr4_ui_clk]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 1 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list frontend/maint_ctrl/aref_switch_r]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk]
