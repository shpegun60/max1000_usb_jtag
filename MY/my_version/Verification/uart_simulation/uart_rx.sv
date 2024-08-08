
//========================= uart RX =============================

module uart_rx #(parameter CLKS_PER_BIT = 5*11)
(
	input        i_Clock,		// clock
	input 		 reset,			// reset
	input        i_rx,			// rx pin

	output       o_rdy,			// receive compleate
	output logic [7:0] o_Rx_Byte,		// RX byte
	output logic o_aux				// strobe receive
);


localparam s_IDLE         = 3'b000;
localparam s_RX_START_BIT = 3'b001;
localparam s_RX_DATA_BITS = 3'b010;
localparam s_RX_STOP_BIT  = 3'b011;
localparam s_CLEANUP      = 3'b100;

logic           r_Rx_Data_R = 1'b1;
logic           r_Rx_Data   = 1'b1;

logic [10:0]    r_Clock_Count = '0;
logic [2:0]     r_Bit_Index   = '0; //8 bits total
logic [7:0]     r_Rx_Byte     = '0;
logic           r_rdy         = '0;
logic [2:0]     r_state       = '0;


assign o_rdy   = r_rdy;
//assign o_Rx_Byte = r_Rx_Byte;

always_ff @(posedge i_Clock, negedge reset) begin
	if(!reset) begin
		r_Rx_Data_R <= 1'b1;
		r_Rx_Data   <= 1'b1;
	end else begin
		r_Rx_Data_R <= i_rx;
		r_Rx_Data   <= r_Rx_Data_R;
	end
end


always_ff @(posedge i_Clock, negedge reset) begin
	if(!reset) begin
		r_rdy       <= 1'b0;
		r_Clock_Count <= '0;
		r_Bit_Index   <= '0;
		r_state <= s_IDLE;
		r_Rx_Byte <= 8'd0;
		o_aux <= '0;
	end else begin
		
		r_rdy       <= 1'b0;
		
		case (r_state)
		   s_IDLE: begin
				r_Clock_Count <= '0;
				r_Bit_Index   <= '0;
				
				if (r_Rx_Data == 1'b0) r_state <= s_RX_START_BIT;         // Start bit detected
				else r_state <= s_IDLE;
			end
			
		   // Check middle of start bit to make sure it's still low
		   s_RX_START_BIT: begin
				if (r_Clock_Count == (CLKS_PER_BIT-1)/2) begin
					if (r_Rx_Data == 1'b0) begin
						r_Clock_Count <= '0;  // reset counter, found the middle
						r_state     <= s_RX_DATA_BITS;
					end else
						r_state <= s_IDLE;
					end
				else begin
					 r_Clock_Count <= r_Clock_Count + 1'd1;
					 r_state     <= s_RX_START_BIT;
				end
			end // case: s_RX_START_BIT
			
		   // Wait CLKS_PER_BIT-1 clock cycles to sample serial data
		   s_RX_DATA_BITS: begin
				if (r_Clock_Count < CLKS_PER_BIT-1) begin
					r_Clock_Count <= r_Clock_Count + 1'd1;
					r_state     <= s_RX_DATA_BITS;
				end else begin
					r_Clock_Count          <= '0;
					r_Rx_Byte[r_Bit_Index] <= r_Rx_Data;
					
					// Check if we have received all bits
					if (r_Bit_Index < 7) begin
						r_Bit_Index <= r_Bit_Index + 1'd1;
						r_state   <= s_RX_DATA_BITS;
					end else begin
						r_Bit_Index <= '0;
						r_state   <= s_RX_STOP_BIT;
					end
				end
			end // case: s_RX_DATA_BITS
			
		   // Receive Stop bit.  Stop bit = 1
		   s_RX_STOP_BIT: begin
				// Wait CLKS_PER_BIT-1 clock cycles for Stop bit to finish
				if (r_Clock_Count < CLKS_PER_BIT-1) begin
					r_Clock_Count <= r_Clock_Count + 1'd1;
					r_state     <= s_RX_STOP_BIT;
				end else begin
					o_Rx_Byte <= r_Rx_Byte;
					r_rdy       <= 1'b1;
					r_Clock_Count <= '0;
					r_state     <= s_CLEANUP;
				end
			end // case: s_RX_STOP_BIT
			
		   // Stay here 1 clock
		   s_CLEANUP: begin
				o_aux <= ~o_aux;
				r_state <= s_IDLE;
			end
			
		  default: r_state <= s_IDLE;
			
		endcase
	end
end 

endmodule // uart_rx
