// For more code explanation refer to sc_fifo.sv
module axi4_stream_fifo #(
  // AXI4 interface parameters
  parameter int TDATA_WIDTH    = 32,
  parameter int TUSER_WIDTH    = 1,
  parameter int TDEST_WIDTH    = 1,
  parameter int TID_WIDTH      = 1,
  // FIFO parameters
  parameter int WORDS_AMOUNT   = 8,
  parameter int SMART          = 1,
  parameter int SHOW_PKT_SIZE  = 0,
  parameter int ADDR_WIDTH     = $clog2( WORDS_AMOUNT ),
  parameter int PKT_SIZE_WIDTH = ADDR_WIDTH + $clog2( TDATA_WIDTH / 8 ),
  // Doesn't work in SMART mode
  parameter int MEM_OPT        = 0,
  parameter int MAX_PKTS       = 10,
  parameter int MAX_PKT_SIZE   = 1920
)(
  input                       clk_i,
  input                       rst_i,
  output                      full_o,
  output                      empty_o,
  output                      drop_o,
  output [ADDR_WIDTH : 0]     used_words_o,
  output [ADDR_WIDTH : 0]     pkts_amount_o,
  output [PKT_SIZE_WIDTH : 0] pkt_size_o,
  axi4_stream_if.slave        pkt_i,
  axi4_stream_if.master       pkt_o
);

localparam int TDATA_WIDTH_B = TDATA_WIDTH / 8;
localparam int PKT_CNT_WIDTH = $clog2( MAX_PKT_SIZE );

typedef struct packed {
  logic [TDATA_WIDTH - 1 : 0]   tdata;
  logic [TDATA_WIDTH_B - 1 : 0] tstrb;
  logic [TDATA_WIDTH_B - 1 : 0] tkeep;
  logic                         tlast;
  logic [TUSER_WIDTH - 1 : 0]   tuser;
  logic [TDEST_WIDTH - 1 : 0]   tdest;
  logic [TID_WIDTH - 1 : 0]     tid;
} axi4_stream_word_t;

typedef struct packed {
  logic [TUSER_WIDTH - 1 : 0]   tuser;
  logic [TDEST_WIDTH - 1 : 0]   tdest;
  logic [TID_WIDTH - 1 : 0]     tid;
} axi4_stream_sop_t;

typedef struct packed {
  logic [TDATA_WIDTH_B - 1 : 0] tstrb;
  logic [TDATA_WIDTH_B - 1 : 0] tkeep;
} axi4_stream_eop_t;

localparam int FIFO_WIDTH = MEM_OPT ? TDATA_WIDTH : $bits( axi4_stream_word_t );
// Data words for RAM
axi4_stream_word_t wr_data;
axi4_stream_word_t rd_data;

logic [ADDR_WIDTH - 1 : 0] wr_addr;
logic                      wr_req;
logic                      full, full_comb;
logic [ADDR_WIDTH - 1 : 0] rd_addr;
logic                      rd_req;
logic [ADDR_WIDTH : 0]     used_words, used_words_comb;

logic [ADDR_WIDTH : 0]     pkt_cnt;
logic [ADDR_WIDTH : 0]     pkt_word_cnt;
logic [ADDR_WIDTH : 0]     pkt_word_cnt_m1;
logic [ADDR_WIDTH : 0]     pkt_word_cnt_p1;
logic [ADDR_WIDTH : 0]     pkt_word_cnt_p2;

logic                      rd_en;
logic                      data_in_ram;
logic                      data_in_o_reg;
logic                      svrl_w_in_mem;
logic                      first_word;
logic                      wr_pkt_done;
logic                      rd_pkt_done;

logic                      drop_state;

localparam int SOP_DATA_WIDTH       = $bits( axi4_stream_sop_t );
localparam int EOP_DATA_WIDTH       = $bits( axi4_stream_eop_t );

typedef struct packed {
  logic [PKT_CNT_WIDTH - 1 : 0] meta_ptr;
  axi4_stream_sop_t             sop_meta;
  axi4_stream_eop_t             eop_meta;
} meta_fifo_t;

localparam int META_FIFO_DATA_WIDTH = $bits( meta_fifo_t );

axi4_stream_sop_t              saved_sop_meta;
logic [PKT_CNT_WIDTH - 1 : 0]  pop_meta_cnt;
logic                          meta_fifo_push;
logic                          meta_fifo_pop;
logic                          meta_fifo_full;
logic                          meta_fifo_empty;
meta_fifo_t                    meta_fifo_wr_data;
meta_fifo_t                    meta_fifo_rd_data;
logic                          meta_fifo_tfirst;

logic                          was_tlast;
logic                          tfirst;

assign wr_data.tdata = pkt_i.tdata;
assign wr_data.tstrb = pkt_i.tstrb;
assign wr_data.tkeep = pkt_i.tkeep;
assign wr_data.tlast = pkt_i.tlast;
assign wr_data.tuser = pkt_i.tuser;
assign wr_data.tdest = pkt_i.tdest;
assign wr_data.tid   = pkt_i.tid;

assign rd_req        = pkt_o.tvalid && pkt_o.tready;
assign wr_req        = MEM_OPT ? pkt_i.tvalid && !full && !meta_fifo_full && !drop_state :
                                 pkt_i.tvalid && !full && !drop_state;

generate
  if( SMART )
    begin : drop_logic
      // When current packet is about to make FIFO full and it is not currently the
      // last word of the packet then the rest of the packet won't be able to be
      // written. So we discard the whole packet and enter drop state. The other
      // case is when we are already full and new packet apprears. Then we are also
      // entering the drop state and waiting till the end of packet, because we
      // don't want to write packet without its first words.
      // When the last word of the packet appears, we exit drop state.
      always_ff @( posedge clk_i, posedge rst_i )
        if( rst_i )
          drop_state <= '0;
        else
          if( drop_state && pkt_i.tvalid && pkt_i.tlast )
            drop_state <= 1'b0;
          else
            if( full_comb && !pkt_i.tlast || full && pkt_i.tvalid )
              drop_state <= 1'b1;
      
      assign drop_o       = drop_state && pkt_i.tvalid && pkt_i.tlast;
      // We are always ready if we are dropping packets on overflow
      assign pkt_i.tready = 1'b1;

      if( SHOW_PKT_SIZE )
        begin : cnt_pkt_size
          localparam int RX_BYTE_CNT_WIDTH = $clog2( TDATA_WIDTH_B );

          logic [PKT_SIZE_WIDTH : 0]    pkt_size;
          logic [PKT_SIZE_WIDTH : 0]    pkt_size_inc;
          logic [RX_BYTE_CNT_WIDTH : 0] rx_bytes;
          logic                         no_pkt_size;

          // Amount of ones in tkeep signal is amount of bytes to receive
          always_comb
            begin
              rx_bytes = '0;
              if( pkt_i.tvalid )
                if( pkt_i.tlast )
                  begin
                    for( int lmo = 0; lmo < TDATA_WIDTH_B; lmo++ )
                      if( pkt_i.tkeep[lmo] )
                        rx_bytes = rx_bytes + 1'b1;
                  end
                else
                  rx_bytes = ( RX_BYTE_CNT_WIDTH + 1 )'( TDATA_WIDTH_B );
            end

          assign pkt_size_inc = pkt_size + rx_bytes;

          // Receive bytes counter
          always_ff @( posedge clk_i, posedge rst_i ) 
            if( rst_i )
              pkt_size <= '0;
            else
              if( pkt_i.tvalid && pkt_i.tready )
                if( pkt_i.tlast || drop_state )
                  pkt_size <= '0;
                else
                  pkt_size <= pkt_size_inc;

          // Another FIFO just for packet sizes
          sc_fifo #(
            .DATA_WIDTH   ( PKT_SIZE_WIDTH + 1 ),
            .WORDS_AMOUNT ( WORDS_AMOUNT       )
          ) pkt_size_fifo (
            .clk_i        ( clk_i              ),
            .rst_i        ( rst_i              ),
            .wr_i         ( wr_pkt_done        ),
            .wr_data_i    ( pkt_size_inc       ),
            .rd_i         ( rd_pkt_done        ),
            .rd_data_o    ( pkt_size_o         ),
            .used_words_o (                    ),
            .full_o       (                    ),
            .empty_o      ( no_pkt_size        )
          );

          assign pkt_o.tvalid = !no_pkt_size && pkt_cnt > 'd0 && data_in_o_reg;
        end
      else
        begin : no_cnt_pkt_size
          assign pkt_size_o   = '0;
          assign pkt_o.tvalid = pkt_cnt > 'd0 && data_in_o_reg;
        end
    end
  else
    begin : backpressure_logic
      // We do not drop packets in passthrough mode
      assign drop_state   = 1'b0;
      assign drop_o       = 1'b0;
      // We are backpressuring if we are full
      assign pkt_i.tready = MEM_OPT ? !full && !meta_fifo_full : !full;
      // Valid whenether we have data at output
      assign pkt_o.tvalid = data_in_o_reg;
      assign pkt_size_o   = '0;
    end
endgenerate

// Packet has been successfuly read from FIFO
assign rd_pkt_done   = rd_req && pkt_o.tlast;
// Packet has been succsessfuly written to FIFO
assign wr_pkt_done   = wr_req && pkt_i.tlast;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    pkt_cnt <= '0;
  else
    if( wr_pkt_done && !rd_pkt_done )
      pkt_cnt <= pkt_cnt + 1'b1;
    else
      if( !wr_pkt_done && rd_pkt_done )
        pkt_cnt <= pkt_cnt - 1'b1;

assign pkts_amount_o = pkt_cnt;

// Indicates how many words of the current packet was written.
// It is needed to revert write address of RAM in case of drop state
always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    begin
      pkt_word_cnt    <= '0;
      pkt_word_cnt_m1 <= '1;
      pkt_word_cnt_p1 <= 'd1;
      pkt_word_cnt_p2 <= 'd2;
    end
  else
    if( wr_pkt_done || drop_state )
      begin
        pkt_word_cnt    <= '0;
        pkt_word_cnt_m1 <= '1;
        pkt_word_cnt_p1 <= 'd1;
        pkt_word_cnt_p2 <= 'd2;
      end
    else
      if( wr_req )
        begin
          pkt_word_cnt    <= pkt_word_cnt    + 1'b1;
          pkt_word_cnt_m1 <= pkt_word_cnt_m1 + 1'b1;
          pkt_word_cnt_p1 <= pkt_word_cnt_p1 + 1'b1;
          pkt_word_cnt_p2 <= pkt_word_cnt_p2 + 1'b1;
        end

always_ff @( posedge clk_i, posedge rst_i )
  if ( rst_i )
    used_words <= '0;
  else
    used_words <= used_words_comb;

always_comb
  begin
    used_words_comb = used_words;
    // Full is triggered only for one tick so we use it 
    // to decrase used_words only once
    if( drop_state )
      begin
        // Used words is decrased by the droped words amount and one
        // currently read word. wr_req is unsetable in drop state
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

assign used_words_o  = used_words;

assign svrl_w_in_mem = used_words > 'd2;
assign first_word    = data_in_ram && !data_in_o_reg;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    data_in_o_reg <= '0;
  else
    // If after drop state we won't have any words in FIFO then we also won't
    // have any words in output register
    if( drop_state &&
        ( ( used_words == pkt_word_cnt && !rd_req ) ||
          ( used_words == pkt_word_cnt_m1 && rd_req ) ) )
      data_in_o_reg <= 1'b0;
    else
      if( rd_req || first_word )
        data_in_o_reg <= data_in_ram;

assign empty_o = !data_in_o_reg;
assign rd_en   = ( first_word || rd_req ) && data_in_ram;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    data_in_ram <= '0;
  else
    // If after drop state there will be only one word in FIFO it will be in
    // output register
    if( drop_state && 
        ( ( used_words == pkt_word_cnt && !rd_req ) ||
          ( used_words == pkt_word_cnt_p1 && rd_req ) ) )
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
    // We use full like in used_words scenario
    // If it is the first packet entering FIFO and it is in drop state.
    // Then it is packet of size that larger than FIFO capacity and it will be
    // cleared as well as output register. So write address will be decrased
    // one less the usual.
    if( drop_state && full )
      wr_addr <= wr_addr - ( pkt_word_cnt[ADDR_WIDTH - 1 : 0] );
    else 
      if( wr_req )
        wr_addr <= wr_addr + 1'b1;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    rd_addr <= '0;
  else
    // We don't need to increase read address after drop state that left one
    // word in output register, that was outputed in the same tick as drop
    // state appears. I.e. fifo was flushed not by drop state, but by regular
    // read operation.
    if( drop_state && full && pkt_cnt == 0 )
      rd_addr <= rd_addr - 1'b1;
    else
      if( rd_en ) 
        rd_addr <= rd_addr + 1'b1;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    full <= 1'b0;
  else
    full <= full_comb;

always_comb
  begin
    full_comb = full;
    if( !rd_req && wr_req )
      full_comb = used_words == ( 2**ADDR_WIDTH  );
    else
      // We do not reset full state with drop state when there weren't any
      // words written. I.e. whole packet was ignored during drop state.
      if( rd_req && !wr_req || drop_state && pkt_word_cnt != '0 )
        full_comb = 1'b0;
  end

assign full_o = MEM_OPT ? full || meta_fifo_full : full;

generate
  if( MEM_OPT )
    begin : tdata_ram
      dual_port_ram #(
        .DATA_WIDTH ( FIFO_WIDTH ),
        .ADDR_WIDTH ( ADDR_WIDTH )
      ) ram (
        .wr_clk_i   ( clk_i      ),
        .wr_addr_i  ( wr_addr    ),
        .wr_data_i  ( wr_data.tdata    ),
        .wr_i       ( wr_req     ),
        .rd_clk_i   ( clk_i      ),
        .rd_addr_i  ( rd_addr    ),
        .rd_data_o  ( rd_data.tdata    ),
        .rd_i       ( rd_en      )
      );
    end
  else
    begin : axi_word_t_ram
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
    end
endgenerate

generate
  if( MEM_OPT )
    begin : meta_fifo_gen
      always_ff @( posedge clk_i, posedge rst_i )
        if( rst_i )
          was_tlast <= 1'b1;
        else
          if( pkt_i.tvalid && pkt_i.tready )
            if( pkt_i.tlast )
              was_tlast <= 1'b1;
            else
              was_tlast <= 1'b0;
      
      assign tfirst         = was_tlast && pkt_i.tvalid;
      assign meta_fifo_push = wr_req && pkt_i.tlast; 
      assign meta_fifo_pop  = rd_req && pop_meta_cnt == meta_fifo_rd_data.meta_ptr && !meta_fifo_empty;
      
      always_ff @( posedge clk_i, posedge rst_i )
        if( rst_i )
          saved_sop_meta <= SOP_DATA_WIDTH'( 0 );
        else
          if( wr_req && tfirst )
            begin
              saved_sop_meta.tuser <= pkt_i.tuser;
              saved_sop_meta.tdest <= pkt_i.tdest;
              saved_sop_meta.tid   <= pkt_i.tid;
            end
      
      always_ff @( posedge clk_i, posedge rst_i )
        if( rst_i )
          pop_meta_cnt <= PKT_CNT_WIDTH'( 0 );
        else
          if( rd_req )
            if( meta_fifo_pop )
              pop_meta_cnt <= PKT_CNT_WIDTH'( 0 );
            else
              pop_meta_cnt <= pop_meta_cnt + 1'b1;
      
      assign meta_fifo_tfirst = !pop_meta_cnt;

      always_ff @( posedge clk_i, posedge rst_i )
        if( rst_i )
          meta_fifo_wr_data.meta_ptr <= PKT_CNT_WIDTH'( 0 );
        else
          if( wr_req )
            if( pkt_i.tlast )
              meta_fifo_wr_data.meta_ptr <= PKT_CNT_WIDTH'( 0 );
            else
              meta_fifo_wr_data.meta_ptr <= meta_fifo_wr_data.meta_ptr + 1'b1;
      
      always_comb
        if( tfirst )
          begin
            meta_fifo_wr_data.sop_meta.tuser = pkt_i.tuser;
            meta_fifo_wr_data.sop_meta.tdest = pkt_i.tdest;
            meta_fifo_wr_data.sop_meta.tid   = pkt_i.tid;
          end
        else
          meta_fifo_wr_data.sop_meta = saved_sop_meta;
      
      assign meta_fifo_wr_data.eop_meta.tstrb = pkt_i.tstrb;
      assign meta_fifo_wr_data.eop_meta.tkeep = pkt_i.tkeep;
      
      sc_fifo #(
        .DATA_WIDTH   ( META_FIFO_DATA_WIDTH ),
        .WORDS_AMOUNT ( MAX_PKTS             ),
        .USE_LUTS     ( 1                    )
      ) meta_fifo_inst (
        .clk_i        ( clk_i                ),
        .rst_i        ( rst_i                ),
        .wr_i         ( meta_fifo_push       ),
        .wr_data_i    ( meta_fifo_wr_data    ),
        .rd_i         ( meta_fifo_pop        ),
        .rd_data_o    ( meta_fifo_rd_data    ),
        .used_words_o (                      ),
        .full_o       ( meta_fifo_full       ),
        .empty_o      ( meta_fifo_empty      )
      );
      
      assign pkt_o.tuser = meta_fifo_empty ? saved_sop_meta.tuser && meta_fifo_tfirst : 
                                             meta_fifo_rd_data.sop_meta.tuser && meta_fifo_tfirst;
      assign pkt_o.tdest = meta_fifo_empty ? saved_sop_meta.tdest && meta_fifo_tfirst:
                                             meta_fifo_rd_data.sop_meta.tdest && meta_fifo_tfirst;
      assign pkt_o.tid   = meta_fifo_empty ? saved_sop_meta.tid && meta_fifo_tfirst:
                                             meta_fifo_rd_data.sop_meta.tid && meta_fifo_tfirst;
      assign pkt_o.tlast = meta_fifo_pop;
      assign pkt_o.tstrb = meta_fifo_pop ? meta_fifo_rd_data.eop_meta.tstrb : '1;
      assign pkt_o.tkeep = meta_fifo_pop ? meta_fifo_rd_data.eop_meta.tkeep : '1;
    end
  else
    begin : no_meta_fifo_gen
      assign pkt_o.tstrb   = rd_data.tstrb;
      assign pkt_o.tkeep   = rd_data.tkeep;
      assign pkt_o.tlast   = rd_data.tlast;
      assign pkt_o.tuser   = rd_data.tuser;
      assign pkt_o.tdest   = rd_data.tdest;
      assign pkt_o.tid     = rd_data.tid;
    end
endgenerate

assign pkt_o.tdata   = rd_data.tdata;

endmodule
