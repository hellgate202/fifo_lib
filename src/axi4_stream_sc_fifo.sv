module axi4_stream_sc_fifo #(
  parameter int BUFFER_DEPTH       = 64,
  parameter int DATA_WIDTH         = 32,
  parameter int USER_WIDTH         = 1,
  parameter int DEST_WIDTH         = 1,
  parameter int ID_WIDTH           = 1,
  parameter int CONTINIOUS_TVALID  = 1,
  parameter int ALLOW_BACKPRESSURE = 0
)(
  input                 clk_i,
  input                 rst_i,
  axi4_stream_if.slave  pkt_i,
  axi4_stream_if.master pkt_o
);

localparam int DATA_WIDTH_B = DATA_WIDTH / 8;
localparam int ADDR_WIDTH   = $clog2( BUFFER_DEPTH / DATA_WIDTH_B );
localparam int FIFO_WIDTH   = DATA_WIDTH + USER_WIDTH + DEST_WIDTH + 
                              ID_WIDTH + 2 * DATA_WIDTH_B + 1;

typedef struct packed {
  logic [DATA_WIDTH - 1 : 0]   tdata;
  logic [DATA_WIDTH_B - 1 : 0] tstrb;
  logic [DATA_WIDTH_B - 1 : 0] tkeep;
  logic                        tlast;
  logic [USER_WIDTH - 1 : 0]   tuser;
  logic [DEST_WIDTH - 1 : 0]   tdest;
  logic [ID_WIDTH - 1 : 0]     tid;
} axi4_stream_word_t;

axi4_stream_word_t         wr_data;
axi4_stream_word_t         rd_data;
logic [ADDR_WIDTH - 1 : 0] wr_addr;
logic [ADDR_WIDTH - 1 : 0] rd_addr;
logic [ADDR_WIDTH : 0]     used_words;
logic                      rd_en;
logic                      wr_en;

logic                      data_in_mem;
logic                      data_at_output;

logic                      pkt_running;
logic                      first_word;
logic                      fifo_overflow;
logic                      drop_pkt;
logic [ADDR_WIDTH : 0]     pkt_words_cnt;
logic [ADDR_WIDTH - 1 : 0] pkt_start_addr;
logic [ADDR_WIDTH : 0 ]    pkts_cnt;

assign wr_data.tdata = pkt_i.tdata;
assign wr_data.tstrb = pkt_i.tstrb;
assign wr_data.tkeep = pkt_i.tkeep;
assign wr_data.tlast = pkt_i.tlast;
assign wr_data.tuser = pkt_i.tuser;
assign wr_data.tdest = pkt_i.tdest;
assign wr_data.tid   = pkt_i.tid;

assign pkt_o.tdata = rd_data.tdata;
assign pkt_o.tstrb = rd_data.tstrb;
assign pkt_o.tkeep = rd_data.tkeep;
assign pkt_o.tlast = rd_data.tlast;
assign pkt_o.tuser = rd_data.tuser;
assign pkt_o.tdest = rd_data.tdest;
assign pkt_o.tid   = rd_data.tid;

assign pkt_i.tready = 1'b1;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    pkt_running <= '0;
  else
    if( pkt_i.tvalid && pkt_i.tready )
      if( pkt_i.tlast )
        pkt_running <= 1'b0;
      else
        pkt_running <= 1'b1;

assign first_word = !pkt_running && pkt_i.tvalid;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    drop_pkt <= '0;
  else
    if( fifo_overflow && pkt_i.tvalid && pkt_i.tready && !pkt_i.tlast )
      drop_pkt <= 1'b1;
    else
      if( pkt_i.tvalid && pkt_i.tready && pkt_i.tlast )
        drop_pkt <= 1'b0;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    pkt_words_cnt <= '0;
  else
    if( pkt_i.tvalid && pkt_i.tready && !fifo_overflow )
      if( first_word )
        pkt_words_cnt <= 'd1;
      else
        pkt_words_cnt <= pkt_words_cnt + 1'b1;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    pkt_start_addr <= '0;
  else
    if( pkt_i.tvalid && pkt_i.tready && first_word )
      pkt_start_addr <= wr_addr;

assign fifo_overflow = ( pkt_i.tvalid && pkt_i.tready ) && 
                      !( pkt_o.tvalid && pkt_o.tready ) &&
                       used_words == ( 2 ** ADDR_WIDTH - 1 );

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    used_words <= '0;
  else
    if( fifo_overflow )
      used_words <= used_words - pkt_words_cnt;
    else
      if( ( pkt_i.tvalid && pkt_i.tready && !drop_pkt ) && 
         !( pkt_o.tvalid && pkt_o.tready ) )
        used_words <= used_words + 1'b1;
      else
        if( !( pkt_i.tvalid && pkt_i.tready && !drop_pkt ) && 
             ( pkt_o.tvalid && pkt_o.tready ) )
          used_words <= used_words - 1'b1;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    data_in_mem <= '0;
  else
    if( data_in_mem )
      begin
        if( pkt_o.tvalid && pkt_o.tready )
          data_in_mem <= ( pkt_i.tvalid && pkt_i.tready && !drop_pkt ) || ( used_words > 'd2 );
        else
          if( !data_at_output )
            data_in_mem <= pkt_i.tvalid && pkt_i.tready && !drop_pkt;
      end
    else
      data_in_mem <= pkt_i.tvalid && pkt_i.tready && !drop_pkt;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    data_at_output <= '0;
  else
    if( pkt_o.tvalid && pkt_o.tready || !data_at_output )
      data_at_output <= data_in_mem;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    wr_addr <= '0;
  else
    if( pkt_i.tvalid && pkt_i.tready )
      if( fifo_overflow || drop_pkt )
        wr_addr <= pkt_start_addr;
      else
        if( data_in_mem && data_at_output || !( pkt_o.tvalid && pkt_o.tready ) && used_words == 'd1 )
          wr_addr <= wr_addr + 1'b1;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    rd_addr <= '0;
  else
    if( pkt_o.tvalid && pkt_o.tready && data_in_mem && data_at_output )
      rd_addr <= rd_addr + 1'b1;

assign rd_en = data_in_mem && !data_at_output || pkt_o.tvalid && pkt_o.tready; 
assign wr_en = pkt_i.tvalid && pkt_i.tready && !drop_pkt;

assign pkt_o.tvalid = pkts_cnt > '0;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    pkts_cnt <= '0;
  else
    if( ( pkt_i.tvalid && pkt_i.tready && pkt_i.tlast && !( fifo_overflow || drop_pkt ) &&
       !( pkt_o.tvalid && pkt_o.tready && pkt_o.tlast ) ) )
      pkts_cnt <= pkts_cnt + 1'b1;
    else
      if( !( pkt_i.tvalid && pkt_i.tready && pkt_i.tlast && !( fifo_overflow || drop_pkt ) ) &&
           ( pkt_o.tvalid && pkt_o.tready && pkt_o.tlast ) )
        pkts_cnt <= pkts_cnt - 1'b1;

dual_port_ram #(
  .DATA_WIDTH ( FIFO_WIDTH ),
  .ADDR_WIDTH ( ADDR_WIDTH )
) ram (
  .wr_clk_i   ( clk_i      ),
  .wr_addr_i  ( wr_addr    ),
  .wr_data_i  ( wr_data    ),
  .wr_i       ( wr_en      ),
  .rd_clk_i   ( clk_i      ),
  .rd_addr_i  ( rd_addr    ),
  .rd_data_o  ( rd_data    ),
  .rd_i       ( rd_en      )
);

endmodule
