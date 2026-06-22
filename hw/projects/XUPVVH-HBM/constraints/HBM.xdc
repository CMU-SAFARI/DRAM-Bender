##############################################
##########      Configuration       ##########
##############################################
set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.USR_ACCESS TIMESTAMP [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 85.0 [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]

##############################################
##########    Board Clocks/Reset    ##########
##############################################
set_property IOSTANDARD LVCMOS18 [get_ports sys_rst_l]
set_property PACKAGE_PIN F18 [get_ports sys_rst_l]


##############################################
##########           LEDs           ##########
##############################################
set_property IOSTANDARD LVCMOS18 [get_ports icc]
set_property PACKAGE_PIN L19 [get_ports icc]

##############################################
##########           PCIe           ##########
##############################################

set_property PACKAGE_PIN BG23 [get_ports pcie_rst]
set_property IOSTANDARD LVCMOS12 [get_ports pcie_rst]
set_property PULLUP true [get_ports pcie_rst]
set_property PACKAGE_PIN AR14 [get_ports clk_ref_n]
set_property PACKAGE_PIN AR15 [get_ports clk_ref_p]
create_clock -period 10.000 -name refclk_100 [get_ports clk_ref_p]


##############################################
##########      Memory Clocks       ##########
##############################################

create_clock -period 10.000 [get_ports c0_sys_clk_p]
set_property PACKAGE_PIN G35 [get_ports c0_sys_clk_p]
set_property PACKAGE_PIN G36 [get_ports c0_sys_clk_n]
set_property IOSTANDARD DIFF_SSTL12_DCI [get_ports c0_sys_clk_p]
set_property IOSTANDARD DIFF_SSTL12_DCI [get_ports c0_sys_clk_n]
set_property ODT RTT_48 [get_ports c0_sys_clk_p]

set_clock_groups -asynchronous -group [get_clocks c0_sys_clk_p -include_generated_clocks]
create_clock -period 10.000 -name refclk_100 [get_ports clk_ref_p]
set_clock_groups -asynchronous -group [get_clocks refclk_100 -include_generated_clocks]

#create_clock -period 10.000 [get_ports main_clk]
#set_property IOSTANDARD LVCMOS12 [get_ports main_clk]

#set_property IOSTANDARD LVCMOS18 [get_ports main_clk]
#set_property PACKAGE_PIN F20 [get_ports main_clk]


set_property MARK_DEBUG false [get_nets HBM_adapter/ctrl_top/hbm_inst/DRAM_0_STAT_CATTRIP]

set_property MARK_DEBUG false [get_nets {HBM_adapter/ctrl_top/hbm_inst/DRAM_0_STAT_TEMP[0]}]
set_property MARK_DEBUG false [get_nets {HBM_adapter/ctrl_top/hbm_inst/DRAM_0_STAT_TEMP[1]}]
set_property MARK_DEBUG false [get_nets {HBM_adapter/ctrl_top/hbm_inst/DRAM_0_STAT_TEMP[2]}]
set_property MARK_DEBUG false [get_nets {HBM_adapter/ctrl_top/hbm_inst/DRAM_0_STAT_TEMP[3]}]
set_property MARK_DEBUG false [get_nets {HBM_adapter/ctrl_top/hbm_inst/DRAM_0_STAT_TEMP[4]}]
set_property MARK_DEBUG false [get_nets {HBM_adapter/ctrl_top/hbm_inst/DRAM_0_STAT_TEMP[5]}]
set_property MARK_DEBUG false [get_nets {HBM_adapter/ctrl_top/hbm_inst/DRAM_0_STAT_TEMP[6]}]
