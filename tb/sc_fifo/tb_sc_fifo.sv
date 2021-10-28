`timescale 1 ps / 1 ps

module tb_sc_fifo;

parameter int DATA_WIDTH   = 2;
parameter int WORDS_AMOUNT = 2;
parameter int CLK_T        = 10000;
parameter int ADDR_WIDTH   = $clog2( WORDS_AMOUNT );

// Amount of operation to perform
parameter int OP_AMOUNT    = 1_000_000;

bit                      clk;
bit                      rst;
bit                      wr;
bit [DATA_WIDTH - 1 : 0] wr_data;
bit                      rd;
bit [DATA_WIDTH - 1 : 0] rd_data;
bit [ADDR_WIDTH : 0]     used_words;
bit                      full;
bit                      empty;

// What we get from queue
bit [DATA_WIDTH - 1 : 0] ref_word;
// What we get from FIFO
bit [DATA_WIDTH - 1 : 0] rd_word;
// We use SystemVerilog queue to compare with FIFO
bit [DATA_WIDTH - 1 : 0] ref_fifo [$];

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
  while( full )
    @( posedge clk );
  wr            <= 1'b1;
  wr_data       <= word;
  @( posedge clk );
  wr            <= 1'b0;
endtask

task automatic get_word_from_fifo(
  output bit [DATA_WIDTH - 1 : 0] word
);
  while( empty )
    @( posedge clk );
  rd            <= 1'b1;
  @( posedge clk );
  word           = rd_data;
  rd            <= 1'b0;
endtask

task automatic fifo_mon();
  forever
    begin
      if( wr && !full )
        ref_fifo.push_back( wr_data );
      if( rd && !empty )
        begin
          ref_word = ref_fifo.pop_front( );
          if( ref_word != rd_data )
            begin
              $display( "Wrong data! Was %0h, must be %0h", rd_data, ref_word );
              @( posedge clk );
              $stop();
            end
        end
      @( posedge clk );
    end
endtask

sc_fifo #(
  .DATA_WIDTH   ( DATA_WIDTH   ),
  .WORDS_AMOUNT ( WORDS_AMOUNT ),
  .USE_LUTS     ( 1            )
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
      fifo_mon();
    join_none
    apply_rst();
    fork
      // Two parallel processess with 50/50 probability in every tick
      // trying to perform read and write operations
      repeat( OP_AMOUNT )
        if( $urandom_range( 1 ) )
          put_word_in_fifo( $urandom_range( 2**DATA_WIDTH - 1 ) );
        else
          @( posedge clk );
      repeat( OP_AMOUNT )
        if( $urandom_range( 1 ) )
          get_word_from_fifo( rd_word );
        else
          @( posedge clk );
    join_any
    repeat( 10 )
      @( posedge clk );
    $display( "Everything is fine." );
    $stop();
  end

endmodule
