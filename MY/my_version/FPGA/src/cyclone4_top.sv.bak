module cyclone4_top
(
	input CLK,
	input nRXF,
	input nTXE,
	input B_TDO,
	input B_ASDO,
	output logic B_TCK,
	output logic B_TMS,
	output logic B_NCE,
	output logic B_NCS,
	output logic B_TDI,
	output logic	B_OE,
	output logic nRD,
	output logic WR,
	inout [7:0] D,
	
	output o_led
);


/// PLL CLOCK INST *************************************************************************

logic pll_clk;

logic pll_reset;
logic pll_locked;

pll_dev PLL_DEV
(
	.areset(1'b0),
	.inclk0(CLK),
	.c0(pll_clk),
	.locked(1'b0)
);


logic reset_n;
advanced_reset_n #(1) RESET_INST
(
	.i_independent_clk(CLK),                                      // independent clk (from quartz)
	.i_hardware_reset_n(1'b1),                                     // independent hard reset (from buttom)
	//.o_heart_bit,                                            // heart bit for visual work detection
	.o_pll_reset(pll_reset),														  // pll reset
	.o_pll_locked(pll_locked),														  // pll locked
	
	.i_clk_domain(pll_clk),          // input clk domains
	.o_sync_async_reset_n(reset_n)   // output reset_n for each clk domains
);


//*******************************************************************************************


//jtag_logic BLASTER_INST
//(
//	.CLK(pll_clk),
//	.nRXF(nRXF),
//	.nTXE(nTXE),
//	.B_TDO(B_TDO),
//	.B_ASDO(B_ASDO),
//	.B_TCK(B_TCK),
//	.B_TMS(B_TMS),
//	.B_NCE(B_NCE),
//	.B_NCS(B_NCS),
//	.B_TDI(B_TDI),
//	.B_OE(B_OE),
//	.nRD(nRD),
//	.WR(WR),
//	.D(D)
//);


//jtag_logic_verilog BLASTER_INST
//(
//	.CLK(pll_clk),
//	.nRST_ASYNC(reset_n),
//	.nRST_SYNC(1'b1),
//	.nRXF(nRXF),
//	.nTXE(nTXE),
//	.B_TDO(B_TDO),
//	.B_ASDO(B_ASDO),
//	.B_TCK(B_TCK),
//	.B_TMS(B_TMS),
//	.B_NCE(B_NCE),
//	.B_NCS(B_NCS),
//	.B_TDI(B_TDI),
//	.B_OE(B_OE),
//	.nRD(nRD),
//	.WR(WR),
//	.D(D),
//	
//	.BUSY_LED(o_led)
//);


blaster_handler BLASTER_INST
(
	.CLK(pll_clk),
	.nRST_ASYNC(reset_n),
	.nRXF(nRXF),
	.nTXE(nTXE),
	.B_TDO(B_TDO),
	.B_ASDO(B_ASDO),
	.B_TCK(B_TCK),
	.B_TMS(B_TMS),
	.B_NCE(B_NCE),
	.B_NCS(B_NCS),
	.B_TDI(B_TDI),
	.B_OE(B_OE),
	.nRD(nRD),
	.WR(WR),
	.D(D),
	
	.BUSY_LED(o_led)
);




endmodule
