// For code explanation refer to sc_fifo.sv
module axi4_stream_sc_fifo_smart #(
  parameter int BUFFER_DEPTH       = 64,
  parameter int DATA_WIDTH         = 32,
  parameter int USER_WIDTH         = 1,
  parameter int DEST_WIDTH         = 1,
  parameter int ID_WIDTH           = 1
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

axi4_stream_word_t wr_data;
axi4_stream_word_t rd_data;

logic [ADDR_WIDTH - 1 : 0] wr_addr;
logic                      wr_req;
logic                      full;
logic [ADDR_WIDTH - 1 : 0] rd_addr;
logic                      rd_req;
logic [ADDR_WIDTH : 0]     used_words, used_words_comb;
logic [ADDR_WIDTH : 0]     pkt_cnt;
logic [ADDR_WIDTH : 0]     pkt_word_cnt;
logic                      rd_en;
logic                      data_in_ram;
logic                      data_in_o_reg;
logic                      svrl_w_in_mem;
logic                      mem_n_empty;
logic                      first_word;
logic                      wr_pkt_done;
logic                      rd_pkt_done;
logic                      drop_state;

assign wr_data.tdata = pkt_i.tdata;
assign wr_data.tstrb = pkt_i.tstrb;
assign wr_data.tkeep = pkt_i.tkeep;
assign wr_data.tlast = pkt_i.tlast;
assign wr_data.tuser = pkt_i.tuser;
assign wr_data.tdest = pkt_i.tdest;
assign wr_data.tid   = pkt_i.tid;

assign pkt_o.tdata   = rd_data.tdata;
assign pkt_o.tstrb   = rd_data.tstrb;
assign pkt_o.tkeep   = rd_data.tkeep;
assign pkt_o.tlast   = rd_data.tlast;
assign pkt_o.tuser   = rd_data.tuser;
assign pkt_o.tdest   = rd_data.tdest;
assign pkt_o.tid     = rd_data.tid;

assign rd_req        = pkt_o.tvalid && pkt_o.tready;
assign wr_req        = pkt_i.tvalid && !full && !drop_state;

assign rd_pkt_done   = rd_req && pkt_o.tlast;
assign wr_pkt_done   = wr_req && pkt_i.tlast;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    drop_state <= '0;
  else
    if( drop_state && pkt_i.tvalid && pkt_i.tready && pkt_i.tlast )
      drop_state <= 1'b0;
    else
      if( wr_req && !rd_req && used_words == 2 ** ADDR_WIDTH && !pkt_i.tlast || pkt_i.tvalid && pkt_i.tready && full )
        drop_state <= 1'b1;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    pkt_cnt <= '0;
  else
    if( wr_pkt_done && !rd_pkt_done )
      pkt_cnt <= pkt_cnt + 1'b1;
    else
      if( !wr_pkt_done && rd_pkt_done )
        pkt_cnt <= pkt_cnt - 1'b1;

assign pkt_i.tready = 1'b1;
assign pkt_o.tvalid = pkt_cnt > 'd0 && data_in_o_reg;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    pkt_word_cnt <= '0;
  else
    if( wr_pkt_done || drop_state )
      pkt_word_cnt <= '0;
    else
      if( wr_req )
        pkt_word_cnt <= pkt_word_cnt + 1'b1;

always_ff @( posedge clk_i, posedge rst_i )
  if ( rst_i )
    used_words <= '0;
  else
    used_words <= used_words_comb;

always_comb
  begin
    used_words_comb = used_words;
    if( drop_state && full )
      begin
        if( rd_req )
          used_words_comb = used_words - pkt_word_cnt - 1'b1;
        else
          used_words_comb = used_words - pkt_word_cnt;
      end
    else
      begin
        if( wr_req && !rd_req )
          used_words_comb = used_words + 1'b1;
        else
          if( !wr_req && rd_req )
            used_words_comb = used_words - 1'b1;
      end
  end

assign svrl_w_in_mem = used_words > 'd2;
assign mem_n_empty   = used_words > 'd1;
assign first_word    = data_in_ram && !data_in_o_reg;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    data_in_o_reg <= '0;
  else
    if( drop_state && used_words_comb == '0 )
      data_in_o_reg <= 1'b0;
    else
      if( rd_req || first_word )
        data_in_o_reg <= data_in_ram;

assign rd_en = first_word || rd_req;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    data_in_ram <= '0;
  else
    if( drop_state && ( used_words_comb < 'd2 ) )
      data_in_ram <= 1'b0;
    else
      if( rd_req )
        data_in_ram <= wr_req || svrl_w_in_mem;
      else
        if( first_word || !data_in_ram )
          data_in_ram <= wr_req;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    wr_addr <= '0;
  else
    if( drop_state && full )
      wr_addr <= wr_addr - ( pkt_word_cnt - ( pkt_cnt == '0 ) );
    else 
      if( wr_req && ( data_in_ram || !rd_req && data_in_o_reg ) )
        wr_addr <= wr_addr + 1'b1;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    rd_addr <= '0;
  else
    if( rd_req && data_in_ram && !( drop_state && used_words_comb == '0 ) )
      rd_addr <= rd_addr + 1'b1;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    full <= '0;
  else
    if( !rd_req && wr_req )
      full <= used_words == ( 2**ADDR_WIDTH );
    else
      if( rd_req && !wr_req || drop_state && pkt_word_cnt != '0 )
        full <= 1'b0;

dual_port_ram #(
  .DATA_WIDTH ( FIFO_WIDTH ),
  .ADDR_WIDTH ( ADDR_WIDTH )
) ram (
  .wr_clk_i   ( clk_i      ),
  .wr_addr_i  ( wr_addr    ),
  .wr_data_i  ( wr_data    ),
  .wr_i       ( wr_req     ),
  .rd_clk_i   ( clk_i      ),
  .rd_addr_i  ( rd_addr    ),
  .rd_data_o  ( rd_data    ),
  .rd_i       ( rd_en      )
);

endmodule
