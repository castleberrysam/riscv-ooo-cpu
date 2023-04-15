// branch target buffer
module btb #(
  parameter BTB_NUM_SETS = 256,
  parameter BTB_NUM_WAYS = 2
  )(
  input         clk,
  input         rst,

  // brpred interface
  input         brpred_btb_valid,
  input [31:2]  brpred_btb_addr,
  output        btb_brpred_ready,

  output        btb_brpred_valid,
  output        btb_brpred_uncond,
  output [31:2] btb_brpred_target,

  // rob interface
  input         rob_flush,
  input         rob_ret_branch,
  input         rob_ret_bptaken,
  input         rob_ret_uncond,
  input         rob_ret_btbhit,
  input         rob_ret_btbuncond,
  input [31:2]  rob_ret_addr,
  input [31:2]  rob_ret_target);

  localparam IDX_WIDTH = $clog2(BTB_NUM_SETS);
  localparam IDX_LSB = 2;
  localparam IDX_MSB = IDX_LSB + IDX_WIDTH - 1;

  localparam TAG_WIDTH = 31 - (IDX_MSB+1) + 1;
  localparam TGT_WIDTH = 31 - 2 + 1;
  localparam LRU_WIDTH = BTB_NUM_WAYS - 1;

  localparam WAY_WIDTH = 2 + TAG_WIDTH + TGT_WIDTH;
  localparam SET_WIDTH = (BTB_NUM_WAYS * WAY_WIDTH) + LRU_WIDTH;

  wire                              alloc_valid;
  wire                              alloc_uncond;
  wire [31:2]                       alloc_target;
  wire                              alloc_valid_r;
  wire                              alloc_uncond_r;
  wire [31:2]                       alloc_target_r;

  wire                              uncond_update_valid;
  wire                              uncond_update_valid_r;

  wire                              rob_rd_valid;
  wire [IDX_MSB:IDX_LSB]            rob_rd_idx;
  wire [31:IDX_MSB+1]               rob_rd_tag;
  wire                              rob_wr_valid;

  wire                              brpred_rd_valid;
  wire [IDX_MSB:IDX_LSB]            brpred_rd_idx;
  wire [31:IDX_MSB+1]               brpred_rd_tag;
  wire                              brpred_rd_valid_r;

  wire                              rd_en;
  wire [IDX_MSB:IDX_LSB]            rd_idx;
  wire [31:IDX_MSB+1]               rd_tag;
  wire [IDX_MSB:IDX_LSB]            rd_idx_r;
  wire [31:IDX_MSB+1]               rd_tag_r;

  wire                              btb_init;
  wire [IDX_MSB+1:IDX_LSB]          btb_init_r;

  wire [SET_WIDTH-1:0]              rd_data;
  wire [BTB_NUM_WAYS-1:0]           rd_way_valid;
  wire [BTB_NUM_WAYS-1:0]           rd_way_uncond;
  wire [BTB_NUM_WAYS*TAG_WIDTH-1:0] rd_way_tag;
  wire [BTB_NUM_WAYS*TGT_WIDTH-1:0] rd_way_target;
  wire [BTB_NUM_WAYS-1:0]           hit_way;

  wire [LRU_WIDTH-1:0]              rd_lru;
  wire [BTB_NUM_WAYS-2:0]           lru_nxt;
  wire                              lru_update_valid;

  wire [BTB_NUM_WAYS-1:0]           lru_vic_way;
  wire                              any_invalid_way;
  wire [BTB_NUM_WAYS-1:0]           invalid_way;
  wire [BTB_NUM_WAYS-1:0]           alloc_way;
  wire [WAY_WIDTH-1:0]              alloc_way_wr_data;

  wire                              wr_en;
  wire [IDX_MSB:IDX_LSB]            wr_idx;
  wire [SET_WIDTH-1:0]              alloc_wr_data;
  wire [SET_WIDTH-1:0]              uncond_update_wr_data;
  wire [SET_WIDTH-1:0]              lru_update_wr_data;
  wire [SET_WIDTH-1:0]              wr_data;

  assign alloc_valid = rob_ret_branch & ~rob_ret_btbhit & ~rob_wr_valid;
  // allocate taken branch as unconditional, this improves warmup time for loop branches
  assign alloc_uncond = rob_ret_uncond | rob_ret_bptaken;
  assign alloc_target = rob_ret_target;

  dffr       u_alloc_valid_r  (alloc_valid_r,  alloc_valid,  clk, 1'b1, rst);
  dff        u_alloc_uncond_r (alloc_uncond_r, alloc_uncond, clk, alloc_valid);
  dff  #(30) u_alloc_target_r (alloc_target_r, alloc_target, clk, alloc_valid);

  assign alloc_way_wr_data = {alloc_target_r,rd_tag_r,alloc_uncond_r,1'b1};

  // when a branch marked unconditional was not-taken, demote to conditional
  assign uncond_update_valid = rob_ret_branch & ~rob_ret_uncond & ~rob_ret_bptaken &
                               rob_ret_btbhit & rob_ret_btbuncond;

  dffr u_uncond_update_valid_r (uncond_update_valid_r, uncond_update_valid, clk, 1'b1, rst);

  assign rob_rd_valid = alloc_valid | uncond_update_valid;
  assign rob_rd_idx = rob_ret_addr[IDX_MSB:IDX_LSB];
  assign rob_rd_tag = rob_ret_addr[31:IDX_MSB+1];

  assign rob_wr_valid = alloc_valid_r | uncond_update_valid_r;

  assign brpred_rd_valid = brpred_btb_valid & ~rob_rd_valid & ~rob_wr_valid;
  assign brpred_rd_idx = brpred_btb_addr[IDX_MSB:IDX_LSB];
  assign brpred_rd_tag = brpred_btb_addr[31:IDX_MSB+1];

  dffr u_brpred_rd_valid_r (brpred_rd_valid_r, brpred_rd_valid, clk, 1'b1, rst);

  assign lru_update_valid = brpred_rd_valid_r & (lru_nxt != rd_lru) & ~rob_rd_valid;
  assign lru_update_wr_data = {lru_nxt,rd_data[BTB_NUM_WAYS*WAY_WIDTH-1:0]};

  assign rd_en = brpred_btb_valid | rob_rd_valid;
  assign rd_idx = rob_rd_valid ? rob_rd_idx : brpred_rd_idx;
  assign rd_tag = rob_rd_valid ? rob_rd_tag : brpred_rd_tag;

  dff #(IDX_WIDTH) u_rd_idx_r (rd_idx_r, rd_idx, clk, rd_en);
  dff #(TAG_WIDTH) u_rd_tag_r (rd_tag_r, rd_tag, clk, rd_en);

`ifdef SYNTHESIS
  wire [IDX_MSB+1:IDX_LSB] btb_init_nxt;
  assign btb_init = ~btb_init_r[IDX_MSB+1];
  assign btb_init_nxt = btb_init_r + 1;
  dffr #(IDX_MSB-IDX_LSB+2) u_btb_init_r (btb_init_r, btb_init_nxt, clk, btb_init, rst);
`else
  assign btb_init = 0;
  assign btb_init_r = 0;
  integer k;
  initial
    for(k = 0; k < BTB_NUM_SETS; k=k+1)
      u_btb_ram.mem[k] = 0;
`endif

  assign wr_en = btb_init | lru_update_valid | rob_wr_valid;
  assign wr_idx = btb_init ? btb_init_r[IDX_MSB:IDX_LSB] : rd_idx_r;

  sram_1r1w #(IDX_WIDTH,SET_WIDTH,1) u_btb_ram (
    .rd_clk(clk),
    .rd_en(rd_en),
    .rd_addr(rd_idx),
    .rd_data(rd_data),
    .wr_clk(clk),
    .wr_en(wr_en),
    .wr_addr(wr_idx),
    .wr_data(wr_data));

  genvar i;
  generate
    for(i = 0; i < BTB_NUM_WAYS; i=i+1) begin
      assign {rd_way_target[i*TGT_WIDTH+:TGT_WIDTH],
              rd_way_tag[i*TAG_WIDTH+:TAG_WIDTH],
              rd_way_uncond[i],
              rd_way_valid[i]} = rd_data[i*WAY_WIDTH+:WAY_WIDTH];
      assign hit_way[i] = rd_way_valid[i] & (rd_way_tag[i*TAG_WIDTH+:TAG_WIDTH] == rd_tag_r);
    end
  endgenerate
  assign rd_lru = rd_data[BTB_NUM_WAYS*WAY_WIDTH+:LRU_WIDTH];

  generate
    if(BTB_NUM_WAYS == 2) begin
      assign lru_vic_way = rd_lru ? 2'b10 : 2'b01;
      assign lru_nxt = hit_way[0];
    end else if(BTB_NUM_WAYS == 4) begin
      assign lru_vic_way = rd_lru[2] ? (rd_lru[1] ? 4'b1000 : 4'b0100) :
                                       (rd_lru[0] ? 4'b0010 : 4'b0001);
      wire [BTB_NUM_WAYS-2:0] lru_set, lru_rst;
      assign lru_set = {hit_way[0] | hit_way[1],
                        hit_way[2],
                        hit_way[0]};
      assign lru_rst = {hit_way[2] | hit_way[3],
                        hit_way[3],
                        hit_way[1]};
      assign lru_nxt = (rd_lru | lru_set) & ~lru_rst;
    end
  endgenerate

  priarb #(BTB_NUM_WAYS) u_invalid_way (
    .req(~rd_way_valid),
    .grant_valid(any_invalid_way),
    .grant(invalid_way));

  assign alloc_way = any_invalid_way ? invalid_way : lru_vic_way;

  genvar j;
  generate
    for(j = 0; j < BTB_NUM_WAYS; j=j+1) begin
      assign alloc_wr_data[j*WAY_WIDTH+:WAY_WIDTH] = alloc_way[j] ? alloc_way_wr_data :
                                                                    rd_data[j*WAY_WIDTH+:WAY_WIDTH];
      assign uncond_update_wr_data[j*WAY_WIDTH+:WAY_WIDTH] =
          rd_data[j*WAY_WIDTH+:WAY_WIDTH] & {{TGT_WIDTH{1'b1}},{TAG_WIDTH{1'b1}},~hit_way[j],1'b1};
    end
  endgenerate
  assign alloc_wr_data[BTB_NUM_WAYS*WAY_WIDTH+:BTB_NUM_WAYS-1] = rd_lru;
  assign uncond_update_wr_data[BTB_NUM_WAYS*WAY_WIDTH+:BTB_NUM_WAYS-1] = rd_lru;

  assign wr_data = alloc_valid_r ? alloc_wr_data :
           uncond_update_valid_r ? uncond_update_wr_data :
                                   lru_update_wr_data;

  assign btb_brpred_ready = ~btb_init & ~rob_rd_valid & ~rob_wr_valid;

  assign btb_brpred_valid = brpred_rd_valid_r & (|hit_way);
  premux #(1,BTB_NUM_WAYS) u_btb_brpred_uncond (
    .sel(hit_way),
    .in(rd_way_uncond),
    .out(btb_brpred_uncond));
  premux #(TGT_WIDTH,BTB_NUM_WAYS) u_btb_brpred_target (
    .sel(hit_way),
    .in(rd_way_target),
    .out(btb_brpred_target));

endmodule
