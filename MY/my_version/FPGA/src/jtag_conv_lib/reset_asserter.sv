module jtag_reset_n_asserter
(
	input logic  CLK,				// external 24/25 MHz oscillator
	input logic  nRST_ASYNC,		// async reset
	input logic  IDLE_LED,
	
	output logic RESET_JTAG
);


logic [25:0] r_counter = '0;

always_ff @(posedge CLK, negedge nRST_ASYNC) begin
	if(~nRST_ASYNC) begin
		r_counter <= '0;
	end else begin
		
		r_counter <= IDLE_LED ? (r_counter + 1'b1) : '0;
		
		if(r_counter[25]) begin
			r_counter <= '0;
		end
		
	end
end

assign RESET_JTAG = ~r_counter[25];



endmodule
