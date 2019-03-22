onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider DUT
add wave -noupdate /tb_sc_fifo/dut/clk_i
add wave -noupdate /tb_sc_fifo/dut/rst_i
add wave -noupdate /tb_sc_fifo/dut/wr_i
add wave -noupdate -radix hexadecimal /tb_sc_fifo/dut/wr_data_i
add wave -noupdate /tb_sc_fifo/dut/rd_i
add wave -noupdate -radix hexadecimal /tb_sc_fifo/dut/rd_data_o
add wave -noupdate -radix unsigned /tb_sc_fifo/dut/used_words_o
add wave -noupdate -radix unsigned /tb_sc_fifo/dut/full_o
add wave -noupdate -radix unsigned /tb_sc_fifo/dut/empty_o
add wave -noupdate -radix hexadecimal /tb_sc_fifo/dut/wr_addr
add wave -noupdate /tb_sc_fifo/dut/wr_req
add wave -noupdate -radix unsigned /tb_sc_fifo/dut/full
add wave -noupdate -radix hexadecimal /tb_sc_fifo/dut/rd_addr
add wave -noupdate /tb_sc_fifo/dut/rd_req
add wave -noupdate -radix unsigned /tb_sc_fifo/dut/empty
add wave -noupdate -radix unsigned /tb_sc_fifo/dut/used_words
add wave -noupdate /tb_sc_fifo/dut/data_in_mem
add wave -noupdate /tb_sc_fifo/dut/data_at_output
add wave -noupdate -divider RAM
add wave -noupdate /tb_sc_fifo/dut/ram/rst_i
add wave -noupdate /tb_sc_fifo/dut/ram/wr_clk_i
add wave -noupdate -radix hexadecimal /tb_sc_fifo/dut/ram/wr_addr_i
add wave -noupdate -radix hexadecimal /tb_sc_fifo/dut/ram/wr_data_i
add wave -noupdate /tb_sc_fifo/dut/ram/wr_i
add wave -noupdate /tb_sc_fifo/dut/ram/rd_clk_i
add wave -noupdate -radix hexadecimal /tb_sc_fifo/dut/ram/rd_addr_i
add wave -noupdate -radix hexadecimal /tb_sc_fifo/dut/ram/rd_data_o
add wave -noupdate /tb_sc_fifo/dut/ram/rd_i
add wave -noupdate -radix hexadecimal /tb_sc_fifo/dut/ram/rd_data
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {35706 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 263
configure wave -valuecolwidth 100
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
WaveRestoreZoom {0 ps} {204750 ps}
