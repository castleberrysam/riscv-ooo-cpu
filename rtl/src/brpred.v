// branch predictor top level
module brpred #(
  parameter BTB_NUM_SETS = 256,
  parameter BTB_NUM_WAYS = 2,
  parameter PHT_IDX_MSB = 13,
  parameter BPATTR_WIDTH = 3
  )(
  input                     clk,
  input                     rst,

  // fetch interface
  input                     fetch_brpred_ready,
  output                    brpred_fetch_valid,
  output                    brpred_fetch_bptaken,
  output [BPATTR_WIDTH-1:0] brpred_fetch_bpattr,
  output [31:2]             brpred_fetch_addr,
  output [31:2]             brpred_fetch_target,

  // rob interface
  input                     rob_flush,
  input                     rob_ret_branch,
  input                     rob_ret_bptaken,
  input                     rob_ret_uncond,
  input [BPATTR_WIDTH-1:0]  rob_ret_bpattr,
  input [31:2]              rob_ret_addr,
  input [31:2]              rob_ret_target);

  /*AUTOWIRE*/
  // Beginning of automatic wires (for undeclared instantiated-module outputs)
  wire                  btb_brpred_ready;
  wire [31:2]           btb_brpred_target;
  wire                  btb_brpred_uncond;
  wire                  btb_brpred_valid;
  wire                  pht_brpred_bptaken;
  wire                  pht_brpred_phtsat;
  wire                  pht_brpred_ready;
  // End of automatics

  // s0 stage
  wire        valid_s0;
  wire [31:2] pc_s0;

  wire        pc_s0_en;
  wire [31:2] pc_s0_nxt;
  wire [31:2] pc_s0_r;

  // s1 stage
  wire        valid_s1_r;
  wire [31:2] pc_s1_r;

  wire        replay_s1;
  wire        bptaken_s1;

  // s0 stage
  assign valid_s0 = fetch_brpred_ready & btb_brpred_ready & pht_brpred_ready & ~rob_flush;
  assign pc_s0 = bptaken_s1 ? btb_brpred_target : pc_s0_r;

  assign pc_s0_en = rob_flush | replay_s1 | valid_s0 | bptaken_s1;
  assign pc_s0_nxt = rob_flush ? rob_ret_target :
                     replay_s1 ? pc_s1_r :
                      valid_s0 ? (pc_s0 + 30'b1) :
                                 pc_s0;
  dffr #(30,30'h04000000) u_pc_s0_r (pc_s0_r, pc_s0_nxt, clk, pc_s0_en, rst);

  // s1 stage
  dffr       u_valid_s1_r (valid_s1_r, valid_s0, clk, 1'b1, rst);
  dff  #(30) u_pc_s1_r    (pc_s1_r,    pc_s0,    clk, valid_s0);

  assign replay_s1 = valid_s1_r & ~fetch_brpred_ready;
  assign bptaken_s1 = valid_s1_r & btb_brpred_valid & (btb_brpred_uncond | pht_brpred_bptaken);

  assign brpred_fetch_valid = valid_s1_r;
  assign brpred_fetch_bptaken = bptaken_s1;
  assign brpred_fetch_bpattr = {btb_brpred_uncond,btb_brpred_valid,pht_brpred_phtsat};
  assign brpred_fetch_addr = pc_s1_r;
  assign brpred_fetch_target = btb_brpred_target;

  assign rob_ret_phtsat = rob_ret_bpattr[0];
  assign rob_ret_btbhit = rob_ret_bpattr[1];
  assign rob_ret_btbuncond = rob_ret_bpattr[2];

  btb #(
    /*AUTOINSTPARAM*/
        // Parameters
        .BTB_NUM_SETS   (BTB_NUM_SETS),
        .BTB_NUM_WAYS   (BTB_NUM_WAYS)) u_btb (
    // Inputs
    .brpred_btb_valid(valid_s0),
    .brpred_btb_addr(pc_s0[31:2]),
    /*AUTOINST*/
    // Outputs
    .btb_brpred_ready(btb_brpred_ready),
    .btb_brpred_target(btb_brpred_target[31:2]),
    .btb_brpred_uncond(btb_brpred_uncond),
    .btb_brpred_valid(btb_brpred_valid),
    // Inputs
    .clk(clk),
    .rob_flush(rob_flush),
    .rob_ret_addr(rob_ret_addr),
    .rob_ret_bptaken(rob_ret_bptaken),
    .rob_ret_branch(rob_ret_branch),
    .rob_ret_btbhit(rob_ret_btbhit),
    .rob_ret_btbuncond(rob_ret_btbuncond),
    .rob_ret_target(rob_ret_target),
    .rob_ret_uncond(rob_ret_uncond),
    .rst(rst));

  pht #(
    /*AUTOINSTPARAM*/
        // Parameters
        .PHT_IDX_MSB    (PHT_IDX_MSB)) u_pht (
    // Inputs
    .brpred_pht_valid(valid_s0),
    .brpred_pht_addr(pc_s0[31:2]),
    /*AUTOINST*/
    // Outputs
    .pht_brpred_bptaken(pht_brpred_bptaken),
    .pht_brpred_phtsat(pht_brpred_phtsat),
    .pht_brpred_ready(pht_brpred_ready),
    // Inputs
    .btb_brpred_uncond(btb_brpred_uncond),
    .btb_brpred_valid(btb_brpred_valid),
    .clk(clk),
    .rob_flush(rob_flush),
    .rob_ret_addr(rob_ret_addr),
    .rob_ret_bptaken(rob_ret_bptaken),
    .rob_ret_branch(rob_ret_branch),
    .rob_ret_phtsat(rob_ret_phtsat),
    .rst(rst));

endmodule
