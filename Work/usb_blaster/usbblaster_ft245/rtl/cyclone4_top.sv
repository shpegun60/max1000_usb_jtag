module jtag_logic
(
	input  CLK,
	input  nRXF,
	input  nTXE,
	input  B_TDO,
	input  B_ASDO,
	output logic B_TCK,
	output logic B_TMS,
	output logic B_NCE,
	output logic B_NCS,
	output logic B_TDI,
	output logic B_OE,
	output logic nRD,
	output logic WR,
	
	inout [7:0] D
);

enum logic [3:0] {
	wait_for_nRXF_low					= 4'b0000,
	set_nRD_low							= 4'b0001,
	keep_nRD_low						= 4'b0010,
	latch_data_from_host				= 4'b0011,
	set_nRD_high						= 4'b0100,
	bits_set_pins_from_data				= 4'b0101,
	bytes_set_bitcount					= 4'b0110,
	bytes_get_tdo_set_tdi				= 4'b0111,
	bytes_clock_high_and_shift			= 4'b1000,
	bytes_keep_clock_high				= 4'b1001,
	bytes_clock_finish					= 4'b1010,
	wait_for_nTXE_low					= 4'b1011,
	set_WR_high							= 4'b1100,
	output_enable						= 4'b1101,
	set_WR_low							= 4'b1110,
	output_disable 						= 4'b1111
} state = wait_for_nRXF_low, next_state;

logic carry;
logic do_output;
logic [7:0] ioshifter;
logic [8:0] bitcount;

always_comb begin
	
	next_state <= wait_for_nRXF_low;
	
	unique case(state)
		
		// ============================ INPUT
		wait_for_nRXF_low: next_state <= nRXF ? wait_for_nRXF_low : set_nRD_low;
		
		set_nRD_low: next_state <= keep_nRD_low;
		
		keep_nRD_low: next_state <= latch_data_from_host;
		
		latch_data_from_host: next_state <= set_nRD_high;
		
		set_nRD_high: begin
			if(bitcount[8:3] != 6'b000000) begin
				next_state <= bytes_get_tdo_set_tdi;
			end else if(ioshifter[7] == 1'b1) begin
				next_state <= bytes_set_bitcount;
			end else begin
				next_state <= bits_set_pins_from_data;
			end;
		end
		
		bytes_set_bitcount: next_state <= wait_for_nRXF_low;
		
		// ============================ BIT BANGING
		bits_set_pins_from_data: begin
			if(ioshifter[6] == 1'b0) next_state <= wait_for_nRXF_low; ///-- read next byte from host
			else 					 next_state <= wait_for_nTXE_low; //-- output byte to host
		end
		
		// ============================ BYTE OUTPUT (SHIFT OUT 8 BITS)
		bytes_get_tdo_set_tdi: next_state <= bytes_clock_high_and_shift;
		
		bytes_clock_high_and_shift: next_state <= bytes_keep_clock_high;
		
		bytes_keep_clock_high: next_state <= bytes_clock_finish;
		
		bytes_clock_finish: begin
			if(bitcount[2:0] != 3'b111) begin
				next_state <= bytes_get_tdo_set_tdi; //clock next bit
			end else if(do_output == 1'b1) begin
				next_state <= wait_for_nTXE_low; // output byte to host
			end else begin
				next_state <= wait_for_nRXF_low; // read next byte from host
			end
		end
		
		// ============================ OUTPUT BYTE TO HOST
		wait_for_nTXE_low: next_state <= nTXE ? wait_for_nTXE_low : set_WR_high;
		
		set_WR_high: next_state <= output_enable;
		
		output_enable: next_state <= set_WR_low;
		
		set_WR_low: next_state <= output_disable;
		
		output_disable: next_state <= wait_for_nRXF_low; // read next byte from host
		
	endcase
end

always_ff @(posedge CLK) begin
	if ((state == set_nRD_low) | (state == keep_nRD_low) | (state == latch_data_from_host)) begin
		nRD <= 1'b0;
	end else begin
		nRD <= 1'b1;
	end
	
	if (state == latch_data_from_host) begin
		ioshifter[7:0] <= D;
	end
	
	if((state == set_WR_high) | (state == output_enable)) begin
		WR <= 1'b1;
	end else begin
		WR <= 1'b0;
	end
	
	if ((state == output_enable) | (state == set_WR_low)) begin
		D <= ioshifter[7:0];
	end else begin
		D <= 8'bZZZZZZZZ;
	end
	
	if(state == bits_set_pins_from_data) begin
		B_TCK <= ioshifter[0];
		B_TMS <= ioshifter[1];
		B_NCE <= ioshifter[2];
		B_NCS <= ioshifter[3];
		B_TDI <= ioshifter[4];
		B_OE  <= ioshifter[5];
		ioshifter <= 6'b000000 & B_ASDO & B_TDO;
	end
	
	if(state == bytes_set_bitcount) begin
		bitcount <= ioshifter[5:0] & 3'b111;
		do_output <= ioshifter[6];
	end
	
	if(state == bytes_get_tdo_set_tdi) begin
		if(B_NCS) begin
			carry <= B_TDO; // JTAG mode (nCS=1)
		end else begin
			carry <= B_ASDO; // Active Serial mode (nCS=0)
		end
		B_TDI <= ioshifter[0];
		bitcount <= bitcount - 1'b1;
	end
	
	if((state == bytes_clock_high_and_shift) | (state == bytes_keep_clock_high)) begin
		B_TCK <= 1'b1;
	end
	
	if(state == bytes_clock_high_and_shift) begin
		ioshifter <= carry & ioshifter[7:1];
	end
	
	if(state == bytes_clock_finish) begin
		B_TCK <= 1'b0;
	end

	state <= next_state;
	
end

endmodule
