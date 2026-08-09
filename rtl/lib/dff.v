module dff #(
  parameter A = 1,
  parameter B = 1
  ) (
  output reg [A*B-1:0] q,
  input [A*B-1:0]      d,
  input                clk,
  input                en);

  always @(posedge clk)
    if(en)
      q <= d;

endmodule
