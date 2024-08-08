/************ This is an univibrator to elongate input pulse **************/
module blaster_univibrator #(parameter BIT_WIDTH = 6)
(
	input logic i_clk,                        // Clocking
	input logic i_rst_n,                        // reset n
	input logic i_strobe,                     // Input strobe
	output 		o_out,								// Output strobe
	
	input logic [(BIT_WIDTH-1):0] i_data_pulse // Quantity of elongated pulses
);

logic [(BIT_WIDTH-1):0]  rCount = '0;
logic rS = 1'b0;
logic rR = 1'b0;

assign o_out = rR | i_strobe;

always_ff @(posedge i_strobe, posedge rR) begin: strobe // Synchronization toward positive edge "i_Clk"
	if (rR) rS <= 1'b0;
	else 	rS <= 1'b1;
end: strobe


always_ff @(posedge i_clk, negedge i_rst_n) begin: OnePulse_label // Univibrator
	if(~i_rst_n) begin
		rCount 	<= '0;
		rR 		<= 1'b0;
	end else begin
		if (~rR) rCount <= i_data_pulse;
		else rCount <= rCount - 1'b1;
		
		if (rS) rR <= 1'b1;
		else if ((rCount == 0) & rR) rR <= 1'b0;
	end
end: OnePulse_label

endmodule
/**************************************************************************/