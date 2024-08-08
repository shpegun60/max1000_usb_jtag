module blaster_handler #(parameter CLKS_PER_BIT = 25, parameter logic [7:0] JTAG_SPEED_CNT = 8'd2)
(
	input  i_reset_n,     // RESET global signal
	input  i_clk, // Primary FPGA CLOCK
	
	// uart
	input  i_rx,
	output o_tx,
	
	// jtag to devices
	output logic o_tck,
	output logic o_tdi,
	output logic o_tms,
	input  i_tdo,
	
	output logic o_led
);


localparam logic [7:0] BYTE_LENGTH = 8'd8;

//*******************************************
// blaster TX
//*******************************************

logic       tx_start = 1'b0;
logic [7:0] tx_byte;
logic       tx_done;

logic       tx_start_elong;
blaster_univibrator #(.BIT_WIDTH(3)) blaster_nivibrator_inst ( .i_clk(i_clk), .i_strobe(tx_start), .i_data_pulse(3'd4), .o_out(tx_start_elong));

blaster_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) blaster_tx_inst
(
	.i_clk(i_clk),
	.reset(i_reset_n),
	.i_start(tx_start_elong),
	.i_in(tx_byte),
	.o_tx_pin(o_tx),
	.o_done(tx_done)//,
	//output logic aux
);

logic tx_ready;
dffe dffe_tx_done(.d(1'b1), .clk(i_clk), .clrn(~tx_start_elong), .prn(i_reset_n), .ena(tx_done), .q(tx_ready));

// fifo tx --------------------

logic	[7:0]  fifo_tx_data = '0;
logic	  fifo_tx_rdreq = 1'b0;
logic	  fifo_tx_wrreq = 1'b0;
logic	  fifo_tx_empty;
logic	  fifo_tx_full;

blaster_fifo blaster_fifo_tx_inst
(
	.aclr(~i_reset_n),
	.clock(~i_clk),
	.data(fifo_tx_data),
	.rdreq(fifo_tx_rdreq),
	.wrreq(fifo_tx_wrreq),
	.empty(fifo_tx_empty),
	.full(fifo_tx_full),
	.q(tx_byte)
);


//*******************************************
// blaster RX
//*******************************************

logic rx_valid;
logic [7:0] rx_byte;

blaster_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) blaster_rx_inst
(
	.i_Clock(i_clk),		// clock
	.reset(i_reset_n),			// reset
	.i_rx(i_rx),			// rx pin

	.o_rdy(rx_valid),			// receive compleate
	.o_Rx_Byte(rx_byte)//,		// RX byte
	//output logic o_aux				// strobe receive
);

// fifo rx --------------------

logic  		 fifo_rx_rdreq = 1'b0;
logic		  	 fifo_rx_empty;
logic [7:0]  fifo_rx_q;

blaster_fifo blaster_fifo_rx_inst
(
	.aclr(~i_reset_n),
	.clock(~i_clk),
	.data(rx_byte),
	.rdreq(fifo_rx_rdreq),
	.wrreq(rx_valid),
	.empty(fifo_rx_empty),
	//.full,
	.q(fifo_rx_q)
);



/////////////////////////////////////////////////////////////////////////////////////
//***************************************
// buddiness logic
//***************************************

logic shift_en_comb;
logic read_en_comb;
assign shift_en_comb = fifo_rx_q[7];
assign read_en_comb  = fifo_rx_q[6];

logic shift_en_reg = 1'b0;
logic read_en_reg = 1'b0;


logic [5:0] byte_cnt = '0;
logic [3:0] shift_cnt = '0;
logic [7:0] r_clk_counter = '0;

logic end_shift_mode;
assign end_shift_mode = (byte_cnt == 6'd0);


// rx proceed fsm
(* syn_encoding = "one-hot" *) enum logic[7:0] {
	IDLE 				= 8'b00000001,
	READ_FLAGS 		= 8'b00000010,
	BIT_BANG			= 8'b00000100,
	FIFO_WRITE		= 8'b00001000,
	FIFO_READ		= 8'b00010000,
	LATCH				= 8'b00100000,
	SHIFT_L			= 8'b01000000,
	SHIFT_H			= 8'b10000000
	
} current_blaster_state = IDLE, next_blaster_state;


// Sequential state transition
always_ff @(posedge i_clk, negedge i_reset_n) begin
	if(~i_reset_n) current_blaster_state <= IDLE;
	else 				current_blaster_state <= next_blaster_state;
end

// Combinational next state logic
always_comb begin
	next_blaster_state <= IDLE;
	
	unique case (current_blaster_state)
		
		IDLE: 			next_blaster_state <= fifo_rx_rdreq ? READ_FLAGS : IDLE;
		READ_FLAGS: 	next_blaster_state <= shift_en_comb ? FIFO_READ  : BIT_BANG;
		
		BIT_BANG: 		next_blaster_state <= read_en_reg ? FIFO_WRITE : IDLE;
		FIFO_WRITE:		next_blaster_state <= fifo_tx_wrreq ? (shift_en_reg ? (end_shift_mode ? IDLE : FIFO_READ) : IDLE) : FIFO_WRITE;
		
		FIFO_READ:		next_blaster_state <= fifo_rx_rdreq ? LATCH 		: FIFO_READ;
		LATCH: 			next_blaster_state <= SHIFT_L;
		
		SHIFT_L: 		next_blaster_state <= o_tck ? SHIFT_H : SHIFT_L;
		SHIFT_H: begin
			if(o_tck) begin
				next_blaster_state <= SHIFT_H;
			end else begin
				
				if(shift_cnt == BYTE_LENGTH) begin
					
					if(read_en_reg) begin
						next_blaster_state <= FIFO_WRITE;
					end else begin
						if(end_shift_mode) begin
							next_blaster_state <= IDLE;
						end else begin
							next_blaster_state <= FIFO_READ;
						end
					end					
				end else begin
					next_blaster_state <= SHIFT_L;
				end
				
			end
		end
		
	endcase
end

// state handler
always_ff @(posedge i_clk, negedge i_reset_n) begin
	if(~i_reset_n) begin
		byte_cnt <= '0;
		shift_en_reg <= 1'b0;
		read_en_reg <= 1'b0;
		
		o_tck <= 1'b0;
		o_tdi <= 1'b0;
		o_tms <= 1'b0;
		o_led <= 1'b0;
		
		fifo_tx_data <= '0;
		r_clk_counter <= '0;
		
		shift_cnt <= '0;
	end else begin
		
		unique case(next_blaster_state)
			
			IDLE: begin
				r_clk_counter <= '0;
			end
			
			READ_FLAGS: begin
				shift_en_reg <= shift_en_comb;
				read_en_reg  <= read_en_comb;
				
				if(shift_en_comb) begin
					byte_cnt <= fifo_rx_q[5:0];
				end
			end
			
			// bit-bang mode (default) ----------------------------------------
			BIT_BANG: begin
				o_tck <= fifo_rx_q[0]; // 0x01 mask
				o_tms <= fifo_rx_q[1]; // 0x02 mask
				o_tdi <= fifo_rx_q[4]; // 0x10 mask
				o_led <= fifo_rx_q[5]; // 0x20 mask
				
				fifo_tx_data <= {7'b000_0000, i_tdo}; // tdo ==> 0x00 mask
			end
			
			// shift mode ---------------------------------------------------
			LATCH: begin
				byte_cnt <= byte_cnt - 1'b1;
				shift_cnt <= '0;
				o_tck <= 1'b0;
			end
			
			SHIFT_L: begin
				o_tck <= 1'b0;
				
				r_clk_counter <= r_clk_counter + 1'b1;
				
				if(r_clk_counter == JTAG_SPEED_CNT) begin
					o_tdi <= fifo_rx_q[shift_cnt];
					fifo_tx_data <= {i_tdo, fifo_tx_data[7:1]};
					o_tck <= 1'b1;
					
					r_clk_counter <= '0;
				end
				
				//TDI_OUT(dshift); din = DATAOUT_IN(); TCK_1();
			end
			
			SHIFT_H: begin
				o_tck <= 1'b1;
				
				r_clk_counter <= r_clk_counter + 1'b1;
				
				if(r_clk_counter == JTAG_SPEED_CNT) begin
					shift_cnt <= shift_cnt + 1'b1;
					o_tck <= 1'b0;
					r_clk_counter <= '0;
				end
				
				//dshift = (dshift >> 1) | (din << 7); TCK_0()
			end
			
		endcase
		
	end
end

//***********************************************
// fifo proceed
//***********************************************


// tx write req------------------------------------
always_ff @(posedge i_clk, negedge i_reset_n) begin
	if(~i_reset_n) begin
		fifo_tx_wrreq <= 1'b0;
	end else begin
		fifo_tx_wrreq <= 1'b0;
		
		if(~fifo_tx_full & (next_blaster_state == FIFO_WRITE)) begin
			fifo_tx_wrreq <= 1'b1;
		end
	end
end


// rx read req------------------------------------
always_ff @(posedge i_clk, negedge i_reset_n) begin
	if(~i_reset_n) begin
		fifo_rx_rdreq <= 1'b0;
	end else begin
		fifo_rx_rdreq <= 1'b0;
		
		if(~fifo_rx_empty & (next_blaster_state == IDLE) & (next_blaster_state == FIFO_READ)) begin
			fifo_rx_rdreq <= 1'b1;
		end
	end
end

// send fifo tx data -----------------------------

always_ff @(posedge i_clk, negedge i_reset_n) begin
	if(~i_reset_n) begin
		fifo_tx_rdreq <= 1'b0;
		tx_start <= 1'b0;
	end else begin
		fifo_tx_rdreq <= 1'b0;
		
		if(~fifo_tx_empty & tx_ready) begin
			fifo_tx_rdreq <= 1'b1;
		end
		
		tx_start <= fifo_tx_rdreq;
	end
end



endmodule
