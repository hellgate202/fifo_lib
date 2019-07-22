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

proc axi4_stream_sc_fifo_pth {} {
  compile_src axi4_stream_sc_fifo_pth
#vopt +acc tb_axi4_stream_sc_fifo -o tb_axi4_stream_sc_fifo_opt
#vsim tb_axi4_stream_sc_fifo_opt
  vsim tb_axi4_stream_sc_fifo_pth
  draw_waveforms axi4_stream_sc_fifo_pth
  run -all
}

proc axi4_stream_sc_fifo_smart {} {
  compile_src axi4_stream_sc_fifo_smart
#vopt +acc tb_axi4_stream_sc_fifo -o tb_axi4_stream_sc_fifo_opt
#vsim tb_axi4_stream_sc_fifo_opt
  vsim tb_axi4_stream_sc_fifo_smart
  draw_waveforms axi4_stream_sc_fifo_smart
  run -all
}

proc help {} {
  echo "Type following one of following commands to run appropriate testbench:"
  echo "sc_fifo                   - Single clock FIFO."
  echo "dc_fifo                   - Dual clock FIFO."
  echo "axi4_stream_sc_fifo_pth   - AXI4-Stream passthrough FIFO"
  echo "axi4_stream_sc_fifo_smart - AXI4-Stream smart FIFO"
  echo "Type help to repeat this message."
}

help
