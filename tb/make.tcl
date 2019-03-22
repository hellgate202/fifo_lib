vlib work
vlog -sv -incr -f ./files
vsim tb_sc_fifo
do wave.do
run -all
