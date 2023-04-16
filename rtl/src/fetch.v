// instruction fetch unit
module fetch #(
  parameter BTB_NUM_SETS = 256,
  parameter BTB_NUM_WAYS = 2,
  parameter PHT_IDX_MSB = 13,
  parameter BPATTR_WIDTH = 3,
  parameter FQ_SIZE = 8
  )(
  input                     clk,
  input                     rst,

  // icache interface
  output                    fetch_ic_req,
  output [31:2]             fetch_ic_addr,
  output                    fetch_ic_flush,
  input                     icache_ready,
  input                     icache_valid,
  input                     icache_error,
  input [31:0]              icache_data,

  // decode interface
  output                    fetch_de_valid,
  output                    fetch_de_error,
  output [31:2]             fetch_de_addr,
  output [31:0]             fetch_de_insn,
  output                    fetch_de_bptaken,
  output [BPATTR_WIDTH-1:0] fetch_de_bpattr,
  output [31:2]             fetch_de_target,
  input                     decode_stall,

  // rob interface
  input                     rob_flush,
  input                     rob_ret_branch,
  input                     rob_ret_bptaken,
  input                     rob_ret_uncond,
  input                     rob_ret_raspush,
  input                     rob_ret_raspop,
  input [BPATTR_WIDTH-1:0]  rob_ret_bpattr,
  input [31:2]              rob_ret_addr,
  input [31:2]              rob_ret_target);

  localparam FQ_PTR_WIDTH = $clog2(FQ_SIZE);

  /*AUTOWIRE*/
  // Beginning of automatic wires (for undeclared instantiated-module outputs)
  wire [31:2]           brpred_fetch_addr;
  wire [BPATTR_WIDTH-1:0] brpred_fetch_bpattr;
  wire                  brpred_fetch_bptaken;
  wire [31:2]           brpred_fetch_target;
  wire                  brpred_fetch_valid;
  // End of automatics

  wire fetch_brpred_ready;

  wire fq_empty;
  wire fq_full;

  wire                  fq_tail_en;
  wire [FQ_PTR_WIDTH:0] fq_tail_nxt;
  wire [FQ_PTR_WIDTH:0] fq_tail_r;

  wire [FQ_SIZE-1:0]    fq_tail_dec;
  wire [FQ_SIZE-1:0]    fq_tail_wen;

  wire                  fq_mid_en;
  wire [FQ_PTR_WIDTH:0] fq_mid_nxt;
  wire [FQ_PTR_WIDTH:0] fq_mid_r;

  wire [FQ_SIZE-1:0]    fq_mid_dec;
  wire [FQ_SIZE-1:0]    fq_mid_wen;

  wire                  fq_head_en;
  wire [FQ_PTR_WIDTH:0] fq_head_nxt;
  wire [FQ_PTR_WIDTH:0] fq_head_r;

  wire [FQ_SIZE*32-1:0]           fq_insn_r;
  wire [FQ_SIZE*30-1:0]           fq_addr_r;
  wire [FQ_SIZE*30-1:0]           fq_target_r;
  wire [FQ_SIZE-1:0]              fq_bptaken_r;
  wire [FQ_SIZE*BPATTR_WIDTH-1:0] fq_bpattr_r;
  wire [FQ_SIZE-1:0]              fq_error_r;

  // compare head and mid for empty, head and tail for full
  assign fq_empty = (fq_head_r[FQ_PTR_WIDTH-1:0] == fq_mid_r[FQ_PTR_WIDTH-1:0]) &
                    (fq_head_r[FQ_PTR_WIDTH] == fq_mid_r[FQ_PTR_WIDTH]);
  assign fq_full  = (fq_head_r[FQ_PTR_WIDTH-1:0] == fq_tail_r[FQ_PTR_WIDTH-1:0]) &
                    (fq_head_r[FQ_PTR_WIDTH] != fq_tail_r[FQ_PTR_WIDTH]);

  assign fq_tail_en = rob_flush | fetch_ic_req & icache_ready;
  assign fq_tail_nxt = rob_flush ? {FQ_PTR_WIDTH+1{1'b0}} : (fq_tail_r + 1);
  dffr #(FQ_PTR_WIDTH+1) u_fq_tail_r (fq_tail_r, fq_tail_nxt, clk, fq_tail_en, rst);

  decoder #(FQ_PTR_WIDTH) u_fq_tail_dec (fq_tail_r[FQ_PTR_WIDTH-1:0], fq_tail_dec);
  assign fq_tail_wen = fq_tail_dec & {FQ_SIZE{fq_tail_en}};

  genvar i;
  generate
    for(i = 0; i < FQ_SIZE; i=i+1) begin
      dff #(30)           u_fq_addr_r    (fq_addr_r[i*30+:30],   brpred_fetch_addr,    clk, fq_tail_wen[i]);
      dff #(30)           u_fq_target_r  (fq_target_r[i*30+:30], brpred_fetch_target,  clk, fq_tail_wen[i]);
      dff                 u_fq_bptaken_r (fq_bptaken_r[i],       brpred_fetch_bptaken, clk, fq_tail_wen[i]);
      dff #(BPATTR_WIDTH) u_fq_bpattr_r  (fq_bpattr_r[i*BPATTR_WIDTH+:BPATTR_WIDTH], brpred_fetch_bpattr, clk, fq_tail_wen[i]);
    end
  endgenerate

  assign fq_mid_en = rob_flush | icache_valid;
  assign fq_mid_nxt = rob_flush ? {FQ_PTR_WIDTH+1{1'b0}} : (fq_mid_r + 1);
  dffr #(FQ_PTR_WIDTH+1) u_fq_mid_r  (fq_mid_r,  fq_mid_nxt,  clk, fq_mid_en,  rst);

  assign fetch_ic_req = brpred_fetch_valid & ~fq_full;
  assign fetch_ic_addr = brpred_fetch_addr;
  assign fetch_ic_flush = rob_flush;
  assign fetch_brpred_ready = icache_ready & ~fq_full;

  decoder #(FQ_PTR_WIDTH) u_fq_mid_dec (fq_mid_r[FQ_PTR_WIDTH-1:0], fq_mid_dec);
  assign fq_mid_wen = fq_mid_dec & {FQ_SIZE{fq_mid_en}};

  genvar j;
  generate
    for(j = 0; j < FQ_SIZE; j=j+1) begin
      dff #(32) u_fq_insn_r  (fq_insn_r[j*32+:32], icache_data,  clk, fq_mid_wen[j]);
      dff       u_fq_error_r (fq_error_r[j],       icache_error, clk, fq_mid_wen[j]);
    end
  endgenerate

  assign fq_head_en = rob_flush | fetch_de_valid & ~decode_stall;
  assign fq_head_nxt = rob_flush ? {FQ_PTR_WIDTH+1{1'b0}} : (fq_head_r + 1);
  dffr #(FQ_PTR_WIDTH+1) u_fq_head_r (fq_head_r, fq_head_nxt, clk, fq_head_en, rst);

  assign fetch_de_valid = ~fq_empty;
  mux #(1, FQ_SIZE)           u_fetch_de_error   (fq_head_r[FQ_PTR_WIDTH-1:0], fq_error_r,   fetch_de_error);
  mux #(30,FQ_SIZE)           u_fetch_de_addr    (fq_head_r[FQ_PTR_WIDTH-1:0], fq_addr_r,    fetch_de_addr);
  mux #(32,FQ_SIZE)           u_fetch_de_insn    (fq_head_r[FQ_PTR_WIDTH-1:0], fq_insn_r,    fetch_de_insn);
  mux #(1, FQ_SIZE)           u_fetch_de_bptaken (fq_head_r[FQ_PTR_WIDTH-1:0], fq_bptaken_r, fetch_de_bptaken);
  mux #(BPATTR_WIDTH,FQ_SIZE) u_fetch_de_bpattr  (fq_head_r[FQ_PTR_WIDTH-1:0], fq_bpattr_r,  fetch_de_bpattr);
  mux #(30,FQ_SIZE)           u_fetch_de_target  (fq_head_r[FQ_PTR_WIDTH-1:0], fq_target_r,  fetch_de_target);

  brpred #(
    /*AUTOINSTPARAM*/
           // Parameters
           .BPATTR_WIDTH        (BPATTR_WIDTH),
           .BTB_NUM_SETS        (BTB_NUM_SETS),
           .BTB_NUM_WAYS        (BTB_NUM_WAYS),
           .PHT_IDX_MSB         (PHT_IDX_MSB)) u_brpred (
    /*AUTOINST*/
    // Outputs
    .brpred_fetch_addr(brpred_fetch_addr[31:2]),
    .brpred_fetch_bpattr(brpred_fetch_bpattr[BPATTR_WIDTH-1:0]),
    .brpred_fetch_bptaken(brpred_fetch_bptaken),
    .brpred_fetch_target(brpred_fetch_target[31:2]),
    .brpred_fetch_valid(brpred_fetch_valid),
    // Inputs
    .clk(clk),
    .fetch_brpred_ready(fetch_brpred_ready),
    .rob_flush(rob_flush),
    .rob_ret_addr(rob_ret_addr),
    .rob_ret_bpattr(rob_ret_bpattr),
    .rob_ret_bptaken(rob_ret_bptaken),
    .rob_ret_branch(rob_ret_branch),
    .rob_ret_raspop(rob_ret_raspop),
    .rob_ret_raspush(rob_ret_raspush),
    .rob_ret_target(rob_ret_target),
    .rob_ret_uncond(rob_ret_uncond),
    .rst(rst));

`ifndef SYNTHESIS
`include "fetch_val.v"
`endif

endmodule
