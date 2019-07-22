// For code explanation refer to sc_fifo.sv
module axi4_stream_sc_fifo_pth #(
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
logic [ADDR_WIDTH : 0]     used_words;
logic                      rd_en;
logic                      data_in_ram;
logic                      data_in_o_reg;
logic                      svrl_w_in_mem;
logic                      mem_n_empty;
logic                      first_word;

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
assign wr_req        = pkt_i.tvalid && pkt_i.tready;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    used_words <= '0;
  else
    if( wr_req && !rd_req )
      used_words <= used_words + 1'b1;
    else
      if( !wr_req && rd_req )
        used_words <= used_words - 1'b1;

assign svrl_w_in_mem = used_words > 'd2;
assign mem_n_empty   = used_words > 'd1;
assign first_word    = data_in_ram && !data_in_o_reg;
assign pkt_i.tready  = !full;
assign pkt_o.tvalid  = data_in_o_reg;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    data_in_o_reg <= '0;
  else
    if( rd_req || first_word )
      data_in_o_reg <= data_in_ram;

assign rd_en = first_word || rd_req;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    data_in_ram <= '0;
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
    if( wr_req && ( data_in_ram || !rd_req && data_in_o_reg ) )
      wr_addr <= wr_addr + 1'b1;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    rd_addr <= '0;
  else
    if( rd_req && data_in_ram )
      rd_addr <= rd_addr + 1'b1;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    full <= '0;
  else
    // One word more than in the memory, due to output register
    if( !rd_req && wr_req )
      full <= used_words == ( 2**ADDR_WIDTH );
    else
      if( rd_req && !wr_req )
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
