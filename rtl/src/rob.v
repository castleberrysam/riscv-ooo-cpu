// reorder buffer and retirement unit
module rob #(
  parameter ROBID_MSB = 4,
  parameter BPATTR_WIDTH = 2
  )(
  input                     clk,
  input                     rst,

  // decode interface
  input                     decode_rob_valid,
  input                     decode_error,
  input [1:0]               decode_ecause,
  input [6:0]               decode_retop,
  input [31:2]              decode_addr,
  input [5:0]               decode_rd,
  input                     decode_bptaken,
  input                     decode_raspush,
  input                     decode_raspop,
  input [BPATTR_WIDTH-1:0]  decode_bpattr,
  input [31:2]              decode_bptarget,
  input                     decode_forward,
  input [31:2]              decode_target,
  output                    rob_full,
  output [ROBID_MSB:0]      rob_robid,

  // rename interface
  input                     rename_inhibit,
  input [ROBID_MSB:0]       rename_robid,
  output                    rob_rename_ishead,

  // wb interface
  input                     wb_valid,
  input                     wb_error,
  input [4:0]               wb_ecause,
  input [ROBID_MSB:0]       wb_robid,
  input [31:0]              wb_result,

  // common signals
  output                    rob_flush,

  // fetch interface
  output                    rob_ret_branch,
  output                    rob_ret_bptaken,
  output                    rob_ret_uncond,
  output                    rob_ret_raspush,
  output                    rob_ret_raspop,
  output [BPATTR_WIDTH-1:0] rob_ret_bpattr,
  output [31:2]             rob_ret_addr,
  output [31:2]             rob_ret_target,

  // rat interface
  output                    rob_ret_commit,
  output [4:0]              rob_ret_rd,
  output [31:0]             rob_ret_result,

  // lsq interface (out)
  output                    rob_ret_store,

  // csr interface
  input [31:2]              csr_tvec,
  output                    rob_ret_valid,
  output                    rob_ret_csr,
  output                    rob_csr_valid,
  output [31:2]             rob_csr_epc,
  output [4:0]              rob_csr_ecause,
  output [31:0]             rob_csr_tval);

  localparam ROB_SIZE = 1 << (ROBID_MSB+1);

  wire [ROB_SIZE-1:0]    buf_executed;
  wire [ROB_SIZE-1:0]    buf_error;
  wire [ROB_SIZE*7-1:0]  buf_retop;
  wire [ROB_SIZE*30-1:0] buf_addr;
  wire [ROB_SIZE*6-1:0]  buf_rd;
  wire [ROB_SIZE*5-1:0]  buf_ecause;
  wire [ROB_SIZE*32-1:0] buf_result;
  wire [ROB_SIZE*30-1:0] buf_target;
  wire [ROB_SIZE-1:0]    buf_bptaken;
  wire [ROB_SIZE-1:0]    buf_forwarded;

  wire [ROB_SIZE-1:0]              raspush_r;
  wire [ROB_SIZE-1:0]              raspop_r;
  wire [ROB_SIZE*BPATTR_WIDTH-1:0] bpattr_r;
  wire [ROB_SIZE*30-1:0]           bptarget_r;

  // insert at tail, remove at head
  wire [ROBID_MSB:0]   buf_head, buf_tail;
  wire                 buf_head_pol, buf_tail_pol;
  wire [ROBID_MSB+1:0] buf_head_next, buf_tail_next;

  wire         ret_valid;
  wire         ret_error;
  wire  [ 6:0] ret_retop;
  wire  [31:2] ret_addr;
  wire  [ 5:0] ret_rd;
  wire  [ 4:0] ret_ecause;
  wire  [31:0] ret_result;
  wire  [31:2] ret_target;
  wire         ret_bptaken;
  wire         ret_forwarded;

  wire                    ret_raspush_r;
  wire                    ret_raspop_r;
  wire [BPATTR_WIDTH-1:0] ret_bpattr_r;
  wire [31:2]             ret_bptarget_r;

  wire [ROBID_MSB:0] ret_rd_addr;
  wire               ret_rd_addr_pol;
  wire               ret_rd_empty;
  assign ret_rd_empty = (ret_rd_addr == buf_tail) & (ret_rd_addr_pol == buf_tail_pol);

  // derived signals
  wire buf_full;
  assign buf_full = (buf_head == buf_tail) & (buf_head_pol != buf_tail_pol);

  wire decode_beat;
  assign decode_beat = decode_rob_valid & ~rob_full;

  wire br_result;
  assign br_result = ret_result[0] ^ ret_retop[0];

  wire ret_exc, ret_mispred_type, ret_mispred_dir, ret_mispred_tgt, ret_mispred;
  assign ret_exc = ret_valid & ret_error;
  assign ret_mispred_type = ret_bptaken & ~ret_retop[4] & ~ret_retop[6];
  assign ret_mispred_tgt = ret_retop[4] & ret_forwarded & (ret_bptarget_r != ret_result[31:2]);
  assign ret_mispred_dir = ret_retop[4] & ~ret_bptaken |
                           ret_retop[6] & (br_result ^ ret_bptaken);
  assign ret_mispred = ret_valid & (ret_mispred_type | ret_mispred_tgt | ret_mispred_dir);

  // decode interface
  assign rob_full = buf_full;
  assign rob_robid = buf_tail;

  // rename interface: CSR execution
  assign rob_rename_ishead = rename_robid == ret_rd_addr;

  // common signals
  assign rob_flush = ret_exc | ret_mispred;

  // fetch interface
  assign rob_ret_branch = rob_ret_valid & (ret_retop[4] | ret_retop[6]);
  assign rob_ret_bptaken = br_result;
  assign rob_ret_uncond = ret_retop[4];
  assign rob_ret_raspush = ret_raspush_r;
  assign rob_ret_raspop = ret_raspop_r;
  assign rob_ret_bpattr = ret_bpattr_r;
  assign rob_ret_addr = ret_addr;
  assign rob_ret_target = ret_error ? csr_tvec : (ret_forwarded ? ret_result[31:2] : ret_target);

  // csr interface
  assign rob_ret_valid = ret_valid & ~ret_error;
  assign rob_ret_csr = rob_ret_valid & ret_retop[5];
  assign rob_csr_valid = ret_exc;
  assign rob_csr_epc = ret_addr;
  assign rob_csr_ecause = ret_ecause;
  assign rob_csr_tval = 0;  // TODO

  // rat interface
  assign rob_ret_commit = rob_ret_valid & ~ret_rd[5];
  assign rob_ret_rd = ret_rd[4:0];
  assign rob_ret_result = ret_forwarded ? {ret_target,2'b0} : ret_result;

  // lsq interface (out)
  assign rob_ret_store = rob_ret_valid & ret_retop[3];

  // forward buf_head when reading consecutive addrs
  inc #(ROBID_MSB+2) buf_head_inc ({buf_head_pol, buf_head}, buf_head_next);
  mux #(ROBID_MSB+1,2) ret_rd_addr_mux(ret_valid, {buf_head_next[ROBID_MSB:0], buf_head}, ret_rd_addr);
  mux #(1,2) ret_rd_addr_pol_mux(ret_valid, {buf_head_next[ROBID_MSB+1], buf_head_pol}, ret_rd_addr_pol);

  flop #(ROBID_MSB+2) buf_head_flop(clk, rst | rob_flush, 0, ret_valid, buf_head_next, {buf_head_pol, buf_head});

  // buf_tail
  inc #(ROBID_MSB+2) buf_tail_inc ({buf_tail_pol, buf_tail}, buf_tail_next);
  flop #(ROBID_MSB+2) buf_tail_flop(clk, rst | rob_flush, 0, decode_beat, buf_tail_next, {buf_tail_pol, buf_tail});

  wire rename_inhibit_r;
  flop rename_inhibit_flop(clk, rst | rob_flush, 0, 1, rename_inhibit, rename_inhibit_r);

  wire [ROB_SIZE-1:0] buf_tail_splat, wb_robid_splat, ret_rd_addr_splat;
  // TODO: replace decoders with onehot
  decoder #(ROBID_MSB+1) buf_tail_decoder(buf_tail, buf_tail_splat);
  decoder #(ROBID_MSB+1) wb_robid_decoder(wb_robid, wb_robid_splat);
  decoder #(ROBID_MSB+1) ret_rd_addr_decoder(ret_rd_addr, ret_rd_addr_splat);
  wire [ROB_SIZE-1:0] buf_tail_en = {ROB_SIZE{decode_beat}} & buf_tail_splat;
  wire [ROB_SIZE-1:0] wb_robid_en = {ROB_SIZE{wb_valid & ~rename_inhibit_r}} & wb_robid_splat;

  genvar i;
  generate
    for (i = 0; i < ROB_SIZE; i = i + 1) begin
      // dual write
      flop buf_executed_flop(clk, 0, 0, buf_tail_en[i] | wb_robid_en[i],
        buf_tail_en[i] & (decode_error | decode_retop[3]) | wb_robid_en[i], buf_executed[i]);
      flop buf_error_flop   (clk, 0, 0, buf_tail_en[i] | wb_robid_en[i],
        buf_tail_en[i] & decode_error | wb_robid_en[i] & wb_error, buf_error[i]);
      flop #(5) buf_ecause_flop  (clk, 0, 0, buf_tail_en[i] | wb_robid_en[i],
        {5{buf_tail_en[i]}} & {3'b0, decode_ecause} | {5{wb_robid_en[i]}} | wb_ecause,
        buf_ecause[(i+1)*5-1:i*5]);
      // single write
      flop #(32) buf_result_flop(clk, 0, 0, wb_robid_en[i], wb_result,      buf_result   [(i+1)*32-1:i*32]);
      flop #(7)  buf_retop_flop (clk, 0, 0, buf_tail_en[i], decode_retop,   buf_retop    [(i+1)*7-1:i*7]);
      flop #(30) buf_addr_flop  (clk, 0, 0, buf_tail_en[i], decode_addr,    buf_addr     [(i+1)*30-1:i*30]);
      flop #(6)  buf_rd_flop    (clk, 0, 0, buf_tail_en[i], decode_rd,      buf_rd       [(i+1)*6-1:i*6]);
      flop #(30) buf_target_flop(clk, 0, 0, buf_tail_en[i], decode_target,  buf_target   [(i+1)*30-1:i*30]);
      flop buf_bptaken_flop     (clk, 0, 0, buf_tail_en[i], decode_bptaken, buf_bptaken  [i]);
      flop buf_forward_flop     (clk, 0, 0, buf_tail_en[i], decode_forward, buf_forwarded[i]);

      dff                 u_raspush_r  (raspush_r[i],         decode_raspush,  clk, buf_tail_en[i]);
      dff                 u_raspop_r   (raspop_r[i],          decode_raspop,   clk, buf_tail_en[i]);
      dff #(BPATTR_WIDTH) u_bpattr_r   (bpattr_r[i*BPATTR_WIDTH+:BPATTR_WIDTH], decode_bpattr, clk, buf_tail_en[i]);
      dff #(30)           u_bptarget_r (bptarget_r[i*30+:30], decode_bptarget, clk, buf_tail_en[i]);
    end
  endgenerate

  // read
  wire        read_executed;
  wire        read_error;
  wire [ 6:0] read_retop;
  wire [29:0] read_addr;
  wire [ 5:0] read_rd;
  wire [ 4:0] read_ecause;
  wire [31:0] read_result;
  wire [29:0] read_target;
  wire        read_bptaken;
  wire        read_forwarded;
  premux #(1,  ROB_SIZE) buf_executed_mux(ret_rd_addr_splat, buf_executed, read_executed);
  premux #(1,  ROB_SIZE) buf_error_mux(ret_rd_addr_splat, buf_error, read_error);
  premux #(7,  ROB_SIZE) buf_retop_mux(ret_rd_addr_splat, buf_retop, read_retop);
  premux #(30, ROB_SIZE) buf_addr_mux(ret_rd_addr_splat, buf_addr, read_addr);
  premux #(6,  ROB_SIZE) buf_rd_mux(ret_rd_addr_splat, buf_rd, read_rd);
  premux #(5,  ROB_SIZE) buf_ecause_mux(ret_rd_addr_splat, buf_ecause, read_ecause);
  premux #(32, ROB_SIZE) buf_result_mux(ret_rd_addr_splat, buf_result, read_result);
  premux #(30, ROB_SIZE) buf_target_mux(ret_rd_addr_splat, buf_target, read_target);
  premux #(1,  ROB_SIZE) buf_bptaken_mux(ret_rd_addr_splat, buf_bptaken, read_bptaken);
  premux #(1,  ROB_SIZE) buf_forwarded_mux(ret_rd_addr_splat, buf_forwarded, read_forwarded);

  wire                    read_raspush;
  wire                    read_raspop;
  wire [BPATTR_WIDTH-1:0] read_bpattr;
  wire [31:2]             read_bptarget;
  premux #(1,           ROB_SIZE) u_read_raspush  (ret_rd_addr_splat, raspush_r,  read_raspush);
  premux #(1,           ROB_SIZE) u_read_raspop   (ret_rd_addr_splat, raspop_r,   read_raspop);
  premux #(BPATTR_WIDTH,ROB_SIZE) u_read_bpattr   (ret_rd_addr_splat, bpattr_r,   read_bpattr);
  premux #(30,          ROB_SIZE) u_read_bptarget (ret_rd_addr_splat, bptarget_r, read_bptarget);

  flop ret_valid_flop(clk, rst | rob_flush, 0, 1,
      read_executed & ~ret_rd_empty & (~read_retop[3] | ~rob_rename_ishead), ret_valid);
  flop #(7)  ret_retop_flop     (clk, 0, 0, 1, read_retop, ret_retop);
  flop #(30) ret_addr_flop      (clk, 0, 0, 1, read_addr, ret_addr);
  flop #(6)  ret_rd_flop        (clk, 0, 0, 1, read_rd, ret_rd);
  flop #(5)  ret_ecause_flop    (clk, 0, 0, 1, read_ecause, ret_ecause);
  flop #(32) ret_result_flop    (clk, 0, 0, 1, read_result, ret_result);
  flop #(30) ret_target_flop    (clk, 0, 0, 1, read_target, ret_target);
  flop ret_error_flop           (clk, 0, 0, 1, read_error, ret_error);
  flop ret_bptaken_flop         (clk, 0, 0, 1, read_bptaken, ret_bptaken);
  flop ret_forwarded_flop       (clk, 0, 0, 1, read_forwarded, ret_forwarded);

  dff                 u_ret_raspush_r  (ret_raspush_r,  read_raspush,  clk, 1'b1);
  dff                 u_ret_raspop_r   (ret_raspop_r,   read_raspop,   clk, 1'b1);
  dff #(BPATTR_WIDTH) u_ret_bpattr_r   (ret_bpattr_r,   read_bpattr,   clk, 1'b1);
  dff #(30)           u_ret_bptarget_r (ret_bptarget_r, read_bptarget, clk, 1'b1);

`ifndef SYNTHESIS
  always @(posedge clk) begin
    if (ret_valid)
      tb_top.tb_trace_rob_retire(buf_head, ret_retop, ret_addr, ret_error, ret_mispred, ret_ecause,
                                 ret_rd, rob_ret_result);
    if (rob_flush)
      tb_top.tb_log_rob_flush();
  end
`endif

endmodule
