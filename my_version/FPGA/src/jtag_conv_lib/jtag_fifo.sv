module jtag_fifo_logic
(
	input logic  CLK,				// external 24/25 MHz oscillator
	input logic  nRST_ASYNC,		// async reset
	
	// JTAG mode
	output logic B_TCK,				// JTAG output: TCK to chain, AS/PS DCLK
	output logic B_TDI,				// JTAG output: TDI to chain, AS: ASDI, PS: DATA0
	input  logic B_TDO,				 // JTAG input: TDO, AS/PS input: CONF_DONE
	output logic B_TMS,				// JTAG output: TMS to chain, AS/PS nCONFIG
	
	// Active serial mode
	input  logic B_ASDO,			 // AS input: DATAOUT, PS input: nSTATUS
	output logic B_NCE,				// AS output: nCE
	output logic B_NCS,				// AS output: nCS
	
	// internal rx interface
	input RXE,
	output logic RX_RD_REQ,
	input logic [7:0] RX_DATA,
	
	// internal tx interface
	input TXF,
	output logic TX_WR_REQ,
	output logic [7:0] TX_DATA,
	
	// leds
	output logic B_OE,			 // LED output/output driver enable 
	output logic BUSY_LED,		// LED output/output busy
	output logic IDLE_LED
);

//***************************************************************************************************************

enum logic [3:0] {
	WAIT_FOR_N_RXF_LOW						= 4'd0,
	SET_N_RD_LOW								= 4'd1,
	LATCH_DATA_FROM_HOST						= 4'd2,
	SET_N_RD_HIGH								= 4'd3,
	BITS_SET_PINS_FROM_DATA					= 4'd4,
	BYTES_SET_BITCOUNT						= 4'd5,
	BYTES_GET_TDO_SET_TDI					= 4'd6,
	BYTES_CLOCK_HIGH_AND_SHIFT				= 4'd7,
	BYTES_KEEP_CLOCK_HIGH					= 4'd8,
	BYTES_CLOCK_FINISH						= 4'd9,
	WAIT_FOR_N_TXE_LOW						= 4'd10,
	SET_WR_HIGH									= 4'd11
} state = WAIT_FOR_N_RXF_LOW, next_state = WAIT_FOR_N_RXF_LOW;

logic carry_in = 1'b0;
logic do_output = 1'b0;
logic [7:0] ioshifter = '0;
logic [8:0] bitcount = '0;


// Sequential state transition
always_ff @(posedge CLK, negedge nRST_ASYNC) begin
	if(~nRST_ASYNC)  	state <= WAIT_FOR_N_RXF_LOW;
	else 					state <= next_state;
end


// Combinational next state logic
always_comb begin
	
	next_state <= WAIT_FOR_N_RXF_LOW;
	
	unique case(state)
		
		// ============================ INPUT
		WAIT_FOR_N_RXF_LOW: 		next_state <= RXE ? WAIT_FOR_N_RXF_LOW : SET_N_RD_LOW;
		SET_N_RD_LOW: 				next_state <= LATCH_DATA_FROM_HOST;
		LATCH_DATA_FROM_HOST:	next_state <= SET_N_RD_HIGH;
		
		SET_N_RD_HIGH: begin
			if(bitcount[8:3] != 6'b000000) begin
				next_state <= BYTES_GET_TDO_SET_TDI;
			end else if(ioshifter[7]) begin
				next_state <= BYTES_SET_BITCOUNT;
			end else begin
				next_state <= BITS_SET_PINS_FROM_DATA;
			end
		end
		
		BYTES_SET_BITCOUNT: next_state <= WAIT_FOR_N_RXF_LOW;
		
		// ============================ BIT BANGING
		BITS_SET_PINS_FROM_DATA: begin
			if(~ioshifter[6]) next_state <= WAIT_FOR_N_RXF_LOW; // read next byte from host
			else 			  next_state <= WAIT_FOR_N_TXE_LOW; // output byte to host
		end
		
		// ============================ BYTE OUTPUT (SHIFT OUT 8 BITS)
		BYTES_GET_TDO_SET_TDI: next_state <= BYTES_CLOCK_HIGH_AND_SHIFT;
		
		BYTES_CLOCK_HIGH_AND_SHIFT: next_state <= BYTES_KEEP_CLOCK_HIGH;
		
		BYTES_KEEP_CLOCK_HIGH: next_state <= BYTES_CLOCK_FINISH;
		
		BYTES_CLOCK_FINISH: begin
			if(bitcount[2:0] != 3'b111) begin
				next_state <= BYTES_GET_TDO_SET_TDI; //clock next bit
			end else if(do_output) begin
				next_state <= WAIT_FOR_N_TXE_LOW; // output byte to host
			end else begin
				next_state <= WAIT_FOR_N_RXF_LOW; // read next byte from host
			end
		end
		
		// ============================ OUTPUT BYTE TO HOST
		WAIT_FOR_N_TXE_LOW: next_state <= TXF ? WAIT_FOR_N_TXE_LOW : SET_WR_HIGH;
		SET_WR_HIGH: next_state <= WAIT_FOR_N_RXF_LOW;
		
	endcase
end


// state handler

always_ff @(posedge CLK, negedge nRST_ASYNC) begin
	if(~nRST_ASYNC) begin
		B_TCK <= 1'b0;
		B_TDI <= 1'b0;
		B_TMS <= 1'b0;
		
		B_NCE <= 1'b1;				// AS output: nCE
		B_NCS <= 1'b1;				// AS output: nCS
		
		RX_RD_REQ <= 1'b0;
		
		TX_WR_REQ <= 1'b0;
		TX_DATA <= '0;
		B_OE  <= 1'b0;
		
		carry_in  <= 1'b0;
		do_output <= 1'b0;
		ioshifter <= '0;
		bitcount  <= '0;
	end else begin
		
		TX_WR_REQ <= 1'b0;
		RX_RD_REQ <= 1'b0;
		
		if (state == SET_N_RD_LOW) begin
			RX_RD_REQ <= 1'b1;
		end
		
		if (state == LATCH_DATA_FROM_HOST) begin
			ioshifter <= RX_DATA;
		end
		
		if(state == SET_WR_HIGH) begin
			TX_DATA <= ioshifter;
			TX_WR_REQ <= 1'b1;
		end
		
		if(state == BITS_SET_PINS_FROM_DATA) begin
			B_TCK <= ioshifter[0];
			B_TMS <= ioshifter[1];
			B_NCE <= ioshifter[2];
			B_NCS <= ioshifter[3];
			B_TDI <= ioshifter[4];
			B_OE  <= ioshifter[5];
			ioshifter <= {6'b000000, B_ASDO, B_TDO};
		end
		
		if(state == BYTES_SET_BITCOUNT) begin
			bitcount <= {ioshifter[5:0], 3'b111};
			do_output <= ioshifter[6];
		end
		
		if(state == BYTES_GET_TDO_SET_TDI) begin
			if(B_NCS) begin
				carry_in <= B_TDO; // JTAG mode (nCS=1)
			end else begin
				carry_in <= B_ASDO; // Active Serial mode (nCS=0)
			end
			B_TDI <= ioshifter[0];
			bitcount <= bitcount - 1'b1;
		end
		
		if((state == BYTES_CLOCK_HIGH_AND_SHIFT) | (state == BYTES_KEEP_CLOCK_HIGH)) begin
			B_TCK <= 1'b1;
		end
		
		if(state == BYTES_CLOCK_HIGH_AND_SHIFT) begin
			ioshifter <= {carry_in, ioshifter[7:1]};
		end
		
		if(state == BYTES_CLOCK_FINISH) begin
			B_TCK <= 1'b0;
		end
		
	end
end



// busy led only for test ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

always_ff @(posedge CLK, negedge nRST_ASYNC) begin
	if(~nRST_ASYNC) begin
		BUSY_LED <= 1'b0;
	end else begin
		
		if((state == LATCH_DATA_FROM_HOST) | (state == SET_N_RD_LOW) | (state == SET_N_RD_HIGH) | (state == BYTES_SET_BITCOUNT) | (state == BITS_SET_PINS_FROM_DATA) | (state == BYTES_GET_TDO_SET_TDI) | 
			(state == BYTES_CLOCK_HIGH_AND_SHIFT) | (state == BYTES_KEEP_CLOCK_HIGH) | (state == BYTES_CLOCK_FINISH) | (state == WAIT_FOR_N_TXE_LOW) | (state == SET_WR_HIGH)) begin
			BUSY_LED <= 1'b0;
		end else begin
			BUSY_LED <= 1'b1;
		end
		
		IDLE_LED <= (state == WAIT_FOR_N_RXF_LOW) ? 1'b1 : 1'b0;
		
	end
end



endmodule
