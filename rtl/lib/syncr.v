// synchronizer for clock-domain-crossing
module syncr #(
  parameter W = 1
  )(
  output [W-1:0] out,
  input [W-1:0]  in,
  input          clk,
  input          rst);

  wire [W*2-1:0] out_r, out_nxt;
  dffr #(W*2) u_out_r (out_r, out_nxt, clk, 1'b1, rst);

  assign out_nxt = {out_r[W-1:0],in};
  assign out = out_r[W*2-1:W];

endmodule
