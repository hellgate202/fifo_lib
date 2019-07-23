`include "../../lib/axi4_lib/src/class/AXI4StreamMaster.sv"
`include "../../lib/axi4_lib/src/class/AXI4StreamSlave.sv"

`timescale 1 ps / 1 ps

module tb_axi4_stream_fifo;

parameter int WORDS_AMOUNT   = 32;
parameter int DATA_WIDTH     = 32;
parameter int USER_WIDTH     = 1;
parameter int DEST_WIDTH     = 1;
parameter int ID_WIDTH       = 1;

parameter int RANDOM_TVALID  = 1;
parameter int RANDOM_TREADY  = 1;
parameter int PKTS_AMOUNT    = 1000;
parameter int MAX_PKT_SIZE_B = 132;
parameter int MIN_PKT_SIZE_B = 136;
parameter int SMART          = 1;

parameter int CLK_T          = 5000;

parameter int ADDR_WIDTH     = $clog2( WORDS_AMOUNT );

typedef bit [7 : 0] pkt_q [$];

bit                  clk;
bit                  rst;
bit                  full;
bit                  empty;
bit                  drop;
bit [ADDR_WIDTH : 0] used_words;
bit [ADDR_WIDTH : 0] pkts_amount;

pkt_q tx_pkt;
pkt_q rx_pkt;
pkt_q tx_pkt_pool [$];
pkt_q rx_pkt_pool [$];

task automatic clk_gen();
  forever
    begin
      #( CLK_T / 2 );
      clk = !clk;
    end
endtask

task automatic apply_rst();
  @( posedge clk );
  rst = 1'b1;
  @( posedge clk );
  rst = 1'b0;
endtask

task automatic pkt_check();
  forever
    if( rx_mbx.num() )
      begin
        rx_mbx.get( rx_pkt );
        for( int i = 0; i < rx_pkt_pool.size(); i++ )
          if( rx_pkt == rx_pkt_pool[i] )
            begin
              rx_pkt_pool.delete(i);
              break;
            end
          else
            if( i == ( rx_pkt_pool.size() - 1 ) )
              begin
                $display( "Corrupted packet" );
                for( int i = 0; i < rx_pkt.size(); i++ )
                  $write( "%0h ", rx_pkt[i] );
                  $write( "\n" );
                $stop();
              end
      end
    else
      @( posedge clk );
endtask

function automatic pkt_q create_pkt(
  int pkt_size
);
  pkt_q pkt;
  
  for( int i = 0; i < pkt_size; i++ )
    pkt.push_back( $urandom_range( 255 ) );

  return pkt;
endfunction

mailbox rx_mbx = new();

axi4_stream_if #(
  .DATA_WIDTH ( DATA_WIDTH ),
  .ID_WIDTH   ( ID_WIDTH   ),
  .DEST_WIDTH ( DEST_WIDTH ),
  .USER_WIDTH ( USER_WIDTH )
) pkt_i (
  .aclk       ( clk        ),
  .aresetn    ( !rst       )
);

AXI4StreamMaster #(
  .DATA_WIDTH    ( DATA_WIDTH    ),
  .ID_WIDTH      ( ID_WIDTH      ),
  .DEST_WIDTH    ( DEST_WIDTH    ),
  .USER_WIDTH    ( USER_WIDTH    ),
  .RANDOM_TVALID ( RANDOM_TVALID )
) pkt_sender;

axi4_stream_if #(
  .DATA_WIDTH ( DATA_WIDTH ),
  .ID_WIDTH   ( ID_WIDTH   ),
  .DEST_WIDTH ( DEST_WIDTH ),
  .USER_WIDTH ( USER_WIDTH )
) pkt_o (
  .aclk       ( clk        ),
  .aresetn    ( !rst       )
);

AXI4StreamSlave #(
  .DATA_WIDTH    ( DATA_WIDTH    ),
  .ID_WIDTH      ( ID_WIDTH      ),
  .DEST_WIDTH    ( DEST_WIDTH    ),
  .USER_WIDTH    ( USER_WIDTH    ),
  .RANDOM_TREADY ( RANDOM_TREADY )
) pkt_receiver;

axi4_stream_fifo #(
  .DATA_WIDTH    ( DATA_WIDTH         ),
  .USER_WIDTH    ( USER_WIDTH         ),
  .DEST_WIDTH    ( DEST_WIDTH         ),
  .ID_WIDTH      ( ID_WIDTH           ),
  .WORDS_AMOUNT  ( WORDS_AMOUNT       ),
  .SMART         ( SMART              )
) DUT (
  .clk_i         ( clk                ),
  .rst_i         ( rst                ),
  .full_o        ( full               ),
  .empty_o       ( empty              ),
  .drop_o        ( drop               ),
  .used_words_o  ( used_words         ),
  .pkts_amount_o ( pkts_amount        ),
  .pkt_i         ( pkt_i              ),
  .pkt_o         ( pkt_o              )
);

initial
  begin
    pkt_sender   = new( .axi4_stream_if_v ( pkt_i ) );
    pkt_receiver = new ( .axi4_stream_if_v ( pkt_o  ),
                         .rx_data_mbx      ( rx_mbx )
                       );
    fork
      clk_gen();
      pkt_check();
    join_none
    apply_rst();
    repeat( PKTS_AMOUNT )
      begin
        tx_pkt = create_pkt( $urandom_range( MAX_PKT_SIZE_B, MIN_PKT_SIZE_B ) );
        tx_pkt_pool.push_back( tx_pkt );
      end
    rx_pkt_pool = tx_pkt_pool;
    for( int i = 0; i < PKTS_AMOUNT; i++ )
      begin
        tx_pkt = tx_pkt_pool[i];
        pkt_sender.tx_data( tx_pkt );
        wait( pkt_sender.pkt_end.triggered );
      end
    @( posedge clk );
    while( pkt_o.tvalid )
      @( posedge clk );
    @( posedge clk );
    @( posedge clk );
    $display( "%0d packets were droped", rx_pkt_pool.size() );
    $display( "Everything is fine." );
    repeat( 10 )
      @( posedge clk );
    $stop();
  end

endmodule
