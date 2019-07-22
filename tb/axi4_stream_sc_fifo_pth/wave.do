onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider PKT_I
add wave -noupdate -radix hexadecimal /tb_axi4_stream_sc_fifo_pth/pkt_i/aclk
add wave -noupdate -radix hexadecimal /tb_axi4_stream_sc_fifo_pth/pkt_i/aresetn
add wave -noupdate -radix hexadecimal /tb_axi4_stream_sc_fifo_pth/pkt_i/tvalid
add wave -noupdate -radix hexadecimal /tb_axi4_stream_sc_fifo_pth/pkt_i/tready
add wave -noupdate -radix hexadecimal /tb_axi4_stream_sc_fifo_pth/pkt_i/tdata
add wave -noupdate -radix hexadecimal /tb_axi4_stream_sc_fifo_pth/pkt_i/tstrb
add wave -noupdate -radix hexadecimal /tb_axi4_stream_sc_fifo_pth/pkt_i/tkeep
add wave -noupdate -radix hexadecimal /tb_axi4_stream_sc_fifo_pth/pkt_i/tlast
add wave -noupdate -radix hexadecimal /tb_axi4_stream_sc_fifo_pth/pkt_i/tid
add wave -noupdate -radix hexadecimal /tb_axi4_stream_sc_fifo_pth/pkt_i/tdest
add wave -noupdate -radix hexadecimal /tb_axi4_stream_sc_fifo_pth/pkt_i/tuser
add wave -noupdate -divider DUT
add wave -noupdate -radix hexadecimal /tb_axi4_stream_sc_fifo_pth/DUT/clk_i
add wave -noupdate -radix hexadecimal /tb_axi4_stream_sc_fifo_pth/DUT/rst_i
add wave -noupdate -radix hexadecimal /tb_axi4_stream_sc_fifo_pth/DUT/wr_data
add wave -noupdate -radix hexadecimal /tb_axi4_stream_sc_fifo_pth/DUT/rd_data
add wave -noupdate -radix hexadecimal /tb_axi4_stream_sc_fifo_pth/DUT/wr_addr
add wave -noupdate -radix hexadecimal /tb_axi4_stream_sc_fifo_pth/DUT/rd_addr
add wave -noupdate -radix hexadecimal /tb_axi4_stream_sc_fifo_pth/DUT/used_words
add wave -noupdate -radix hexadecimal /tb_axi4_stream_sc_fifo_pth/DUT/rd_en
add wave -noupdate -radix hexadecimal /tb_axi4_stream_sc_fifo_pth/DUT/wr_en
add wave -noupdate -radix hexadecimal /tb_axi4_stream_sc_fifo_pth/DUT/data_in_mem
add wave -noupdate -radix hexadecimal /tb_axi4_stream_sc_fifo_pth/DUT/data_at_output
add wave -noupdate -radix hexadecimal /tb_axi4_stream_sc_fifo_pth/DUT/pkt_running
add wave -noupdate -radix hexadecimal /tb_axi4_stream_sc_fifo_pth/DUT/first_word
add wave -noupdate -radix hexadecimal /tb_axi4_stream_sc_fifo_pth/DUT/fifo_overflow
add wave -noupdate -radix hexadecimal /tb_axi4_stream_sc_fifo_pth/DUT/drop_pkt
add wave -noupdate -radix hexadecimal /tb_axi4_stream_sc_fifo_pth/DUT/pkt_words_cnt
add wave -noupdate -radix hexadecimal /tb_axi4_stream_sc_fifo_pth/DUT/pkt_start_addr
add wave -noupdate -radix hexadecimal /tb_axi4_stream_sc_fifo_pth/DUT/pkts_cnt
add wave -noupdate -divider PKT_O
add wave -noupdate -radix hexadecimal /tb_axi4_stream_sc_fifo_pth/pkt_o/aclk
add wave -noupdate -radix hexadecimal /tb_axi4_stream_sc_fifo_pth/pkt_o/aresetn
add wave -noupdate -radix hexadecimal /tb_axi4_stream_sc_fifo_pth/pkt_o/tvalid
add wave -noupdate -radix hexadecimal /tb_axi4_stream_sc_fifo_pth/pkt_o/tready
add wave -noupdate -radix hexadecimal /tb_axi4_stream_sc_fifo_pth/pkt_o/tdata
add wave -noupdate -radix hexadecimal /tb_axi4_stream_sc_fifo_pth/pkt_o/tstrb
add wave -noupdate -radix hexadecimal /tb_axi4_stream_sc_fifo_pth/pkt_o/tkeep
add wave -noupdate -radix hexadecimal /tb_axi4_stream_sc_fifo_pth/pkt_o/tlast
add wave -noupdate -radix hexadecimal /tb_axi4_stream_sc_fifo_pth/pkt_o/tid
add wave -noupdate -radix hexadecimal /tb_axi4_stream_sc_fifo_pth/pkt_o/tdest
add wave -noupdate -radix hexadecimal /tb_axi4_stream_sc_fifo_pth/pkt_o/tuser
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {69831 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 351
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
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {44625 ps}
