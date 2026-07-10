module ddr3 (
  input rst_n,
  input ck,
  input ck_n,
  input cke,
  input cs_n,
  input ras_n,
  input cas_n,
  input we_n,
  inout [1:0] dm_tdqs,
  input [2:0] ba,
  input [13:0] addr,
  inout [15:0] dq,
  inout [1:0] dqs,
  inout [1:0] dqs_n,
  output [1:0] tdqs_n,
  input odt);

endmodule
