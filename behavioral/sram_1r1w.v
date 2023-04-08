module sram_1r1w #(
  parameter ADDRW = 8,
  parameter DATAW = 8,
  parameter DELAY = 2
  )(

  input                  rd_clk,
  input                  rd_en,
  input [ADDRW-1:0]      rd_addr,
  output reg [DATAW-1:0] rd_data,

  input                  wr_clk,
  input                  wr_en,
  input [ADDRW-1:0]      wr_addr,
  input [DATAW-1:0]      wr_data);

  reg [DATAW-1:0] mem [0:(1<<ADDRW)-1];

  generate
    if(DELAY == 2) begin
      reg             rd_en_r;
      reg [ADDRW-1:0] rd_addr_r;
      reg [DATAW-1:0] rd_data_r;
      always @(posedge rd_clk) begin
        rd_en_r <= rd_en;
        rd_addr_r <= rd_addr;
        if(rd_en_r)
          rd_data <= mem[rd_addr_r];
      end
    end else
      always @(posedge rd_clk)
        if(rd_en)
          rd_data <= mem[rd_addr];
  endgenerate

  always @(posedge wr_clk)
    if(wr_en)
      mem[wr_addr] <= wr_data;

endmodule
