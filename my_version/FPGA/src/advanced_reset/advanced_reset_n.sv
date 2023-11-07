module advanced_reset_n #(parameter QUANTITY_OF_CLK_DOMAINS = 1)
(
	input    i_independent_clk,                                      // independent clk (from quartz)
	input    i_hardware_reset_n,                                     // independent hard reset (from buttom)
	output   o_heart_bit,                                            // heart bit for visual work detection
	output 	o_pll_reset,														  // pll reset
	output 	o_pll_locked,														  // pll locked
	
	input  [(QUANTITY_OF_CLK_DOMAINS - 1):0] i_clk_domain,          // input clk domains
	output [(QUANTITY_OF_CLK_DOMAINS - 1):0] o_sync_async_reset_n   // output reset_n for each clk domains
);

// software reset inst
logic w_software_rstn; 
reset #(.RESET_OFF(1'b1), .POWER_UP_COUNTER_DELAY(25'd33_000_000)) software_reset_inst
(
	.i_clk   (i_independent_clk),
	.o_reset (w_software_rstn),
	.heart_bit(o_heart_bit)
);

logic w_rst_n;
assign w_rst_n = w_software_rstn & i_hardware_reset_n; // soft & hardware reset_n

// generating sync-async reset for each clk domain 
genvar i;
generate
	for(i = 0; i < QUANTITY_OF_CLK_DOMAINS; i++) begin : CLK_DOMAIN_RESET_GENERATE
		sync_async_reset #(.RESET_OFF(1'b1), .QUANTITY_OF_PROTECTION_REGISTERS(3)) SYNC_ASYNC_RESET_INST
		(
			.i_clock              (i_clk_domain[i]),
			.i_async_reset_n      (w_rst_n),
			.o_sync_async_reset_n (o_sync_async_reset_n[i])
		);
	end

endgenerate

// pll advanced settings
assign o_pll_reset = ~w_rst_n;
assign o_pll_locked 	= 1'b0;

endmodule  // advanced reset_n