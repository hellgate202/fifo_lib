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
// Moving data from RAM to output reg
logic                      rd_en;
// There is unread data in RAM
logic                      data_in_ram;
// There is unread data at output reg
logic                      data_in_rd_data;
// More than one word in RAM
logic                      svrl_w_in_mem;
// At least one word in RAM
logic                      mem_not_empty;

assign full_o       = full;
assign empty_o      = empty;
assign used_words_o = used_words;
// Protection from write into full FIFO.
assign wr_req       = wr_i && !full;
// Protection from read from empty FIFO.
assign rd_req       = rd_i && !empty;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    used_words <= '0;
  else
    if( wr_req && !rd_req )
      used_words <= used_words + 1'b1;
    else
      if( !wr_req && rd_req )
        used_words <= used_words - 1'b1;

// Relationship of used_words signal to words amount in RAM
// used_words signal represents how many words we have stored in FIFO
// But FIFO consists not only of RAM memory, but also ща
assign svrl_w_in_mem = used_words > 'd2;
assign mem_not_empty = used_words > 'd1;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    data_in_ram <= '0;
  else
    if( data_in_ram )
      begin
        if( rd_req )
          data_in_ram <= wr_req || svrl_w_in_mem;
        else
          if( empty )
            data_in_ram <= wr_req;
      end
    else
      data_in_ram <= wr_req;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    data_at_output <= '0;
  else
    // If there is data in ram[rd_addr_i] it will move to rd_data reg at read
    // request (feed new data to output) or when there is no data at output
    // (See data_in_mem always block)
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
assign rd_en = data_in_mem && ( !data_at_output || rd_req );

dual_port_ram #(
  .DATA_WIDTH ( DATA_WIDTH ),
  .ADDR_WIDTH ( ADDR_WIDTH )
) ram (
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
