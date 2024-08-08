module sync_async_reset #(parameter logic RESET_OFF = 1'b1, parameter QUANTITY_OF_PROTECTION_REGISTERS = 4)
(
	input    i_clock,              // clk from clk domain
	input    i_async_reset_n,      // input async reset
	output   o_sync_async_reset_n  // output sync async reset
);

logic [QUANTITY_OF_PROTECTION_REGISTERS:0] r_delay; //reset shift register


dff dff_first  (.d(RESET_OFF),  .clk(i_clock),  .clrn(i_async_reset_n), .prn(1'd1), .q(r_delay[0]));

genvar i;
generate
	for(i = 0; i < QUANTITY_OF_PROTECTION_REGISTERS; i++) begin : reset_registers_inst
		
		dff dff_delay (.d(r_delay[i]), .clk(i_clock),  .clrn(i_async_reset_n), .prn(1'd1), .q(r_delay[i+1]));
		
	end
endgenerate

assign o_sync_async_reset_n = r_delay[QUANTITY_OF_PROTECTION_REGISTERS];

endmodule  // sync_async_reset