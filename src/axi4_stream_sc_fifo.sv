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

localparam int ADDR_WIDTH   = $clog2( BUFFER_DEPTH );
localparam int DATA_WIDTH_B = DATA_WIDTH / 8;
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
logic                      wr_req;
logic                      full, full_comb;
logic [ADDR_WIDTH - 1 : 0] rd_addr;
logic                      rd_req;
logic [ADDR_WIDTH : 0]     used_words;
logic                      rd_en;

logic                      data_in_mem;
logic                      data_at_output;

logic                      pkt_running;
logic                      first_word;
logic                      fifo_overflow;
logic [ADDR_WIDTH : 0]     pkt_words_cnt;
logic [ADDR_WIDTH - 1 : 0] pkt_start_addr;

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

assign wr_req = pkt_i.tvalid && pkt_i.tready;
assign rd_req = pkt_o.tvalid && pkt_o.tready;

generate
  if( ALLOW_BACKPRESSURE )
    begin : backpressure_when_full
      assign pkt_i.tready = !full;
      // We don't need those signals when
      // we are applying backpressure
      assign pkt_running    = 1'b0;
      assign first_word     = 1'b0;
      assign fifo_overflow  = 1'b0;
      assign pkt_words_cnt  = '0;
      assign pkt_start_addr = '0;
    end
  else
    begin : drop_when_full

      assign pkt_i.tready = 1'b1;

      always_ff @( posedge clk_i, posedge rst_i )
        if( rst_i )
          pkt_running <= '0;
        else
          if( wr_req )
            if( pkt_i.tlast )
              pkt_running <= 1'b0;
            else
              pkt_running <= 1'b1;

      assign first_word = !pkt_running && pkt_i.tvalid;

      always_ff @( posedge clk_i, posedge rst_i )
        if( rst_i )
          fifo_overflow <= '0;
        else
          if( full_comb && wr_req && !pkt_i.tlast )
            fifo_overflow <= 1'b1;
          else
            if( wr_req && pkt_i.tlast )
              fifo_overflow <= 1'b0;

      always_ff @( posedge clk_i, posedge rst_i )
        if( rst_i )
          pkt_words_cnt <= '0;
        else
          if( wr_req && !fifo_overflow )
            if( first_word )
              pkt_words_cnt <= 'd1;
            else
              pkt_words_cnt <= pkt_words_cnt + 1'b1;

      always_ff @( posedge clk_i, posedge rst_i )
        if( rst_i )
          pkt_start_addr <= '0;
        else
          if( wr_req && first_word )
            pkt_start_addr <= wr_addr;
    end
endgenerate

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    full <= '0;
  else
    full <= full_comb;

always_comb
  begin
    full_comb = full;
    if( pkt_i.tvalid && !pkt_o.tready )
      full_comb = used_words == ( 2 ** ADDR_WIDTH - 1 );
    else
      if( pkt_o.tready && !pkt_i.tvalid )
        full_comb = 1'b0;
  end

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    used_words <= '0;
  else
    if( ALLOW_BACKPRESSURE == 0 && full_comb )
      used_words <= used_words - pkt_words_cnt;
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
        if( rd_req )
          data_in_mem <= ( wr_req && !fifo_overflow ) || ( used_words > 'd2 );
        else
          if( ~data_at_output )
            data_in_mem <= wr_req && !fifo_overflow;
      end
    else
      data_in_mem <= wr_req;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    data_at_output <= '0;
  else
    if( rd_req || !data_at_output )
      data_at_output <= data_in_mem;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    wr_addr <= '0;
  else
    if( wr_req )
      if( ALLOW_BACKPRESSURE == 0 && ( full_comb || fifo_overflow ) )
        wr_addr <= pkt_start_addr;
      else
        if( data_in_mem && data_at_output || !rd_req && used_words == 'd1 )
          wr_addr <= wr_addr + 1'b1;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    rd_addr <= '0;
  else
    if( rd_req && data_in_mem && data_at_output )
      rd_addr <= rd_addr + 1'b1;

assign rd_en = data_in_mem && !data_at_output || rd_req; 

generate
  if( CONTINIOUS_TVALID )
    begin : store_pkt

      logic [ADDR_WIDTH : 0 ] pkts_cnt;

      assign pkt_o.tvalid = pkts_cnt > '0;

      always_ff @( posedge clk_i, posedge rst_i )
        if( rst_i )
          pkts_cnt <= '0;
        else
          if( ( wr_req && pkt_i.tlast && !fifo_overflow ) &&
             !( rd_req && pkt_o.tlast ) )
            pkts_cnt <= pkts_cnt + 1'b1;
          else
            if( !( wr_req && pkt_i.tlast && !fifo_overflow ) &&
                 ( rd_req && pkt_o.tlast ) )
              pkts_cnt <= pkts_cnt - 1'b1;
    end
  else
    begin : passthrough
      assign pkt_o.tvalid = data_at_output;
    end
endgenerate

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
