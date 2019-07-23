onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix hexadecimal /tb_sc_fifo/dut/clk_i
add wave -noupdate -radix hexadecimal /tb_sc_fifo/dut/rst_i
add wave -noupdate -radix hexadecimal /tb_sc_fifo/dut/wr_i
add wave -noupdate -radix hexadecimal /tb_sc_fifo/dut/wr_data_i
add wave -noupdate -radix hexadecimal /tb_sc_fifo/dut/rd_i
add wave -noupdate -radix hexadecimal /tb_sc_fifo/dut/rd_data_o
add wave -noupdate -radix hexadecimal /tb_sc_fifo/dut/used_words_o
add wave -noupdate -radix hexadecimal /tb_sc_fifo/dut/full_o
add wave -noupdate -radix hexadecimal /tb_sc_fifo/dut/empty_o
add wave -noupdate -radix hexadecimal /tb_sc_fifo/dut/wr_addr
add wave -noupdate -radix hexadecimal /tb_sc_fifo/dut/wr_req
add wave -noupdate -radix hexadecimal /tb_sc_fifo/dut/full
add wave -noupdate -radix hexadecimal /tb_sc_fifo/dut/rd_addr
add wave -noupdate -radix hexadecimal /tb_sc_fifo/dut/rd_req
add wave -noupdate -radix hexadecimal /tb_sc_fifo/dut/empty
add wave -noupdate -radix hexadecimal /tb_sc_fifo/dut/used_words
add wave -noupdate -radix hexadecimal /tb_sc_fifo/dut/rd_en
add wave -noupdate -radix hexadecimal /tb_sc_fifo/dut/data_in_ram
add wave -noupdate -radix hexadecimal /tb_sc_fifo/dut/data_in_o_reg
add wave -noupdate -radix hexadecimal /tb_sc_fifo/dut/svrl_w_in_mem
add wave -noupdate -radix hexadecimal /tb_sc_fifo/dut/first_word
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {2473715000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 300
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
WaveRestoreZoom {0 ps} {10855629750 ps}
