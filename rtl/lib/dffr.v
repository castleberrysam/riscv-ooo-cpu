module dffr #(
  parameter         W = 1,
  parameter [W-1:0] RV = 0
  )(
  output reg [W-1:0] q,
  input [W-1:0]      d,
  input              clk,
  input              en,
  input              rst);

  always @(posedge clk)
    if(rst)
      q <= RV;
    else if(en)
      q <= d;

endmodule
