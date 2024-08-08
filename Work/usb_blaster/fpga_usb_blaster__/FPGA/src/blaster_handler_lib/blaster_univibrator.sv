/************ This is an univibrator to elongate input pulse **************/
module blaster_univibrator #(BIT_WIDTH=6)
(
  input logic i_clk,                        // Clocking
  input logic i_strobe,                     // An input strobe
	
  input logic [BIT_WIDTH-1:0] i_data_pulse, // Quantity of elongated pulses
  output o_out
  
);
logic [BIT_WIDTH-1 : 0]  rCount;
logic rS;
logic rR = 1'b0;

assign o_out = rR;  

always_ff @(posedge i_strobe or posedge rR) begin: strobe // Synchronization toward positive edge "i_Clk"
	
	if (rR) rS <= 0;
	else rS <= 1;
	
end: strobe 


always_ff @(posedge i_clk) begin: OnePulse_label // Univibrator
	
	if (~rR) rCount <= i_data_pulse;
	else rCount <= rCount-1'b1;
	
	if (rS) rR <= 1;
	else if (rCount==0 && rR) rR <= 0;
	
end: OnePulse_label

endmodule
/**************************************************************************/