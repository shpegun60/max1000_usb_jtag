
//==================== uart_tx =====================
module uart_tx #(parameter CLKS_PER_BIT)
(
	input       i_clk,
	input 		reset,
	input       i_start,
	input [7:0] i_in,
	output logic  o_tx_pin,
	output      o_done,

	output logic aux
);
  
localparam s_IDLE         = 3'b000;
localparam s_TX_START_BIT = 3'b001;
localparam s_TX_DATA_BITS = 3'b010;
localparam s_TX_STOP_BIT  = 3'b011;
localparam s_CLEANUP      = 3'b100;

logic [2:0]    r_SM_Main     = '0;
logic [10:0]   r_Clock_Count = '0;
logic [2:0]    r_Bit_Index   = '0;
logic [7:0]    r_Tx_Data     = '0;
logic          r_Tx_Done     = '0;

always @(posedge i_clk, negedge reset) begin
	if(!reset) begin
		o_tx_pin <= 1'b1;
		r_Tx_Done <= 1'b0;
		r_Clock_Count <= '0;
		r_Bit_Index <= '0;
		r_Tx_Data <= '0;
		r_SM_Main <= s_IDLE;
	end else begin
		case (r_SM_Main)
		   s_IDLE: begin
				o_tx_pin   <= 1'b1;         // Drive Line High for Idle
				r_Tx_Done     <= 1'b0;
				r_Clock_Count <= '0;
				r_Bit_Index   <= '0;
				
				if (i_start) begin
					r_Tx_Data   <= i_in;
					r_SM_Main   <= s_TX_START_BIT;
				end else begin
					r_SM_Main <= s_IDLE;
				end
			end // case: s_IDLE
			
			
		  // Send out Start Bit. Start bit = 0
		   s_TX_START_BIT: begin
				o_tx_pin <= 1'b0;
				
				// Wait CLKS_PER_BIT-1 clock cycles for start bit to finish
				if (r_Clock_Count < CLKS_PER_BIT-1) begin
					r_Clock_Count <= r_Clock_Count + 1'd1;
					r_SM_Main     <= s_TX_START_BIT;
				end else begin
					//r_Tx_Active   <= 1'b1;
					r_Clock_Count <= '0;
					r_SM_Main     <= s_TX_DATA_BITS;
				end
			end // case: s_TX_START_BIT
			
			
		  // Wait CLKS_PER_BIT-1 clock cycles for data bits to finish         
		   s_TX_DATA_BITS: begin
				
				o_tx_pin <= r_Tx_Data[r_Bit_Index];
				
				if (r_Clock_Count < CLKS_PER_BIT-1) begin
					r_Clock_Count <= r_Clock_Count + 1'd1;
					r_SM_Main     <= s_TX_DATA_BITS;
				end else begin
					r_Clock_Count <= '0;
					
					// Check if we have sent out all bits
					if (r_Bit_Index < 7) begin
						r_Bit_Index <= r_Bit_Index + 1'd1;
						r_SM_Main   <= s_TX_DATA_BITS;
					end else begin
						r_Bit_Index <= '0;
						r_SM_Main   <= s_TX_STOP_BIT;
					end
				end
			end // case: s_TX_DATA_BITS
			
			
		  // Send out Stop bit.  Stop bit = 1
		   s_TX_STOP_BIT: begin
				o_tx_pin <= 1'b1;
				
				// Wait CLKS_PER_BIT-1 clock cycles for Stop bit to finish
				if (r_Clock_Count < CLKS_PER_BIT-1) begin
					r_Clock_Count <= r_Clock_Count + 1'd1;
					r_SM_Main     <= s_TX_STOP_BIT;
				end else begin
					
					r_Tx_Done     <= 1'b1;
					r_Clock_Count <= '0;
					r_SM_Main     <= s_CLEANUP;
					//r_Tx_Active   <= 1'b0;
				end
			end // case: s_Tx_STOP_BIT
			
			
		  // Stay here 1 clock
			s_CLEANUP: begin
				aux <= ~aux;
				r_Tx_Done <= 1'b1;
				r_SM_Main <= s_IDLE;
			end
			
			
		  default: r_SM_Main <= s_IDLE;
			
		endcase
	end
end

//assign o_Tx_Active = r_Tx_Active;
assign o_done = r_Tx_Done;
   
endmodule

