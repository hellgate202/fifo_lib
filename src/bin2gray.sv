module bin2gray #(
  parameter int DATA_WIDTH = 8
)(
  input  [DATA_WIDTH - 1 : 0] bin_i,
  output [DATA_WIDTH - 1 : 0] gray_o
);

logic [DATA_WIDTH - 1 : 0] gray_data;

assign gray_o = gray_data;

always_comb
  begin
    gray_data[DATA_WIDTH - 1] = bin_i[DATA_WIDTH - 1];
    for( int i = DATA_WIDTH - 2; i >= 0; i-- )
      gray_data[i] = bin_i[i] ^ bin_i[i + 1];
  end

endmodule
