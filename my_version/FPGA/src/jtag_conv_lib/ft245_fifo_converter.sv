module ft245_fifo_converter
(
	input logic  CLK,				// external 24/25 MHz oscillator
	input logic  nRST_ASYNC,		// async reset
	
	// external FT245BM interface 
	input logic  nRXF,			 // FT245BM nRXF
	input logic  nTXE,			 // FT245BM nTXE
	output logic nRD,			// FT245BM nRD
	output logic WR,			// FT245BM WR
	inout [7:0] D,				// FT245BM D[7..0]
	
	// internal rx interface
	input RXF,
	output logic RX_WR_REQ,
	output logic [7:0] RX_DATA,
	
	// internal tx interface
	input TXE,
	output logic TX_RD_REQ,
	input logic [7:0] TX_DATA
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
	// rx --------------------------------------------------------
	CHECK_RX								= 4'd0,
	SET_N_RD_LOW							= 4'd1,
	KEEP_N_RD_LOW							= 4'd2,
	LATCH_DATA_FROM_HOST					= 4'd3,
	SET_N_RD_HIGH							= 4'd4,
	// tx --------------------------------------------------------
	CHECK_TX								= 4'd5,
	WAIT_FOR_N_TXE_LOW						= 4'd6,
	RD_REQ									= 4'd7,
	SET_WR_HIGH								= 4'd8,
	OUTPUT_ENABLE							= 4'd9,
	SET_WR_LOW								= 4'd10,
	OUTPUT_DISABLE 							= 4'd11
} state = CHECK_RX, next_state = CHECK_RX;


// Sequential state transition
always_ff @(posedge CLK, negedge protected_reset_n) begin
	if(~protected_reset_n)  state <= CHECK_RX;
	else 					state <= next_state;
end


// Combinational next state logic
always_comb begin
	
	next_state <= CHECK_RX;
	
	unique case(state)
		
		// ============================ INPUT
		CHECK_RX: 					next_state <= (protect_reg[2] | RXF) ? CHECK_TX : SET_N_RD_LOW;// (protect_reg[3]) ? CHECK_RX : SET_N_RD_LOW;
		SET_N_RD_LOW:				next_state <= KEEP_N_RD_LOW;
		KEEP_N_RD_LOW: 			next_state <= LATCH_DATA_FROM_HOST;
		LATCH_DATA_FROM_HOST: 	next_state <= SET_N_RD_HIGH;
		SET_N_RD_HIGH: 			next_state <= CHECK_TX;
		
		CHECK_TX: 					next_state <= TXE ? CHECK_RX : WAIT_FOR_N_TXE_LOW;
		
		// ============================ OUTPUT BYTE TO HOST
		WAIT_FOR_N_TXE_LOW: 	next_state <= /*nTXE*/protect_reg_txe[2] ? WAIT_FOR_N_TXE_LOW : RD_REQ;
		RD_REQ: 					next_state <= SET_WR_HIGH;
		SET_WR_HIGH: 			next_state <= OUTPUT_ENABLE;
		OUTPUT_ENABLE: 		next_state <= SET_WR_LOW;
		SET_WR_LOW: 			next_state <= OUTPUT_DISABLE;
		OUTPUT_DISABLE: 		next_state <= CHECK_RX;
	endcase
end

// state handler
always_ff @(posedge CLK, negedge protected_reset_n) begin
	if(~protected_reset_n) begin
		nRD <= 1'b1;
		WR  <= 1'b0;
		
		RX_WR_REQ 	<= 1'b0;
		RX_DATA 	<= '0;
		
		TX_RD_REQ <= 1'b0;
		
		//D <= 8'bZZZZZZZZ;
		
	end else begin
		
		RX_WR_REQ <= 1'b0;
		TX_RD_REQ <= 1'b0;
		
		// read section ------------------------------------------------------------------------------------------------
		if ((state == SET_N_RD_LOW) | (state == KEEP_N_RD_LOW) | (state == LATCH_DATA_FROM_HOST)) begin
			nRD <= 1'b0;
		end else begin
			nRD <= 1'b1;
		end
		
		if (state == LATCH_DATA_FROM_HOST) begin
			RX_DATA <= D;
			RX_WR_REQ <= 1'b1;
		end
		
		// write section -----------------------------------------------------------------------------------------------
		if(next_state == RD_REQ) begin
			TX_RD_REQ <= 1'b1;
		end
		
		if((state == SET_WR_HIGH) | (state == OUTPUT_ENABLE)) begin
			WR <= 1'b1;
		end else begin
			WR <= 1'b0;
		end
		
//		if ((state == OUTPUT_ENABLE) | (state == SET_WR_LOW)) begin
//			D <= TX_DATA;
//		end else begin
//			D <= 8'bZZZZZZZZ;
//		end
	end
end

assign D = WR ? TX_DATA : 8'bZZZZZZZZ;


endmodule
