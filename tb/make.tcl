proc compile_src { name } {
  vlib work
  vlog -sv -f ./$name/files 
}

proc draw_waveforms { tb_name } {
  if { [file exists "./$tb_name/wave.do"] } {
    do ./$tb_name/wave.do
  }
}

proc sc_fifo {} {
  compile_src sc_fifo
  #vopt +acc tb_sc_fifo -o tb_sc_fifo_opt
  vsim tb_sc_fifo
  draw_waveforms sc_fifo
  run -all
}

proc dc_fifo {} {
  compile_src dc_fifo
  #vopt +acc tb_dc_fifo -o tb_dc_fifo_opt
  vsim tb_dc_fifo
  draw_waveforms dc_fifo
  run -all
}

proc axi4_stream_fifo {} {
  compile_src axi4_stream_fifo
#vopt +acc tb_axi4_stream_fifo -o tb_axi4_stream_fifo_opt
#vsim tb_axi4_stream_fifo_opt
  vsim tb_axi4_stream_fifo
  draw_waveforms axi4_stream_fifo
  run -all
}

proc help {} {
  echo "Type following one of following commands to run appropriate testbench:"
  echo "sc_fifo          - Single Clock FIFO."
  echo "dc_fifo          - Dual Clock FIFO."
  echo "axi4_stream_fifo - AXI4-Stream FIFO in Smart Mode"
  echo "Type help to repeat this message."
}

help
