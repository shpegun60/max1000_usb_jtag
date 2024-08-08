module cyclone4_top
(
	//input  i_rstn,     // RESET global signal
	input  i_clk_50MHz, // Primary FPGA CLOCK
	
	input  i_rx,
	output o_tx,
	
	// jtag to devices
	output logic o_tck,
	output logic o_tdi,
	output logic o_tms,
	input  i_tdo,

	
	output logic [1:0] 			o_led
);


logic sync_async_reset_n;

advanced_reset_n #(1) RESET_INST
(
	.i_independent_clk(i_clk_50MHz),                                      // independent clk (from quartz)
	.i_hardware_reset_n(/*i_rstn*/1'b1),                                     // independent hard reset (from buttom)
	.o_heart_bit(/*o_led[1]*/),                                            // heart bit for visual work detection
	//.o_pll_reset(),														  // pll reset
	//.o_pll_locked(),														  // pll locked
	
	.i_clk_domain(i_clk_50MHz),          // input clk domains
	.o_sync_async_reset_n(sync_async_reset_n)   // output reset_n for each clk domains
);


blaster_handler #(.CLKS_PER_BIT(/*25*/109)) BLASTER_INST
(
	.i_reset_n(sync_async_reset_n),     // RESET global signal
	.i_clk(i_clk_50MHz), // Primary FPGA CLOCK
	
	.*,
	.i_ASDO(1'b0),
	.o_NCE(),
	.o_NCS(),
	.o_led(o_led[0])
);



assign o_led[1] = 1'b1;

endmodule
