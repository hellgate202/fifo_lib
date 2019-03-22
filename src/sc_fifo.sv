module sc_fifo #(
  parameter int DATA_WIDTH   = 8,
  parameter int WORDS_AMOUNT = 8,
  parameter int ADDR_WIDTH   = $clog2( WORDS_AMOUNT )
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
logic                      rd_en;

assign full_o       = full;
assign empty_o      = empty;
assign used_words_o = used_words;
// Protection from write into full FIFO.
assign wr_req       = wr_i && ~full;
// Protection from read from empty FIFO.
assign rd_req       = rd_i && ~empty;

// We have unread data in memory.
logic data_in_mem;
// We have unread data at output.
logic data_at_output;

// Represents how many words are in FIFO
// but doesn't represent how many words are in
// memory.
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
    data_in_mem <= '0;
  else
    if( data_in_mem )
      begin
        // If we want to get data from fifo
        // wr_req means it is read during write.
        // When used_words == 'd2 && rd_req appears
        // that means that it is going to be 'd1
        // which also means we don't have data in memory
        // but only at output.
        if( rd_req )
          data_in_mem <= wr_req || ( used_words > 'd2 );
        else
          // This is the case for the first write after
          // FIFO was empty.
          if( ~data_at_output )
            data_in_mem <= wr_req;
      end
    else
      // Data appears at memory right after wr_req.
      data_in_mem <= wr_req;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    data_at_output <= '0;
  else
    // !data_at_output == empty, so we become not empty
    // when there is data in memory
    // when somebody reads from FIFO the data is removed
    // from the output and it trys to refresh it from
    // data_in_mem.
    if( rd_req || !data_at_output )
      data_at_output <= data_in_mem;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    wr_addr <= '0;
  else
    // We store data not only in memory but also at output regeister
    // That means that the first case when we can increment wr_addr is when there
    // is actual data at the output and the memory (i.e. we need next address in
    // memory). The second case is when we write first word (used_words == 'd1) and
    // about to write second word. If will read at the same moment - data from
    // mem will pass to output and we don't need to increment address.
    if( wr_req && ( data_in_mem && data_at_output || !rd_req && used_words == 'd1 ) )
      wr_addr <= wr_addr + 1'b1;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    rd_addr <= '0;
  else
    // We need to increment read address when we need to pass new data
    // to output, i.e. first, we read and data from output is discarded,
    // second, data from memory comes to output, third, we need new data
    // to prepare.
    if( rd_req && data_in_mem && data_at_output )
      rd_addr <= rd_addr + 1'b1;

assign empty = !data_at_output;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    full <= '0;
  else
    if( !rd_req && wr_req )
      full <= used_words == ( 2**ADDR_WIDTH - 1 );
    else
      if( rd_req && !wr_req )
        full <= 1'b0;

// We generate one read strobe when there is no data at output to
// push data to output and gain new data if available
assign rd_en = data_in_mem && !data_at_output || rd_req;

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
  .rd_i       ( rd_en      )
);

endmodule
