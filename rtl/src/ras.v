// return address stack
module ras (
  input         clk,
  input         rst,

  // brpred interface
  input         brpred_ras_push,
  input [31:2]  brpred_ras_addr,

  input         brpred_ras_pop,
  output        ras_brpred_valid,
  output [31:2] ras_brpred_target,

  // rob interface
  input         rob_flush,
  input         rob_ret_branch,
  input         rob_ret_raspush,
  input         rob_ret_raspop,
  input [31:2]  rob_ret_addr);

  wire        arch_retaddr_update;
  wire        arch_retaddr_v_nxt;
  wire [31:2] arch_retaddr_nxt;
  wire        arch_retaddr_v_r;
  wire [31:2] arch_retaddr_r;

  wire        spec_retaddr_update;
  wire        spec_retaddr_v_nxt;
  wire [31:2] spec_retaddr_nxt;
  wire        spec_retaddr_v_r;
  wire [31:2] spec_retaddr_r;

  assign arch_retaddr_update = rob_ret_branch & rob_ret_raspush;
  assign arch_retaddr_v_nxt = (arch_retaddr_v_r | rob_ret_branch & rob_ret_raspush) &
                              ~(rob_ret_branch & rob_ret_raspop);
  assign arch_retaddr_nxt = rob_ret_addr + 30'd1;

  dffr      u_arch_retaddr_v_r (arch_retaddr_v_r, arch_retaddr_v_nxt, clk, 1'b1, rst);
  dff #(30) u_arch_retaddr_r   (arch_retaddr_r,   arch_retaddr_nxt,   clk, arch_retaddr_update);

  assign spec_retaddr_update = rob_flush | brpred_ras_push;
  assign spec_retaddr_v_nxt = rob_flush ? arch_retaddr_v_nxt :
                                          (spec_retaddr_v_r | brpred_ras_push) & ~brpred_ras_pop;
  assign spec_retaddr_nxt = rob_flush ? (arch_retaddr_update ? arch_retaddr_nxt : arch_retaddr_r) :
                                        (brpred_ras_addr + 30'd1);

  dffr      u_spec_retaddr_v_r (spec_retaddr_v_r, spec_retaddr_v_nxt, clk, 1'b1, rst);
  dff #(30) u_spec_retaddr_r   (spec_retaddr_r,   spec_retaddr_nxt,   clk, spec_retaddr_update);

  assign ras_brpred_valid = spec_retaddr_v_r;
  assign ras_brpred_target = spec_retaddr_r;

endmodule
