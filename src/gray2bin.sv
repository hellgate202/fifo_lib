module gray2bin #(
  parameter int DATA_WIDTH = 8
)(
  input  [DATA_WIDTH - 1 : 0] gray_i,
  output [DATA_WIDTH - 1 : 0] bin_o
);

logic [DATA_WIDTH - 1 : 0] bin_data;

assign bin_o = bin_data;

always_comb
  begin
    bin_data[DATA_WIDTH - 1] = gray_i[DATA_WIDTH - 1];
    for( int i = DATA_WIDTH - 2; i >= 0; i-- )
      bin_data[i] = gray_i[i] ^ bin_data[i + 1];
  end

endmodule
