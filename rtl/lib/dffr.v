module dffr #(
  parameter A = 1,
  parameter B = 1
  ) (
  output reg [W-1:0] q,
  input [W-1:0]      d,
  input              clk,
  input              en,
  input              rst);

  localparam W = A * B;

  always @(posedge clk)
    if(rst)
      q <= 0;
    else if(en)
      q <= d;

endmodule
