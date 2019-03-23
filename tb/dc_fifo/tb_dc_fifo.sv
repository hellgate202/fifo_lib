`timescale 1 ps / 1 ps

module tb_dc_fifo;

parameter int DATA_WIDTH   = 8;
parameter int WORDS_AMOUNT = 8;
parameter int WR_CLK_T     = 8000;
parameter int RD_CLK_T     = 10000;
parameter int ADDR_WIDTH   = $clog2( WORDS_AMOUNT );

parameter int OP_AMOUNT    = 1_000_000;

bit                      wr_clk;
bit                      rd_clk;
bit                      rst;
bit                      wr;
bit [DATA_WIDTH - 1 : 0] wr_data;
bit                      rd;
bit [DATA_WIDTH - 1 : 0] rd_data;
bit [ADDR_WIDTH : 0]     wr_used_words;
bit [ADDR_WIDTH : 0]     rd_used_words;
bit                      wr_full;
bit                      wr_empty;
bit                      rd_full;
bit                      rd_empty;

bit [DATA_WIDTH - 1 : 0] ref_word;
bit [DATA_WIDTH - 1 : 0] rd_word;
bit [DATA_WIDTH - 1 : 0] ref_fifo [$];

task automatic wr_clk_gen();
  forever
    begin
      #( WR_CLK_T / 2 );
      wr_clk = ~wr_clk;
    end
endtask

task automatic rd_clk_gen();
  forever
    begin
      #( RD_CLK_T / 2 );
      rd_clk = ~rd_clk;
    end
endtask

task automatic apply_rst();
  #20000;
  rst = 1'b1;
  #20000;
  rst = 1'b0;
endtask

task automatic put_word_in_fifo(
  input bit [DATA_WIDTH - 1 : 0] word
);
  while( wr_full )
    @( posedge wr_clk );
  wr            <= 1'b1;
  wr_data       <= word;
  @( posedge wr_clk );
  wr            <= 1'b0;
endtask

task automatic get_word_from_fifo(
  output bit [DATA_WIDTH - 1 : 0] word
);
  while( rd_empty )
    @( posedge rd_clk );
  rd            <= 1'b1;
  @( posedge rd_clk );
  word           = rd_data;
  rd            <= 1'b0;
endtask

task automatic fifo_mon();
  fork
    forever
      begin
        if( wr && !wr_full )
          ref_fifo.push_back( wr_data );
        @( posedge wr_clk );
      end
  join_none
  forever
    begin
      if( rd && !rd_empty )
        begin
          ref_word = ref_fifo.pop_front( );
          if( ref_word != rd_data )
            begin
              $display( "Wrong data! Was %0h, must be %0h", rd_data, ref_word );
              @( posedge rd_clk );
              $stop();
            end
        end
      @( posedge rd_clk );
    end
endtask

dc_fifo #(
  .DATA_WIDTH      ( DATA_WIDTH    ),
  .WORDS_AMOUNT    ( WORDS_AMOUNT  )
) dut (
  .wr_clk_i        ( wr_clk        ),
  .rd_clk_i        ( rd_clk        ),
  .rst_i           ( rst           ),
  .wr_i            ( wr            ),
  .wr_data_i       ( wr_data       ),
  .rd_i            ( rd            ),
  .rd_data_o       ( rd_data       ),
  .wr_used_words_o ( wr_used_words ),
  .wr_full_o       ( wr_full       ),
  .wr_empty_o      ( wr_empty      ),
  .rd_used_words_o ( rd_used_words ),
  .rd_full_o       ( rd_full       ),
  .rd_empty_o      ( rd_empty      )
);

initial
  begin
    fork
      wr_clk_gen();
      rd_clk_gen();
      fifo_mon();
    join_none
    apply_rst();
    fork
      repeat( OP_AMOUNT )
        if( $urandom_range( 1 ) )
          put_word_in_fifo( $urandom_range( 2**DATA_WIDTH - 1 ) );
        else
          @( posedge wr_clk );
      repeat( OP_AMOUNT )
        if( $urandom_range( 1 ) )
          get_word_from_fifo( rd_word );
        else
          @( posedge rd_clk );
    join_any
    repeat( 10 )
      fork
        @( posedge wr_clk );
        @( posedge rd_clk );
      join_any
    $display( "Everything is fine." );
    $stop();
  end

endmodule
