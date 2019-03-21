module sc_fifo #(
  parameter int DATA_WIDTH   = 8,
  parameter int WORDS_AMOUNT = 8
  parameter int ADDR_WIDTH   = $clog2( WORDS_AMOUNT );
)(
  input                       clk_i,
  input                       rst_i,
  input                       wr_i,
  input  [DATA_WIDTH - 1 : 0] wr_data_i,
  input                       rd_i,
  output [DATA_WIDTH - 1 : 0] rd_data_o,
  output [ADDR_WIDTH : 0]     used_words_o,
  output                      full_o,
  output                      empty_o
);

logic [ADDR_WIDTH - 1 : 0] wr_addr;
logic                      wr_req;
logic                      full;
logic [ADDR_WIDTH - 1 : 0] rd_addr;
logic                      rd_req;
logic                      empty;
logic [ADDR_WIDTH : 0]     used_words;

assign full_o       = full;
assign empty_o      = empty;
assign used_words_o = used_words;
assign wr_req       = wr_i && ~full;
assign rd_req       = rd_i && ~empty;

logic addr_locked;
logic data_locked;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    used_words <= '0;
  else
    if( wr_req && !rd_req )
      used_words <= used_words + 1'b1;
    else
      if( !wr_req && rd_req )
        used_words <= used_words - 1'b1;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    addr_locked <= '0;
  else
    if( addr_locked )
      begin
        if( rd_req )
          addr_locked <= wr_req || ( used_words > 'd2 );
        else
          if( ~data_locked )
            addr_locked <= wr_req;
      end
    else
      addr_locked <= wr_req;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    data_locked <= '0;
  else
    if( data_locked && rd_req || !data_locked )
      data_locked <= addr_locked;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    wr_addr <= '0;
  else
    if( wr_req && ( addr_locked && data_locked || !rd_req && used_words == 'd1 ) )
      wr_addr <= wr_addr + 1'b1;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    rd_addr <= '0;
  else
    if( rd_req && addr_locked && data_locked )
      rd_addr <= rd_addr + 1'b1;

assign empty = !data_locked;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    full <= '0;
  else
    if( !rd_req && wr_req )
      full <= used_words == ( 2**ADDR_WIDTH - 1 );
    else
      if( rd_req && !wr_req )
        full <= 1'b0;

dual_port_ram #(
  .DATA_WIDTH ( DATA_WIDTH ),
  .ADDR_WIDTH ( ADDR_WIDTH )
) ram (
  .rst_i      ( rst_i      ),
  .wr_clk_i   ( clk_i      ),
  .wr_addr_i  ( wr_addr    ),
  .wr_data_i  ( wr_data_i  ),
  .wr_i       ( wr_req     ),
  .rd_clk_i   ( clk_i      ),
  .rd_addr_i  ( rd_addr    ),
  .rd_data_o  ( rd_data_o  ),
  .rd_i       ( 1'b1       )
);

endmodule
