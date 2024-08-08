

`timescale 1ns / 100ps


interface signals_intf (input logic clk100Mhz, clk_100_delay, hardwareReset); // Define the interface
	logic tx_pin;
	logic tx_done;
	
	logic [7:0] Rx_Byte;
	logic rx_ready;
	logic rx_valid;
	
	// jtag wires
	logic o_tck;
	logic o_tdi;
	logic o_tms;
	logic  i_tdo;
	
	logic o_led;
	
endinterface: signals_intf
	
module top_sim();

	//***************************************************************************************************************************
	// 								RESET/ CLK INIT
	//***************************************************************************************************************************
	
	parameter shortint delay	 = 5;
	parameter shortint delay_clk = 3;
	parameter shortint T = 20;                  // This is a number of clocking periods
    parameter shortint rst_delay = T * delay;  // this is a reset delay which equal T clocks
	
	logic clk = 0;   // CLOCK for the project
	logic clk_delayed;   // CLOCK for the project
    logic reset = 1; // RESET for the project
	
	initial forever clk = #(delay) ~clk; // This is clocking frequency
	assign #delay_clk clk_delayed = clk;
    default clocking cb_clk100Mhz @(posedge clk); endclocking
	
	task rst_genegate (shortint rst_length); // RESET task
		reset = 0;
		#rst_length;
		@(posedge clk);
		reset = 1;
	endtask
	
	initial begin: rst_gen
		reset_reg();
		#delay rst_genegate(rst_delay);
    end: rst_gen  // RESET generating
	
	//**************************************************************************************************************************
	//               end
	//***************************************************************************************************************************
	
	signals_intf corr_intf(clk, clk_delayed, reset);
	
	logic [7:0] tx_byte;
	logic [7:0] counter;
	logic tx_start;
	
	task reset_reg;
		tx_byte <= '0;
		tx_start <= 1'b0;
		counter <= '0;
	endtask
	
	
	localparam CLKS_PER_BIT = 2;
	
	logic tx_from_blaster;
	uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) UART_TX_INST
	(
		.i_clk(corr_intf.clk100Mhz),
		.reset(corr_intf.hardwareReset),
		.i_start(tx_start),
		.i_in(tx_byte),
		.o_tx_pin(corr_intf.tx_pin),
		.o_done(corr_intf.tx_done)
	);
	
	blaster_handler #(.CLKS_PER_BIT(CLKS_PER_BIT), .JTAG_SPEED_CNT(8'd2)) BLASTER_INST
	(
		.i_reset_n(corr_intf.hardwareReset),     // RESET global signal
		.i_clk(corr_intf.clk100Mhz), // Primary FPGA CLOCK
		
		// uart
		.i_rx(corr_intf.tx_pin),
		.o_tx(tx_from_blaster),
		
		// jtag to devices
		.o_tck(corr_intf.o_tck),
		.o_tdi(corr_intf.o_tdi),
		.o_tms(corr_intf.o_tms),
		.i_tdo(corr_intf.i_tdo),
		
		.o_led(corr_intf.o_led)
	);
	
	uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) UART_RX_INST
	(
		.i_Clock(corr_intf.clk100Mhz),		// clock
		.reset(corr_intf.hardwareReset),			// reset
		.i_rx(tx_from_blaster),			// rx pin

		.o_rdy(corr_intf.rx_valid),			// receive compleate
		.o_Rx_Byte(corr_intf.Rx_Byte),		// RX byte
		.o_aux(corr_intf.rx_ready)				// strobe receive
	);
	
	always_ff @(posedge corr_intf.clk100Mhz, negedge corr_intf.hardwareReset) begin
		if(!corr_intf.hardwareReset) begin
			tx_byte <= 8'hC0;
			tx_start <= 1'b0;
			counter <= '0;
			corr_intf.i_tdo <= 1'b1;
		end else begin
			tx_start <= 1'b0;
			counter <= counter + 1'b1;
			if(counter > 8'd30) begin
				tx_byte <= (tx_byte < 8'hC2) ? tx_byte + 1'b1 : '0;
				
				corr_intf.i_tdo <= ~corr_intf.i_tdo;
				
				tx_start <= 1'b1;
				counter <= '0;
			end
		end
	end

endmodule
