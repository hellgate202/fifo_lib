module dc_fifo #(
  parameter int DATA_WIDTH   = 8,
  parameter int WORDS_AMOUNT = 8,
  parameter int ADDR_WIDTH   = $clog2( WORDS_AMOUNT )
)(
  input                       wr_clk_i,
  input  [DATA_WIDTH - 1 : 0] wr_data_i,
  input                       wr_i,
  output [ADDR_WIDTH : 0]     wr_used_words_o,
  output                      wr_full_o,
  output                      wr_empty_o,
  input                       rd_clk_i,
  output [DATA_WIDTH - 1 : 0] rd_data_o,
  input                       rd_i,
  output [ADDR_WIDTH : 0]     rd_used_words_o,
  output                      rd_full_o,
  output                      rd_empty_o,
  input                       rst_i
);

logic                      wr_req;
logic [ADDR_WIDTH : 0]     wr_used_words;
logic                      wr_full;
logic                      wr_empty;
// Write pointer on write clock
logic [ADDR_WIDTH : 0]     wr_ptr_wr_clk;
// Combinational gray-encoded write pointer on write clock
logic [ADDR_WIDTH : 0]     wr_ptr_gray_wr_clk_comb;
// Gray-encoded write pointer on write clock
logic [ADDR_WIDTH : 0]     wr_ptr_gray_wr_clk;
// Gray-encoded write pointer on read clock
logic [ADDR_WIDTH : 0]     wr_ptr_gray_rd_clk;
// Gray-encoded write pointer on read clock 1 tick delayed
logic [ADDR_WIDTH : 0]     wr_ptr_gray_rd_clk_mtstb;
// Combinational write pointer on read clock
logic [ADDR_WIDTH : 0]     wr_ptr_rd_clk_comb;
// Wrtie pointer on read clock
logic [ADDR_WIDTH : 0]     wr_ptr_rd_clk;
logic [ADDR_WIDTH - 1 : 0] wr_addr;

logic                      rd_req;
logic [ADDR_WIDTH : 0]     rd_used_words;
logic                      rd_full;
logic                      rd_empty;
// Read pointer on read clock
logic [ADDR_WIDTH : 0]     rd_ptr_rd_clk;
// Combinational gray-encoded read pointer on read clock
logic [ADDR_WIDTH : 0]     rd_ptr_gray_rd_clk_comb;
// Gray-encoded read pointer on read clock
logic [ADDR_WIDTH : 0]     rd_ptr_gray_rd_clk;
// Gray-encoded read pointer on write clock
logic [ADDR_WIDTH : 0]     rd_ptr_gray_wr_clk;
// Gray-encoded read pointer on write clock 1 tick delayed
logic [ADDR_WIDTH : 0]     rd_ptr_gray_wr_clk_mtstb;
// Combinational read pointer on write clock
logic [ADDR_WIDTH : 0]     rd_ptr_wr_clk_comb;
// Read pointer on write clock
logic [ADDR_WIDTH : 0]     rd_ptr_wr_clk;
logic [ADDR_WIDTH - 1 : 0] rd_addr;
// Moving data from RAM to output reg
logic                      rd_en;
// There is unread data in RAM
logic                      data_in_ram;
// There is unread data in output reg
logic                      data_in_o_reg;

// Synchronizing reset with read clock
logic                      rst_rd_clk_d1;
logic                      rst_rd_clk_d2;
logic                      rst_rd_clk;

// Synchronizing reset with write clock
logic                      rst_wr_clk_d1;
logic                      rst_wr_clk_d2;
logic                      rst_wr_clk;

// Asynchronous assert and synchronous deassert
always_ff @( posedge rd_clk_i, posedge rst_i )
  if( rst_i )
    begin
      rst_rd_clk_d1 <= 1'b1;
      rst_rd_clk_d2 <= 1'b1;
    end
  else
    begin
      rst_rd_clk_d1 <= 1'b0;
      rst_rd_clk_d2 <= rst_rd_clk_d1;
    end

assign rst_rd_clk = rst_rd_clk_d2;

always_ff @( posedge wr_clk_i, posedge rst_i )
  if( rst_i )
    begin
      rst_wr_clk_d1 <= 1'b1;
      rst_wr_clk_d2 <= 1'b1;
    end
  else
    begin
      rst_wr_clk_d1 <= 1'b0;
      rst_wr_clk_d2 <= rst_wr_clk_d1;
    end

assign rst_wr_clk = rst_wr_clk_d2;

assign wr_used_words_o = wr_used_words;
assign wr_full_o       = wr_full;
assign wr_empty_o      = wr_empty;
assign rd_used_words_o = rd_used_words;
assign rd_full_o       = rd_full;
assign rd_empty_o      = rd_empty;

// Protection from write to full FIFO
assign wr_req          = wr_i && !wr_full;
assign wr_addr         = wr_ptr_wr_clk[ADDR_WIDTH - 1 : 0];
// Protection from read from empty FIFO
assign rd_req          = rd_i && !rd_empty;
assign rd_addr         = rd_ptr_rd_clk[ADDR_WIDTH - 1 : 0];

// Basic address counter
always_ff @( posedge wr_clk_i, posedge rst_wr_clk )
  if( rst_wr_clk )
    wr_ptr_wr_clk <= '0;
  else
    if( wr_req )
      wr_ptr_wr_clk <= wr_ptr_wr_clk + 1'b1;

// Conversion to the Gray code
bin2gray #(
  .DATA_WIDTH ( ADDR_WIDTH + 1          )
) wr_ptr_to_gray_enc (
  .bin_i      ( wr_ptr_wr_clk           ),
  .gray_o     ( wr_ptr_gray_wr_clk_comb )
);

always_ff @( posedge wr_clk_i, posedge rst_wr_clk )
  if( rst_wr_clk )
    wr_ptr_gray_wr_clk <= '0;
  else
    wr_ptr_gray_wr_clk <= wr_ptr_gray_wr_clk_comb;

// Clock domain crossing
always_ff @( posedge rd_clk_i, posedge rst_rd_clk )
  if( rst_rd_clk )
    wr_ptr_gray_rd_clk <= '0;
  else
    wr_ptr_gray_rd_clk <= wr_ptr_gray_wr_clk;

// Delay for metastability protection
always_ff @( posedge rd_clk_i, posedge rst_rd_clk )
  if( rst_rd_clk )
    wr_ptr_gray_rd_clk_mtstb <= '0;
  else
    wr_ptr_gray_rd_clk_mtstb <= wr_ptr_gray_rd_clk;

// Gray code decoding
gray2bin #(
  .DATA_WIDTH ( ADDR_WIDTH + 1           )
) wr_ptr_from_gray_dec (
  .gray_i     ( wr_ptr_gray_rd_clk_mtstb ),
  .bin_o      ( wr_ptr_rd_clk_comb       )
);

always_ff @( posedge rd_clk_i, posedge rst_rd_clk )
  if( rst_rd_clk )
    wr_ptr_rd_clk <= '0;
  else
    wr_ptr_rd_clk <= wr_ptr_rd_clk_comb;

// Everything is the same as for write pointer
always_ff @( posedge rd_clk_i, posedge rst_rd_clk )
  if( rst_rd_clk )
    rd_ptr_rd_clk <= '0;
  else
    if( rd_en )
      rd_ptr_rd_clk <= rd_ptr_rd_clk + 1'b1;

bin2gray #(
  .DATA_WIDTH ( ADDR_WIDTH + 1          )
) rd_ptr_to_gray_enc (
  .bin_i      ( rd_ptr_rd_clk           ),
  .gray_o     ( rd_ptr_gray_rd_clk_comb )
);

always_ff @( posedge rd_clk_i, posedge rst_rd_clk )
  if( rst_rd_clk )
    rd_ptr_gray_rd_clk <= '0;
  else
    rd_ptr_gray_rd_clk <= rd_ptr_gray_rd_clk_comb;

always_ff @( posedge wr_clk_i, posedge rst_wr_clk )
  if( rst_wr_clk )
    rd_ptr_gray_wr_clk <= '0;
  else
    rd_ptr_gray_wr_clk <= rd_ptr_gray_rd_clk;

always_ff @( posedge wr_clk_i, posedge rst_wr_clk )
  if( rst_wr_clk )
    rd_ptr_gray_wr_clk_mtstb <= '0;
  else
    rd_ptr_gray_wr_clk_mtstb <= rd_ptr_gray_wr_clk;

gray2bin #(
  .DATA_WIDTH ( ADDR_WIDTH + 1           )
) rd_ptr_from_gray_dec (
  .gray_i     ( rd_ptr_gray_wr_clk_mtstb ),
  .bin_o      ( rd_ptr_wr_clk_comb       )
);

always_ff @( posedge wr_clk_i, posedge rst_wr_clk )
  if( rst_wr_clk )
    rd_ptr_wr_clk <= '0;
  else
    rd_ptr_wr_clk <= rd_ptr_wr_clk_comb;


// Write and read pointers are one bit wider than memory address.
// When they are equal that means, that we read as much data as we have
// written.
// We need to detect when memory address surpass its highest value.
// For example on 3-bit wide address we have 3'h2 read address and 3'h7 write
// address after two write operations it will become 3'h2. And by common sense
// we declare that it is full, but by the rule mentioned above it is empty.
// That's why we need an extra MSB to indicate that we are catching read
// pointer from behind if MSBs are not equal.
assign wr_full       = wr_ptr_wr_clk[ADDR_WIDTH]         != rd_ptr_wr_clk[ADDR_WIDTH] &&
                       wr_ptr_wr_clk[ADDR_WIDTH - 1 : 0] == rd_ptr_wr_clk[ADDR_WIDTH - 1 : 0];
assign rd_full       = rd_ptr_rd_clk[ADDR_WIDTH]         != wr_ptr_rd_clk[ADDR_WIDTH] &&
                       rd_ptr_rd_clk[ADDR_WIDTH - 1 : 0] == wr_ptr_rd_clk[ADDR_WIDTH - 1 : 0];

assign wr_used_words = wr_ptr_wr_clk - rd_ptr_wr_clk;
assign rd_used_words = wr_ptr_rd_clk - rd_ptr_rd_clk;
// If MSB and address are the same, then we are empty
assign wr_empty      = wr_ptr_wr_clk == rd_ptr_wr_clk;
// Just like in sc_fifo
assign rd_empty      = !data_in_o_reg;

// This method ad some latency in status signals response, but there is no
// other choice, because of clock crossing
assign data_in_ram   = wr_ptr_rd_clk != rd_ptr_rd_clk;

always_ff @( posedge rd_clk_i, posedge rst_i )
  if( rst_i )
    data_in_o_reg <= '0;
  else
    if( rd_req || !data_in_o_reg )
      data_in_o_reg <= data_in_ram;

assign rd_en = data_in_ram && ( !data_in_o_reg || rd_req );

dual_port_ram #(
  .DATA_WIDTH ( DATA_WIDTH ),
  .ADDR_WIDTH ( ADDR_WIDTH )
) ram (
  .wr_clk_i   ( wr_clk_i   ),
  .wr_addr_i  ( wr_addr    ),
  .wr_data_i  ( wr_data_i  ),
  .wr_i       ( wr_req     ),
  .rd_clk_i   ( rd_clk_i   ),
  .rd_addr_i  ( rd_addr    ),
  .rd_data_o  ( rd_data_o  ),
  .rd_i       ( rd_en      )
);

endmodule
