onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_dc_fifo/dut/wr_clk_i
add wave -noupdate /tb_dc_fifo/dut/wr_data_i
add wave -noupdate /tb_dc_fifo/dut/wr_i
add wave -noupdate -radix unsigned /tb_dc_fifo/dut/wr_used_words_o
add wave -noupdate /tb_dc_fifo/dut/wr_full_o
add wave -noupdate /tb_dc_fifo/dut/wr_empty_o
add wave -noupdate /tb_dc_fifo/dut/rd_clk_i
add wave -noupdate /tb_dc_fifo/dut/rd_data_o
add wave -noupdate /tb_dc_fifo/dut/rd_i
add wave -noupdate -radix unsigned /tb_dc_fifo/dut/rd_used_words_o
add wave -noupdate /tb_dc_fifo/dut/rd_full_o
add wave -noupdate /tb_dc_fifo/dut/rd_empty_o
add wave -noupdate /tb_dc_fifo/dut/rst_i
add wave -noupdate /tb_dc_fifo/dut/wr_req
add wave -noupdate -radix unsigned /tb_dc_fifo/dut/wr_used_words
add wave -noupdate /tb_dc_fifo/dut/wr_full
add wave -noupdate /tb_dc_fifo/dut/wr_empty
add wave -noupdate -radix binary /tb_dc_fifo/dut/wr_ptr_wr_clk
add wave -noupdate -radix binary /tb_dc_fifo/dut/wr_ptr_gray_wr_clk
add wave -noupdate -radix binary /tb_dc_fifo/dut/wr_ptr_gray_rd_clk
add wave -noupdate -radix binary /tb_dc_fifo/dut/wr_ptr_gray_rd_clk_mtstb
add wave -noupdate /tb_dc_fifo/dut/wr_ptr_rd_clk
add wave -noupdate /tb_dc_fifo/dut/wr_addr
add wave -noupdate /tb_dc_fifo/dut/rd_req
add wave -noupdate -radix unsigned /tb_dc_fifo/dut/rd_used_words
add wave -noupdate /tb_dc_fifo/dut/rd_full
add wave -noupdate /tb_dc_fifo/dut/rd_empty
add wave -noupdate /tb_dc_fifo/dut/rd_ptr_rd_clk
add wave -noupdate -radix binary /tb_dc_fifo/dut/rd_ptr_gray_rd_clk
add wave -noupdate -radix binary /tb_dc_fifo/dut/rd_ptr_gray_wr_clk
add wave -noupdate -radix binary /tb_dc_fifo/dut/rd_ptr_gray_wr_clk_mtstb
add wave -noupdate -radix binary /tb_dc_fifo/dut/rd_ptr_wr_clk
add wave -noupdate /tb_dc_fifo/dut/rd_addr
add wave -noupdate /tb_dc_fifo/dut/rd_en
add wave -noupdate /tb_dc_fifo/dut/data_in_mem
add wave -noupdate /tb_dc_fifo/dut/data_at_output
add wave -noupdate -divider RAM
add wave -noupdate /tb_dc_fifo/dut/ram/rst_i
add wave -noupdate /tb_dc_fifo/dut/ram/wr_clk_i
add wave -noupdate /tb_dc_fifo/dut/ram/wr_addr_i
add wave -noupdate /tb_dc_fifo/dut/ram/wr_data_i
add wave -noupdate /tb_dc_fifo/dut/ram/wr_i
add wave -noupdate /tb_dc_fifo/dut/ram/rd_clk_i
add wave -noupdate /tb_dc_fifo/dut/ram/rd_addr_i
add wave -noupdate /tb_dc_fifo/dut/ram/rd_data_o
add wave -noupdate /tb_dc_fifo/dut/ram/rd_i
add wave -noupdate /tb_dc_fifo/dut/ram/rd_data
add wave -noupdate -divider MEM
add wave -noupdate -radix hexadecimal -childformat {{{/tb_dc_fifo/dut/ram/ram[7]} -radix hexadecimal} {{/tb_dc_fifo/dut/ram/ram[6]} -radix hexadecimal} {{/tb_dc_fifo/dut/ram/ram[5]} -radix hexadecimal} {{/tb_dc_fifo/dut/ram/ram[4]} -radix hexadecimal} {{/tb_dc_fifo/dut/ram/ram[3]} -radix hexadecimal} {{/tb_dc_fifo/dut/ram/ram[2]} -radix hexadecimal} {{/tb_dc_fifo/dut/ram/ram[1]} -radix hexadecimal} {{/tb_dc_fifo/dut/ram/ram[0]} -radix hexadecimal}} -expand -subitemconfig {{/tb_dc_fifo/dut/ram/ram[7]} {-height 16 -radix hexadecimal} {/tb_dc_fifo/dut/ram/ram[6]} {-height 16 -radix hexadecimal} {/tb_dc_fifo/dut/ram/ram[5]} {-height 16 -radix hexadecimal} {/tb_dc_fifo/dut/ram/ram[4]} {-height 16 -radix hexadecimal} {/tb_dc_fifo/dut/ram/ram[3]} {-height 16 -radix hexadecimal} {/tb_dc_fifo/dut/ram/ram[2]} {-height 16 -radix hexadecimal} {/tb_dc_fifo/dut/ram/ram[1]} {-height 16 -radix hexadecimal} {/tb_dc_fifo/dut/ram/ram[0]} {-height 16 -radix hexadecimal}} /tb_dc_fifo/dut/ram/ram
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {4563465000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 353
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
WaveRestoreZoom {0 ps} {9765131250 ps}
