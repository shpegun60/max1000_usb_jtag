module jtag_logic
(
	input  CLK,
	input  nRST,
	
	// external_fifo
	input  nRXF,
	input  nTXE,
	output logic nRD,
	output logic WR,
	inout [7:0] D,
	// ltag
	input  B_TDO,
	output logic B_TCK,
	output logic B_TMS,
	output logic B_TDI,
	// active serial
	input  B_ASDO,
	output logic B_NCE,
	output logic B_NCS,
	// led
	output logic B_OE
);

enum logic [3:0] {
	WAIT_FOR_N_RXF_LOW					= 4'b0000,
	SET_N_RD_LOW							= 4'b0001,
	KEEP_N_RD_LOW							= 4'b0010,
	LATCH_DATA_FROM_HOST					= 4'b0011,
	SET_N_RD_HIGH							= 4'b0100,
	BITS_SET_PINS_FROM_DATA				= 4'b0101,
	BYTES_SET_BITCOUNT					= 4'b0110,
	BYTES_GET_TDO_SET_TDI				= 4'b0111,
	BYTES_CLOCK_HIGH_AND_SHIFT			= 4'b1000,
	BYTES_KEEP_CLOCK_HIGH				= 4'b1001,
	BYTES_CLOCK_FINISH					= 4'b1010,
	WAIT_FOR_N_TXE_LOW					= 4'b1011,
	SET_WR_HIGH								= 4'b1100,
	OUTPUT_ENABLE							= 4'b1101,
	SET_WR_LOW								= 4'b1110,
	OUTPUT_DISABLE 						= 4'b1111
} state = WAIT_FOR_N_RXF_LOW, next_state;

logic carry_in = 1'b0;
logic do_output = 1'b0;
logic [7:0] ioshifter = '0;
logic [8:0] bitcount = '0;


// Sequential state transition
always_ff @(posedge CLK, negedge nRST) begin
	if(~nRST) begin
		state <= WAIT_FOR_N_RXF_LOW;
	end else begin
		state <= next_state;
	end
end


// Combinational next state logic
always_comb begin
	
	next_state <= WAIT_FOR_N_RXF_LOW;
	
	unique case(state)
		
		// ============================ INPUT
		WAIT_FOR_N_RXF_LOW: next_state <= nRXF ? WAIT_FOR_N_RXF_LOW : SET_N_RD_LOW;
		
		SET_N_RD_LOW: next_state <= KEEP_N_RD_LOW;
		
		KEEP_N_RD_LOW: next_state <= LATCH_DATA_FROM_HOST;
		
		LATCH_DATA_FROM_HOST: next_state <= SET_N_RD_HIGH;
		
		SET_N_RD_HIGH: begin
			if(bitcount[8:3] != 6'b000000) begin
				next_state <= BYTES_GET_TDO_SET_TDI;
			end else if(ioshifter[7] == 1'b1) begin
				next_state <= BYTES_SET_BITCOUNT;
			end else begin
				next_state <= BITS_SET_PINS_FROM_DATA;
			end;
		end
		
		BYTES_SET_BITCOUNT: next_state <= WAIT_FOR_N_RXF_LOW;
		
		// ============================ BIT BANGING
		BITS_SET_PINS_FROM_DATA: begin
			if(ioshifter[6] == 1'b0) next_state <= WAIT_FOR_N_RXF_LOW; // read next byte from host
			else 					 next_state <= WAIT_FOR_N_TXE_LOW; // output byte to host
		end
		
		// ============================ BYTE OUTPUT (SHIFT OUT 8 BITS)
		BYTES_GET_TDO_SET_TDI: next_state <= BYTES_CLOCK_HIGH_AND_SHIFT;
		
		BYTES_CLOCK_HIGH_AND_SHIFT: next_state <= BYTES_KEEP_CLOCK_HIGH;
		
		BYTES_KEEP_CLOCK_HIGH: next_state <= BYTES_CLOCK_FINISH;
		
		BYTES_CLOCK_FINISH: begin
			if(bitcount[2:0] != 3'b111) begin
				next_state <= BYTES_GET_TDO_SET_TDI; //clock next bit
			end else if(do_output == 1'b1) begin
				next_state <= WAIT_FOR_N_TXE_LOW; // output byte to host
			end else begin
				next_state <= WAIT_FOR_N_RXF_LOW; // read next byte from host
			end
		end
		
		// ============================ OUTPUT BYTE TO HOST
		WAIT_FOR_N_TXE_LOW: next_state <= nTXE ? WAIT_FOR_N_TXE_LOW : SET_WR_HIGH;
		
		SET_WR_HIGH: next_state <= OUTPUT_ENABLE;
		
		OUTPUT_ENABLE: next_state <= SET_WR_LOW;
		
		SET_WR_LOW: next_state <= OUTPUT_DISABLE;
		
		OUTPUT_DISABLE: next_state <= WAIT_FOR_N_RXF_LOW; // read next byte from host
		
	endcase
end


// state handler
always_ff @(posedge CLK, negedge nRST) begin
	if(~nRST) begin
		nRD <= 1'b1;
		ioshifter <= '0;
		WR <= 1'b0;
		D <= 8'bZZZZZZZZ;
		
		B_TCK <= 1'b0;
		B_TMS <= 1'b0;
		B_NCE <= 1'b0;
		B_NCS <= 1'b0;
		B_TDI <= 1'b0;
		B_OE  <= 1'b0;
		
		bitcount <= '0;
		
		do_output <= 1'b0;
		carry_in <= 1'b0;
	end else begin
		if ((state == SET_N_RD_LOW) | (state == KEEP_N_RD_LOW) | (state == LATCH_DATA_FROM_HOST)) begin
			nRD <= 1'b0;
		end else begin
			nRD <= 1'b1;
		end
		
		if (state == LATCH_DATA_FROM_HOST) begin
			ioshifter[7:0] <= D;
		end
		
		if((state == SET_WR_HIGH) | (state == OUTPUT_ENABLE)) begin
			WR <= 1'b1;
		end else begin
			WR <= 1'b0;
		end
		
		if ((state == OUTPUT_ENABLE) | (state == SET_WR_LOW)) begin
			D <= ioshifter[7:0];
		end else begin
			D <= 8'bZZZZZZZZ;
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

endmodule
