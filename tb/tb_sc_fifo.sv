`timescale 1 ps / 1 ps

module tb_sc_fifo;

parameter int DATA_WIDTH   = 8;
parameter int WORDS_AMOUNT = 8;
parameter int CLK_T        = 10000;
parameter int ADDR_WIDTH   = $clog2( WORDS_AMOUNT );
parameter int FIFO_CAP     = 2**ADDR_WIDTH;

bit                      clk;
bit                      rst;
bit                      wr;
bit [DATA_WIDTH - 1 : 0] wr_data;
bit                      rd;
bit [DATA_WIDTH - 1 : 0] rd_data;
bit [ADDR_WIDTH : 0]     used_words;
bit                      full;
bit                      empty;

bit [DATA_WIDTH - 1 : 0] rd_word;
bit [DATA_WIDTH - 1 : 0] ref_queue;

task automatic clk_gen();
  forever
    begin
      #( CLK_T / 2 );
      clk = ~clk;
    end
endtask

task automatic apply_rst();
  @( posedge clk );
  rst <= 1'b1;
  @( posedge clk );
  rst <= 1'b0;
endtask

task automatic put_word_in_fifo(
  input bit [DATA_WIDTH - 1 : 0] word
);
  if( ref_queue.size() != used_words )
    begin
      $display( "FIFO used_words_o signal is %0d", used_words );
      $dsiplay( "But should be %0d", ref_queue.size() );
      $stop();
    end
  while( full )
    begin
      if( ref_queue.size() != FIFO_CAP )
        begin
          $display( "FIFO asserted full signal, but it contatins only %0d words", ref_queue.size() );
          $display( "FIFO capacity is %0d", FIFO_CAP );
          $stop();
        end
      else
        @( posedge clk );
    end
  wr      <= 1'b1;
  wr_data <= word;
  ref_queue.push_back( word );
  @( posedge clk );
  wr      <= 1'b0;
endtask

task automatic get_word_from_fifo(
  output bit [DATA_WIDTH - 1 : 0] word
);
  while( empty )
    @( posedge clk );
  word  = rd_data;
  rd   <= 1'b1;
  @( posedge clk );
  rd   <= 1'b0;
endtask

sc_fifo #(
  .DATA_WIDTH   ( DATA_WIDTH   ),
  .WORDS_AMOUNT ( WORDS_AMOUNT )
) dut (
  .clk_i        ( clk          ),
  .rst_i        ( rst          ),
  .wr_i         ( wr           ),
  .wr_data_i    ( wr_data      ),
  .rd_i         ( rd           ),
  .rd_data_o    ( rd_data      ),
  .used_words_o ( used_words   ),
  .full_o       ( full         ),
  .empty_o      ( empty        )
);

initial
  begin
    fork
      clk_gen();
    join_none
    apply_rst();
    repeat( 8 )
      put_word_in_fifo( $urandom_range( 255 ) );
    @( posedge clk );
    repeat( 6 )
      get_word_from_fifo( rd_word );
    @( posedge clk );
    repeat( 2 )
      get_word_from_fifo( rd_word );
    put_word_in_fifo( $urandom_range( 255 ) );
    @( posedge clk );
    fork
      repeat( 5 )
        put_word_in_fifo( $urandom_range( 255 ) );
    join_none
    repeat( 6 )
      get_word_from_fifo( rd_word );
    repeat( 10 )
      @( posedge clk );
    $stop();
  end

endmodule
