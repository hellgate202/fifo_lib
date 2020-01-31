onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider PKT_I
add wave -noupdate -radix hexadecimal /tb_axi4_stream_fifo/pkt_i/aclk
add wave -noupdate -radix hexadecimal /tb_axi4_stream_fifo/pkt_i/aresetn
add wave -noupdate -radix hexadecimal /tb_axi4_stream_fifo/pkt_i/tvalid
add wave -noupdate -radix hexadecimal /tb_axi4_stream_fifo/pkt_i/tready
add wave -noupdate -radix hexadecimal /tb_axi4_stream_fifo/pkt_i/tdata
add wave -noupdate -radix binary /tb_axi4_stream_fifo/pkt_i/tstrb
add wave -noupdate -radix binary /tb_axi4_stream_fifo/pkt_i/tkeep
add wave -noupdate -radix hexadecimal /tb_axi4_stream_fifo/pkt_i/tlast
add wave -noupdate -radix hexadecimal /tb_axi4_stream_fifo/pkt_i/tid
add wave -noupdate -radix hexadecimal /tb_axi4_stream_fifo/pkt_i/tdest
add wave -noupdate -radix hexadecimal /tb_axi4_stream_fifo/pkt_i/tuser
add wave -noupdate -divider DUT
add wave -noupdate -radix hexadecimal /tb_axi4_stream_fifo/DUT/clk_i
add wave -noupdate -radix hexadecimal /tb_axi4_stream_fifo/DUT/rst_i
add wave -noupdate -radix hexadecimal /tb_axi4_stream_fifo/DUT/full_o
add wave -noupdate -radix hexadecimal /tb_axi4_stream_fifo/DUT/empty_o
add wave -noupdate -radix hexadecimal /tb_axi4_stream_fifo/DUT/drop_o
add wave -noupdate -radix unsigned /tb_axi4_stream_fifo/DUT/used_words_o
add wave -noupdate -radix unsigned /tb_axi4_stream_fifo/DUT/pkts_amount_o
add wave -noupdate /tb_axi4_stream_fifo/DUT/pkt_size_o
add wave -noupdate -radix hexadecimal /tb_axi4_stream_fifo/DUT/wr_data
add wave -noupdate -radix hexadecimal /tb_axi4_stream_fifo/DUT/rd_data
add wave -noupdate -radix hexadecimal /tb_axi4_stream_fifo/DUT/wr_addr
add wave -noupdate -radix hexadecimal /tb_axi4_stream_fifo/DUT/wr_req
add wave -noupdate -radix hexadecimal /tb_axi4_stream_fifo/DUT/full
add wave -noupdate -radix hexadecimal /tb_axi4_stream_fifo/DUT/full_comb
add wave -noupdate -radix hexadecimal /tb_axi4_stream_fifo/DUT/rd_addr
add wave -noupdate -radix hexadecimal /tb_axi4_stream_fifo/DUT/rd_req
add wave -noupdate -radix unsigned /tb_axi4_stream_fifo/DUT/used_words
add wave -noupdate -radix unsigned /tb_axi4_stream_fifo/DUT/used_words_comb
add wave -noupdate -radix unsigned /tb_axi4_stream_fifo/DUT/pkt_cnt
add wave -noupdate -radix unsigned /tb_axi4_stream_fifo/DUT/pkt_word_cnt
add wave -noupdate -radix hexadecimal /tb_axi4_stream_fifo/DUT/rd_en
add wave -noupdate -radix hexadecimal /tb_axi4_stream_fifo/DUT/data_in_ram
add wave -noupdate -radix hexadecimal /tb_axi4_stream_fifo/DUT/data_in_o_reg
add wave -noupdate -radix hexadecimal /tb_axi4_stream_fifo/DUT/svrl_w_in_mem
add wave -noupdate -radix hexadecimal /tb_axi4_stream_fifo/DUT/first_word
add wave -noupdate -radix hexadecimal /tb_axi4_stream_fifo/DUT/wr_pkt_done
add wave -noupdate -radix hexadecimal /tb_axi4_stream_fifo/DUT/rd_pkt_done
add wave -noupdate -radix hexadecimal /tb_axi4_stream_fifo/DUT/drop_state
add wave -noupdate -divider PKT_O
add wave -noupdate -radix hexadecimal /tb_axi4_stream_fifo/pkt_o/aclk
add wave -noupdate -radix hexadecimal /tb_axi4_stream_fifo/pkt_o/aresetn
add wave -noupdate -radix hexadecimal /tb_axi4_stream_fifo/pkt_o/tvalid
add wave -noupdate -radix hexadecimal /tb_axi4_stream_fifo/pkt_o/tready
add wave -noupdate -radix hexadecimal /tb_axi4_stream_fifo/pkt_o/tdata
add wave -noupdate -radix binary /tb_axi4_stream_fifo/pkt_o/tstrb
add wave -noupdate -radix binary /tb_axi4_stream_fifo/pkt_o/tkeep
add wave -noupdate -radix hexadecimal /tb_axi4_stream_fifo/pkt_o/tlast
add wave -noupdate -radix hexadecimal /tb_axi4_stream_fifo/pkt_o/tid
add wave -noupdate -radix hexadecimal /tb_axi4_stream_fifo/pkt_o/tdest
add wave -noupdate -radix hexadecimal /tb_axi4_stream_fifo/pkt_o/tuser
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {247147500 ps} 0}
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
WaveRestoreZoom {0 ps} {354676875 ps}
