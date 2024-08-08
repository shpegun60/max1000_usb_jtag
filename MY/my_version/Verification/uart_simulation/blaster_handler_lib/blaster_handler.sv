module blaster_handler #(parameter CLKS_PER_BIT = 25)
(
	input  i_reset_n,     // RESET global signal
	input  i_clk, // Primary FPGA CLOCK
	
	// uart
	input  i_rx,
	output o_tx,
	
	// JTAG mode
	output logic o_tck,
	output logic o_tdi,
	output logic o_tms,
	input  i_tdo,
	
	// Active Serial mode
	input  		 i_ASDO,
	output logic o_NCE,
	output logic o_NCS,
	
	output logic o_led
);

//*******************************************
// blaster TX
//*******************************************

logic       tx_start = 1'b0;
logic [7:0] tx_byte;
logic       tx_done;

logic       tx_start_elong;
blaster_univibrator #(.BIT_WIDTH(3)) blaster_nivibrator_inst ( .i_clk(i_clk), .i_rst_n(i_reset_n), .i_strobe(tx_start), .i_data_pulse(3'd3), .o_out(tx_start_elong));

blaster_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) blaster_tx_inst
(
	.i_clk(i_clk),
	.reset(i_reset_n),
	.i_start(tx_start_elong),
	.i_in(tx_byte),
	.o_tx_pin(o_tx),
	.o_done(tx_done),
	.aux()
);

logic tx_ready;
dffe dffe_tx_done(.d(1'b1), .clk(i_clk), .clrn(~tx_start_elong), .prn(i_reset_n), .ena(tx_done), .q(tx_ready));

// fifo tx --------------------

logic	[7:0]  fifo_tx_data;
logic	  fifo_tx_rdreq = 1'b0;
logic	  fifo_tx_wrreq;
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
	.o_Rx_Byte(rx_byte),		// RX byte
	.o_aux()				// strobe receive
);

// fifo rx --------------------

logic  		 fifo_rx_rdreq;
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
	.full(),
	.q(fifo_rx_q)
);



/////////////////////////////////////////////////////////////////////////////////////
//***************************************
// buddiness logic
//***************************************

jtag_logic jtag_logic_ibst
(
	.CLK(i_clk),
	.nRST(i_reset_n),
	
	// JTAG mode
	.B_TDO(i_tdo),
	.B_TCK(o_tck),
	.B_TMS(o_tms),
	.B_TDI(o_tdi),
	
	// Active Serial mode
	.B_ASDO(i_ASDO),
	.B_NCE(o_NCE),
	.B_NCS(o_NCS),
	
	// led
	.B_OE(o_led),
	
	// fifo data
	.RX_RD_REQ(fifo_rx_rdreq),
	.RX_EMPTY(fifo_rx_empty),
	.D_IN(fifo_rx_q),
	
	.TX_FULL(fifo_tx_full),
	.TX_WR_REQ(fifo_tx_wrreq),
	.D_OUT(fifo_tx_data)
);

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
