## Generated SDC file "max10_blaster.out.sdc"

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

## DATE    "Sat Jun 05 17:52:07 2021"

##
## DEVICE  "10M08SCE144C8G"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {i_clk_50MHz} -period 1.000 -waveform { 0.000 0.500 } [get_ports {i_clk_50MHz}]
create_clock -name {blaster_handler:BLASTER_PROCEED_INST|tx_start} -period 1.000 -waveform { 0.000 0.500 } [get_registers {blaster_handler:BLASTER_PROCEED_INST|tx_start}]


#**************************************************************
# Create Generated Clock
#**************************************************************



#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

set_clock_uncertainty -rise_from [get_clocks {i_clk_50MHz}] -rise_to [get_clocks {i_clk_50MHz}]  0.070  
set_clock_uncertainty -rise_from [get_clocks {i_clk_50MHz}] -fall_to [get_clocks {i_clk_50MHz}]  0.070  
set_clock_uncertainty -rise_from [get_clocks {i_clk_50MHz}] -rise_to [get_clocks {blaster_handler:BLASTER_PROCEED_INST|tx_start}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {i_clk_50MHz}] -fall_to [get_clocks {blaster_handler:BLASTER_PROCEED_INST|tx_start}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {i_clk_50MHz}] -rise_to [get_clocks {i_clk_50MHz}]  0.070  
set_clock_uncertainty -fall_from [get_clocks {i_clk_50MHz}] -fall_to [get_clocks {i_clk_50MHz}]  0.070  
set_clock_uncertainty -fall_from [get_clocks {i_clk_50MHz}] -rise_to [get_clocks {blaster_handler:BLASTER_PROCEED_INST|tx_start}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {i_clk_50MHz}] -fall_to [get_clocks {blaster_handler:BLASTER_PROCEED_INST|tx_start}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {blaster_handler:BLASTER_PROCEED_INST|tx_start}] -rise_to [get_clocks {i_clk_50MHz}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {blaster_handler:BLASTER_PROCEED_INST|tx_start}] -fall_to [get_clocks {i_clk_50MHz}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {blaster_handler:BLASTER_PROCEED_INST|tx_start}] -rise_to [get_clocks {i_clk_50MHz}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {blaster_handler:BLASTER_PROCEED_INST|tx_start}] -fall_to [get_clocks {i_clk_50MHz}]  0.040  


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

