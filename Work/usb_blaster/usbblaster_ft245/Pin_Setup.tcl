#5i-USB BLASTER PIN tcl
#pin setting
#www.5iFPGA.com
#Designed By ≥È—Ãµƒ”„

set_global_assignment -name RESERVE_ALL_UNUSED_PINS "AS INPUT TRI-STATED"

set_location_assignment PIN_2 -to D\[0\]
set_location_assignment PIN_3 -to D\[1\]
set_location_assignment PIN_4 -to D\[2\]
set_location_assignment PIN_5 -to D\[3\]
set_location_assignment PIN_6 -to D\[4\]
set_location_assignment PIN_7 -to D\[5\]
set_location_assignment PIN_8 -to D\[6\]
set_location_assignment PIN_15 -to D\[7\]

set_location_assignment PIN_12 -to CLK

set_location_assignment PIN_17 -to WR
set_location_assignment PIN_16 -to nRD
set_location_assignment PIN_19 -to nRXF
set_location_assignment PIN_18 -to nTXE


set_location_assignment PIN_47 -to B_TDO
set_location_assignment PIN_48 -to B_ASDO
set_location_assignment PIN_49 -to B_TCK
set_location_assignment PIN_50 -to B_TMS
set_location_assignment PIN_26 -to B_NCE
set_location_assignment PIN_27 -to B_NCS
set_location_assignment PIN_28 -to B_TDI
set_location_assignment PIN_76 -to B_OE 