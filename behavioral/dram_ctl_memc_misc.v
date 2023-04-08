module dram_ctl_memc_misc(
  input      clk,
  input      rst,
  input      rst_tg_mc,
  output reg reset);

  always @(posedge clk)
    reset <= rst | rst_tg_mc;

endmodule
