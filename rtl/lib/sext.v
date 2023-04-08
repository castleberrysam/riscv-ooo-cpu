module sext #(
  parameter OUT = 32,
  parameter IN = 16
  )(
  input [IN-1:0]   in,
  output [OUT-1:0] out);

  assign out = {{(OUT-IN){in[IN-1]}}, in};

endmodule
