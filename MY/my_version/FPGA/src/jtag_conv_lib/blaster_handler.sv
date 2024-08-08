module blaster_handler
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

logic RESET_JTAG;
logic IDLE_LED;

jtag_reset_n_asserter reset_jtag_inst
(
	.CLK(CLK),				// external 24/25 MHz oscillator
	.nRST_ASYNC(nRST_ASYNC),		// async reset
	.IDLE_LED(IDLE_LED),
	
	.RESET_JTAG(RESET_JTAG)
);

logic internal_reset;
assign internal_reset = nRST_ASYNC & RESET_JTAG;

//*******************************************
// blaster TX
//*******************************************

// write
logic	[7:0]  fifo_tx_data;
logic	  fifo_tx_wrreq;
logic	  fifo_tx_full;

//read
logic	  fifo_tx_rdreq;
logic	  fifo_tx_empty;
logic	[7:0]  fifo_tx_q;

blaster_fifo blaster_fifo_tx_inst
(
	.aclr(~internal_reset),
	.clock(~CLK),
	.data(fifo_tx_data),
	.rdreq(fifo_tx_rdreq),
	.wrreq(fifo_tx_wrreq),
	.empty(fifo_tx_empty),
	.full(fifo_tx_full),
	//.almost_full(fifo_tx_full),
	.q(fifo_tx_q)
);

//*******************************************
// blaster RX
//*******************************************

// read
logic  		 fifo_rx_rdreq;
logic		 fifo_rx_empty;
logic [7:0]  fifo_rx_q;

// write
logic [7:0]  fifo_rx_data;
logic  		 fifo_rx_wrreq;
logic		 fifo_rx_full;

blaster_fifo blaster_fifo_rx_inst
(
	.aclr(~internal_reset),
	.clock(~CLK),
	.data(fifo_rx_data),
	.rdreq(fifo_rx_rdreq),
	.wrreq(fifo_rx_wrreq),
	.empty(fifo_rx_empty),
	.full(fifo_rx_full),
	//.almost_full(fifo_rx_full),
	.q(fifo_rx_q)
);

/////////////////////////////////////////////////////////////////////////////////////
//***************************************
// buddiness logic
//***************************************

ft245_fifo_converter ft245_driver
(
	.CLK(~CLK),				// external 24/25 MHz oscillator
	.nRST_ASYNC(internal_reset),		// async reset
	
	// external FT245BM interface 
	.nRXF(nRXF),			 // FT245BM nRXF
	.nTXE(nTXE),			 // FT245BM nTXE
	.nRD(nRD),			// FT245BM nRD
	.WR(WR),			// FT245BM WR
	.D(D),				// FT245BM D[7..0]
	
	// internal rx interface
	.RXF(fifo_rx_full),
	.RX_WR_REQ(fifo_rx_wrreq),
	.RX_DATA(fifo_rx_data),
	
	// internal tx interface
	.TXE(fifo_tx_empty),
	.TX_RD_REQ(fifo_tx_rdreq),
	.TX_DATA(fifo_tx_q)
);

jtag_fifo_logic blaster_driver
(
	.CLK(CLK),				// external 24/25 MHz oscillator
	.nRST_ASYNC(internal_reset),		// async reset
	
	// JTAG mode
	.B_TCK(B_TCK),				// JTAG output: TCK to chain, AS/PS DCLK
	.B_TDI(B_TDI),				// JTAG output: TDI to chain, AS: ASDI, PS: DATA0
	.B_TDO(B_TDO),				 // JTAG input: TDO, AS/PS input: CONF_DONE
	.B_TMS(B_TMS),				// JTAG output: TMS to chain, AS/PS nCONFIG
	
	// Active serial mode
	.B_ASDO(B_ASDO),			 // AS input: DATAOUT, PS input: nSTATUS
	.B_NCE(B_NCE),				// AS output: nCE
	.B_NCS(B_NCS),				// AS output: nCS
	
	// internal rx interface
	.RXE(fifo_rx_empty),
	.RX_RD_REQ(fifo_rx_rdreq),
	.RX_DATA(fifo_rx_q),
	
	// internal tx interface
	.TXF(fifo_tx_full),
	.TX_WR_REQ(fifo_tx_wrreq),
	.TX_DATA(fifo_tx_data),
	
	// leds
	.B_OE(B_OE),			 // LED output/output driver enable 
	.BUSY_LED(BUSY_LED),		// LED output/output busy
	.IDLE_LED(IDLE_LED)
);






endmodule
