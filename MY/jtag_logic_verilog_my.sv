module jtag_logic_verilog
(
	input logic  CLK,				// external 24/25 MHz oscillator
	input logic  nRST_ASYNC,		// async reset
	input logic  nRST_SYNC,			// sync reset
	
	// JTAG mode
	output logic B_TCK,				// JTAG output: TCK to chain, AS/PS DCLK
	output logic B_TDI,				// JTAG output: TDI to chain, AS: ASDI, PS: DATA0
	input  logic B_TDO,				 // JTAG input: TDO, AS/PS input: CONF_DONE
	output logic B_TMS,				// JTAG output: TMS to chain, AS/PS nCONFIG
	
	// Active serial mode
	input  logic B_ASDO,			 // AS input: DATAOUT, PS input: nSTATUS
	output logic B_NCE,				// AS output: nCE
	output logic B_NCS,				// AS output: nCS
	
	// external FT245BM interface 
	input logic  nRXF,			 // FT245BM nRXF
	input logic  nTXE,			 // FT245BM nTXE
	output logic nRD,			// FT245BM nRD
	output logic WR,			// FT245BM WR
	inout [7:0] D,				// FT245BM D[7..0]
	
	// leds
	output logic B_OE,			 // LED output/output driver enable 
	output logic BUSY_LED		// LED output/output busy 
);

// METASTABILITY PROTECTION *************************************************************************************

//input logic  nRST_ASYNC
logic [2:0] protect_reset;
logic protected_reset_n;
dff dff_protect_reset1 (.d(1'b1), 					.clk(CLK), .clrn(nRST_ASYNC), .prn(1'b1), .q(protect_reset[0]));
dff dff_protect_reset2 (.d(protect_reset[0]),  	.clk(CLK), .clrn(nRST_ASYNC), .prn(1'b1), .q(protect_reset[1]));
dff dff_protect_reset3 (.d(protect_reset[1]),  	.clk(CLK), .clrn(nRST_ASYNC), .prn(1'b1), .q(protect_reset[2]));

assign protected_reset_n = protect_reset[2];

// input  nRXF
logic [2:0] protect_reg;
dff dff_protect_nRXF1 (.d(nRXF), 				.clk(CLK), .clrn(1'b1), .prn(protected_reset_n), .q(protect_reg[0]));
dff dff_protect_nRXF2 (.d(protect_reg[0]),  	.clk(CLK), .clrn(1'b1), .prn(protected_reset_n), .q(protect_reg[1]));
dff dff_protect_nRXF3 (.d(protect_reg[1]),  	.clk(CLK), .clrn(1'b1), .prn(protected_reset_n), .q(protect_reg[2]));

// input  nTXE
logic [2:0] protect_reg_txe;
dff dff_protect_nTXE1 (.d(nTXE),  						.clk(CLK), .clrn(1'b1), .prn(protected_reset_n), .q(protect_reg_txe[0]));
dff dff_protect_nTXE2 (.d(protect_reg_txe[0]),  	.clk(CLK), .clrn(1'b1), .prn(protected_reset_n), .q(protect_reg_txe[1]));
dff dff_protect_nTXE3 (.d(protect_reg_txe[1]),  	.clk(CLK), .clrn(1'b1), .prn(protected_reset_n), .q(protect_reg_txe[2]));

//***************************************************************************************************************

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
} state = WAIT_FOR_N_RXF_LOW, next_state = WAIT_FOR_N_RXF_LOW;


logic carry_in = 1'b0;
logic do_output = 1'b0;
logic [7:0] ioshifter = '0;
logic [8:0] bitcount = '0;


// Sequential state transition
always_ff @(posedge CLK, negedge protected_reset_n) begin
	if(~protected_reset_n)  state <= WAIT_FOR_N_RXF_LOW;
	else 							state <= next_state;
end


// Combinational next state logic
always_comb begin
	
	next_state <= WAIT_FOR_N_RXF_LOW;
	
	unique case(state)
		
		// ============================ INPUT
		WAIT_FOR_N_RXF_LOW: next_state <= protect_reg[2] ? WAIT_FOR_N_RXF_LOW : SET_N_RD_LOW;
		
		SET_N_RD_LOW: next_state <= KEEP_N_RD_LOW;
		
		KEEP_N_RD_LOW: next_state <= LATCH_DATA_FROM_HOST;
		
		LATCH_DATA_FROM_HOST: next_state <= SET_N_RD_HIGH;
		
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
			else 					 next_state <= WAIT_FOR_N_TXE_LOW; // output byte to host
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
		WAIT_FOR_N_TXE_LOW: next_state <= protect_reg_txe[2] ? WAIT_FOR_N_TXE_LOW : SET_WR_HIGH;
		
		SET_WR_HIGH: next_state <= OUTPUT_ENABLE;
		
		OUTPUT_ENABLE: next_state <= SET_WR_LOW;
		
		SET_WR_LOW: next_state <= OUTPUT_DISABLE;
		
		OUTPUT_DISABLE: next_state <= WAIT_FOR_N_RXF_LOW; // read next byte from host
		
	endcase
end

// state handler
always_ff @(posedge CLK, negedge protected_reset_n) begin
	if(~protected_reset_n) begin
		// jtag
		B_TCK <= 1'b0;
		B_TDI <= 1'b0;
		B_TMS <= 1'b0;
		
		// Active serial
		B_NCE <= 1'b1;
		B_NCS <= 1'b1;
		
		//external FT245BM
		nRD 	<= 1'b1;
		WR  	<= 1'b0;
		//D <= 8'bZZZZZZZZ;
		
		// led
		B_OE 	<= 1'b0;
		
		// internal registers
		carry_in 	<= 1'b0;
		do_output 	<= 1'b0;
		ioshifter 	<= '0;
		bitcount 	<= '0;
	end else begin
		
		if ((state == SET_N_RD_LOW) | (state == KEEP_N_RD_LOW) | (state == LATCH_DATA_FROM_HOST)) begin
			nRD <= 1'b0;
		end else begin
			nRD <= 1'b1;
		end
		
		if (state == LATCH_DATA_FROM_HOST) begin
			ioshifter <= D;
		end
		
		if((state == SET_WR_HIGH) | (state == OUTPUT_ENABLE)) begin
			WR <= 1'b1;
		end else begin
			WR <= 1'b0;
		end
		
		//if ((state == OUTPUT_ENABLE) | (state == SET_WR_LOW)) begin
		//	D <= ioshifter;
		//end else begin
		//	D <= 8'bZZZZZZZZ;
		//end
		
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

assign D = WR ? ioshifter : 8'bZZZZZZZZ;

// busy led only for test ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
always_ff @(posedge CLK, negedge protected_reset_n) begin
	if(~protected_reset_n) begin
		BUSY_LED <= 1'b0;
	end else begin
		
		if((state == SET_N_RD_HIGH) | (state == BYTES_SET_BITCOUNT) | (state == BITS_SET_PINS_FROM_DATA) | (state == BYTES_GET_TDO_SET_TDI) | 
			(state == BYTES_CLOCK_HIGH_AND_SHIFT) | (state == BYTES_KEEP_CLOCK_HIGH) | (state == BYTES_CLOCK_FINISH) | (state == WAIT_FOR_N_TXE_LOW) | (state == SET_WR_HIGH) | (state == OUTPUT_ENABLE) | 
			(state == SET_WR_LOW) | (state == OUTPUT_DISABLE)) begin
			
			BUSY_LED <= 1'b0;
		end else begin
			BUSY_LED <= 1'b1;
		end
		
	end
end





endmodule
