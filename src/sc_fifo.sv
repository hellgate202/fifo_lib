module sc_fifo #(
  parameter int DATA_WIDTH   = 8,
  parameter int WORDS_AMOUNT = 8,
  parameter int ADDR_WIDTH   = $clog2( WORDS_AMOUNT ), 
  parameter int USE_LUTS     = 0
)(
  input                       clk_i,
  input                       rst_i,
  input                       wr_i,
  input  [DATA_WIDTH - 1 : 0] wr_data_i,
  input                       rd_i,
  output [DATA_WIDTH - 1 : 0] rd_data_o,
  output [ADDR_WIDTH : 0]     used_words_o,
  output                      full_o,
  output                      empty_o
);

logic [ADDR_WIDTH - 1 : 0] wr_addr;
logic                      wr_req;
logic                      full;
logic [ADDR_WIDTH - 1 : 0] rd_addr;
logic                      rd_req;
logic                      empty;
logic [ADDR_WIDTH : 0]     used_words;
// Moving data from RAM to output reg
logic                      rd_en;
// There is unread data in RAM
logic                      data_in_ram;
// There is unread data in output reg
logic                      data_in_o_reg;
// More than one word in RAM
logic                      svrl_w_in_mem;
// First word in FIFO datapath after empty
logic                      first_word;

assign full_o       = full;
assign empty_o      = empty;
assign used_words_o = used_words;
// Protection from write into full FIFO.
assign wr_req       = wr_i && !full;
// Protection from read from empty FIFO.
assign rd_req       = rd_i && !empty;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    used_words <= '0;
  else
    if( wr_req && !rd_req )
      used_words <= used_words + 1'b1;
    else
      if( !wr_req && rd_req )
        used_words <= used_words - 1'b1;

// Relationship of used_words signal to words amount in RAM and
// data_in_ram and data_in_o_reg behavior
// used_words signal represents how many words we have stored in FIFO
// But FIFO consists not only of RAM memory, but also of output register.
// 0. used_words == 0; no data was written neither to RAM nor to output reg
// 1. used_words == 1; one word of data was written either to RAM or to
//    output reg. After being read FIFO becomes empty.
//                   __    __    __    __    __    __
//    clk_i         /  \__/  \__/  \__/  \__/  \__/  \__
//                   _____
//    wr_i          /     \_____________________________
//                                           _____
//    rd_i          ________________________/     \_____
//                         _____
//    data_in_ram   ______/     \_______________________
//                               _________________
//    data_in_o_reg ____________/                 \_____
//                  ______ _______________________ _____
//    used_words    ___0__X____________1__________X__0__
//
// 2. used_words == 2; one word of data was written both to RAM and to output
//    reg. After being read only word in output reg is left
//                   __    __    __    __    __    __
//    clk_i         /  \__/  \__/  \__/  \__/  \__/  \__
//                   ___________
//    wr_i          /           \_______________________
//                                           _____
//    rd_i          ________________________/     \_____
//                         _______________________
//    data_in_ram   ______/                       \_____
//                               _______________________
//    data_in_o_reg ____________/
//                  ______ _____ ___________ ___________
//    used_words    ___0__X__1__X_____2_____X_____1_____
//
// 3. used_words > 2; several words of data was written both to RAM and one
//    word to output reg. After being read, at least one word will left in RAM
//    and more than one word will left in FIFO
//                   __    __    __    __    __    __
//    clk_i         /  \__/  \__/  \__/  \__/  \__/  \__
//                   _________________
//    wr_i          /                 \_________________
//                                           _____
//    rd_i          ________________________/     \_____
//                         _____________________________
//    data_in_ram   ______/
//                               _______________________
//    data_in_o_reg ____________/
//                  ______ _____ _____ _____ _____ _____
//    used_words    ___0__X__1__X__2__X__3__X__2__X__1__

assign svrl_w_in_mem = used_words > 'd2;
assign first_word    = data_in_ram && !data_in_o_reg;

// FIFO data output is provided by the output register im RAM 
// module. In its turn the output register recieves data from
// RAM. Output register will require new data in two cases:
// 1. When read operation is requested
// 2. When first word is written into FIFO after being empied
always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    data_in_o_reg <= '0;
  else
    if( rd_req || first_word )
      data_in_o_reg <= data_in_ram;

// Pulling data from ram to output register
assign rd_en = ( first_word || rd_req ) && data_in_ram;
assign empty = !data_in_o_reg;

// There are 2 cases when data in RAM can be depleted:
// 1. Read request will pull one word from RAM and after that 
//    there will be another word if it was read-during-write operation
//    or if there more than one word in RAM
// 2. If we are writing to empty FIFO, then on the next tick data will move
//    to the output register (first_word condition)
// In other cases if there is no data in RAM wr_req will update data_in_ram
always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    data_in_ram <= '0;
  else
    if( rd_req )
      data_in_ram <= wr_req || svrl_w_in_mem;
    else
      if( first_word || !data_in_ram )
        data_in_ram <= wr_req;

// In normal case we must increment write address every time we write data.
// But here we have an output reg where we can also store data.
// Purpose of incrementing write address is to preserve unread data in memory.
// 1. We don't need to increment write address on empty FIFO (used_words == 0), 
// because next tick data will move from memory to output register
// 2. Due to the same reason, if used_words == 1 and this word is in the output
// reg, and read request is applied then it will be free next tick and new data
// can pass to the output register.
// Except two cases above write address will increment if write request is
// applied
always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    wr_addr <= '0;
  else
    if( wr_req )
      wr_addr <= wr_addr + 1'b1;

// When we apply read request we need to increment read address to move to
// next data position if it is present.
// Read requests are only valid when there is data at the output register
// (i.e. FIFO is not empty to outside logic).
// The following condition reperesnts, that if after we read data from
// output register there will be another word in memory (data_in_ram == 1)
always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    rd_addr <= '0;
  else
    if( rd_en )
      rd_addr <= rd_addr + 1'b1;

always_ff @( posedge clk_i, posedge rst_i )
  if( rst_i )
    full <= '0;
  else
    // One word more than in the memory, due to output register
    if( !rd_req && wr_req )
      full <= used_words == ( ADDR_WIDTH + 1 )'( 2**ADDR_WIDTH - 1 );
    else
      if( rd_req && !wr_req )
        full <= 1'b0;

dual_port_ram #(
  .DATA_WIDTH ( DATA_WIDTH ),
  .ADDR_WIDTH ( ADDR_WIDTH ),
  .USE_LUTS   ( USE_LUTS   )
) ram (
  .wr_clk_i   ( clk_i      ),
  .wr_addr_i  ( wr_addr    ),
  .wr_data_i  ( wr_data_i  ),
  .wr_i       ( wr_req     ),
  .rd_clk_i   ( clk_i      ),
  .rd_addr_i  ( rd_addr    ),
  .rd_data_o  ( rd_data_o  ),
  .rd_i       ( rd_en      )
);

endmodule
