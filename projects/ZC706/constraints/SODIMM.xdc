create_clock -period 5.000 [get_ports c0_sys_clk_p]
set_clock_groups -asynchronous -group [get_clocks c0_sys_clk_p -include_generated_clocks]

# Set DCI_CASCADE
set_property DCI_CASCADE {34} [get_iobanks 33]
############## NET - IOSTANDARD ##################
# Bank: 34 - PL_CPU_RESET
set_property VCCAUX_IO DONTCARE [get_ports sys_rst]
set_property IOSTANDARD LVCMOS15 [get_ports sys_rst]
set_property PACKAGE_PIN A8 [get_ports sys_rst]

# Bank: 11 - GPIO_LED_RIGHT
#set_property DRIVE 12 [get_ports init_calib_complete]
#set_property SLEW SLOW [get_ports init_calib_complete]
#set_property IOSTANDARD LVCMOS25 [get_ports init_calib_complete]
#set_property PACKAGE_PIN W21 [get_ports init_calib_complete]

# PadFunction: IO_L2P_T0_33
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[0]}]
set_property SLEW FAST [get_ports {ddr3_dq[0]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[0]}]
set_property PACKAGE_PIN L1 [get_ports {ddr3_dq[0]}]

# PadFunction: IO_L4N_T0_33
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[1]}]
set_property SLEW FAST [get_ports {ddr3_dq[1]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[1]}]
set_property PACKAGE_PIN L2 [get_ports {ddr3_dq[1]}]

# PadFunction: IO_L5P_T0_33
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[2]}]
set_property SLEW FAST [get_ports {ddr3_dq[2]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[2]}]
set_property PACKAGE_PIN K5 [get_ports {ddr3_dq[2]}]

# PadFunction: IO_L1P_T0_33
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[3]}]
set_property SLEW FAST [get_ports {ddr3_dq[3]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[3]}]
set_property PACKAGE_PIN J4 [get_ports {ddr3_dq[3]}]

# PadFunction: IO_L2N_T0_33
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[4]}]
set_property SLEW FAST [get_ports {ddr3_dq[4]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[4]}]
set_property PACKAGE_PIN K1 [get_ports {ddr3_dq[4]}]

# PadFunction: IO_L4P_T0_33
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[5]}]
set_property SLEW FAST [get_ports {ddr3_dq[5]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[5]}]
set_property PACKAGE_PIN L3 [get_ports {ddr3_dq[5]}]

# PadFunction: IO_L5N_T0_33
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[6]}]
set_property SLEW FAST [get_ports {ddr3_dq[6]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[6]}]
set_property PACKAGE_PIN J5 [get_ports {ddr3_dq[6]}]

# PadFunction: IO_L6P_T0_33
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[7]}]
set_property SLEW FAST [get_ports {ddr3_dq[7]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[7]}]
set_property PACKAGE_PIN K6 [get_ports {ddr3_dq[7]}]

# PadFunction: IO_L8N_T1_33
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[8]}]
set_property SLEW FAST [get_ports {ddr3_dq[8]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[8]}]
set_property PACKAGE_PIN G6 [get_ports {ddr3_dq[8]}]

# PadFunction: IO_L11P_T1_SRCC_33
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[9]}]
set_property SLEW FAST [get_ports {ddr3_dq[9]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[9]}]
set_property PACKAGE_PIN H4 [get_ports {ddr3_dq[9]}]

# PadFunction: IO_L8P_T1_33
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[10]}]
set_property SLEW FAST [get_ports {ddr3_dq[10]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[10]}]
set_property PACKAGE_PIN H6 [get_ports {ddr3_dq[10]}]

# PadFunction: IO_L11N_T1_SRCC_33
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[11]}]
set_property SLEW FAST [get_ports {ddr3_dq[11]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[11]}]
set_property PACKAGE_PIN H3 [get_ports {ddr3_dq[11]}]

# PadFunction: IO_L10N_T1_33
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[12]}]
set_property SLEW FAST [get_ports {ddr3_dq[12]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[12]}]
set_property PACKAGE_PIN G1 [get_ports {ddr3_dq[12]}]

# PadFunction: IO_L10P_T1_33
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[13]}]
set_property SLEW FAST [get_ports {ddr3_dq[13]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[13]}]
set_property PACKAGE_PIN H2 [get_ports {ddr3_dq[13]}]

# PadFunction: IO_L12P_T1_MRCC_33
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[14]}]
set_property SLEW FAST [get_ports {ddr3_dq[14]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[14]}]
set_property PACKAGE_PIN G5 [get_ports {ddr3_dq[14]}]

# PadFunction: IO_L12N_T1_MRCC_33
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[15]}]
set_property SLEW FAST [get_ports {ddr3_dq[15]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[15]}]
set_property PACKAGE_PIN G4 [get_ports {ddr3_dq[15]}]

# PadFunction: IO_L17N_T2_33
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[16]}]
set_property SLEW FAST [get_ports {ddr3_dq[16]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[16]}]
set_property PACKAGE_PIN E2 [get_ports {ddr3_dq[16]}]

# PadFunction: IO_L17P_T2_33
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[17]}]
set_property SLEW FAST [get_ports {ddr3_dq[17]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[17]}]
set_property PACKAGE_PIN E3 [get_ports {ddr3_dq[17]}]

# PadFunction: IO_L16P_T2_33
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[18]}]
set_property SLEW FAST [get_ports {ddr3_dq[18]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[18]}]
set_property PACKAGE_PIN D4 [get_ports {ddr3_dq[18]}]

# PadFunction: IO_L13N_T2_MRCC_33
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[19]}]
set_property SLEW FAST [get_ports {ddr3_dq[19]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[19]}]
set_property PACKAGE_PIN E5 [get_ports {ddr3_dq[19]}]

# PadFunction: IO_L14P_T2_SRCC_33
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[20]}]
set_property SLEW FAST [get_ports {ddr3_dq[20]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[20]}]
set_property PACKAGE_PIN F4 [get_ports {ddr3_dq[20]}]

# PadFunction: IO_L14N_T2_SRCC_33
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[21]}]
set_property SLEW FAST [get_ports {ddr3_dq[21]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[21]}]
set_property PACKAGE_PIN F3 [get_ports {ddr3_dq[21]}]

# PadFunction: IO_L18N_T2_33
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[22]}]
set_property SLEW FAST [get_ports {ddr3_dq[22]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[22]}]
set_property PACKAGE_PIN D1 [get_ports {ddr3_dq[22]}]

# PadFunction: IO_L16N_T2_33
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[23]}]
set_property SLEW FAST [get_ports {ddr3_dq[23]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[23]}]
set_property PACKAGE_PIN D3 [get_ports {ddr3_dq[23]}]

# PadFunction: IO_L24N_T3_33
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[24]}]
set_property SLEW FAST [get_ports {ddr3_dq[24]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[24]}]
set_property PACKAGE_PIN A2 [get_ports {ddr3_dq[24]}]

# PadFunction: IO_L23P_T3_33
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[25]}]
set_property SLEW FAST [get_ports {ddr3_dq[25]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[25]}]
set_property PACKAGE_PIN B2 [get_ports {ddr3_dq[25]}]

# PadFunction: IO_L20N_T3_33
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[26]}]
set_property SLEW FAST [get_ports {ddr3_dq[26]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[26]}]
set_property PACKAGE_PIN B4 [get_ports {ddr3_dq[26]}]

# PadFunction: IO_L20P_T3_33
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[27]}]
set_property SLEW FAST [get_ports {ddr3_dq[27]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[27]}]
set_property PACKAGE_PIN B5 [get_ports {ddr3_dq[27]}]

# PadFunction: IO_L24P_T3_33
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[28]}]
set_property SLEW FAST [get_ports {ddr3_dq[28]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[28]}]
set_property PACKAGE_PIN A3 [get_ports {ddr3_dq[28]}]

# PadFunction: IO_L23N_T3_33
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[29]}]
set_property SLEW FAST [get_ports {ddr3_dq[29]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[29]}]
set_property PACKAGE_PIN B1 [get_ports {ddr3_dq[29]}]

# PadFunction: IO_L22N_T3_33
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[30]}]
set_property SLEW FAST [get_ports {ddr3_dq[30]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[30]}]
set_property PACKAGE_PIN C1 [get_ports {ddr3_dq[30]}]

# PadFunction: IO_L19P_T3_33
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[31]}]
set_property SLEW FAST [get_ports {ddr3_dq[31]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[31]}]
set_property PACKAGE_PIN C4 [get_ports {ddr3_dq[31]}]

# PadFunction: IO_L22N_T3_34
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[32]}]
set_property SLEW FAST [get_ports {ddr3_dq[32]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[32]}]
set_property PACKAGE_PIN K10 [get_ports {ddr3_dq[32]}]

# PadFunction: IO_L23N_T3_34
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[33]}]
set_property SLEW FAST [get_ports {ddr3_dq[33]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[33]}]
set_property PACKAGE_PIN L9 [get_ports {ddr3_dq[33]}]

# PadFunction: IO_L24N_T3_34
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[34]}]
set_property SLEW FAST [get_ports {ddr3_dq[34]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[34]}]
set_property PACKAGE_PIN K12 [get_ports {ddr3_dq[34]}]

# PadFunction: IO_L20N_T3_34
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[35]}]
set_property SLEW FAST [get_ports {ddr3_dq[35]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[35]}]
set_property PACKAGE_PIN J9 [get_ports {ddr3_dq[35]}]

# PadFunction: IO_L22P_T3_34
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[36]}]
set_property SLEW FAST [get_ports {ddr3_dq[36]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[36]}]
set_property PACKAGE_PIN K11 [get_ports {ddr3_dq[36]}]

# PadFunction: IO_L23P_T3_34
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[37]}]
set_property SLEW FAST [get_ports {ddr3_dq[37]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[37]}]
set_property PACKAGE_PIN L10 [get_ports {ddr3_dq[37]}]

# PadFunction: IO_L20P_T3_34
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[38]}]
set_property SLEW FAST [get_ports {ddr3_dq[38]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[38]}]
set_property PACKAGE_PIN J10 [get_ports {ddr3_dq[38]}]

# PadFunction: IO_L19P_T3_34
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[39]}]
set_property SLEW FAST [get_ports {ddr3_dq[39]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[39]}]
set_property PACKAGE_PIN L7 [get_ports {ddr3_dq[39]}]

# PadFunction: IO_L12N_T1_MRCC_35
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[40]}]
set_property SLEW FAST [get_ports {ddr3_dq[40]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[40]}]
set_property PACKAGE_PIN F14 [get_ports {ddr3_dq[40]}]

# PadFunction: IO_L12P_T1_MRCC_35
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[41]}]
set_property SLEW FAST [get_ports {ddr3_dq[41]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[41]}]
set_property PACKAGE_PIN F15 [get_ports {ddr3_dq[41]}]

# PadFunction: IO_L10P_T1_AD11P_35
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[42]}]
set_property SLEW FAST [get_ports {ddr3_dq[42]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[42]}]
set_property PACKAGE_PIN F13 [get_ports {ddr3_dq[42]}]

# PadFunction: IO_L7N_T1_AD2N_35
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[43]}]
set_property SLEW FAST [get_ports {ddr3_dq[43]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[43]}]
set_property PACKAGE_PIN G16 [get_ports {ddr3_dq[43]}]

# PadFunction: IO_L8P_T1_AD10P_35
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[44]}]
set_property SLEW FAST [get_ports {ddr3_dq[44]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[44]}]
set_property PACKAGE_PIN G15 [get_ports {ddr3_dq[44]}]

# PadFunction: IO_L10N_T1_AD11N_35
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[45]}]
set_property SLEW FAST [get_ports {ddr3_dq[45]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[45]}]
set_property PACKAGE_PIN E12 [get_ports {ddr3_dq[45]}]

# PadFunction: IO_L11N_T1_SRCC_35
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[46]}]
set_property SLEW FAST [get_ports {ddr3_dq[46]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[46]}]
set_property PACKAGE_PIN D13 [get_ports {ddr3_dq[46]}]

# PadFunction: IO_L11P_T1_SRCC_35
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[47]}]
set_property SLEW FAST [get_ports {ddr3_dq[47]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[47]}]
set_property PACKAGE_PIN E13 [get_ports {ddr3_dq[47]}]

# PadFunction: IO_L14P_T2_AD4P_SRCC_35
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[48]}]
set_property SLEW FAST [get_ports {ddr3_dq[48]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[48]}]
set_property PACKAGE_PIN D15 [get_ports {ddr3_dq[48]}]

# PadFunction: IO_L13N_T2_MRCC_35
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[49]}]
set_property SLEW FAST [get_ports {ddr3_dq[49]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[49]}]
set_property PACKAGE_PIN E15 [get_ports {ddr3_dq[49]}]

# PadFunction: IO_L16P_T2_35
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[50]}]
set_property SLEW FAST [get_ports {ddr3_dq[50]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[50]}]
set_property PACKAGE_PIN D16 [get_ports {ddr3_dq[50]}]

# PadFunction: IO_L13P_T2_MRCC_35
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[51]}]
set_property SLEW FAST [get_ports {ddr3_dq[51]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[51]}]
set_property PACKAGE_PIN E16 [get_ports {ddr3_dq[51]}]

# PadFunction: IO_L17P_T2_AD5P_35
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[52]}]
set_property SLEW FAST [get_ports {ddr3_dq[52]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[52]}]
set_property PACKAGE_PIN C17 [get_ports {ddr3_dq[52]}]

# PadFunction: IO_L17N_T2_AD5N_35
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[53]}]
set_property SLEW FAST [get_ports {ddr3_dq[53]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[53]}]
set_property PACKAGE_PIN B16 [get_ports {ddr3_dq[53]}]

# PadFunction: IO_L14N_T2_AD4N_SRCC_35
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[54]}]
set_property SLEW FAST [get_ports {ddr3_dq[54]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[54]}]
set_property PACKAGE_PIN D14 [get_ports {ddr3_dq[54]}]

# PadFunction: IO_L18P_T2_AD13P_35
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[55]}]
set_property SLEW FAST [get_ports {ddr3_dq[55]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[55]}]
set_property PACKAGE_PIN B17 [get_ports {ddr3_dq[55]}]

# PadFunction: IO_L20N_T3_AD6N_35
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[56]}]
set_property SLEW FAST [get_ports {ddr3_dq[56]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[56]}]
set_property PACKAGE_PIN B12 [get_ports {ddr3_dq[56]}]

# PadFunction: IO_L20P_T3_AD6P_35
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[57]}]
set_property SLEW FAST [get_ports {ddr3_dq[57]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[57]}]
set_property PACKAGE_PIN C12 [get_ports {ddr3_dq[57]}]

# PadFunction: IO_L24N_T3_AD15N_35
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[58]}]
set_property SLEW FAST [get_ports {ddr3_dq[58]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[58]}]
set_property PACKAGE_PIN A12 [get_ports {ddr3_dq[58]}]

# PadFunction: IO_L23N_T3_35
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[59]}]
set_property SLEW FAST [get_ports {ddr3_dq[59]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[59]}]
set_property PACKAGE_PIN A14 [get_ports {ddr3_dq[59]}]

# PadFunction: IO_L24P_T3_AD15P_35
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[60]}]
set_property SLEW FAST [get_ports {ddr3_dq[60]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[60]}]
set_property PACKAGE_PIN A13 [get_ports {ddr3_dq[60]}]

# PadFunction: IO_L22N_T3_AD7N_35
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[61]}]
set_property SLEW FAST [get_ports {ddr3_dq[61]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[61]}]
set_property PACKAGE_PIN B11 [get_ports {ddr3_dq[61]}]

# PadFunction: IO_L19P_T3_35
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[62]}]
set_property SLEW FAST [get_ports {ddr3_dq[62]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[62]}]
set_property PACKAGE_PIN C14 [get_ports {ddr3_dq[62]}]

# PadFunction: IO_L23P_T3_35
set_property VCCAUX_IO HIGH [get_ports {ddr3_dq[63]}]
set_property SLEW FAST [get_ports {ddr3_dq[63]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[63]}]
set_property PACKAGE_PIN B14 [get_ports {ddr3_dq[63]}]

# PadFunction: IO_L1N_T0_34
set_property VCCAUX_IO HIGH [get_ports {ddr3_addr[13]}]
set_property SLEW FAST [get_ports {ddr3_addr[13]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[13]}]
set_property PACKAGE_PIN A10 [get_ports {ddr3_addr[13]}]

# PadFunction: IO_L9P_T1_DQS_34
set_property VCCAUX_IO HIGH [get_ports {ddr3_addr[12]}]
set_property SLEW FAST [get_ports {ddr3_addr[12]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[12]}]
set_property PACKAGE_PIN H12 [get_ports {ddr3_addr[12]}]

# PadFunction: IO_L4N_T0_34
set_property VCCAUX_IO HIGH [get_ports {ddr3_addr[11]}]
set_property SLEW FAST [get_ports {ddr3_addr[11]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[11]}]
set_property PACKAGE_PIN B7 [get_ports {ddr3_addr[11]}]

# PadFunction: IO_L17N_T2_34
set_property VCCAUX_IO HIGH [get_ports {ddr3_addr[10]}]
set_property SLEW FAST [get_ports {ddr3_addr[10]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[10]}]
set_property PACKAGE_PIN D6 [get_ports {ddr3_addr[10]}]

# PadFunction: IO_L15P_T2_DQS_34
set_property VCCAUX_IO HIGH [get_ports {ddr3_addr[9]}]
set_property SLEW FAST [get_ports {ddr3_addr[9]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[9]}]
set_property PACKAGE_PIN J8 [get_ports {ddr3_addr[9]}]

# PadFunction: IO_L1P_T0_34
set_property VCCAUX_IO HIGH [get_ports {ddr3_addr[8]}]
set_property SLEW FAST [get_ports {ddr3_addr[8]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[8]}]
set_property PACKAGE_PIN B10 [get_ports {ddr3_addr[8]}]

# PadFunction: IO_L14N_T2_SRCC_34
set_property VCCAUX_IO HIGH [get_ports {ddr3_addr[7]}]
set_property SLEW FAST [get_ports {ddr3_addr[7]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[7]}]
set_property PACKAGE_PIN E8 [get_ports {ddr3_addr[7]}]

# PadFunction: IO_L14P_T2_SRCC_34
set_property VCCAUX_IO HIGH [get_ports {ddr3_addr[6]}]
set_property SLEW FAST [get_ports {ddr3_addr[6]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[6]}]
set_property PACKAGE_PIN F9 [get_ports {ddr3_addr[6]}]

# PadFunction: IO_L5N_T0_34
set_property VCCAUX_IO HIGH [get_ports {ddr3_addr[5]}]
set_property SLEW FAST [get_ports {ddr3_addr[5]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[5]}]
set_property PACKAGE_PIN B6 [get_ports {ddr3_addr[5]}]

# PadFunction: IO_L8N_T1_34
set_property VCCAUX_IO HIGH [get_ports {ddr3_addr[4]}]
set_property SLEW FAST [get_ports {ddr3_addr[4]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[4]}]
set_property PACKAGE_PIN D11 [get_ports {ddr3_addr[4]}]

# PadFunction: IO_L2N_T0_34
set_property VCCAUX_IO HIGH [get_ports {ddr3_addr[3]}]
set_property SLEW FAST [get_ports {ddr3_addr[3]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[3]}]
set_property PACKAGE_PIN A9 [get_ports {ddr3_addr[3]}]

# PadFunction: IO_L8P_T1_34
set_property VCCAUX_IO HIGH [get_ports {ddr3_addr[2]}]
set_property SLEW FAST [get_ports {ddr3_addr[2]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[2]}]
set_property PACKAGE_PIN E11 [get_ports {ddr3_addr[2]}]

# PadFunction: IO_L2P_T0_34
set_property VCCAUX_IO HIGH [get_ports {ddr3_addr[1]}]
set_property SLEW FAST [get_ports {ddr3_addr[1]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[1]}]
set_property PACKAGE_PIN B9 [get_ports {ddr3_addr[1]}]

# PadFunction: IO_L10P_T1_34
set_property VCCAUX_IO HIGH [get_ports {ddr3_addr[0]}]
set_property SLEW FAST [get_ports {ddr3_addr[0]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[0]}]
set_property PACKAGE_PIN E10 [get_ports {ddr3_addr[0]}]

# PadFunction: IO_L3N_T0_DQS_34
set_property VCCAUX_IO HIGH [get_ports {ddr3_ba[2]}]
set_property SLEW FAST [get_ports {ddr3_ba[2]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_ba[2]}]
set_property PACKAGE_PIN A7 [get_ports {ddr3_ba[2]}]

# PadFunction: IO_L18P_T2_34
set_property VCCAUX_IO HIGH [get_ports {ddr3_ba[1]}]
set_property SLEW FAST [get_ports {ddr3_ba[1]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_ba[1]}]
set_property PACKAGE_PIN H7 [get_ports {ddr3_ba[1]}]

# PadFunction: IO_L16P_T2_34
set_property VCCAUX_IO HIGH [get_ports {ddr3_ba[0]}]
set_property SLEW FAST [get_ports {ddr3_ba[0]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_ba[0]}]
set_property PACKAGE_PIN F8 [get_ports {ddr3_ba[0]}]

# PadFunction: IO_L7N_T1_34
set_property VCCAUX_IO HIGH [get_ports ddr3_ras_n]
set_property SLEW FAST [get_ports ddr3_ras_n]
set_property IOSTANDARD SSTL15 [get_ports ddr3_ras_n]
set_property PACKAGE_PIN H11 [get_ports ddr3_ras_n]

# PadFunction: IO_L17P_T2_34
set_property VCCAUX_IO HIGH [get_ports ddr3_cas_n]
set_property SLEW FAST [get_ports ddr3_cas_n]
set_property IOSTANDARD SSTL15 [get_ports ddr3_cas_n]
set_property PACKAGE_PIN E7 [get_ports ddr3_cas_n]

# PadFunction: IO_L16N_T2_34
set_property VCCAUX_IO HIGH [get_ports ddr3_we_n]
set_property SLEW FAST [get_ports ddr3_we_n]
set_property IOSTANDARD SSTL15 [get_ports ddr3_we_n]
set_property PACKAGE_PIN F7 [get_ports ddr3_we_n]

# PadFunction: IO_L7P_T1_AD2P_35
set_property VCCAUX_IO HIGH [get_ports ddr3_reset_n]
set_property SLEW FAST [get_ports ddr3_reset_n]
set_property IOSTANDARD LVCMOS15 [get_ports ddr3_reset_n]
set_property PACKAGE_PIN G17 [get_ports ddr3_reset_n]

# PadFunction: IO_L10N_T1_34
set_property VCCAUX_IO HIGH [get_ports {ddr3_cke[0]}]
set_property SLEW FAST [get_ports {ddr3_cke[0]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_cke[0]}]
set_property PACKAGE_PIN D10 [get_ports {ddr3_cke[0]}]

# PadFunction: IO_L18N_T2_34
set_property VCCAUX_IO HIGH [get_ports {ddr3_odt[0]}]
set_property SLEW FAST [get_ports {ddr3_odt[0]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_odt[0]}]
set_property PACKAGE_PIN G7 [get_ports {ddr3_odt[0]}]

# PadFunction: IO_L7P_T1_34
set_property VCCAUX_IO HIGH [get_ports {ddr3_cs_n[0]}]
set_property SLEW FAST [get_ports {ddr3_cs_n[0]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_cs_n[0]}]
set_property PACKAGE_PIN J11 [get_ports {ddr3_cs_n[0]}]

# PadFunction: IO_L1N_T0_33
set_property VCCAUX_IO HIGH [get_ports {ddr3_dm[0]}]
set_property SLEW FAST [get_ports {ddr3_dm[0]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dm[0]}]
set_property PACKAGE_PIN J3 [get_ports {ddr3_dm[0]}]

# PadFunction: IO_L7N_T1_33
set_property VCCAUX_IO HIGH [get_ports {ddr3_dm[1]}]
set_property SLEW FAST [get_ports {ddr3_dm[1]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dm[1]}]
set_property PACKAGE_PIN F2 [get_ports {ddr3_dm[1]}]

# PadFunction: IO_L18P_T2_33
set_property VCCAUX_IO HIGH [get_ports {ddr3_dm[2]}]
set_property SLEW FAST [get_ports {ddr3_dm[2]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dm[2]}]
set_property PACKAGE_PIN E1 [get_ports {ddr3_dm[2]}]

# PadFunction: IO_L22P_T3_33
set_property VCCAUX_IO HIGH [get_ports {ddr3_dm[3]}]
set_property SLEW FAST [get_ports {ddr3_dm[3]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dm[3]}]
set_property PACKAGE_PIN C2 [get_ports {ddr3_dm[3]}]

# PadFunction: IO_L24P_T3_34
set_property VCCAUX_IO HIGH [get_ports {ddr3_dm[4]}]
set_property SLEW FAST [get_ports {ddr3_dm[4]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dm[4]}]
set_property PACKAGE_PIN L12 [get_ports {ddr3_dm[4]}]

# PadFunction: IO_L8N_T1_AD10N_35
set_property VCCAUX_IO HIGH [get_ports {ddr3_dm[5]}]
set_property SLEW FAST [get_ports {ddr3_dm[5]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dm[5]}]
set_property PACKAGE_PIN G14 [get_ports {ddr3_dm[5]}]

# PadFunction: IO_L16N_T2_35
set_property VCCAUX_IO HIGH [get_ports {ddr3_dm[6]}]
set_property SLEW FAST [get_ports {ddr3_dm[6]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dm[6]}]
set_property PACKAGE_PIN C16 [get_ports {ddr3_dm[6]}]

# PadFunction: IO_L22P_T3_AD7P_35
set_property VCCAUX_IO HIGH [get_ports {ddr3_dm[7]}]
set_property SLEW FAST [get_ports {ddr3_dm[7]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dm[7]}]
set_property PACKAGE_PIN C11 [get_ports {ddr3_dm[7]}]

set_property VCCAUX_IO DONTCARE [get_ports c0_sys_clk_p]
set_property IOSTANDARD DIFF_SSTL15 [get_ports c0_sys_clk_p]
set_property PACKAGE_PIN H9 [get_ports c0_sys_clk_p]

set_property IOSTANDARD DIFF_SSTL15 [get_ports c0_sys_clk_n]
set_property PACKAGE_PIN G9 [get_ports c0_sys_clk_n]

# set_property SLEW SLOW [get_ports clk_200mhz]
# set_property IOSTANDARD LVCMOS15 [get_ports clk_200mhz]
# set_property PACKAGE_PIN AJ21 [get_ports clk_200mhz]

# PadFunction: IO_L3P_T0_DQS_33
set_property VCCAUX_IO HIGH [get_ports {ddr3_dqs_p[0]}]
set_property SLEW FAST [get_ports {ddr3_dqs_p[0]}]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddr3_dqs_p[0]}]

# PadFunction: IO_L3N_T0_DQS_33
set_property SLEW FAST [get_ports {ddr3_dqs_n[0]}]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddr3_dqs_n[0]}]
set_property PACKAGE_PIN K3 [get_ports {ddr3_dqs_p[0]}]
set_property PACKAGE_PIN K2 [get_ports {ddr3_dqs_n[0]}]

# PadFunction: IO_L9P_T1_DQS_33
set_property VCCAUX_IO HIGH [get_ports {ddr3_dqs_p[1]}]
set_property SLEW FAST [get_ports {ddr3_dqs_p[1]}]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddr3_dqs_p[1]}]

# PadFunction: IO_L9N_T1_DQS_33
set_property SLEW FAST [get_ports {ddr3_dqs_n[1]}]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddr3_dqs_n[1]}]
set_property PACKAGE_PIN J1 [get_ports {ddr3_dqs_p[1]}]
set_property PACKAGE_PIN H1 [get_ports {ddr3_dqs_n[1]}]

# PadFunction: IO_L15P_T2_DQS_33
set_property VCCAUX_IO HIGH [get_ports {ddr3_dqs_p[2]}]
set_property SLEW FAST [get_ports {ddr3_dqs_p[2]}]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddr3_dqs_p[2]}]

# PadFunction: IO_L15N_T2_DQS_33
set_property SLEW FAST [get_ports {ddr3_dqs_n[2]}]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddr3_dqs_n[2]}]
set_property PACKAGE_PIN E6 [get_ports {ddr3_dqs_p[2]}]
set_property PACKAGE_PIN D5 [get_ports {ddr3_dqs_n[2]}]

# PadFunction: IO_L21P_T3_DQS_33
set_property VCCAUX_IO HIGH [get_ports {ddr3_dqs_p[3]}]
set_property SLEW FAST [get_ports {ddr3_dqs_p[3]}]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddr3_dqs_p[3]}]

# PadFunction: IO_L21N_T3_DQS_33
set_property SLEW FAST [get_ports {ddr3_dqs_n[3]}]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddr3_dqs_n[3]}]
set_property PACKAGE_PIN A5 [get_ports {ddr3_dqs_p[3]}]
set_property PACKAGE_PIN A4 [get_ports {ddr3_dqs_n[3]}]

# PadFunction: IO_L21P_T3_DQS_34
set_property VCCAUX_IO HIGH [get_ports {ddr3_dqs_p[4]}]
set_property SLEW FAST [get_ports {ddr3_dqs_p[4]}]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddr3_dqs_p[4]}]

# PadFunction: IO_L21N_T3_DQS_34
set_property SLEW FAST [get_ports {ddr3_dqs_n[4]}]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddr3_dqs_n[4]}]
set_property PACKAGE_PIN L8 [get_ports {ddr3_dqs_p[4]}]
set_property PACKAGE_PIN K8 [get_ports {ddr3_dqs_n[4]}]

# PadFunction: IO_L9P_T1_DQS_AD3P_35
set_property VCCAUX_IO HIGH [get_ports {ddr3_dqs_p[5]}]
set_property SLEW FAST [get_ports {ddr3_dqs_p[5]}]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddr3_dqs_p[5]}]

# PadFunction: IO_L9N_T1_DQS_AD3N_35
set_property SLEW FAST [get_ports {ddr3_dqs_n[5]}]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddr3_dqs_n[5]}]
set_property PACKAGE_PIN G12 [get_ports {ddr3_dqs_p[5]}]
set_property PACKAGE_PIN F12 [get_ports {ddr3_dqs_n[5]}]

# PadFunction: IO_L15P_T2_DQS_AD12P_35
set_property VCCAUX_IO HIGH [get_ports {ddr3_dqs_p[6]}]
set_property SLEW FAST [get_ports {ddr3_dqs_p[6]}]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddr3_dqs_p[6]}]

# PadFunction: IO_L15N_T2_DQS_AD12N_35
set_property SLEW FAST [get_ports {ddr3_dqs_n[6]}]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddr3_dqs_n[6]}]
set_property PACKAGE_PIN F17 [get_ports {ddr3_dqs_p[6]}]
set_property PACKAGE_PIN E17 [get_ports {ddr3_dqs_n[6]}]

# PadFunction: IO_L21P_T3_DQS_AD14P_35
set_property VCCAUX_IO HIGH [get_ports {ddr3_dqs_p[7]}]
set_property SLEW FAST [get_ports {ddr3_dqs_p[7]}]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddr3_dqs_p[7]}]

# PadFunction: IO_L21N_T3_DQS_AD14N_35
set_property SLEW FAST [get_ports {ddr3_dqs_n[7]}]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddr3_dqs_n[7]}]
set_property PACKAGE_PIN B15 [get_ports {ddr3_dqs_p[7]}]
set_property PACKAGE_PIN A15 [get_ports {ddr3_dqs_n[7]}]

# PadFunction: IO_L11P_T1_SRCC_34
set_property VCCAUX_IO HIGH [get_ports {ddr3_ck_p[0]}]
set_property SLEW FAST [get_ports {ddr3_ck_p[0]}]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddr3_ck_p[0]}]

# PadFunction: IO_L11N_T1_SRCC_34
set_property SLEW FAST [get_ports {ddr3_ck_n[0]}]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddr3_ck_n[0]}]
set_property PACKAGE_PIN G10 [get_ports {ddr3_ck_p[0]}]
set_property PACKAGE_PIN F10 [get_ports {ddr3_ck_n[0]}]

set_property IODELAY_GROUP MEMCTL_IODELAY_MIG0 [get_cells -hier -filter {NAME =~ *.idelaye2}]

set_property LOC PHASER_OUT_PHY_X1Y19 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_2.u_ddr_phy_4lanes/ddr_byte_lane_D.ddr_byte_lane_D/phaser_out}]
set_property LOC PHASER_OUT_PHY_X1Y18 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_2.u_ddr_phy_4lanes/ddr_byte_lane_C.ddr_byte_lane_C/phaser_out}]
set_property LOC PHASER_OUT_PHY_X1Y17 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_2.u_ddr_phy_4lanes/ddr_byte_lane_B.ddr_byte_lane_B/phaser_out}]
set_property LOC PHASER_OUT_PHY_X1Y16 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_2.u_ddr_phy_4lanes/ddr_byte_lane_A.ddr_byte_lane_A/phaser_out}]
set_property LOC PHASER_OUT_PHY_X1Y23 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_1.u_ddr_phy_4lanes/ddr_byte_lane_D.ddr_byte_lane_D/phaser_out}]
set_property LOC PHASER_OUT_PHY_X1Y22 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_1.u_ddr_phy_4lanes/ddr_byte_lane_C.ddr_byte_lane_C/phaser_out}]
set_property LOC PHASER_OUT_PHY_X1Y21 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_1.u_ddr_phy_4lanes/ddr_byte_lane_B.ddr_byte_lane_B/phaser_out}]
set_property LOC PHASER_OUT_PHY_X1Y20 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_1.u_ddr_phy_4lanes/ddr_byte_lane_A.ddr_byte_lane_A/phaser_out}]
set_property LOC PHASER_OUT_PHY_X1Y26 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_C.ddr_byte_lane_C/phaser_out}]
set_property LOC PHASER_OUT_PHY_X1Y25 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_B.ddr_byte_lane_B/phaser_out}]
set_property LOC PHASER_OUT_PHY_X1Y24 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_A.ddr_byte_lane_A/phaser_out}]

set_property LOC PHASER_IN_PHY_X1Y19 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_2.u_ddr_phy_4lanes/ddr_byte_lane_D.ddr_byte_lane_D/phaser_in_gen.phaser_in}]
set_property LOC PHASER_IN_PHY_X1Y18 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_2.u_ddr_phy_4lanes/ddr_byte_lane_C.ddr_byte_lane_C/phaser_in_gen.phaser_in}]
set_property LOC PHASER_IN_PHY_X1Y17 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_2.u_ddr_phy_4lanes/ddr_byte_lane_B.ddr_byte_lane_B/phaser_in_gen.phaser_in}]
set_property LOC PHASER_IN_PHY_X1Y16 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_2.u_ddr_phy_4lanes/ddr_byte_lane_A.ddr_byte_lane_A/phaser_in_gen.phaser_in}]
set_property LOC PHASER_IN_PHY_X1Y20 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_1.u_ddr_phy_4lanes/ddr_byte_lane_A.ddr_byte_lane_A/phaser_in_gen.phaser_in}]
set_property LOC PHASER_IN_PHY_X1Y26 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_C.ddr_byte_lane_C/phaser_in_gen.phaser_in}]
set_property LOC PHASER_IN_PHY_X1Y25 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_B.ddr_byte_lane_B/phaser_in_gen.phaser_in}]
set_property LOC PHASER_IN_PHY_X1Y24 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_A.ddr_byte_lane_A/phaser_in_gen.phaser_in}]

set_property LOC OUT_FIFO_X1Y19 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_2.u_ddr_phy_4lanes/ddr_byte_lane_D.ddr_byte_lane_D/out_fifo}]
set_property LOC OUT_FIFO_X1Y18 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_2.u_ddr_phy_4lanes/ddr_byte_lane_C.ddr_byte_lane_C/out_fifo}]
set_property LOC OUT_FIFO_X1Y17 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_2.u_ddr_phy_4lanes/ddr_byte_lane_B.ddr_byte_lane_B/out_fifo}]
set_property LOC OUT_FIFO_X1Y16 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_2.u_ddr_phy_4lanes/ddr_byte_lane_A.ddr_byte_lane_A/out_fifo}]
set_property LOC OUT_FIFO_X1Y23 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_1.u_ddr_phy_4lanes/ddr_byte_lane_D.ddr_byte_lane_D/out_fifo}]
set_property LOC OUT_FIFO_X1Y22 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_1.u_ddr_phy_4lanes/ddr_byte_lane_C.ddr_byte_lane_C/out_fifo}]
set_property LOC OUT_FIFO_X1Y21 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_1.u_ddr_phy_4lanes/ddr_byte_lane_B.ddr_byte_lane_B/out_fifo}]
set_property LOC OUT_FIFO_X1Y20 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_1.u_ddr_phy_4lanes/ddr_byte_lane_A.ddr_byte_lane_A/out_fifo}]
set_property LOC OUT_FIFO_X1Y26 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_C.ddr_byte_lane_C/out_fifo}]
set_property LOC OUT_FIFO_X1Y25 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_B.ddr_byte_lane_B/out_fifo}]
set_property LOC OUT_FIFO_X1Y24 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_A.ddr_byte_lane_A/out_fifo}]

set_property LOC IN_FIFO_X1Y19 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_2.u_ddr_phy_4lanes/ddr_byte_lane_D.ddr_byte_lane_D/in_fifo_gen.in_fifo}]
set_property LOC IN_FIFO_X1Y18 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_2.u_ddr_phy_4lanes/ddr_byte_lane_C.ddr_byte_lane_C/in_fifo_gen.in_fifo}]
set_property LOC IN_FIFO_X1Y17 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_2.u_ddr_phy_4lanes/ddr_byte_lane_B.ddr_byte_lane_B/in_fifo_gen.in_fifo}]
set_property LOC IN_FIFO_X1Y16 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_2.u_ddr_phy_4lanes/ddr_byte_lane_A.ddr_byte_lane_A/in_fifo_gen.in_fifo}]
set_property LOC IN_FIFO_X1Y20 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_1.u_ddr_phy_4lanes/ddr_byte_lane_A.ddr_byte_lane_A/in_fifo_gen.in_fifo}]
set_property LOC IN_FIFO_X1Y26 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_C.ddr_byte_lane_C/in_fifo_gen.in_fifo}]
set_property LOC IN_FIFO_X1Y25 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_B.ddr_byte_lane_B/in_fifo_gen.in_fifo}]
set_property LOC IN_FIFO_X1Y24 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_A.ddr_byte_lane_A/in_fifo_gen.in_fifo}]

set_property LOC PHY_CONTROL_X1Y4 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_2.u_ddr_phy_4lanes/phy_control_i}]
set_property LOC PHY_CONTROL_X1Y5 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_1.u_ddr_phy_4lanes/phy_control_i}]
set_property LOC PHY_CONTROL_X1Y6 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/phy_control_i}]

set_property LOC PHASER_REF_X1Y4 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_2.u_ddr_phy_4lanes/phaser_ref_i}]
set_property LOC PHASER_REF_X1Y5 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_1.u_ddr_phy_4lanes/phaser_ref_i}]
set_property LOC PHASER_REF_X1Y6 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/phaser_ref_i}]

set_property LOC OLOGIC_X1Y243 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_2.u_ddr_phy_4lanes/ddr_byte_lane_D.ddr_byte_lane_D/ddr_byte_group_io/*slave_ts}]
set_property LOC OLOGIC_X1Y231 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_2.u_ddr_phy_4lanes/ddr_byte_lane_C.ddr_byte_lane_C/ddr_byte_group_io/*slave_ts}]
set_property LOC OLOGIC_X1Y219 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_2.u_ddr_phy_4lanes/ddr_byte_lane_B.ddr_byte_lane_B/ddr_byte_group_io/*slave_ts}]
set_property LOC OLOGIC_X1Y207 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_2.u_ddr_phy_4lanes/ddr_byte_lane_A.ddr_byte_lane_A/ddr_byte_group_io/*slave_ts}]
set_property LOC OLOGIC_X1Y257 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_1.u_ddr_phy_4lanes/ddr_byte_lane_A.ddr_byte_lane_A/ddr_byte_group_io/*slave_ts}]
set_property LOC OLOGIC_X1Y331 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_C.ddr_byte_lane_C/ddr_byte_group_io/*slave_ts}]
set_property LOC OLOGIC_X1Y319 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_B.ddr_byte_lane_B/ddr_byte_group_io/*slave_ts}]
set_property LOC OLOGIC_X1Y307 [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_A.ddr_byte_lane_A/ddr_byte_group_io/*slave_ts}]

set_property LOC PLLE2_ADV_X1Y5 [get_cells -hier -filter {NAME =~ */u_ddr3_infrastructure/plle2_i}]
set_property LOC MMCME2_ADV_X1Y5 [get_cells -hier -filter {NAME =~ */u_ddr3_infrastructure/gen_mmcm.mmcm_i}]

set_false_path -through [get_pins -filter {NAME =~ */DQSFOUND} -of [get_cells -hier -filter {REF_NAME == PHASER_IN_PHY}]]

set_multicycle_path -setup -start -through [get_pins -filter {NAME =~ */OSERDESRST} -of [get_cells -hier -filter {REF_NAME == PHASER_OUT_PHY}]] 2
set_multicycle_path -hold -start -through [get_pins -filter {NAME =~ */OSERDESRST} -of [get_cells -hier -filter {REF_NAME == PHASER_OUT_PHY}]] 1

set_max_delay -datapath_only -from [get_cells -hier -filter {NAME =~ *temp_mon_enabled.u_tempmon/* && IS_SEQUENTIAL}] -to [get_cells -hier -filter {NAME =~ *temp_mon_enabled.u_tempmon/device_temp_sync_r1*}] 20.000
set_max_delay -datapath_only -from [get_cells -hier *rstdiv0_sync_r1_reg*] -to [get_pins -filter {NAME =~ */RESET} -of [get_cells -hier -filter {REF_NAME == PHY_CONTROL}]] 5.000

set_max_delay -datapath_only -from [get_cells -hier -filter {NAME =~ *ddr3_infrastructure/rstdiv0_sync_r1_reg*}] -to [get_cells -hier -filter {NAME =~ *temp_mon_enabled.u_tempmon/xadc_supplied_temperature.rst_r1*}] 20.000

# PCIE
set_property LOC GTXE2_CHANNEL_X0Y15 [get_cells {zc706_pcie/zc706_pcie_x4_gen2_support_i/zc706_pcie_x4_gen2_i/inst/inst/gt_top_i/pipe_wrapper_i/pipe_lane[0].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
set_property PACKAGE_PIN P5 [get_ports {pci_exp_rxn[0]}]
set_property PACKAGE_PIN P6 [get_ports {pci_exp_rxp[0]}]
set_property PACKAGE_PIN N3 [get_ports {pci_exp_txn[0]}]
set_property PACKAGE_PIN N4 [get_ports {pci_exp_txp[0]}]

set_property LOC GTXE2_CHANNEL_X0Y14 [get_cells {zc706_pcie/zc706_pcie_x4_gen2_support_i/zc706_pcie_x4_gen2_i/inst/inst/gt_top_i/pipe_wrapper_i/pipe_lane[1].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
set_property PACKAGE_PIN T5 [get_ports {pci_exp_rxn[1]}]
set_property PACKAGE_PIN T6 [get_ports {pci_exp_rxp[1]}]
set_property PACKAGE_PIN P1 [get_ports {pci_exp_txn[1]}]
set_property PACKAGE_PIN P2 [get_ports {pci_exp_txp[1]}]

set_property LOC GTXE2_CHANNEL_X0Y13 [get_cells {zc706_pcie/zc706_pcie_x4_gen2_support_i/zc706_pcie_x4_gen2_i/inst/inst/gt_top_i/pipe_wrapper_i/pipe_lane[2].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
set_property PACKAGE_PIN U3 [get_ports {pci_exp_rxn[2]}]
set_property PACKAGE_PIN U4 [get_ports {pci_exp_rxp[2]}]
set_property PACKAGE_PIN R3 [get_ports {pci_exp_txn[2]}]
set_property PACKAGE_PIN R4 [get_ports {pci_exp_txp[2]}]

set_property LOC GTXE2_CHANNEL_X0Y12 [get_cells {zc706_pcie/zc706_pcie_x4_gen2_support_i/zc706_pcie_x4_gen2_i/inst/inst/gt_top_i/pipe_wrapper_i/pipe_lane[3].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
set_property PACKAGE_PIN V5 [get_ports {pci_exp_rxn[3]}]
set_property PACKAGE_PIN V6 [get_ports {pci_exp_rxp[3]}]
set_property PACKAGE_PIN T1 [get_ports {pci_exp_txn[3]}]
set_property PACKAGE_PIN T2 [get_ports {pci_exp_txp[3]}]

set_property IOSTANDARD LVCMOS15 [get_ports pcie_rst_n]
set_property PULLUP true [get_ports pcie_rst_n]
set_property PACKAGE_PIN AK23 [get_ports pcie_rst_n]

create_clock -period 10.000 -name sys_clk -waveform {0.000 5.000} [get_ports clk_ref_p]
set_clock_groups -asynchronous -group [get_clocks sys_clk -include_generated_clocks]
set_false_path -to [get_pins zc706_pcie/zc706_pcie_x4_gen2_support_i/pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/S0]
set_false_path -to [get_pins zc706_pcie/zc706_pcie_x4_gen2_support_i/pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/S1]
create_generated_clock -name clk_125mhz_x0y0 [get_pins zc706_pcie/zc706_pcie_x4_gen2_support_i/pipe_clock_i/mmcm_i/CLKOUT0]
create_generated_clock -name clk_250mhz_x0y0 [get_pins zc706_pcie/zc706_pcie_x4_gen2_support_i/pipe_clock_i/mmcm_i/CLKOUT1]
create_generated_clock -name clk_125mhz_mux_x0y0 -source [get_pins zc706_pcie/zc706_pcie_x4_gen2_support_i/pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/I0] -divide_by 1 [get_pins zc706_pcie/zc706_pcie_x4_gen2_support_i/pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/O]
create_generated_clock -name clk_250mhz_mux_x0y0 -source [get_pins zc706_pcie/zc706_pcie_x4_gen2_support_i/pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/I1] -divide_by 1 -add -master_clock [get_clocks -of [get_pins zc706_pcie/zc706_pcie_x4_gen2_support_i/pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/I1]] [get_pins zc706_pcie/zc706_pcie_x4_gen2_support_i/pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/O]
set_clock_groups -name pcieclkmux -physically_exclusive -group clk_125mhz_mux_x0y0 -group clk_250mhz_mux_x0y0

set_property LOC IBUFDS_GTE2_X0Y6 [get_cells zc706_pcie/refclk_ibuf]

set_false_path -from [get_ports pcie_rst_n]
