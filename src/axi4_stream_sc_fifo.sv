module axi4_stream_sc_fifo #(
  parameter int ALLOW_SLAVE_BACKPRESSURE = 1,
  parameter int DATA_WIDTH               = 32,
  parameter int DEST_WIDTH               = 1,
  parameter int USER_WIDTH               = 1,
  parameter int ID_WIDTH                 = 1
)(
  input                       clk_i,
  input                       rst_i,
  output [ADDR_WIDTH - 1 : 0] pkts_amount_o,
  axi4_stream_if.slave        slave_if,
  axi4_stream_if.master       master_if
);

endmodule
