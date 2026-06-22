############################################################################
#  DISCLAIMER:
#  XILINX IS DISCLOSING THIS USER GUIDE, MANUAL, RELEASE NOTE,
#  SCHEMATIC, AND/OR SPECIFICATION (THE "DOCUMENTATION")TO YOU SOLELY
#  FOR USE IN THE DEVELOPMENT OF DESIGNS TO OPERATE WITH XILINX
#  HARDWARE DEVICES. YOU MAY NOT REPRODUCE, DISTRIBUTE, REPUBLISH,
#  DOWNLOAD, DISPLAY, POST, OR TRANSMIT THE DOCUMENTATION IN ANY FORM
#  OR BY ANY MEANS INCLUDING, BUT NOT LIMITED TO, ELECTRONIC,
#  MECHANICAL, PHOTOCOPYING, RECORDING, OR OTHERWISE, WITHOUT THE
#  PRIOR WRITTEN CONSENT OF XILINX. XILINX EXPRESSLY DISCLAIMS ANY
#  LIABILITY ARISING OUT OF YOUR USE OF THE DOCUMENTATION.
#  XILINX RESERVES THE RIGHT, AT ITS SOLE DISCRETION, TO CHANGE THE
#  DOCUMENTATION WITHOUT NOTICE AT ANY TIME. XILINX ASSUMES NO
#  OBLIGATION TO CORRECT ANY ERRORS CONTAINED IN THE DOCUMENTATION,
#  OR TO ADVISE YOU OF ANY CORRECTIONS OR UPDATES. XILINX EXPRESSLY
#  DISCLAIMS ANY LIABILITY IN CONNECTION WITH TECHNICAL SUPPORT OR
#  ASSISTANCETHAT MAY BE PROVIDED TO YOU IN CONNECTION WITH THE
#  DOCUMENTATION.
#  THE DOCUMENTATION IS DISCLOSED TO YOU "AS-IS" WITH NO WARRANTY OF
#  ANY OF THIRD-PARTY RIGHTS. IN NO EVENT WILL XILINXBE LIABLE FOR ANY
#  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR
#  NONINFRINGEMENT STATUTORY, REGARDING THEDOCUMENTATION, INCLUDING
#  ANY WARRANTIES OF KIND.
#  XILINX MAKES NO OTHER WARRANTIES, WHETHER EXPRESS, IMPLIED, OR THE
#  DOCUMENTATION. INCLUDING ANY LOSS OF DATA OR LOST PROFITS, ARISING
#  FROM YOUR USE OF CONSEQUENTIAL, INDIRECT, EXEMPLARY, SPECIAL, OR
#  INCIDENTAL DAMAGES, INCLUDING ANY LOSS OF DATA OR LOST PROFITS,
#  ARISING FROM YOUR USE OF THE DOCUMENTATION.
#
#
#
#   U50QSFP - Master XDC 
#
#   Key Notes:
#       1) PCIe Clocks Support x16 and x8 Bifurcation with both synchronous or asynchronous operation
#       2) Power warning constraint set to warn user if design exceeds 63 Watts
#
#   Clock Tree
#           
#    1) SI5394 - SiLabs Si5394B-A10605-GM
#      - IN0 <-- feedback clock ETH_recovered_clk_P/ETH_recovered_clk_N 
#                PINS: IO_L12P_T1U_N10_GC_68_F19/IO_L12N_T1U_N11_GC_68_F18 #1588 Support
#           
#      - IN1 Unconnected
#           
#      - IN2 Unconnected
#
#      - XA  RPT5032A 40.0000MHz TCXO 
#
#      - OUT0--> SYNCE_CLK_P/SYNCE_CLK_P @ 161.1328125Mhz 
#                PINS: MGTREFCLK0P_131_N36/MGTREFCLK0N_131_N37
#           
#      - OUT1--> CLK_1588_P/CLK_1588_P   @ 322.265625MHz  
#                PINS: MGTREFCLK1P_131_M38/MGTREFCLK1N_131_M39
#           
#      - OUT2 Unconnected
#            
#      - OUT3--> SYNCE_CLK_P/SYNCE_CLK_P @ 100.000Mhz 
#           |
#           |--> SI53306-B-GM --> OUT0  PCIE_SYSCLK0_P/PCIE_SYSCLK0_N 100.000Mhz 
#                             |   PINS: MGTREFCLK1P_227_AA11/MGTREFCLK1N_227_AA10
#                             |
#                             |-> OUT1  PCIE_SYSCLK1_P/PCIE_SYSCLK1_N 100.000Mhz 
#                             |   PINS: MGTREFCLK1P_225_AE11/MGTREFCLK1N_225_AE10
#                             |
#                             |-> OUT2  SYSCLK2_P/SYSCLK2_N 100.000Mhz
#                             |   PINS: IO_L11P_T1U_N8_GC_68/IO_L11N_T1U_N9_GC_68
#                             |
#                             |-> OUT3  SYSCLK3_P/SYSCLK3_N 100.000Mhz 
#                                 PINS: IO_L11P_T1U_N8_GC_64/IO_L11N_T1U_N9_GC_64
#
#   2) PCIE Fingers PEX_REFCLK_P/PEX_REFCLK_P 100Mhz 
#           |->  SI53102 -------> OUT0  PCIE_REFCLK0_P/PCIE_REFCLK0_N 100.000Mhz 
#                             |   PINS: MGTREFCLK0P_227_AB9/MGTREFCLK0N_227_AB8
#                             |
#                             |-> OUT1  PCIE_REFCLK1_P/PCIE_REFCLK1_N 100.000Mhz 
#                                 PINS: MGTREFCLK0P_225_AF9/MGTREFCLK0N_225_AF8
#
#  Revision 1.00.00 - Intial Release
#  Revision 1.00.01 - Removed QSFP_1 references and added addtional debug serial ports.
#                     Added FPGA SYSMON connections to Sattelite Controller.
#                     Add comments to describe input and output information.
#  Revision 1.00.02 - Added constraint to pulldown CATTRIP incase user design does not use the signal.
#                     Added Bitstream generation constraints and support fallback
#  Revision 1.00.03 - Swapped OUT1 and OUT2 on SI5394 in description above, unconnected was on the wrong port.
#                     Changed CONFIGRATE to 63.8 from 85. 85 may not work under all circumstances.
#  Revision 1.00.04 - Formatting and spelling corrections in comments (no functional changes)
#
#################################################################################
#
# Power Constraint to warn User if design will possibly be over cards power limit
#
set_operating_conditions -design_power_budget 63
#
# Bitstream generation
set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property BITSTREAM.CONFIG.CONFIGFALLBACK Enable [current_design]               ;# Golden image is the fall back image if  new bitstream is corrupted.
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 63.8 [current_design]
set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN disable [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN Pullup [current_design]                    ;# Choices are pullnone, pulldown, and pullup.
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR Yes [current_design]
#
# Input SYSTEM CLOCKS (1.8V banks 64 and 68)
#
set_property PACKAGE_PIN G16      [get_ports c0_sys_clk_n]            ;# Bank  68 VCCO - VCC1V8   - IO_L11N_T1U_N9_GC_68
set_property IOSTANDARD  LVDS     [get_ports c0_sys_clk_n]            ;# Bank  68 VCCO - VCC1V8   - IO_L11N_T1U_N9_GC_68
set_property PACKAGE_PIN G17      [get_ports c0_sys_clk_p]            ;# Bank  68 VCCO - VCC1V8   - IO_L11P_T1U_N8_GC_68
set_property IOSTANDARD  LVDS     [get_ports c0_sys_clk_p]            ;# Bank  68 VCCO - VCC1V8   - IO_L11P_T1U_N8_GC_68
set_property DQS_BIAS TRUE        [get_ports c0_sys_clk_p]            ;# Bank  68 VCCO - VCC1V8   - IO_L11P_T1U_N8_GC_68
#set_property PACKAGE_PIN BC18     [get_ports "SYSCLK3_N"]            ;# Bank  64 VCCO - VCC1V8   - IO_L11N_T1U_N9_GC_64
#set_property IOSTANDARD  LVDS     [get_ports "SYSCLK3_N"]            ;# Bank  64 VCCO - VCC1V8   - IO_L11N_T1U_N9_GC_64
#set_property PACKAGE_PIN BB18     [get_ports "SYSCLK3_P"]            ;# Bank  64 VCCO - VCC1V8   - IO_L11P_T1U_N8_GC_64
#set_property IOSTANDARD  LVDS     [get_ports "SYSCLK3_P"]            ;# Bank  64 VCCO - VCC1V8   - IO_L11P_T1U_N8_GC_64
#set_property DQS_BIAS TRUE        [get_ports "SYSCLK3_P"]            ;# Bank  64 VCCO - VCC1V8   - IO_L11P_T1U_N8_GC_64
#
# MGT Clocks
#
# PCIe Clocks 
#
# Input Clocks for Gen3 x16  or Dual x8 Bifurcation on Lane 8-15
# PCIE_REFCLK0 -> PCIe Host clock
# PCIE_SYSCLK0 -> PCIe Asynchronous clock
set_property PACKAGE_PIN AB8      [get_ports clk_ref_n]       ;# Bank 227 - MGTREFCLK0N_227
set_property PACKAGE_PIN AB9      [get_ports clk_ref_p]       ;# Bank 227 - MGTREFCLK0P_227
#set_property PACKAGE_PIN AA10     [get_ports "PCIE_SYSCLK0_N"]       ;# Bank 227 - MGTREFCLK1N_227
#set_property PACKAGE_PIN AA11     [get_ports "PCIE_SYSCLK0_P"]       ;# Bank 227 - MGTREFCLK1P_227
#
# Input Clocks for Dual x8 Bifurcation on Lane 0-7
# PCIE_REFCLK1 -> PCIe Host clock
# PCIE_SYSCLK1 -> PCIe Asynchronous clock 
#set_property PACKAGE_PIN AF8      [get_ports "PCIE_REFCLK1_N"]       ;# Bank 225 - MGTREFCLK0N_225
#set_property PACKAGE_PIN AF9      [get_ports "PCIE_REFCLK1_P"]       ;# Bank 225 - MGTREFCLK0P_225
#set_property PACKAGE_PIN AE10     [get_ports "PCIE_SYSCLK1_N"]       ;# Bank 225 - MGTREFCLK1N_225
#set_property PACKAGE_PIN AE11     [get_ports "PCIE_SYSCLK1_P"]       ;# Bank 225 - MGTREFCLK1P_225
#
# Input QSFP28 Clocks
#
# SYNCE_CLK   -> Ethernet Clock
# CLK_1588    -> 1588 PTP Clock 
#set_property PACKAGE_PIN N37      [get_ports "SYNCE_CLK_N"]          ;# Bank 131 - MGTREFCLK0N_131 
#set_property PACKAGE_PIN N36      [get_ports "SYNCE_CLK_P"]          ;# Bank 131 - MGTREFCLK0P_131
#set_property PACKAGE_PIN M39      [get_ports "CLK_1588_N"]           ;# Bank 131 - MGTREFCLK1N_131
#set_property PACKAGE_PIN M38      [get_ports "CLK_1588_P"]           ;# Bank 131 - MGTREFCLK1P_131
#
# Create Clock Constraints
#
create_clock -period 10.000 -name sysclk2        [get_ports c0_sys_clk_p]
#create_clock -period 10.000 -name sysclk3        [get_ports "SYSCLK3_P"]
create_clock -period 10.000 -name pcie_ref_clk0  [get_ports clk_ref_p]
#create_clock -period 10.000 -name async_ref_clk0 [get_ports "PCIE_SYSCLK0_P"]
#create_clock -period 10.000 -name pcie_ref_clk1  [get_ports "PCIE_REFCLK1_P"]
#create_clock -period 10.000 -name async_ref_clk1 [get_ports "PCIE_SYSCLK1_P"]
#create_clock -period 6.206  -name gtrefclk0      [get_ports "SYNCE_CLK_P"]
#create_clock -period 3.103  -name gtrefclk1      [get_ports "CLK_1588_P"]
set_clock_groups -asynchronous -group [get_clocks c0_sys_clk_p -include_generated_clocks]
set_clock_groups -asynchronous -group [get_clocks pcie_ref_clk0 -include_generated_clocks]                                                                    
# Bank 65 PCIe Connections    (1.8V bank)  
#    PCIE_PERSTN Active low input from PCIe Connector to FPGA to detect presence.                                         
#    PEX_PWRBRKN Active low input from PCIe Connector signalling PCIe card to shut down card power in Server failing condition.
#
set_property PACKAGE_PIN AW27     [get_ports pcie_rst]          ;# Bank  65 VCCO - VCC1V8   - IO_T3U_N12_PERSTN0_65
set_property IOSTANDARD  LVCMOS18 [get_ports pcie_rst]          ;# Bank  65 VCCO - VCC1V8   - IO_T3U_N12_PERSTN0_65
#set_property PULLUP true [get_ports pcie_rst]
#set_property PACKAGE_PIN BD28     [get_ports "PEX_PWRBRKN"]          ;# Bank  65 VCCO - VCC1V8   - IO_L17N_T2U_N9_AD1_D15_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "PEX_PWRBRKN"]          ;# Bank  65 VCCO - VCC1V8   - IO_L17N_T2U_N9_AD1N_D15_65
#
# Bank 65 FPGA to Sattelite Controller UART Interface (115200, No parity, 8 bits, 1 stop bit)
#    FPGA_RXD_MSP  Input from Satellite Controller UART to FPGA
#    FPGA_TXD_MSP  Output from FPGA to Satellite Controller UART
#    This interface is used for the CMS command path, refer to https://www.xilinx.com/products/intellectual-property/cms-subsystem.html and Xilinx PG348
#
#set_property PACKAGE_PIN BB26     [get_ports "FPGA_RXD_MSP"]         ;# Bank  65 VCCO - VCC1V8   - IO_L13N_T2L_N1_GC_QBC_A07_D23_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "FPGA_RXD_MSP"]         ;# Bank  65 VCCO - VCC1V8   - IO_L13N_T2L_N1_GC_QBC_A07_D23_65
#set_property PACKAGE_PIN BB25     [get_ports "FPGA_TXD_MSP"]         ;# Bank  65 VCCO - VCC1V8   - IO_L13P_T2L_N0_GC_QBC_A06_D22_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "FPGA_TXD_MSP"]         ;# Bank  65 VCCO - VCC1V8   - IO_L13P_T2L_N0_GC_QBC_A06_D22_65
#
# Bank 65 FPGA SYSMON I2C Slave Interface to Sattelite Controller to monitor FPGA Temperatures and Voltages.
#    SYSMON_SCL   Slave I2C clock connection from Satellite Controller to FPGA
#    SYSMON_SDA   Slave I2C data connection from Satellite Controller to FPGA
#    SYSMON_ALRTN Slave I2C active low interrupt output from FPGA to Satellite Controller
#
#set_property PACKAGE_PIN AY27     [get_ports "SYSMON_SDA"]          ;# Bank  65 VCCO - VCC1V8   - IO_L23N_T3U_N9_PERSTN1_I2C_SDA_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "SYSMON_SDA"]          ;# Bank  65 VCCO - VCC1V8   - IO_L23N_T3U_N9_PERSTN1_I2C_SDA_65
#set_property PACKAGE_PIN AY26     [get_ports "SYSMON_SCL"]          ;# Bank  65 VCCO - VCC1V8   - IO_L23P_T3U_N8_I2C_SCLK_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "SYSMON_SCL"]          ;# Bank  65 VCCO - VCC1V8   - IO_L23P_T3U_N8_I2C_SCLK_65
#set_property PACKAGE_PIN BF22     [get_ports "SYSMON_ALRTN"]        ;# Bank  65 VCCO - VCC1V8   - IO_T1U_N12_SMBALERT_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "SYSMON_ALRTN"]        ;# Bank  65 VCCO - VCC1V8   - IO_T1U_N12_SMBALERT_65
#
# Bank 65 and 68 FPGA UART Interface 0/1/2 to DMB-01 (User selectable Baud)
#    FPGA_UART0/1/2_RXD  Input from DBM-01 UART to FPGA
#    FPGA_UART0/1/2_TXD  Output from FPGA to DBM-01 UART
#
#set_property PACKAGE_PIN BF26     [get_ports "FPGA_UART0_RXD"]        ;# Bank  65 VCCO - VCC1V8   - IO_L15N_T2L_N5_AD11N_A03_D165
#set_property IOSTANDARD  LVCMOS18 [get_ports "FPGA_UART0_RXD"]        ;# Bank  65 VCCO - VCC1V8   - IO_L15N_T2L_N5_AD11N_A03_D165
#set_property PACKAGE_PIN BE26     [get_ports "FPGA_UART0_TXD"]        ;# Bank  65 VCCO - VCC1V8   - IO_L15P_T2L_N4_AD11P_A02_D1_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "FPGA_UART0_TXD"]        ;# Bank  65 VCCO - VCC1V8   - IO_L15P_T2L_N4_AD11P_A02_D165
#set_property PACKAGE_PIN B15      [get_ports "FPGA_UART1_RXD"]        ;# Bank  68 VCCO - VCC1V8   - IO_L24P_T3U_N10_68
#set_property IOSTANDARD  LVCMOS18 [get_ports "FPGA_UART1_RXD"]        ;# Bank  68 VCCO - VCC1V8   - IO_L24P_T3U_N10_68
#set_property PACKAGE_PIN A17      [get_ports "FPGA_UART1_TXD"]        ;# Bank  68 VCCO - VCC1V8   - IO_L23N_T3U_N9_68
#set_property IOSTANDARD  LVCMOS18 [get_ports "FPGA_UART1_TXD"]        ;# Bank  68 VCCO - VCC1V8   - IO_L23N_T3U_N9_68
#set_property PACKAGE_PIN A18      [get_ports "FPGA_UART2_RXD"]        ;# Bank  68 VCCO - VCC1V8   - IO_L23P_T3U_N8_68
#set_property IOSTANDARD  LVCMOS18 [get_ports "FPGA_UART2_RXD"]        ;# Bank  68 VCCO - VCC1V8   - IO_L23P_T3U_N8_68
#set_property PACKAGE_PIN A19      [get_ports "FPGA_UART2_TXD"]        ;# Bank  68 VCCO - VCC1V8   - IO_L22N_T3U_N7_DBC_AD0N_68
#set_property IOSTANDARD  LVCMOS18 [get_ports "FPGA_UART2_TXD"]        ;# Bank  68 VCCO - VCC1V8   - IO_L22N_T3U_N7_DBC_AD0N_68
# 
# Bank 68 Connections (1.8V bank) QSFP Status Indicators
#    QSFP28_0_ACTIVITY_LED  Active high signal from FPGA to illuminate QSFP green Activity LED
#    QSFP28_0_STATUS_LEDG   Active high signal from FPGA to illuminate QSFP green Status LED
#    QSFP28_0_STATUS_LEDY   Active high signal from FPGA to illuminate QSFP yellow Status LED
#
#set_property PACKAGE_PIN E18      [get_ports icc] ;# Bank  68 VCCO - VCC1V8   - IO_L14P_T2L_N2_GC_68
#set_property IOSTANDARD  LVCMOS18 [get_ports icc] ;# Bank  68 VCCO - VCC1V8   - IO_L14P_T2L_N2_GC_68
#set_property PACKAGE_PIN E16      [get_ports "QSFP28_0_STATUS_LEDG"]  ;# Bank  68 VCCO - VCC1V8   - IO_L13N_T2L_N1_GC_QBC_68 Green LED
#set_property IOSTANDARD  LVCMOS18 [get_ports "QSFP28_0_STATUS_LEDG"]  ;# Bank  68 VCCO - VCC1V8   - IO_L13N_T2L_N1_GC_QBC_68 
#set_property PACKAGE_PIN F17      [get_ports "QSFP28_0_STATUS_LEDY"]  ;# Bank  68 VCCO - VCC1V8   - IO_L13P_T2L_N0_GC_QBC_68 Yellow LED
#set_property IOSTANDARD  LVCMOS18 [get_ports "QSFP28_0_STATUS_LEDY"]  ;# Bank  68 VCCO - VCC1V8   - IO_L13P_T2L_N0_GC_QBC_68
#
# Si5394B-A10605-GM control signals I2C ADDR 0x68
#    SI_RSTB           Active low reset output from FPGA to Si5394B input
#    SI_INTRB          Active low interrupt output from Si5394B to FPGA input
#    SI_PLL_LOCKB      Active low PLL Loss of Lock output from Si5394B to FPGA input
#    SI_IN_LOSB        Active low PLL Loss of Signal output from Si5394B to FPGA input
#    I2C_SI5394_SCLK   Master I2C clock connection from FPGA to Si5394B
#    I2C_SI5394_SDA    Master I2C data connection from FPGA to Si5394B
#    ETH_recovered_clk LVDS clock from FPGA to Si5394B clock input ports IN0 for IEEE-1588 PTP
#
set_property PACKAGE_PIN F20      [get_ports sys_rst_l]              ;# Bank  68 VCCO - VCC1V8   - IO_L10N_T1U_N7_QBC_AD4N_68
set_property IOSTANDARD  LVCMOS18 [get_ports sys_rst_l]              ;# Bank  68 VCCO - VCC1V8   - IO_L10N_T1U_N7_QBC_AD4N_68
#set_property PACKAGE_PIN H18      [get_ports "SI_INTRB"]             ;# Bank  68 VCCO - VCC1V8   - IO_L9P_T1L_N4_AD12P_68
#set_property IOSTANDARD  LVCMOS18 [get_ports "SI_INTRB"]             ;# Bank  68 VCCO - VCC1V8   - IO_L9P_T1L_N4_AD12P_68
#set_property PACKAGE_PIN G19      [get_ports "SI_PLL_LOCKB"]         ;# Bank  68 VCCO - VCC1V8   - IO_L8N_T1L_N3_AD5N_68
#set_property IOSTANDARD  LVCMOS18 [get_ports "SI_PLL_LOCKB"]         ;# Bank  68 VCCO - VCC1V8   - IO_L8N_T1L_N3_AD5N_68
#set_property PACKAGE_PIN H19      [get_ports "SI_IN_LOSB"]           ;# Bank  68 VCCO - VCC1V8   - IO_L8P_T1L_N2_AD5P_68
#set_property IOSTANDARD  LVCMOS18 [get_ports "SI_IN_LOSB"]           ;# Bank  68 VCCO - VCC1V8   - IO_L8P_T1L_N2_AD5P_68
#set_property PACKAGE_PIN L19      [get_ports "I2C_SI5394_SCLK"]      ;# Bank  68 VCCO - VCC1V8   - IO_L5P_T0U_N8_AD14P_68
#set_property IOSTANDARD  LVCMOS18 [get_ports "I2C_SI5394_SCLK"]      ;# Bank  68 VCCO - VCC1V8   - IO_L5P_T0U_N8_AD14P_68
#set_property PACKAGE_PIN J16      [get_ports "I2C_SI5394_SDA"]       ;# Bank  68 VCCO - VCC1V8   - IO_L4N_T0U_N7_DBC_AD7N_68
#set_property IOSTANDARD  LVCMOS18 [get_ports "I2C_SI5394_SDA"]       ;# Bank  68 VCCO - VCC1V8   - IO_L4N_T0U_N7_DBC_AD7N_68
#set_property PACKAGE_PIN F18      [get_ports "ETH_RECOVERED_CLK_N"]  ;# Bank  68 VCCO - VCC1V8   - IO_L12N_T1U_N11_GC_68
#set_property IOSTANDARD  LVDS     [get_ports "ETH_RECOVERED_CLK_N"]  ;# Bank  68 VCCO - VCC1V8   - IO_L12N_T1U_N11_GC_68
#set_property PACKAGE_PIN F19      [get_ports "ETH_RECOVERED_CLK_P"]  ;# Bank  68 VCCO - VCC1V8   - IO_L12P_T1U_N10_GC_68
#set_property IOSTANDARD  LVDS     [get_ports "ETH_RECOVERED_CLK_P"]  ;# Bank  68 VCCO - VCC1V8   - IO_L12P_T1U_N10_GC_68
#
# HBM Catastrophic Over temperature Output signal to Satellite Controller
#    HBM_CATTRIP Active high indicator to Satellite controller to indicate the HBM has exceded its maximum allowable temperature.
#                This signal is not a dedicated FPGA output and is a derived signal in RTL. Making the signal Active will shut
#                the FPGA power rails off.
#
set_property PACKAGE_PIN J18      [get_ports icc]       ;# Bank  68 VCCO - VCC1V8   - IO_L6N_T0U_N11_AD6N_68
set_property IOSTANDARD  LVCMOS18 [get_ports icc]       ;# Bank  68 VCCO - VCC1V8   - IO_L6N_T0U_N11_AD6N_68
set_property PULLDOWN TRUE        [get_ports icc]       ;# Bank  68 VCCO - VCC1V8   - IO_L6N_T0U_N11_AD6N_68
#
# MGTY Connections
#
# These are commented out because typical IPs have the pin location embedded constraints in the IP
#
# QSFP28 MGTY Interface
#
#set_property PACKAGE_PIN J46      QSFP28_0_RX_N[0]     ;# Bank 131 - MGTYRXN0_131
#set_property PACKAGE_PIN G46      QSFP28_0_RX_N[1]     ;# Bank 131 - MGTYRXN1_131
#set_property PACKAGE_PIN F44      QSFP28_0_RX_N[2]     ;# Bank 131 - MGTYRXN2_131
#set_property PACKAGE_PIN E46      QSFP28_0_RX_N[3]     ;# Bank 131 - MGTYRXN3_131
#set_property PACKAGE_PIN J45      QSFP28_0_RX_P[0]     ;# Bank 131 - MGTYRXP0_131
#set_property PACKAGE_PIN G45      QSFP28_0_RX_P[1]     ;# Bank 131 - MGTYRXP1_131
#set_property PACKAGE_PIN F43      QSFP28_0_RX_P[2]     ;# Bank 131 - MGTYRXP2_131
#set_property PACKAGE_PIN E45      QSFP28_0_RX_P[3]     ;# Bank 131 - MGTYRXP3_131
#set_property PACKAGE_PIN D43      QSFP28_0_TX_N[0]     ;# Bank 131 - MGTYTXN0_131
#set_property PACKAGE_PIN C41      QSFP28_0_TX_N[1]     ;# Bank 131 - MGTYTXN1_131
#set_property PACKAGE_PIN B43      QSFP28_0_TX_N[2]     ;# Bank 131 - MGTYTXN2_131
#set_property PACKAGE_PIN A41      QSFP28_0_TX_N[3]     ;# Bank 131 - MGTYTXN3_131
#set_property PACKAGE_PIN D42      QSFP28_0_TX_P[0]     ;# Bank 131 - MGTYTXP0_131
#set_property PACKAGE_PIN C40      QSFP28_0_TX_P[1]     ;# Bank 131 - MGTYTXP1_131
#set_property PACKAGE_PIN B42      QSFP28_0_TX_P[2]     ;# Bank 131 - MGTYTXP2_131
#set_property PACKAGE_PIN A40      QSFP28_0_TX_P[3]     ;# Bank 131 - MGTYTXP3_131
#
# PCIe MGTY Interface
#
#set_property PACKAGE_PIN BE5      [get_ports pci_exp_rxn[7]  ]        ;# Bank 224 - MGTYRXN0_224
#set_property PACKAGE_PIN BD3      [get_ports pci_exp_rxn[6]  ]        ;# Bank 224 - MGTYRXN1_224
#set_property PACKAGE_PIN BB3      [get_ports pci_exp_rxn[5]  ]        ;# Bank 224 - MGTYRXN2_224
#set_property PACKAGE_PIN AY3      [get_ports pci_exp_rxn[4]  ]        ;# Bank 224 - MGTYRXN3_224
#set_property PACKAGE_PIN BE6      [get_ports pci_exp_rxp[7]  ]        ;# Bank 224 - MGTYRXP0_224
#set_property PACKAGE_PIN BD4      [get_ports pci_exp_rxp[6]  ]        ;# Bank 224 - MGTYRXP1_224
#set_property PACKAGE_PIN BB4      [get_ports pci_exp_rxp[5]  ]        ;# Bank 224 - MGTYRXP2_224
#set_property PACKAGE_PIN AY4      [get_ports pci_exp_rxp[4]  ]        ;# Bank 224 - MGTYRXP3_224
#set_property PACKAGE_PIN AT8      [get_ports pci_exp_txn[7]  ]        ;# Bank 224 - MGTYTXN0_224
#set_property PACKAGE_PIN AR6      [get_ports pci_exp_txn[6]  ]        ;# Bank 224 - MGTYTXN1_224
#set_property PACKAGE_PIN AP8      [get_ports pci_exp_txn[5]  ]        ;# Bank 224 - MGTYTXN2_224
#set_property PACKAGE_PIN AN6      [get_ports pci_exp_txn[4]  ]        ;# Bank 224 - MGTYTXN3_224
#set_property PACKAGE_PIN AT9      [get_ports pci_exp_txp[7]  ]        ;# Bank 224 - MGTYTXP0_224
#set_property PACKAGE_PIN AR7      [get_ports pci_exp_txp[6]  ]         ;# Bank 224 - MGTYTXP1_224
#set_property PACKAGE_PIN AP9      [get_ports pci_exp_txp[5]  ]         ;# Bank 224 - MGTYTXP2_224
#set_property PACKAGE_PIN AN7      [get_ports pci_exp_txp[4]  ]         ;# Bank 224 - MGTYTXP3_224
#set_property PACKAGE_PIN BC1      [get_ports pci_exp_rxn[3]  ]        ;# Bank 225 - MGTYRXN0_225
#set_property PACKAGE_PIN BA1      [get_ports pci_exp_rxn[2]  ]        ;# Bank 225 - MGTYRXN1_225
#set_property PACKAGE_PIN AW1      [get_ports pci_exp_rxn[1]  ]        ;# Bank 225 - MGTYRXN2_225
#set_property PACKAGE_PIN AV3      [get_ports pci_exp_rxn[0]  ]        ;# Bank 225 - MGTYRXN3_225
#set_property PACKAGE_PIN BC2      [get_ports pci_exp_rxp[3]  ]        ;# Bank 225 - MGTYRXP0_225
#set_property PACKAGE_PIN BA2      [get_ports pci_exp_rxp[2]  ]        ;# Bank 225 - MGTYRXP1_225
#set_property PACKAGE_PIN AW2      [get_ports pci_exp_rxp[1]  ]        ;# Bank 225 - MGTYRXP2_225
#set_property PACKAGE_PIN AV4      [get_ports pci_exp_rxp[0]  ]        ;# Bank 225 - MGTYRXP3_225
#set_property PACKAGE_PIN AM8      [get_ports pci_exp_txn[3]  ]        ;# Bank 225 - MGTYTXN0_225
#set_property PACKAGE_PIN AL6      [get_ports pci_exp_txn[2]  ]        ;# Bank 225 - MGTYTXN1_225
#set_property PACKAGE_PIN AJ6      [get_ports pci_exp_txn[1]  ]        ;# Bank 225 - MGTYTXN2_225
#set_property PACKAGE_PIN AG6      [get_ports pci_exp_txn[0]  ]        ;# Bank 225 - MGTYTXN3_225
#set_property PACKAGE_PIN AM9      [get_ports pci_exp_txp[3]  ]        ;# Bank 225 - MGTYTXP0_225
#set_property PACKAGE_PIN AL7      [get_ports pci_exp_txp[2]  ]        ;# Bank 225 - MGTYTXP1_225
#set_property PACKAGE_PIN AJ7      [get_ports pci_exp_txp[1]  ]        ;# Bank 225 - MGTYTXP2_225
#set_property PACKAGE_PIN AG7      [get_ports pci_exp_txp[0]  ]        ;# Bank 225 - MGTYTXP3_225

set_property PACKAGE_PIN AU1      [get_ports pci_exp_rxn[7]  ]        ;# Bank 226 - MGTYRXN0_226
set_property PACKAGE_PIN AT3      [get_ports pci_exp_rxn[6]  ]        ;# Bank 226 - MGTYRXN1_226
set_property PACKAGE_PIN AR1      [get_ports pci_exp_rxn[5]  ]        ;# Bank 226 - MGTYRXN2_226
set_property PACKAGE_PIN AP3      [get_ports pci_exp_rxn[4]  ]        ;# Bank 226 - MGTYRXN3_226
set_property PACKAGE_PIN AU2      [get_ports pci_exp_rxp[7]  ]        ;# Bank 226 - MGTYRXP0_226
set_property PACKAGE_PIN AT4      [get_ports pci_exp_rxp[6]  ]        ;# Bank 226 - MGTYRXP1_226
set_property PACKAGE_PIN AR2      [get_ports pci_exp_rxp[5]  ]        ;# Bank 226 - MGTYRXP2_226
set_property PACKAGE_PIN AP4      [get_ports pci_exp_rxp[4]  ]        ;# Bank 226 - MGTYRXP3_226
set_property PACKAGE_PIN AH4      [get_ports pci_exp_txn[7]  ]        ;# Bank 226 - MGTYTXN0_226
set_property PACKAGE_PIN AE6      [get_ports pci_exp_txn[6]  ]        ;# Bank 226 - MGTYTXN1_226
set_property PACKAGE_PIN AF4      [get_ports pci_exp_txn[5]  ]        ;# Bank 226 - MGTYTXN2_226
set_property PACKAGE_PIN AD4      [get_ports pci_exp_txn[4]  ]        ;# Bank 226 - MGTYTXN3_226
set_property PACKAGE_PIN AH5      [get_ports pci_exp_txp[7]  ]        ;# Bank 226 - MGTYTXP0_226
set_property PACKAGE_PIN AE7      [get_ports pci_exp_txp[6]  ]        ;# Bank 226 - MGTYTXP1_226
set_property PACKAGE_PIN AF5      [get_ports pci_exp_txp[5]  ]        ;# Bank 226 - MGTYTXP2_226
set_property PACKAGE_PIN AD5      [get_ports pci_exp_txp[4]  ]        ;# Bank 226 - MGTYTXP3_226
set_property PACKAGE_PIN AN1      [get_ports pci_exp_rxn[3]  ]        ;# Bank 227 - MGTYRXN0_227
set_property PACKAGE_PIN AK3      [get_ports pci_exp_rxn[2]  ]        ;# Bank 227 - MGTYRXN1_227
set_property PACKAGE_PIN AM3      [get_ports pci_exp_rxn[1]  ]        ;# Bank 227 - MGTYRXN2_227
set_property PACKAGE_PIN AL1      [get_ports pci_exp_rxn[0]  ]        ;# Bank 227 - MGTYRXN3_227
set_property PACKAGE_PIN AN2      [get_ports pci_exp_rxp[3]  ]        ;# Bank 227 - MGTYRXP0_227
set_property PACKAGE_PIN AK4      [get_ports pci_exp_rxp[2]  ]        ;# Bank 227 - MGTYRXP1_227
set_property PACKAGE_PIN AM4      [get_ports pci_exp_rxp[1]  ]        ;# Bank 227 - MGTYRXP2_227
set_property PACKAGE_PIN AL2      [get_ports pci_exp_rxp[0]  ]        ;# Bank 227 - MGTYRXP3_227
set_property PACKAGE_PIN AC6      [get_ports pci_exp_txn[3]  ]        ;# Bank 227 - MGTYTXN0_227
set_property PACKAGE_PIN AB4      [get_ports pci_exp_txn[2]  ]        ;# Bank 227 - MGTYTXN1_227
set_property PACKAGE_PIN AA6      [get_ports pci_exp_txn[1]  ]        ;# Bank 227 - MGTYTXN2_227
set_property PACKAGE_PIN Y4       [get_ports pci_exp_txn[0]  ]        ;# Bank 227 - MGTYTXN3_227
set_property PACKAGE_PIN AC7      [get_ports pci_exp_txp[3]  ]        ;# Bank 227 - MGTYTXP0_227
set_property PACKAGE_PIN AB5      [get_ports pci_exp_txp[2]  ]        ;# Bank 227 - MGTYTXP1_227
set_property PACKAGE_PIN AA7      [get_ports pci_exp_txp[1]  ]        ;# Bank 227 - MGTYTXP2_227
set_property PACKAGE_PIN Y5       [get_ports pci_exp_txp[0]  ]        ;# Bank 227 - MGTYTXP3_227


# UNCONNECTED Pins
#
#set_property PACKAGE_PIN A14      [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L24N_T3U_N11_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L24N_T3U_N11_67
#set_property PACKAGE_PIN B14      [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L24P_T3U_N10_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L24P_T3U_N10_67
#set_property PACKAGE_PIN A12      [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L23N_T3U_N9_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L23N_T3U_N9_67
#set_property PACKAGE_PIN A13      [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L23P_T3U_N8_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L23P_T3U_N8_67
#set_property PACKAGE_PIN B11      [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L22N_T3U_N7_DBC_AD0N_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L22N_T3U_N7_DBC_AD0N_67
#set_property PACKAGE_PIN B12      [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L22P_T3U_N6_DBC_AD0P_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L22P_T3U_N6_DBC_AD0P_67
#set_property PACKAGE_PIN A9       [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L21N_T3L_N5_AD8N_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L21N_T3L_N5_AD8N_67
#set_property PACKAGE_PIN A10      [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L21P_T3L_N4_AD8P_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L21P_T3L_N4_AD8P_67
#set_property PACKAGE_PIN C11      [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L20N_T3L_N3_AD1N_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L20N_T3L_N3_AD1N_67
#set_property PACKAGE_PIN C12      [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L20P_T3L_N2_AD1P_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L20P_T3L_N2_AD1P_67
#set_property PACKAGE_PIN B9       [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L19N_T3L_N1_DBC_AD9N_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L19N_T3L_N1_DBC_AD9N_67
#set_property PACKAGE_PIN B10      [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L19P_T3L_N0_DBC_AD9P_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L19P_T3L_N0_DBC_AD9P_67
#set_property PACKAGE_PIN C9       [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_T3U_N12_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_T3U_N12_67
#set_property PACKAGE_PIN D11      [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_T2U_N12_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_T2U_N12_67
#set_property PACKAGE_PIN C13      [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L18N_T2U_N11_AD2N_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L18N_T2U_N11_AD2N_67
#set_property PACKAGE_PIN C14      [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L18P_T2U_N10_AD2P_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L18P_T2U_N10_AD2P_67
#set_property PACKAGE_PIN D13      [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L17N_T2U_N9_AD10N_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L17N_T2U_N9_AD10N_67
#set_property PACKAGE_PIN D14      [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L17P_T2U_N8_AD10P_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L17P_T2U_N8_AD10P_67
#set_property PACKAGE_PIN D9       [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L16N_T2U_N7_QBC_AD3N_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L16N_T2U_N7_QBC_AD3N_67
#set_property PACKAGE_PIN D10      [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L16P_T2U_N6_QBC_AD3P_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L16P_T2U_N6_QBC_AD3P_67
#set_property PACKAGE_PIN E9       [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L15N_T2L_N5_AD11N_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L15N_T2L_N5_AD11N_67
#set_property PACKAGE_PIN F9       [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L15P_T2L_N4_AD11P_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L15P_T2L_N4_AD11P_67
#set_property PACKAGE_PIN E12      [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L14N_T2L_N3_GC_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L14N_T2L_N3_GC_67
#set_property PACKAGE_PIN E13      [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L14P_T2L_N2_GC_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L14P_T2L_N2_GC_67
#set_property PACKAGE_PIN E10      [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L13N_T2L_N1_GC_QBC_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L13N_T2L_N1_GC_QBC_67
#set_property PACKAGE_PIN E11      [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L13P_T2L_N0_GC_QBC_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L13P_T2L_N0_GC_QBC_67
#set_property PACKAGE_PIN F10      [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L12N_T1U_N11_GC_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L12N_T1U_N11_GC_67
#set_property PACKAGE_PIN G10      [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L12P_T1U_N10_GC_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L12P_T1U_N10_GC_67
#set_property PACKAGE_PIN F12      [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L11N_T1U_N9_GC_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L11N_T1U_N9_GC_67
#set_property PACKAGE_PIN F13      [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L11P_T1U_N8_GC_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L11P_T1U_N8_GC_67
#set_property PACKAGE_PIN F14      [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L10N_T1U_N7_QBC_AD4N_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L10N_T1U_N7_QBC_AD4N_67
#set_property PACKAGE_PIN G14      [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L10P_T1U_N6_QBC_AD4P_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L10P_T1U_N6_QBC_AD4P_67
#set_property PACKAGE_PIN H13      [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L9N_T1L_N5_AD12N_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L9N_T1L_N5_AD12N_67
#set_property PACKAGE_PIN H14      [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L9P_T1L_N4_AD12P_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L9P_T1L_N4_AD12P_67
#set_property PACKAGE_PIN G9       [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L8N_T1L_N3_AD5N_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L8N_T1L_N3_AD5N_67
#set_property PACKAGE_PIN H9       [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L8P_T1L_N2_AD5P_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L8P_T1L_N2_AD5P_67
#set_property PACKAGE_PIN G11      [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L7N_T1L_N1_QBC_AD13N_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L7N_T1L_N1_QBC_AD13N_67
#set_property PACKAGE_PIN G12      [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L7P_T1L_N0_QBC_AD13P_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L7P_T1L_N0_QBC_AD13P_67
#set_property PACKAGE_PIN J13      [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_T1U_N12_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_T1U_N12_67
#set_property PACKAGE_PIN K13      [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_T0U_N12_VRP_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_T0U_N12_VRP_67
#set_property PACKAGE_PIN H11      [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L6N_T0U_N11_AD6N_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L6N_T0U_N11_AD6N_67
#set_property PACKAGE_PIN H12      [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L6P_T0U_N10_AD6P_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L6P_T0U_N10_AD6P_67
#set_property PACKAGE_PIN J11      [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L5N_T0U_N9_AD14N_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L5N_T0U_N9_AD14N_67
#set_property PACKAGE_PIN K12      [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L5P_T0U_N8_AD14P_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L5P_T0U_N8_AD14P_67
#set_property PACKAGE_PIN J9       [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L4N_T0U_N7_DBC_AD7N_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L4N_T0U_N7_DBC_AD7N_67
#set_property PACKAGE_PIN J10      [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L4P_T0U_N6_DBC_AD7P_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L4P_T0U_N6_DBC_AD7P_67
#set_property PACKAGE_PIN K9       [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L3N_T0L_N5_AD15N_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L3N_T0L_N5_AD15N_67
#set_property PACKAGE_PIN K10      [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L3P_T0L_N4_AD15P_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L3P_T0L_N4_AD15P_67
#set_property PACKAGE_PIN K11      [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L2N_T0L_N3_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L2N_T0L_N3_67
#set_property PACKAGE_PIN L11      [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L2P_T0L_N2_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L2P_T0L_N2_67
#set_property PACKAGE_PIN L12      [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L1N_T0L_N1_DBC_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L1N_T0L_N1_DBC_67
#set_property PACKAGE_PIN L13      [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L1P_T0L_N0_DBC_67
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  67 VCCO - VCC1V8 - IO_L1P_T0L_N0_DBC_67
#set_property PACKAGE_PIN AV36     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L24N_T3U_N11_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L24N_T3U_N11_66
#set_property PACKAGE_PIN AV35     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L24P_T3U_N10_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L24P_T3U_N10_66
#set_property PACKAGE_PIN BA36     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L23N_T3U_N9_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L23N_T3U_N9_66
#set_property PACKAGE_PIN AY36     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L23P_T3U_N8_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L23P_T3U_N8_66
#set_property PACKAGE_PIN AW33     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L22N_T3U_N7_DBC_AD0N_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L22N_T3U_N7_DBC_AD0N_66
#set_property PACKAGE_PIN AV33     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L22P_T3U_N6_DBC_AD0P_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L22P_T3U_N6_DBC_AD0P_66
#set_property PACKAGE_PIN BA34     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L21N_T3L_N5_AD8N_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L21N_T3L_N5_AD8N_66
#set_property PACKAGE_PIN AY34     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L21P_T3L_N4_AD8P_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L21P_T3L_N4_AD8P_66
#set_property PACKAGE_PIN AW35     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L20N_T3L_N3_AD1N_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L20N_T3L_N3_AD1N_66
#set_property PACKAGE_PIN AW34     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L20P_T3L_N2_AD1P_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L20P_T3L_N2_AD1P_66
#set_property PACKAGE_PIN BA32     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L19N_T3L_N1_DBC_AD9N_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L19N_T3L_N1_DBC_AD9N_66
#set_property PACKAGE_PIN AY32     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L19P_T3L_N0_DBC_AD9P_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L19P_T3L_N0_DBC_AD9P_66
#set_property PACKAGE_PIN AY35     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_T3U_N12_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_T3U_N12_66
#set_property PACKAGE_PIN AW32     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_T2U_N12_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_T2U_N12_66
#set_property PACKAGE_PIN AV32     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L18N_T2U_N11_AD2N_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L18N_T2U_N11_AD2N_66
#set_property PACKAGE_PIN AV31     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L18P_T2U_N10_AD2P_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L18P_T2U_N10_AD2P_66
#set_property PACKAGE_PIN AY30     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L17N_T2U_N9_AD10N_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L17N_T2U_N9_AD10N_66
#set_property PACKAGE_PIN AW30     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L17P_T2U_N8_AD10P_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L17P_T2U_N8_AD10P_66
#set_property PACKAGE_PIN BB29     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L16N_T2U_N7_QBC_AD3N_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L16N_T2U_N7_QBC_AD3N_66
#set_property PACKAGE_PIN BA29     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L16P_T2U_N6_QBC_AD3P_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L16P_T2U_N6_QBC_AD3P_66
#set_property PACKAGE_PIN AY29     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L15N_T2L_N5_AD11N_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L15N_T2L_N5_AD11N_66
#set_property PACKAGE_PIN AW29     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L15P_T2L_N4_AD11P_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L15P_T2L_N4_AD11P_66
#set_property PACKAGE_PIN BB31     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L14N_T2L_N3_GC_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L14N_T2L_N3_GC_66
#set_property PACKAGE_PIN BB30     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L14P_T2L_N2_GC_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L14P_T2L_N2_GC_66
#set_property PACKAGE_PIN BA31     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L13N_T2L_N1_GC_QBC_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L13N_T2L_N1_GC_QBC_66
#set_property PACKAGE_PIN AY31     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L13P_T2L_N0_GC_QBC_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L13P_T2L_N0_GC_QBC_66
#set_property PACKAGE_PIN BB33     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L12N_T1U_N11_GC_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L12N_T1U_N11_GC_66
#set_property PACKAGE_PIN BA33     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L12P_T1U_N10_GC_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L12P_T1U_N10_GC_66
#set_property PACKAGE_PIN BC33     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L11N_T1U_N9_GC_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L11N_T1U_N9_GC_66
#set_property PACKAGE_PIN BC32     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L11P_T1U_N8_GC_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L11P_T1U_N8_GC_66
#set_property PACKAGE_PIN BB35     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L10N_T1U_N7_QBC_AD4N_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L10N_T1U_N7_QBC_AD4N_66
#set_property PACKAGE_PIN BB34     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L10P_T1U_N6_QBC_AD4P_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L10P_T1U_N6_QBC_AD4P_66
#set_property PACKAGE_PIN BC36     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L9N_T1L_N5_AD12N_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L9N_T1L_N5_AD12N_66
#set_property PACKAGE_PIN BB36     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L9P_T1L_N4_AD12P_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L9P_T1L_N4_AD12P_66
#set_property PACKAGE_PIN BD35     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L8N_T1L_N3_AD5N_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L8N_T1L_N3_AD5N_66
#set_property PACKAGE_PIN BC35     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L8P_T1L_N2_AD5P_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L8P_T1L_N2_AD5P_66
#set_property PACKAGE_PIN BE35     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L7N_T1L_N1_QBC_AD13N_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L7N_T1L_N1_QBC_AD13N_66
#set_property PACKAGE_PIN BE34     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L7P_T1L_N0_QBC_AD13P_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L7P_T1L_N0_QBC_AD13P_66
#set_property PACKAGE_PIN BD34     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_T1U_N12_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_T1U_N12_66
#set_property PACKAGE_PIN BD33     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_T0U_N12_VRP_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_T0U_N12_VRP_66
#set_property PACKAGE_PIN BD30     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L6N_T0U_N11_AD6N_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L6N_T0U_N11_AD6N_66
#set_property PACKAGE_PIN BC30     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L6P_T0U_N10_AD6P_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L6P_T0U_N10_AD6P_66
#set_property PACKAGE_PIN BE30     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L5N_T0U_N9_AD14N_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L5N_T0U_N9_AD14N_66
#set_property PACKAGE_PIN BD29     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L5P_T0U_N8_AD14P_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L5P_T0U_N8_AD14P_66
#set_property PACKAGE_PIN BD32     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L4N_T0U_N7_DBC_AD7N_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L4N_T0U_N7_DBC_AD7N_66
#set_property PACKAGE_PIN BC31     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L4P_T0U_N6_DBC_AD7P_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L4P_T0U_N6_DBC_AD7P_66
#set_property PACKAGE_PIN BE32     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L3N_T0L_N5_AD15N_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L3N_T0L_N5_AD15N_66
#set_property PACKAGE_PIN BE31     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L3P_T0L_N4_AD15P_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L3P_T0L_N4_AD15P_66
#set_property PACKAGE_PIN BF34     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L2N_T0L_N3_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L2N_T0L_N3_66
#set_property PACKAGE_PIN BF33     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L2P_T0L_N2_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L2P_T0L_N2_66
#set_property PACKAGE_PIN BF32     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L1N_T0L_N1_DBC_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L1N_T0L_N1_DBC_66
#set_property PACKAGE_PIN BF31     [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L1P_T0L_N0_DBC_66
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  66 VCCO - VCC1V8 - IO_L1P_T0L_N0_DBC_66
#set_property PACKAGE_PIN AV27     [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L24N_T3U_N11_DOUT_CSO_B_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L24N_T3U_N11_DOUT_CSO_B_65
#set_property PACKAGE_PIN AV26     [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L24P_T3U_N10_EMCCLK_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L24P_T3U_N10_EMCCLK_65
#set_property PACKAGE_PIN AW28     [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L22N_T3U_N7_DBC_AD0N_D05_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L22N_T3U_N7_DBC_AD0N_D05_65
#set_property PACKAGE_PIN AV28     [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L22P_T3U_N6_DBC_AD0P_D04_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L22P_T3U_N6_DBC_AD0P_D04_65
#set_property PACKAGE_PIN BC28     [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L21N_T3L_N5_AD8N_D07_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L21N_T3L_N5_AD8N_D07_65
#set_property PACKAGE_PIN BB28     [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L21P_T3L_N4_AD8P_D06_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L21P_T3L_N4_AD8P_D06_65
#set_property PACKAGE_PIN BA28     [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L20N_T3L_N3_AD1N_D09_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L20N_T3L_N3_AD1N_D09_65
#set_property PACKAGE_PIN BA27     [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L20P_T3L_N2_AD1P_D08_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L20P_T3L_N2_AD1P_D08_65
#set_property PACKAGE_PIN BA26     [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L19N_T3L_N1_DBC_AD9N_D11_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L19N_T3L_N1_DBC_AD9N_D11_65
#set_property PACKAGE_PIN AY25     [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L19P_T3L_N0_DBC_AD9P_D10_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L19P_T3L_N0_DBC_AD9P_D10_65
#set_property PACKAGE_PIN BF28     [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_T2U_N12_CSI_ADV_B_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_T2U_N12_CSI_ADV_B_65
#set_property PACKAGE_PIN BF29     [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L18N_T2U_N11_AD2N_D13_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L18N_T2U_N11_AD2N_D13_65
#set_property PACKAGE_PIN BE29     [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L18P_T2U_N10_AD2P_D12_650
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L18P_T2U_N10_AD2P_D12_65
#set_property PACKAGE_PIN BD27     [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L17P_T2U_N8_AD10P_D14_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L17P_T2U_N8_AD10P_D14_65
#set_property PACKAGE_PIN BF27     [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L16N_T2U_N7_QBC_AD3N_A01D17_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L16N_T2U_N7_QBC_AD3N_A0117_65
#set_property PACKAGE_PIN BE27     [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L16P_T2U_N6_QBC_AD3P_A0016_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L16P_T2U_N6_QBC_AD3P_A00D16_65
#set_property PACKAGE_PIN BC27     [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L14N_T2L_N3_GC_A05_D21_60
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L14N_T2L_N3_GC_A05_D21_6
#set_property PACKAGE_PIN BC26     [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L14P_T2L_N2_GC_A04_D20_60
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L14P_T2L_N2_GC_A04_D20_6
#set_property PACKAGE_PIN BD25     [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L12N_T1U_N11_GC_A09_D25_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L12N_T1U_N11_GC_A09_D25_65
#set_property PACKAGE_PIN BC25     [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L12P_T1U_N10_GC_A08_D24_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L12P_T1U_N10_GC_A08_D24_65
#set_property PACKAGE_PIN BD24     [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L11N_T1U_N9_GC_A11_D27_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L11N_T1U_N9_GC_A11_D27_65
#set_property PACKAGE_PIN BD23     [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L11P_T1U_N8_GC_A10_D26_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L11P_T1U_N8_GC_A10_D26_65
#set_property PACKAGE_PIN BE25     [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L10N_T1U_N7_QBC_AD4N_A13_D29_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L10N_T1U_N7_QBC_AD4N_A13_D29_65
#set_property PACKAGE_PIN BE24     [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L10P_T1U_N6_QBC_AD4P_A12_D28_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L10P_T1U_N6_QBC_AD4P_A12_D28_65
#set_property PACKAGE_PIN BE22     [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L9N_T1L_N5_AD12N_A15_D31_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L9N_T1L_N5_AD12N_A15_D31_65
#set_property PACKAGE_PIN BD22     [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L9P_T1L_N4_AD12P_A14_D30_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L9P_T1L_N4_AD12P_A14_D30_65
#set_property PACKAGE_PIN BF24     [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L8N_T1L_N3_AD5N_A17_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L8N_T1L_N3_AD5N_A17_65
#set_property PACKAGE_PIN BF23     [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L8P_T1L_N2_AD5P_A16_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L8P_T1L_N2_AD5P_A16_65
#set_property PACKAGE_PIN BC23     [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L7N_T1L_N1_QBC_AD13N_A19_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L7N_T1L_N1_QBC_AD13N_A19_65
#set_property PACKAGE_PIN BC22     [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L7P_T1L_N0_QBC_AD13P_A18_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L7P_T1L_N0_QBC_AD13P_A18_65
#set_property PACKAGE_PIN AY24     [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_T0U_N12_VRP_A28_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_T0U_N12_VRP_A28_65
#set_property PACKAGE_PIN AW25     [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L6N_T0U_N11_AD6N_A21_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L6N_T0U_N11_AD6N_A21_65
#set_property PACKAGE_PIN AV25     [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L6P_T0U_N10_AD6P_A20_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L6P_T0U_N10_AD6P_A20_65
#set_property PACKAGE_PIN BB24     [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L5N_T0U_N9_AD14N_A23_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L5N_T0U_N9_AD14N_A23_65
#set_property PACKAGE_PIN BA24     [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L5P_T0U_N8_AD14P_A22_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L5P_T0U_N8_AD14P_A22_65
#set_property PACKAGE_PIN BB23     [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L4N_T0U_N7_DBC_AD7N_A25_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L4N_T0U_N7_DBC_AD7N_A25_65
#set_property PACKAGE_PIN BA23     [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L4P_T0U_N6_DBC_AD7P_A24_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L4P_T0U_N6_DBC_AD7P_A24_65
#set_property PACKAGE_PIN BA22     [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L3N_T0L_N5_AD15N_A27_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L3N_T0L_N5_AD15N_A27_65
#set_property PACKAGE_PIN AY22     [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L3P_T0L_N4_AD15P_A26_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L3P_T0L_N4_AD15P_A26_65
#set_property PACKAGE_PIN AW24     [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L2N_T0L_N3_FWE_FCS2_B_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L2N_T0L_N3_FWE_FCS2_B_65
#set_property PACKAGE_PIN AW23     [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L2P_T0L_N2_FOE_B_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L2P_T0L_N2_FOE_B_65
#set_property PACKAGE_PIN AW22     [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L1N_T0L_N1_DBC_RS1_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L1N_T0L_N1_DBC_RS1_65
#set_property PACKAGE_PIN AV22     [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L1P_T0L_N0_DBC_RS0_65
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  65 VCCO - VCC1V8 - IO_L1P_T0L_N0_DBC_RS0_65
#set_property PACKAGE_PIN AV15     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L24N_T3U_N11_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L24N_T3U_N11_64
#set_property PACKAGE_PIN AV16     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L24P_T3U_N10_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L24P_T3U_N10_64
#set_property PACKAGE_PIN AW14     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L23N_T3U_N9_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L23N_T3U_N9_64
#set_property PACKAGE_PIN AW15     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L23P_T3U_N8_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L23P_T3U_N8_64
#set_property PACKAGE_PIN BA14     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L22N_T3U_N7_DBC_AD0N_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L22N_T3U_N7_DBC_AD0N_64
#set_property PACKAGE_PIN AY14     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L22P_T3U_N6_DBC_AD0P_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L22P_T3U_N6_DBC_AD0P_64
#set_property PACKAGE_PIN AY15     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L21N_T3L_N5_AD8N_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L21N_T3L_N5_AD8N_64
#set_property PACKAGE_PIN AY16     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L21P_T3L_N4_AD8P_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L21P_T3L_N4_AD8P_64
#set_property PACKAGE_PIN BB16     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L20N_T3L_N3_AD1N_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L20N_T3L_N3_AD1N_64
#set_property PACKAGE_PIN BA16     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L20P_T3L_N2_AD1P_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L20P_T3L_N2_AD1P_64
#set_property PACKAGE_PIN BC15     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L19N_T3L_N1_DBC_AD9N_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L19N_T3L_N1_DBC_AD9N_64
#set_property PACKAGE_PIN BB15     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L19P_T3L_N0_DBC_AD9P_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L19P_T3L_N0_DBC_AD9P_64
#set_property PACKAGE_PIN AV17     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_T3U_N12_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_T3U_N12_64
#set_property PACKAGE_PIN AV18     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_T2U_N12_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_T2U_N12_64
#set_property PACKAGE_PIN AY17     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L18N_T2U_N11_AD2N_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L18N_T2U_N11_AD2N_64
#set_property PACKAGE_PIN AW17     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L18P_T2U_N10_AD2P_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L18P_T2U_N10_AD2P_64
#set_property PACKAGE_PIN AW18     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L17N_T2U_N9_AD10N_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L17N_T2U_N9_AD10N_64
#set_property PACKAGE_PIN AW19     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L17P_T2U_N8_AD10P_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L17P_T2U_N8_AD10P_64
#set_property PACKAGE_PIN AW20     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L16N_T2U_N7_QBC_AD3N_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L16N_T2U_N7_QBC_AD3N_64
#set_property PACKAGE_PIN AV20     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L16P_T2U_N6_QBC_AD3P_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L16P_T2U_N6_QBC_AD3P_64
#set_property PACKAGE_PIN AY20     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L15N_T2L_N5_AD11N_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L15N_T2L_N5_AD11N_64
#set_property PACKAGE_PIN AY21     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L15P_T2L_N4_AD11P_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L15P_T2L_N4_AD11P_64
#set_property PACKAGE_PIN BA17     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L14N_T2L_N3_GC_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L14N_T2L_N3_GC_64
#set_property PACKAGE_PIN BA18     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L14P_T2L_N2_GC_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L14P_T2L_N2_GC_64
#set_property PACKAGE_PIN BA19     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L13N_T2L_N1_GC_QBC_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L13N_T2L_N1_GC_QBC_64
#set_property PACKAGE_PIN AY19     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L13P_T2L_N0_GC_QBC_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L13P_T2L_N0_GC_QBC_64
#set_property PACKAGE_PIN BB19     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L12N_T1U_N11_GC_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L12N_T1U_N11_GC_64
#set_property PACKAGE_PIN BB20     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L12P_T1U_N10_GC_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L12P_T1U_N10_GC_64
#set_property PACKAGE_PIN BC20     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L10N_T1U_N7_QBC_AD4N_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L10N_T1U_N7_QBC_AD4N_64
#set_property PACKAGE_PIN BC21     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L10P_T1U_N6_QBC_AD4P_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L10P_T1U_N6_QBC_AD4P_64
#set_property PACKAGE_PIN BB21     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L9N_T1L_N5_AD12N_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L9N_T1L_N5_AD12N_64
#set_property PACKAGE_PIN BA21     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L9P_T1L_N4_AD12P_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L9P_T1L_N4_AD12P_64
#set_property PACKAGE_PIN BD19     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L8N_T1L_N3_AD5N_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L8N_T1L_N3_AD5N_64
#set_property PACKAGE_PIN BD20     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L8P_T1L_N2_AD5P_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L8P_T1L_N2_AD5P_64
#set_property PACKAGE_PIN BE20     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L7N_T1L_N1_QBC_AD13N_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L7N_T1L_N1_QBC_AD13N_64
#set_property PACKAGE_PIN BE21     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L7P_T1L_N0_QBC_AD13P_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L7P_T1L_N0_QBC_AD13P_64
#set_property PACKAGE_PIN BF21     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_T1U_N12_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_T1U_N12_64
#set_property PACKAGE_PIN BE19     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_T0U_N12_VRP_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_T0U_N12_VRP_64
#set_property PACKAGE_PIN BC16     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L6N_T0U_N11_AD6N_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L6N_T0U_N11_AD6N_64
#set_property PACKAGE_PIN BC17     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L6P_T0U_N10_AD6P_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L6P_T0U_N10_AD6P_64
#set_property PACKAGE_PIN BE15     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L5N_T0U_N9_AD14N_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L5N_T0U_N9_AD14N_64
#set_property PACKAGE_PIN BD15     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L5P_T0U_N8_AD14P_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L5P_T0U_N8_AD14P_64
#set_property PACKAGE_PIN BD17     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L4N_T0U_N7_DBC_AD7N_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L4N_T0U_N7_DBC_AD7N_64
#set_property PACKAGE_PIN BD18     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L4P_T0U_N6_DBC_AD7P_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L4P_T0U_N6_DBC_AD7P_64
#set_property PACKAGE_PIN BE16     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L3N_T0L_N5_AD15N_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L3N_T0L_N5_AD15N_64
#set_property PACKAGE_PIN BE17     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L3P_T0L_N4_AD15P_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L3P_T0L_N4_AD15P_64
#set_property PACKAGE_PIN BF18     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L2N_T0L_N3_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L2N_T0L_N3_64
#set_property PACKAGE_PIN BF19     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L2P_T0L_N2_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L2P_T0L_N2_64
#set_property PACKAGE_PIN BF16     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L1N_T0L_N1_DBC_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L1N_T0L_N1_DBC_64
#set_property PACKAGE_PIN BF17     [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L1P_T0L_N0_DBC_64
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  64 VCCO - VCC1V8 - IO_L1P_T0L_N0_DBC_64
#set_property PACKAGE_PIN A27      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L24N_T3U_N11_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L24N_T3U_N11_71
#set_property PACKAGE_PIN B27      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L24P_T3U_N10_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L24P_T3U_N10_71
#set_property PACKAGE_PIN A29      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L23N_T3U_N9_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L23N_T3U_N9_71
#set_property PACKAGE_PIN A28      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L23P_T3U_N8_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L23P_T3U_N8_71
#set_property PACKAGE_PIN A30      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L22N_T3U_N7_DBC_AD0N_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L22N_T3U_N7_DBC_AD0N_71
#set_property PACKAGE_PIN B29      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L22P_T3U_N6_DBC_AD0P_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L22P_T3U_N6_DBC_AD0P_71
#set_property PACKAGE_PIN A32      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L21N_T3L_N5_AD8N_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L21N_T3L_N5_AD8N_71
#set_property PACKAGE_PIN B31      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L21P_T3L_N4_AD8P_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L21P_T3L_N4_AD8P_71
#set_property PACKAGE_PIN C28      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L20N_T3L_N3_AD1N_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L20N_T3L_N3_AD1N_71
#set_property PACKAGE_PIN C27      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L20P_T3L_N2_AD1P_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L20P_T3L_N2_AD1P_71
#set_property PACKAGE_PIN B30      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L19N_T3L_N1_DBC_AD9N_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L19N_T3L_N1_DBC_AD9N_71
#set_property PACKAGE_PIN C29      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L19P_T3L_N0_DBC_AD9P_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L19P_T3L_N0_DBC_AD9P_71
#set_property PACKAGE_PIN B32      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_T3U_N12_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_T3U_N12_71
#set_property PACKAGE_PIN C32      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_T2U_N12_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_T2U_N12_71
#set_property PACKAGE_PIN D28      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L18N_T2U_N11_AD2N_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L18N_T2U_N11_AD2N_71
#set_property PACKAGE_PIN E27      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L18P_T2U_N10_AD2P_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L18P_T2U_N10_AD2P_71
#set_property PACKAGE_PIN C31      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L17N_T2U_N9_AD10N_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L17N_T2U_N9_AD10N_71
#set_property PACKAGE_PIN D31      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L17P_T2U_N8_AD10P_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L17P_T2U_N8_AD10P_71
#set_property PACKAGE_PIN D30      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L16N_T2U_N7_QBC_AD3N_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L16N_T2U_N7_QBC_AD3N_71
#set_property PACKAGE_PIN D29      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L16P_T2U_N6_QBC_AD3P_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L16P_T2U_N6_QBC_AD3P_71
#set_property PACKAGE_PIN E32      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L15N_T2L_N5_AD11N_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L15N_T2L_N5_AD11N_71
#set_property PACKAGE_PIN F32      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L15P_T2L_N4_AD11P_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L15P_T2L_N4_AD11P_71
#set_property PACKAGE_PIN E28      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L14N_T2L_N3_GC_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L14N_T2L_N3_GC_71
#set_property PACKAGE_PIN F28      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L14P_T2L_N2_GC_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L14P_T2L_N2_GC_71
#set_property PACKAGE_PIN E31      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L13N_T2L_N1_GC_QBC_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L13N_T2L_N1_GC_QBC_71
#set_property PACKAGE_PIN E30      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L13P_T2L_N0_GC_QBC_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L13P_T2L_N0_GC_QBC_71
#set_property PACKAGE_PIN F30      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L12N_T1U_N11_GC_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L12N_T1U_N11_GC_71
#set_property PACKAGE_PIN F29      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L12P_T1U_N10_GC_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L12P_T1U_N10_GC_71
#set_property PACKAGE_PIN G30      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L11N_T1U_N9_GC_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L11N_T1U_N9_GC_71
#set_property PACKAGE_PIN G29      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L11P_T1U_N8_GC_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L11P_T1U_N8_GC_71
#set_property PACKAGE_PIN F27      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L10N_T1U_N7_QBC_AD4N_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L10N_T1U_N7_QBC_AD4N_71
#set_property PACKAGE_PIN G27      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L10P_T1U_N6_QBC_AD4P_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L10P_T1U_N6_QBC_AD4P_71
#set_property PACKAGE_PIN G32      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L9N_T1L_N5_AD12N_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L9N_T1L_N5_AD12N_71
#set_property PACKAGE_PIN G31      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L9P_T1L_N4_AD12P_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L9P_T1L_N4_AD12P_71
#set_property PACKAGE_PIN H29      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L8N_T1L_N3_AD5N_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L8N_T1L_N3_AD5N_71
#set_property PACKAGE_PIN H28      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L8P_T1L_N2_AD5P_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L8P_T1L_N2_AD5P_71
#set_property PACKAGE_PIN H32      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L7N_T1L_N1_QBC_AD13N_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L7N_T1L_N1_QBC_AD13N_71
#set_property PACKAGE_PIN H31      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L7P_T1L_N0_QBC_AD13P_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L7P_T1L_N0_QBC_AD13P_71
#set_property PACKAGE_PIN H27      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_T1U_N12_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_T1U_N12_71
#set_property PACKAGE_PIN K26      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_T0U_N12_VRP_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_T0U_N12_VRP_71
#set_property PACKAGE_PIN J28      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L6N_T0U_N11_AD6N_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L6N_T0U_N11_AD6N_71
#set_property PACKAGE_PIN K27      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L6P_T0U_N10_AD6P_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L6P_T0U_N10_AD6P_71
#set_property PACKAGE_PIN J30      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L5N_T0U_N9_AD14N_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L5N_T0U_N9_AD14N_71
#set_property PACKAGE_PIN J29      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L5P_T0U_N8_AD14P_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L5P_T0U_N8_AD14P_71
#set_property PACKAGE_PIN J31      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L4N_T0U_N7_DBC_AD7N_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L4N_T0U_N7_DBC_AD7N_71
#set_property PACKAGE_PIN K30      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L4P_T0U_N6_DBC_AD7P_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L4P_T0U_N6_DBC_AD7P_71
#set_property PACKAGE_PIN L29      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L3N_T0L_N5_AD15N_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L3N_T0L_N5_AD15N_71
#set_property PACKAGE_PIN L28      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L3P_T0L_N4_AD15P_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L3P_T0L_N4_AD15P_71
#set_property PACKAGE_PIN K28      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L2N_T0L_N3_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L2N_T0L_N3_71
#set_property PACKAGE_PIN L27      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L2P_T0L_N2_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L2P_T0L_N2_71
#set_property PACKAGE_PIN K31      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L1N_T0L_N1_DBC_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L1N_T0L_N1_DBC_71
#set_property PACKAGE_PIN L30      [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L1P_T0L_N0_DBC_71
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  71 VCCO - VCC1V8 - IO_L1P_T0L_N0_DBC_71
#set_property PACKAGE_PIN A34      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L24N_T3U_N11_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L24N_T3U_N11_70
#set_property PACKAGE_PIN A33      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L24P_T3U_N10_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L24P_T3U_N10_70
#set_property PACKAGE_PIN A35      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L23N_T3U_N9_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L23N_T3U_N9_70
#set_property PACKAGE_PIN B34      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L23P_T3U_N8_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L23P_T3U_N8_70
#set_property PACKAGE_PIN A38      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L22N_T3U_N7_DBC_AD0N_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L22N_T3U_N7_DBC_AD0N_70
#set_property PACKAGE_PIN A37      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L22P_T3U_N6_DBC_AD0P_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L22P_T3U_N6_DBC_AD0P_70
#set_property PACKAGE_PIN B36      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L21N_T3L_N5_AD8N_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L21N_T3L_N5_AD8N_70
#set_property PACKAGE_PIN B35      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L21P_T3L_N4_AD8P_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L21P_T3L_N4_AD8P_70
#set_property PACKAGE_PIN B37      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L20N_T3L_N3_AD1N_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L20N_T3L_N3_AD1N_70
#set_property PACKAGE_PIN C36      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L20P_T3L_N2_AD1P_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L20P_T3L_N2_AD1P_70
#set_property PACKAGE_PIN C34      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L19N_T3L_N1_DBC_AD9N_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L19N_T3L_N1_DBC_AD9N_70
#set_property PACKAGE_PIN C33      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L19P_T3L_N0_DBC_AD9P_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L19P_T3L_N0_DBC_AD9P_70
#set_property PACKAGE_PIN C37      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_T3U_N12_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_T3U_N12_70
#set_property PACKAGE_PIN C38      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_T2U_N12_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_T2U_N12_70
#set_property PACKAGE_PIN D36      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L18N_T2U_N11_AD2N_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L18N_T2U_N11_AD2N_70
#set_property PACKAGE_PIN E35      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L18P_T2U_N10_AD2P_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L18P_T2U_N10_AD2P_70
#set_property PACKAGE_PIN D33      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L17N_T2U_N9_AD10N_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L17N_T2U_N9_AD10N_70
#set_property PACKAGE_PIN E33      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L17P_T2U_N8_AD10P_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L17P_T2U_N8_AD10P_70
#set_property PACKAGE_PIN D38      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L16N_T2U_N7_QBC_AD3N_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L16N_T2U_N7_QBC_AD3N_70
#set_property PACKAGE_PIN E38      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L16P_T2U_N6_QBC_AD3P_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L16P_T2U_N6_QBC_AD3P_70
#set_property PACKAGE_PIN D35      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L15N_T2L_N5_AD11N_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L15N_T2L_N5_AD11N_70
#set_property PACKAGE_PIN D34      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L15P_T2L_N4_AD11P_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L15P_T2L_N4_AD11P_70
#set_property PACKAGE_PIN E37      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L14N_T2L_N3_GC_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L14N_T2L_N3_GC_70
#set_property PACKAGE_PIN E36      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L14P_T2L_N2_GC_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L14P_T2L_N2_GC_70
#set_property PACKAGE_PIN F34      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L13N_T2L_N1_GC_QBC_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L13N_T2L_N1_GC_QBC_70
#set_property PACKAGE_PIN F33      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L13P_T2L_N0_GC_QBC_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L13P_T2L_N0_GC_QBC_70
#set_property PACKAGE_PIN F38      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L12N_T1U_N11_GC_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L12N_T1U_N11_GC_70
#set_property PACKAGE_PIN G37      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L12P_T1U_N10_GC_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L12P_T1U_N10_GC_70
#set_property PACKAGE_PIN F37      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L11N_T1U_N9_GC_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L11N_T1U_N9_GC_70
#set_property PACKAGE_PIN G36      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L11P_T1U_N8_GC_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L11P_T1U_N8_GC_70
#set_property PACKAGE_PIN H37      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L10N_T1U_N7_QBC_AD4N_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L10N_T1U_N7_QBC_AD4N_70
#set_property PACKAGE_PIN H36      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L10P_T1U_N6_QBC_AD4P_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L10P_T1U_N6_QBC_AD4P_70
#set_property PACKAGE_PIN F35      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L9N_T1L_N5_AD12N_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L9N_T1L_N5_AD12N_70
#set_property PACKAGE_PIN G35      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L9P_T1L_N4_AD12P_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L9P_T1L_N4_AD12P_70
#set_property PACKAGE_PIN K38      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L8N_T1L_N3_AD5N_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L8N_T1L_N3_AD5N_70
#set_property PACKAGE_PIN K37      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L8P_T1L_N2_AD5P_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L8P_T1L_N2_AD5P_70
#set_property PACKAGE_PIN H38      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L7N_T1L_N1_QBC_AD13N_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L7N_T1L_N1_QBC_AD13N_70
#set_property PACKAGE_PIN J38      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L7P_T1L_N0_QBC_AD13P_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L7P_T1L_N0_QBC_AD13P_70
#set_property PACKAGE_PIN J36      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_T1U_N12_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_T1U_N12_70
#set_property PACKAGE_PIN H34      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_T0U_N12_VRP_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_T0U_N12_VRP_70
#set_property PACKAGE_PIN G34      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L6N_T0U_N11_AD6N_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L6N_T0U_N11_AD6N_70
#set_property PACKAGE_PIN H33      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L6P_T0U_N10_AD6P_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L6P_T0U_N10_AD6P_70
#set_property PACKAGE_PIN K32      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L5N_T0U_N9_AD14N_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L5N_T0U_N9_AD14N_70
#set_property PACKAGE_PIN L32      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L5P_T0U_N8_AD14P_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L5P_T0U_N8_AD14P_70
#set_property PACKAGE_PIN K35      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L4N_T0U_N7_DBC_AD7N_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L4N_T0U_N7_DBC_AD7N_70
#set_property PACKAGE_PIN L34      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L4P_T0U_N6_DBC_AD7P_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L4P_T0U_N6_DBC_AD7P_70
#set_property PACKAGE_PIN J33      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L3N_T0L_N5_AD15N_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L3N_T0L_N5_AD15N_70
#set_property PACKAGE_PIN K33      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L3P_T0L_N4_AD15P_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L3P_T0L_N4_AD15P_70
#set_property PACKAGE_PIN K36      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L2N_T0L_N3_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L2N_T0L_N3_70
#set_property PACKAGE_PIN L35      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L2P_T0L_N2_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L2P_T0L_N2_70
#set_property PACKAGE_PIN J35      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L1N_T0L_N1_DBC_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L1N_T0L_N1_DBC_70
#set_property PACKAGE_PIN J34      [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L1P_T0L_N0_DBC_70
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  70 VCCO - VCC1V8 - IO_L1P_T0L_N0_DBC_70
#set_property PACKAGE_PIN C23      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L24N_T3U_N11_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L24N_T3U_N11_69
#set_property PACKAGE_PIN C24      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L24P_T3U_N10_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L24P_T3U_N10_69
#set_property PACKAGE_PIN A25      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L23N_T3U_N9_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L23N_T3U_N9_69
#set_property PACKAGE_PIN B26      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L23P_T3U_N8_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L23P_T3U_N8_69
#set_property PACKAGE_PIN A23      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L22N_T3U_N7_DBC_AD0N_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L22N_T3U_N7_DBC_AD0N_69
#set_property PACKAGE_PIN A24      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L22P_T3U_N6_DBC_AD0P_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L22P_T3U_N6_DBC_AD0P_69
#set_property PACKAGE_PIN B24      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L21N_T3L_N5_AD8N_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L21N_T3L_N5_AD8N_69
#set_property PACKAGE_PIN B25      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L21P_T3L_N4_AD8P_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L21P_T3L_N4_AD8P_69
#set_property PACKAGE_PIN A22      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L20N_T3L_N3_AD1N_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L20N_T3L_N3_AD1N_69
#set_property PACKAGE_PIN B22      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L20P_T3L_N2_AD1P_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L20P_T3L_N2_AD1P_69
#set_property PACKAGE_PIN B21      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L19N_T3L_N1_DBC_AD9N_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L19N_T3L_N1_DBC_AD9N_69
#set_property PACKAGE_PIN C22      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L19P_T3L_N0_DBC_AD9P_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L19P_T3L_N0_DBC_AD9P_69
#set_property PACKAGE_PIN C21      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_T3U_N12_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_T3U_N12_69
#set_property PACKAGE_PIN C26      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_T2U_N12_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_T2U_N12_69
#set_property PACKAGE_PIN D26      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L18N_T2U_N11_AD2N_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L18N_T2U_N11_AD2N_69
#set_property PACKAGE_PIN E26      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L18P_T2U_N10_AD2P_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L18P_T2U_N10_AD2P_69
#set_property PACKAGE_PIN D25      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L17N_T2U_N9_AD10N_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L17N_T2U_N9_AD10N_69
#set_property PACKAGE_PIN E25      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L17P_T2U_N8_AD10P_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L17P_T2U_N8_AD10P_69
#set_property PACKAGE_PIN D23      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L16N_T2U_N7_QBC_AD3N_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L16N_T2U_N7_QBC_AD3N_69
#set_property PACKAGE_PIN D24      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L16P_T2U_N6_QBC_AD3P_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L16P_T2U_N6_QBC_AD3P_69
#set_property PACKAGE_PIN D21      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L15N_T2L_N5_AD11N_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L15N_T2L_N5_AD11N_69
#set_property PACKAGE_PIN E21      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L15P_T2L_N4_AD11P_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L15P_T2L_N4_AD11P_69
#set_property PACKAGE_PIN F24      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L14N_T2L_N3_GC_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L14N_T2L_N3_GC_69
#set_property PACKAGE_PIN F25      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L14P_T2L_N2_GC_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L14P_T2L_N2_GC_69
#set_property PACKAGE_PIN E22      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L13N_T2L_N1_GC_QBC_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L13N_T2L_N1_GC_QBC_69
#set_property PACKAGE_PIN E23      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L13P_T2L_N0_GC_QBC_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L13P_T2L_N0_GC_QBC_69
#set_property PACKAGE_PIN G24      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L12N_T1U_N11_GC_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L12N_T1U_N11_GC_69
#set_property PACKAGE_PIN G25      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L12P_T1U_N10_GC_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L12P_T1U_N10_GC_69
#set_property PACKAGE_PIN F22      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L11N_T1U_N9_GC_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L11N_T1U_N9_GC_69
#set_property PACKAGE_PIN F23      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L11P_T1U_N8_GC_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L11P_T1U_N8_GC_69
#set_property PACKAGE_PIN G22      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L10N_T1U_N7_QBC_AD4N_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L10N_T1U_N7_QBC_AD4N_69
#set_property PACKAGE_PIN H23      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L10P_T1U_N6_QBC_AD4P_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L10P_T1U_N6_QBC_AD4P_69
#set_property PACKAGE_PIN G26      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L9N_T1L_N5_AD12N_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L9N_T1L_N5_AD12N_69
#set_property PACKAGE_PIN H26      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L9P_T1L_N4_AD12P_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L9P_T1L_N4_AD12P_69
#set_property PACKAGE_PIN J24      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L8N_T1L_N3_AD5N_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L8N_T1L_N3_AD5N_69
#set_property PACKAGE_PIN K25      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L8P_T1L_N2_AD5P_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L8P_T1L_N2_AD5P_69
#set_property PACKAGE_PIN J25      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L7N_T1L_N1_QBC_AD13N_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L7N_T1L_N1_QBC_AD13N_69
#set_property PACKAGE_PIN J26      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L7P_T1L_N0_QBC_AD13P_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L7P_T1L_N0_QBC_AD13P_69
#set_property PACKAGE_PIN H24      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_T1U_N12_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_T1U_N12_69
#set_property PACKAGE_PIN J23      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_T0U_N12_VRP_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_T0U_N12_VRP_69
#set_property PACKAGE_PIN G21      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L6N_T0U_N11_AD6N_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L6N_T0U_N11_AD6N_69
#set_property PACKAGE_PIN H22      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L6P_T0U_N10_AD6P_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L6P_T0U_N10_AD6P_69
#set_property PACKAGE_PIN H21      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L5N_T0U_N9_AD14N_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L5N_T0U_N9_AD14N_69
#set_property PACKAGE_PIN J21      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L5P_T0U_N8_AD14P_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L5P_T0U_N8_AD14P_69
#set_property PACKAGE_PIN J20      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L4N_T0U_N7_DBC_AD7N_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L4N_T0U_N7_DBC_AD7N_69
#set_property PACKAGE_PIN K20      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L4P_T0U_N6_DBC_AD7P_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L4P_T0U_N6_DBC_AD7P_69
#set_property PACKAGE_PIN K21      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L3N_T0L_N5_AD15N_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L3N_T0L_N5_AD15N_69
#set_property PACKAGE_PIN K22      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L3P_T0L_N4_AD15P_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L3P_T0L_N4_AD15P_69
#set_property PACKAGE_PIN K23      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L2N_T0L_N3_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L2N_T0L_N3_69
#set_property PACKAGE_PIN L24      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L2P_T0L_N2_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L2P_T0L_N2_69
#set_property PACKAGE_PIN L22      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L1N_T0L_N1_DBC_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L1N_T0L_N1_DBC_69
#set_property PACKAGE_PIN L23      [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L1P_T0L_N0_DBC_69
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  69 VCCO - VCC1V8 - IO_L1P_T0L_N0_DBC_69
#set_property PACKAGE_PIN A15      [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L24N_T3U_N11_68
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L24N_T3U_N11_68
#set_property PACKAGE_PIN A20      [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L22P_T3U_N6_DBC_AD0P_68
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L22P_T3U_N6_DBC_AD0P_68
#set_property PACKAGE_PIN B16      [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L21N_T3L_N5_AD8N_68
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L21N_T3L_N5_AD8N_68
#set_property PACKAGE_PIN B17      [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L21P_T3L_N4_AD8P_68
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L21P_T3L_N4_AD8P_68
#set_property PACKAGE_PIN B19      [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L20N_T3L_N3_AD1N_68
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L20N_T3L_N3_AD1N_68
#set_property PACKAGE_PIN B20      [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L20P_T3L_N2_AD1P_68
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L20P_T3L_N2_AD1P_68
#set_property PACKAGE_PIN C16      [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L19N_T3L_N1_DBC_AD9N_68
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L19N_T3L_N1_DBC_AD9N_68
#set_property PACKAGE_PIN C17      [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L19P_T3L_N0_DBC_AD9P_68
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L19P_T3L_N0_DBC_AD9P_68
#set_property PACKAGE_PIN C18      [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_T3U_N12_68
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_T3U_N12_68
#set_property PACKAGE_PIN C19      [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_T2U_N12_68
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_T2U_N12_68
#set_property PACKAGE_PIN D18      [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L18N_T2U_N11_AD2N_68
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L18N_T2U_N11_AD2N_68
#set_property PACKAGE_PIN D19      [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L18P_T2U_N10_AD2P_68
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L18P_T2U_N10_AD2P_68
#set_property PACKAGE_PIN D15      [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L17N_T2U_N9_AD10N_68
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L17N_T2U_N9_AD10N_68
#set_property PACKAGE_PIN D16      [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L17P_T2U_N8_AD10P_68
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L17P_T2U_N8_AD10P_68
#set_property PACKAGE_PIN D20      [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L16N_T2U_N7_QBC_AD3N_68
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L16N_T2U_N7_QBC_AD3N_68
#set_property PACKAGE_PIN E20      [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L16P_T2U_N6_QBC_AD3P_68
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L16P_T2U_N6_QBC_AD3P_68
#set_property PACKAGE_PIN G20      [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L10P_T1U_N6_QBC_AD4P_68
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L10P_T1U_N6_QBC_AD4P_68
#set_property PACKAGE_PIN H17      [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L9N_T1L_N5_AD12N_68
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L9N_T1L_N5_AD12N_68
#set_property PACKAGE_PIN G15      [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L7N_T1L_N1_QBC_AD13N_68
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L7N_T1L_N1_QBC_AD13N_68
#set_property PACKAGE_PIN H16      [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L7P_T1L_N0_QBC_AD13P_68
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L7P_T1L_N0_QBC_AD13P_68
#set_property PACKAGE_PIN J19      [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_T1U_N12_68
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_T1U_N12_68
#set_property PACKAGE_PIN J14      [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_T0U_N12_VRP_68
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_T0U_N12_VRP_68
#set_property PACKAGE_PIN K18      [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L6P_T0U_N10_AD6P_68
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L6P_T0U_N10_AD6P_68
#set_property PACKAGE_PIN L18      [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L5N_T0U_N9_AD14N_68
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L5N_T0U_N9_AD14N_68
#set_property PACKAGE_PIN K16      [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L4P_T0U_N6_DBC_AD7P_68
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L4P_T0U_N6_DBC_AD7P_68
#set_property PACKAGE_PIN K17      [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L3N_T0L_N5_AD15N_68
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L3N_T0L_N5_AD15N_68
#set_property PACKAGE_PIN L17      [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L3P_T0L_N4_AD15P_68
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L3P_T0L_N4_AD15P_68
#set_property PACKAGE_PIN L15      [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L2N_T0L_N3_68
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L2N_T0L_N3_68
#set_property PACKAGE_PIN L16      [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L2P_T0L_N2_68
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L2P_T0L_N2_68
#set_property PACKAGE_PIN J15      [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L1N_T0L_N1_DBC_68
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L1N_T0L_N1_DBC_68
#set_property PACKAGE_PIN K15      [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L1P_T0L_N0_DBC_68
#set_property IOSTANDARD  LVCMOS18 [get_ports "No Connect"] ;# Bank  68 VCCO - VCC1V8   - IO_L1P_T0L_N0_DBC_68
# 
# UNUSED MGTY connections
#
# PACKAGE_PIN AK38     No Connect       Bank 124 - MGTREFCLK0P_124
# PACKAGE_PIN AH39     No Connect       Bank 124 - MGTREFCLK1N_124
# PACKAGE_PIN AH38     No Connect       Bank 124 - MGTREFCLK1P_124
# PACKAGE_PIN AK39     No Connect       Bank 124 - MGTREFCLK0N_124
# PACKAGE_PIN BF43     Grounded         Bank 124 - MGTYRXN0_124
# PACKAGE_PIN BD44     Grounded         Bank 124 - MGTYRXN1_124
# PACKAGE_PIN BB44     Grounded         Bank 124 - MGTYRXN2_124
# PACKAGE_PIN AY44     Grounded         Bank 124 - MGTYRXN3_124
# PACKAGE_PIN BF42     Grounded         Bank 124 - MGTYRXP0_124
# PACKAGE_PIN BD43     Grounded         Bank 124 - MGTYRXP1_124
# PACKAGE_PIN BB43     Grounded         Bank 124 - MGTYRXP2_124
# PACKAGE_PIN AY43     Grounded         Bank 124 - MGTYRXP3_124
# PACKAGE_PIN AT39     No Connect       Bank 124 - MGTYTXN0_124
# PACKAGE_PIN AR41     No Connect       Bank 124 - MGTYTXN1_124
# PACKAGE_PIN AP39     No Connect       Bank 124 - MGTYTXN2_124
# PACKAGE_PIN AN41     No Connect       Bank 124 - MGTYTXN3_124
# PACKAGE_PIN AT38     No Connect       Bank 124 - MGTYTXP0_124
# PACKAGE_PIN AR40     No Connect       Bank 124 - MGTYTXP1_124
# PACKAGE_PIN AP38     No Connect       Bank 124 - MGTYTXP2_124
# PACKAGE_PIN AN40     No Connect       Bank 124 - MGTYTXP3_124
# PACKAGE_PIN AF39     No Connect       Bank 125 - MGTREFCLK0N_125
# PACKAGE_PIN AF38     No Connect       Bank 125 - MGTREFCLK0P_125
# PACKAGE_PIN AE37     No Connect       Bank 125 - MGTREFCLK1N_125
# PACKAGE_PIN AE36     No Connect       Bank 125 - MGTREFCLK1P_125
# PACKAGE_PIN AG36     Grounded         Bank 125 - MGTRREF_LS
# PACKAGE_PIN BC46     Grounded         Bank 125 - MGTYRXN0_125
# PACKAGE_PIN BA46     Grounded         Bank 125 - MGTYRXN1_125
# PACKAGE_PIN AW46     Grounded         Bank 125 - MGTYRXN2_125
# PACKAGE_PIN AV44     Grounded         Bank 125 - MGTYRXN3_125
# PACKAGE_PIN BC45     Grounded         Bank 125 - MGTYRXP0_125
# PACKAGE_PIN BA45     Grounded         Bank 125 - MGTYRXP1_125
# PACKAGE_PIN AW45     Grounded         Bank 125 - MGTYRXP2_125
# PACKAGE_PIN AV43     Grounded         Bank 125 - MGTYRXP3_125
# PACKAGE_PIN AM39     No Connect       Bank 125 - MGTYTXN0_125
# PACKAGE_PIN AL41     No Connect       Bank 125 - MGTYTXN1_125
# PACKAGE_PIN AJ41     No Connect       Bank 125 - MGTYTXN2_125
# PACKAGE_PIN AG41     No Connect       Bank 125 - MGTYTXN3_125
# PACKAGE_PIN AM38     No Connect       Bank 125 - MGTYTXP0_125
# PACKAGE_PIN AL40     No Connect       Bank 125 - MGTYTXP1_125
# PACKAGE_PIN AJ40     No Connect       Bank 125 - MGTYTXP2_125
# PACKAGE_PIN AG40     No Connect       Bank 125 - MGTYTXP3_125
# PACKAGE_PIN AD39     No Connect       Bank 126 - MGTREFCLK0N_126
# PACKAGE_PIN AD38     No Connect       Bank 126 - MGTREFCLK0P_126
# PACKAGE_PIN AC37     No Connect       Bank 126 - MGTREFCLK1N_126
# PACKAGE_PIN AC36     No Connect       Bank 126 - MGTREFCLK1P_126
# PACKAGE_PIN AU46     Grounded         Bank 126 - MGTYRXN0_126
# PACKAGE_PIN AT44     Grounded         Bank 126 - MGTYRXN1_126
# PACKAGE_PIN AR46     Grounded         Bank 126 - MGTYRXN2_126
# PACKAGE_PIN AP44     Grounded         Bank 126 - MGTYRXN3_126
# PACKAGE_PIN AU45     Grounded         Bank 126 - MGTYRXP0_126
# PACKAGE_PIN AT43     Grounded         Bank 126 - MGTYRXP1_126
# PACKAGE_PIN AR45     Grounded         Bank 126 - MGTYRXP2_126
# PACKAGE_PIN AP43     Grounded         Bank 126 - MGTYRXP3_126
# PACKAGE_PIN AH43     No Connect       Bank 126 - MGTYTXN0_126
# PACKAGE_PIN AE41     No Connect       Bank 126 - MGTYTXN1_126
# PACKAGE_PIN AF43     No Connect       Bank 126 - MGTYTXN2_126
# PACKAGE_PIN AD43     No Connect       Bank 126 - MGTYTXN3_126
# PACKAGE_PIN AH42     No Connect       Bank 126 - MGTYTXP0_126
# PACKAGE_PIN AE40     No Connect       Bank 126 - MGTYTXP1_126
# PACKAGE_PIN AF42     No Connect       Bank 126 - MGTYTXP2_126
# PACKAGE_PIN AD42     No Connect       Bank 126 - MGTYTXP3_126
# PACKAGE_PIN AB39     No Connect       Bank 127 - MGTREFCLK0N_127
# PACKAGE_PIN AB38     No Connect       Bank 127 - MGTREFCLK0P_127
# PACKAGE_PIN AA37     No Connect       Bank 127 - MGTREFCLK1N_127
# PACKAGE_PIN AA36     No Connect       Bank 127 - MGTREFCLK1P_127
# PACKAGE_PIN AN46     Grounded         Bank 127 - MGTYRXN0_127
# PACKAGE_PIN AK44     Grounded         Bank 127 - MGTYRXN1_127
# PACKAGE_PIN AM44     Grounded         Bank 127 - MGTYRXN2_127
# PACKAGE_PIN AL46     Grounded         Bank 127 - MGTYRXN3_127
# PACKAGE_PIN AN45     Grounded         Bank 127 - MGTYRXP0_127
# PACKAGE_PIN AK43     Grounded         Bank 127 - MGTYRXP1_127
# PACKAGE_PIN AM43     Grounded         Bank 127 - MGTYRXP2_127
# PACKAGE_PIN AL45     Grounded         Bank 127 - MGTYRXP3_127
# PACKAGE_PIN AC41     No Connect       Bank 127 - MGTYTXN0_127
# PACKAGE_PIN AB43     No Connect       Bank 127 - MGTYTXN1_127
# PACKAGE_PIN AA41     No Connect       Bank 127 - MGTYTXN2_127
# PACKAGE_PIN Y43      No Connect       Bank 127 - MGTYTXN3_127
# PACKAGE_PIN AC40     No Connect       Bank 127 - MGTYTXP0_127
# PACKAGE_PIN AB42     No Connect       Bank 127 - MGTYTXP1_127
# PACKAGE_PIN AA40     No Connect       Bank 127 - MGTYTXP2_127
# PACKAGE_PIN Y42      No Connect       Bank 127 - MGTYTXP3_127
# PACKAGE_PIN Y39      No Connect       Bank 128 - MGTREFCLK0N_128
# PACKAGE_PIN Y38      No Connect       Bank 128 - MGTREFCLK0P_128
# PACKAGE_PIN V39      No Connect       Bank 128 - MGTREFCLK1N_128
# PACKAGE_PIN V38      No Connect       Bank 128 - MGTREFCLK1P_128
# PACKAGE_PIN AJ46     Grounded         Bank 128 - MGTYRXN0_128
# PACKAGE_PIN AG46     Grounded         Bank 128 - MGTYRXN1_128
# PACKAGE_PIN AE46     Grounded         Bank 128 - MGTYRXN2_128
# PACKAGE_PIN AC46     Grounded         Bank 128 - MGTYRXN3_128
# PACKAGE_PIN AJ45     Grounded         Bank 128 - MGTYRXP0_128
# PACKAGE_PIN AG45     Grounded         Bank 128 - MGTYRXP1_128
# PACKAGE_PIN AE45     Grounded         Bank 128 - MGTYRXP2_128
# PACKAGE_PIN AC45     Grounded         Bank 128 - MGTYRXP3_128
# PACKAGE_PIN W41      No Connect       Bank 128 - MGTYTXN0_128
# PACKAGE_PIN U41      No Connect       Bank 128 - MGTYTXN1_128
# PACKAGE_PIN T43      No Connect       Bank 128 - MGTYTXN2_128
# PACKAGE_PIN R41      No Connect       Bank 128 - MGTYTXN3_128
# PACKAGE_PIN W40      No Connect       Bank 128 - MGTYTXP0_128
# PACKAGE_PIN U40      No Connect       Bank 128 - MGTYTXP1_128
# PACKAGE_PIN T42      No Connect       Bank 128 - MGTYTXP2_128
# PACKAGE_PIN R40      No Connect       Bank 128 - MGTYTXP3_128
# PACKAGE_PIN U37      No Connect       Bank 129 - MGTREFCLK0N_129
# PACKAGE_PIN U36      No Connect       Bank 129 - MGTREFCLK0P_129
# PACKAGE_PIN T39      No Connect       Bank 129 - MGTREFCLK1N_129
# PACKAGE_PIN T38      No Connect       Bank 129 - MGTREFCLK1P_129
# PACKAGE_PIN W36      No Connect       Bank 129 - MGTRREF_LN
# PACKAGE_PIN V44      Grounded         Bank 129 - MGTYRXN0_129
# PACKAGE_PIN AA46     Grounded         Bank 129 - MGTYRXN1_129
# PACKAGE_PIN W46      Grounded         Bank 129 - MGTYRXN2_129
# PACKAGE_PIN U46      Grounded         Bank 129 - MGTYRXN3_129
# PACKAGE_PIN V43      Grounded         Bank 129 - MGTYRXP0_129
# PACKAGE_PIN AA45     Grounded         Bank 129 - MGTYRXP1_129
# PACKAGE_PIN W45      Grounded         Bank 129 - MGTYRXP2_129
# PACKAGE_PIN U45      Grounded         Bank 129 - MGTYRXP3_129
# PACKAGE_PIN P43      No Connect       Bank 129 - MGTYTXN0_129
# PACKAGE_PIN N41      No Connect       Bank 129 - MGTYTXN1_129
# PACKAGE_PIN K43      No Connect       Bank 129 - MGTYTXN2_129
# PACKAGE_PIN L41      No Connect       Bank 129 - MGTYTXN3_129
# PACKAGE_PIN P42      No Connect       Bank 129 - MGTYTXP0_129
# PACKAGE_PIN N40      No Connect       Bank 129 - MGTYTXP1_129
# PACKAGE_PIN K42      No Connect       Bank 129 - MGTYTXP2_129
# PACKAGE_PIN L40      No Connect       Bank 129 - MGTYTXP3_129
# PACKAGE_PIN R37      No Connect       Bank 130 - MGTREFCLK0N_130
# PACKAGE_PIN R36      No Connect       Bank 130 - MGTREFCLK0P_130
# PACKAGE_PIN P39      No Connect       Bank 130 - MGTREFCLK1N_130
# PACKAGE_PIN P38      No Connect       Bank 130 - MGTREFCLK1P_130
# PACKAGE_PIN R46      Grounded         Bank 130 - MGTYRXN0_130
# PACKAGE_PIN N46      Grounded         Bank 130 - MGTYRXN1_130
# PACKAGE_PIN M44      Grounded         Bank 130 - MGTYRXN2_130
# PACKAGE_PIN L46      Grounded         Bank 130 - MGTYRXN3_130
# PACKAGE_PIN R45      Grounded         Bank 130 - MGTYRXP0_130
# PACKAGE_PIN N45      Grounded         Bank 130 - MGTYRXP1_130
# PACKAGE_PIN M43      Grounded         Bank 130 - MGTYRXP2_130
# PACKAGE_PIN L45      Grounded         Bank 130 - MGTYRXP3_130
# PACKAGE_PIN J41      No Connect       Bank 130 - MGTYTXN0_130
# PACKAGE_PIN H43      No Connect       Bank 130 - MGTYTXN1_130
# PACKAGE_PIN G41      No Connect       Bank 130 - MGTYTXN2_130
# PACKAGE_PIN E41      No Connect       Bank 130 - MGTYTXN3_130
# PACKAGE_PIN J40      No Connect       Bank 130 - MGTYTXP0_130
# PACKAGE_PIN H42      No Connect       Bank 130 - MGTYTXP1_130
# PACKAGE_PIN G40      No Connect       Bank 130 - MGTYTXP2_130
# PACKAGE_PIN E40      No Connect       Bank 130 - MGTYTXP3_130
# PACKAGE_PIN AK8      No Connect       Bank 224 - MGTREFCLK0N_224
# PACKAGE_PIN AK9      No Connect       Bank 224 - MGTREFCLK0P_224
# PACKAGE_PIN AH8      No Connect       Bank 224 - MGTREFCLK1N_224
# PACKAGE_PIN AH9      No Connect       Bank 224 - MGTREFCLK1P_224
# PACKAGE_PIN AD8      No Connect       Bank 226 - MGTREFCLK0N_226
# PACKAGE_PIN AD9      No Connect       Bank 226 - MGTREFCLK0P_226
# PACKAGE_PIN AC10     No Connect       Bank 226 - MGTREFCLK1N_226
# PACKAGE_PIN AC11     No Connect       Bank 226 - MGTREFCLK1P_226
# PACKAGE_PIN Y8       No Connect       Bank 228 - MGTREFCLK0N_228
# PACKAGE_PIN Y9       No Connect       Bank 228 - MGTREFCLK0P_228
# PACKAGE_PIN V8       No Connect       Bank 228 - MGTREFCLK1N_228
# PACKAGE_PIN V9       No Connect       Bank 228 - MGTREFCLK1P_228
# PACKAGE_PIN AJ1      Grounded         Bank 228 - MGTYRXN0_228
# PACKAGE_PIN AG1      Grounded         Bank 228 - MGTYRXN1_228
# PACKAGE_PIN AE1      Grounded         Bank 228 - MGTYRXN2_228
# PACKAGE_PIN AC1      Grounded         Bank 228 - MGTYRXN3_228
# PACKAGE_PIN AJ2      Grounded         Bank 228 - MGTYRXP0_228
# PACKAGE_PIN AG2      Grounded         Bank 228 - MGTYRXP1_228
# PACKAGE_PIN AE2      Grounded         Bank 228 - MGTYRXP2_228
# PACKAGE_PIN AC2      Grounded         Bank 228 - MGTYRXP3_228
# PACKAGE_PIN W6       No Connect       Bank 228 - MGTYTXN0_228
# PACKAGE_PIN U6       No Connect       Bank 228 - MGTYTXN1_228
# PACKAGE_PIN T4       No Connect       Bank 228 - MGTYTXN2_228
# PACKAGE_PIN R6       No Connect       Bank 228 - MGTYTXN3_228
# PACKAGE_PIN W7       No Connect       Bank 228 - MGTYTXP0_228
# PACKAGE_PIN U7       No Connect       Bank 228 - MGTYTXP1_228
# PACKAGE_PIN T5       No Connect       Bank 228 - MGTYTXP2_228
# PACKAGE_PIN R7       No Connect       Bank 228 - MGTYTXP3_228
# PACKAGE_PIN U10      No Connect       Bank 229 - MGTREFCLK0N_229
# PACKAGE_PIN U11      No Connect       Bank 229 - MGTREFCLK0P_229
# PACKAGE_PIN T8       No Connect       Bank 229 - MGTREFCLK1N_229
# PACKAGE_PIN T9       No Connect       Bank 229 - MGTREFCLK1P_229
# PACKAGE_PIN W11      Grounded         Bank 229 - MGTRREF_RN
# PACKAGE_PIN V3       Grounded         Bank 229 - MGTYRXN0_229
# PACKAGE_PIN AA1      Grounded         Bank 229 - MGTYRXN1_229
# PACKAGE_PIN W1       Grounded         Bank 229 - MGTYRXN2_229
# PACKAGE_PIN U1       Grounded         Bank 229 - MGTYRXN3_229
# PACKAGE_PIN V4       Grounded         Bank 229 - MGTYRXP0_229
# PACKAGE_PIN AA2      Grounded         Bank 229 - MGTYRXP1_229
# PACKAGE_PIN W2       Grounded         Bank 229 - MGTYRXP2_229
# PACKAGE_PIN U2       Grounded         Bank 229 - MGTYRXP3_229
# PACKAGE_PIN P4       No Connect       Bank 229 - MGTYTXN0_229
# PACKAGE_PIN N6       No Connect       Bank 229 - MGTYTXN1_229
# PACKAGE_PIN K4       No Connect       Bank 229 - MGTYTXN2_229
# PACKAGE_PIN L6       No Connect       Bank 229 - MGTYTXN3_229
# PACKAGE_PIN P5       No Connect       Bank 229 - MGTYTXP0_229
# PACKAGE_PIN N7       No Connect       Bank 229 - MGTYTXP1_229
# PACKAGE_PIN K5       No Connect       Bank 229 - MGTYTXP2_229
# PACKAGE_PIN L7       No Connect       Bank 229 - MGTYTXP3_229
# PACKAGE_PIN R10      No Connect       Bank 230 - MGTREFCLK0N_230
# PACKAGE_PIN R11      No Connect       Bank 230 - MGTREFCLK0P_230
# PACKAGE_PIN P8       No Connect       Bank 230 - MGTREFCLK1N_230
# PACKAGE_PIN P9       No Connect       Bank 230 - MGTREFCLK1P_230
# PACKAGE_PIN R1       Grounded         Bank 230 - MGTYRXN0_230
# PACKAGE_PIN N1       Grounded         Bank 230 - MGTYRXN1_230
# PACKAGE_PIN M3       Grounded         Bank 230 - MGTYRXN2_230
# PACKAGE_PIN L1       Grounded         Bank 230 - MGTYRXN3_230
# PACKAGE_PIN R2       Grounded         Bank 230 - MGTYRXP0_230
# PACKAGE_PIN N2       Grounded         Bank 230 - MGTYRXP1_230
# PACKAGE_PIN M4       Grounded         Bank 230 - MGTYRXP2_230
# PACKAGE_PIN L2       Grounded         Bank 230 - MGTYRXP3_230
# PACKAGE_PIN J6       No Connect       Bank 230 - MGTYTXN0_230
# PACKAGE_PIN H4       No Connect       Bank 230 - MGTYTXN1_230
# PACKAGE_PIN G6       No Connect       Bank 230 - MGTYTXN2_230
# PACKAGE_PIN E6       No Connect       Bank 230 - MGTYTXN3_230
# PACKAGE_PIN J7       No Connect       Bank 230 - MGTYTXP0_230
# PACKAGE_PIN H5       No Connect       Bank 230 - MGTYTXP1_230
# PACKAGE_PIN G7       No Connect       Bank 230 - MGTYTXP2_230
# PACKAGE_PIN E7       No Connect       Bank 230 - MGTYTXP3_230
# PACKAGE_PIN N10      No Connect       Bank 231 - MGTREFCLK0N_231
# PACKAGE_PIN N11      No Connect       Bank 231 - MGTREFCLK0P_231
# PACKAGE_PIN M8       No Connect       Bank 231 - MGTREFCLK1N_231
# PACKAGE_PIN M9       No Connect       Bank 231 - MGTREFCLK1P_231
# PACKAGE_PIN J1       Grounded         Bank 231 - MGTYRXN0_231
# PACKAGE_PIN G1       Grounded         Bank 231 - MGTYRXN1_231
# PACKAGE_PIN F3       Grounded         Bank 231 - MGTYRXN2_231
# PACKAGE_PIN E1       Grounded         Bank 231 - MGTYRXN3_231
# PACKAGE_PIN J2       Grounded         Bank 231 - MGTYRXP0_231
# PACKAGE_PIN G2       Grounded         Bank 231 - MGTYRXP1_231
# PACKAGE_PIN F4       Grounded         Bank 231 - MGTYRXP2_231
# PACKAGE_PIN E2       Grounded         Bank 231 - MGTYRXP3_231
# PACKAGE_PIN D4       No Connect       Bank 231 - MGTYTXN0_231
# PACKAGE_PIN C6       No Connect       Bank 231 - MGTYTXN1_231
# PACKAGE_PIN B4       No Connect       Bank 231 - MGTYTXN2_231
# PACKAGE_PIN A6       No Connect       Bank 231 - MGTYTXN3_231
# PACKAGE_PIN D5       No Connect       Bank 231 - MGTYTXP0_231
# PACKAGE_PIN C7       No Connect       Bank 231 - MGTYTXP1_231
# PACKAGE_PIN B5       No Connect       Bank 231 - MGTYTXP2_231
# PACKAGE_PIN A7       No Connect       Bank 231 - MGTYTXP3_231