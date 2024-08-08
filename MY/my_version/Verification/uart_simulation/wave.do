onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /top_sim/UART_RX_INST/i_Clock
add wave -noupdate /top_sim/UART_RX_INST/reset
add wave -noupdate /top_sim/UART_RX_INST/i_rx
add wave -noupdate /top_sim/UART_RX_INST/o_rdy
add wave -noupdate /top_sim/UART_RX_INST/o_Rx_Byte
add wave -noupdate /top_sim/UART_RX_INST/o_aux
add wave -noupdate /top_sim/UART_RX_INST/r_Rx_Data_R
add wave -noupdate /top_sim/UART_RX_INST/r_Rx_Data
add wave -noupdate /top_sim/UART_RX_INST/r_Clock_Count
add wave -noupdate /top_sim/UART_RX_INST/r_Bit_Index
add wave -noupdate /top_sim/UART_RX_INST/r_Rx_Byte
add wave -noupdate /top_sim/UART_RX_INST/r_rdy
add wave -noupdate /top_sim/UART_RX_INST/r_state
add wave -noupdate /top_sim/BLASTER_INST/i_reset_n
add wave -noupdate /top_sim/BLASTER_INST/i_clk
add wave -noupdate /top_sim/BLASTER_INST/i_rx
add wave -noupdate /top_sim/BLASTER_INST/o_tx
add wave -noupdate /top_sim/BLASTER_INST/o_tck
add wave -noupdate /top_sim/BLASTER_INST/o_tdi
add wave -noupdate /top_sim/BLASTER_INST/o_tms
add wave -noupdate /top_sim/BLASTER_INST/i_tdo
add wave -noupdate /top_sim/BLASTER_INST/o_led
add wave -noupdate /top_sim/BLASTER_INST/tx_start
add wave -noupdate /top_sim/BLASTER_INST/tx_byte
add wave -noupdate /top_sim/BLASTER_INST/tx_done
add wave -noupdate /top_sim/BLASTER_INST/tx_start_elong
add wave -noupdate /top_sim/BLASTER_INST/tx_ready
add wave -noupdate /top_sim/BLASTER_INST/fifo_tx_data
add wave -noupdate /top_sim/BLASTER_INST/fifo_tx_rdreq
add wave -noupdate /top_sim/BLASTER_INST/fifo_tx_wrreq
add wave -noupdate /top_sim/BLASTER_INST/fifo_tx_empty
add wave -noupdate /top_sim/BLASTER_INST/fifo_tx_full
add wave -noupdate /top_sim/BLASTER_INST/rx_valid
add wave -noupdate /top_sim/BLASTER_INST/rx_byte
add wave -noupdate /top_sim/BLASTER_INST/fifo_rx_rdreq
add wave -noupdate /top_sim/BLASTER_INST/fifo_rx_empty
add wave -noupdate /top_sim/BLASTER_INST/fifo_rx_q
add wave -noupdate /top_sim/BLASTER_INST/shift_en_comb
add wave -noupdate /top_sim/BLASTER_INST/read_en_comb
add wave -noupdate /top_sim/BLASTER_INST/shift_en_reg
add wave -noupdate /top_sim/BLASTER_INST/read_en_reg
add wave -noupdate /top_sim/BLASTER_INST/byte_cnt
add wave -noupdate /top_sim/BLASTER_INST/shift_cnt
add wave -noupdate /top_sim/BLASTER_INST/r_clk_counter
add wave -noupdate /top_sim/BLASTER_INST/end_shift_mode
add wave -noupdate /top_sim/BLASTER_INST/current_blaster_state
add wave -noupdate /top_sim/BLASTER_INST/next_blaster_state
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {95437492 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 262
configure wave -valuecolwidth 58
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {94458120 ps} {95846730 ps}
