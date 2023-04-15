// bimodal predictor
module pht #(
  parameter PHT_IDX_MSB = 13
  )(
  input                 clk,
  input                 rst,

  // brpred interface
  input                 brpred_pht_valid,
  input [31:2]          brpred_pht_addr,
  output                pht_brpred_ready,
  output                pht_brpred_bptaken,
  output                pht_brpred_phtsat,

  // btb interface
  input                 btb_brpred_valid,
  input                 btb_brpred_uncond,

  // fetch interface
  input                 fetch_brpred_ready,

  // rob interface
  input                 rob_flush,
  input                 rob_ret_branch,
  input                 rob_ret_bptaken,
  input                 rob_ret_phtsat,
  input                 rob_ret_btbhit,
  input                 rob_ret_btbuncond,
  input [31:2]          rob_ret_addr);

  wire                 arch_bhr_update;
  wire [PHT_IDX_MSB:0] arch_bhr_nxt;
  assign arch_bhr_update = rob_ret_branch & rob_ret_btbhit & ~rob_ret_btbuncond;
  assign arch_bhr_nxt = {arch_bhr_r[PHT_IDX_MSB-1:0],rob_ret_bptaken};

  wire [PHT_IDX_MSB:0] arch_bhr_r;
  dffr #(PHT_IDX_MSB+1) u_arch_bhr_r (arch_bhr_r, arch_bhr_nxt, clk, arch_bhr_update, rst);

  wire                 spec_bhr_update;
  wire                 spec_bhr_en;
  wire [PHT_IDX_MSB:0] spec_bhr_nxt;
  wire [PHT_IDX_MSB:0] spec_bhr_in;
  assign spec_bhr_update = brpred_rd_valid_r & fetch_brpred_ready & btb_brpred_valid & ~btb_brpred_uncond;
  assign spec_bhr_en = rob_flush | spec_bhr_update;
  assign spec_bhr_nxt = {spec_bhr_r[PHT_IDX_MSB-1:0],pht_brpred_bptaken};
  assign spec_bhr_in = rob_flush ? (arch_bhr_update ? arch_bhr_nxt : arch_bhr_r) : spec_bhr_nxt;

  wire [PHT_IDX_MSB:0] spec_bhr_r;
  dffr #(PHT_IDX_MSB+1) u_spec_bhr_r (spec_bhr_r, spec_bhr_in, clk, spec_bhr_en, rst);

  wire                 brpred_rd_valid;
  wire [PHT_IDX_MSB:0] brpred_idx;
  assign brpred_rd_valid = brpred_pht_valid & ~update_valid;
  assign brpred_idx = (spec_bhr_update ? spec_bhr_nxt : spec_bhr_r) ^ brpred_pht_addr[3+:PHT_IDX_MSB+1];

  wire brpred_rd_valid_r;
  dffr u_brpred_rd_valid_r (brpred_rd_valid_r, brpred_rd_valid, clk, 1'b1, rst);

  wire                 update_valid;
  wire                 update_bptaken;
  wire [PHT_IDX_MSB:0] update_idx;
  assign update_valid = arch_bhr_update & (rob_flush | ~rob_ret_phtsat);
  assign update_bptaken = rob_ret_bptaken;
  assign update_idx = arch_bhr_r ^ rob_ret_addr[3+:PHT_IDX_MSB+1];

  wire                 update_valid_r;
  wire                 update_bptaken_r;
  wire [PHT_IDX_MSB:0] update_idx_r;
  dffr                  u_update_valid_r   (update_valid_r,   update_valid,   clk, 1'b1, rst);
  dff                   u_update_bptaken_r (update_bptaken_r, update_bptaken, clk, update_valid);
  dff  #(PHT_IDX_MSB+1) u_update_idx_r     (update_idx_r,     update_idx,     clk, update_valid);

  wire                 rd_valid;
  wire [PHT_IDX_MSB:0] rd_idx;
  assign rd_valid = brpred_pht_valid | update_valid;
  assign rd_idx = update_valid ? update_idx : brpred_idx;

  wire                   pht_init;
  wire [PHT_IDX_MSB+1:0] pht_init_r;
`ifdef SYNTHESIS
  wire [PHT_IDX_MSB+1:0] pht_init_nxt;
  assign pht_init = ~pht_init_r[PHT_IDX_MSB+1];
  assign pht_init_nxt = pht_init_r + 1;
  dffr #(PHT_IDX_MSB+2) u_pht_init_r (pht_init_r, pht_init_nxt, clk, pht_init, rst);
`else
  assign pht_init = 0;
  assign pht_init_r = 0;
  integer i;
  initial
    for(i = 0; i < (1 << (PHT_IDX_MSB+1)); i=i+1)
      u_pht_ram.mem[i] = 0;
`endif

  wire                 wr_valid;
  wire [PHT_IDX_MSB:0] wr_idx;
  assign wr_valid = pht_init | update_valid_r;
  assign wr_idx = pht_init ? pht_init_r[PHT_IDX_MSB:0] : update_idx_r;

  wire [1:0] rd_data, wr_data;
  sram_1r1w #(PHT_IDX_MSB+1,2,1) u_pht_ram (
    .rd_clk(clk),
    .rd_en(rd_valid),
    .rd_addr(rd_idx),
    .rd_data(rd_data),
    .wr_clk(clk),
    .wr_en(wr_valid),
    .wr_addr(wr_idx),
    .wr_data(wr_data));

  assign wr_data = pht_init ? 2'b00 :
           update_bptaken_r ? (rd_data == 2'b11 ? 2'b11 : (rd_data + 2'b01)) :
                              (rd_data == 2'b00 ? 2'b00 : (rd_data - 2'b01));

  assign pht_brpred_ready = ~pht_init & ~update_valid;
  assign pht_brpred_bptaken = rd_data[1];
  assign pht_brpred_phtsat = (rd_data == 2'b00) | (rd_data == 2'b11);

endmodule
