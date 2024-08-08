## Generated SDC file "cyclone4_slave.out.sdc"

## Copyright (C) 2018  Intel Corporation. All rights reserved.
## Your use of Intel Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Intel Program License 
## Subscription Agreement, the Intel Quartus Prime License Agreement,
## the Intel FPGA IP License Agreement, or other applicable license
## agreement, including, without limitation, that your use is for
## the sole purpose of programming logic devices manufactured by
## Intel and sold by Intel or its authorized distributors.  Please
## refer to the applicable agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus Prime"
## VERSION "Version 18.1.0 Build 625 09/12/2018 SJ Standard Edition"

## DATE    "Mon Jun 07 11:31:36 2021"

##
## DEVICE  "EP4CE6E22C8"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {i_clk_50MHz} -period 1.000 -waveform { 0.000 0.500 } [get_ports {i_clk_50MHz}]
create_clock -name {blaster_handler:BLASTER_INST|tx_start} -period 1.000 -waveform { 0.000 0.500 } [get_registers {blaster_handler:BLASTER_INST|tx_start}]


#**************************************************************
# Create Generated Clock
#**************************************************************



#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

set_clock_uncertainty -rise_from [get_clocks {blaster_handler:BLASTER_INST|tx_start}] -rise_to [get_clocks {i_clk_50MHz}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {blaster_handler:BLASTER_INST|tx_start}] -fall_to [get_clocks {i_clk_50MHz}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {blaster_handler:BLASTER_INST|tx_start}] -rise_to [get_clocks {i_clk_50MHz}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {blaster_handler:BLASTER_INST|tx_start}] -fall_to [get_clocks {i_clk_50MHz}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {i_clk_50MHz}] -rise_to [get_clocks {blaster_handler:BLASTER_INST|tx_start}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {i_clk_50MHz}] -fall_to [get_clocks {blaster_handler:BLASTER_INST|tx_start}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {i_clk_50MHz}] -rise_to [get_clocks {i_clk_50MHz}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {i_clk_50MHz}] -fall_to [get_clocks {i_clk_50MHz}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {i_clk_50MHz}] -rise_to [get_clocks {blaster_handler:BLASTER_INST|tx_start}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {i_clk_50MHz}] -fall_to [get_clocks {blaster_handler:BLASTER_INST|tx_start}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {i_clk_50MHz}] -rise_to [get_clocks {i_clk_50MHz}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {i_clk_50MHz}] -fall_to [get_clocks {i_clk_50MHz}]  0.020  


#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

