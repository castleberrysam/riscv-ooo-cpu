module dram_ctl_buf #(
  parameter BANK_WIDTH = 3,
  parameter ROW_WIDTH = 14,
  parameter COL_WIDTH = 10,
  parameter TAG_WIDTH = 5,
  parameter BUF_ENTRIES = 16,
  parameter CMD_PER_ENT = 4
  )(
  input                     bus_clk,
  input                     rst,

  input                     memc_clk,
  input                     memc_rst,

  // intf interface
  input                     intf_buf_cmd_v,
  input                     intf_buf_write,
  input [TAG_WIDTH-1:0]     intf_buf_tag,
  input [ADDR_MSB:6]        intf_buf_addr,
  // 2rdy indicates we have two free entries
  output                    buf_intf_cmd_rdy,
  output                    buf_intf_cmd_2rdy,

  input                     intf_buf_wr_v,
  input [63:0]              intf_buf_wr_data,

  // 2v indicates we have two done entries
  output                    buf_intf_cmd_v,
  output                    buf_intf_cmd_2v,
  output [TAG_WIDTH-1:0]    buf_intf_cmd_tag,
  output [ADDR_MSB:6]       buf_intf_cmd_addr,
  input                     intf_buf_cmd_done,

  input                     intf_buf_rd_v,
  output [63:0]             buf_intf_rd_data,

  // memory controller commands
  output                    use_addr,
  output [CMD_ID_WIDTH-1:0] data_buf_addr,
  output [2:0]              cmd,
  output                    hi_priority,
  output [BANK_WIDTH-1:0]   bank,
  output [ROW_WIDTH-1:0]    row,
  output [COL_WIDTH-1:0]    col,
  input                     accept,

  // memory controller write data
  input                     wr_data_en,
  input [CMD_ID_WIDTH-1:0]  wr_data_addr,
  input                     wr_data_offset,
  output [7:0]              wr_data_mask,
  output [63:0]             wr_data,

  // memory controller read data
  input                     rd_data_en,
  input                     rd_data_end,
  input [CMD_ID_WIDTH-1:0]  rd_data_addr,
  input                     rd_data_offset,
  input [63:0]              rd_data);

  localparam ADDR_MSB = BANK_WIDTH + ROW_WIDTH + COL_WIDTH - 1;

  // each command reads 16 bytes, so each entry sends four commands
  localparam ENT_ID_WIDTH = $clog2(BUF_ENTRIES);
  localparam CMD_ID_WIDTH = ENT_ID_WIDTH + $clog2(CMD_PER_ENT);

  // command buffer
  wire [BUF_ENTRIES-1:0]                     ent_state_idle, ent_state_cmd, ent_state_done;
  wire [BUF_ENTRIES*$clog2(CMD_PER_ENT)-1:0] ent_state_cnt;
  wire [BUF_ENTRIES-1:0]                     ent_write;
  wire [BUF_ENTRIES*TAG_WIDTH-1:0]           ent_tag;
  wire [BUF_ENTRIES*(ADDR_MSB-5)-1:0]        ent_addr;
  dram_ctl_buf_ent #(
    .TAG_WIDTH(TAG_WIDTH),
    .ADDR_MSB(ADDR_MSB),
    .ADDR_LSB(6),
    .CMD_PER_ENT(CMD_PER_ENT)
    ) u_buf_ent [BUF_ENTRIES-1:0] (
    .bus_clk(bus_clk),
    .rst(rst),
    .memc_clk(memc_clk),
    .memc_rst(memc_rst),
    .wr_v(ent_alloc_sel),
    .wr_write(intf_buf_write),
    .wr_tag(intf_buf_tag),
    .wr_addr(intf_buf_addr),
    .cmd_beat(ent_cmd_beat),
    .rsp_beat(ent_rsp_beat),
    .dealloc(ent_dealloc_sel),
    .state_idle(ent_state_idle),
    .state_cmd(ent_state_cmd),
    .state_done(ent_state_done),
    .state_cnt(ent_state_cnt),
    .write(ent_write),
    .tag(ent_tag),
    .addr(ent_addr));

  // allocation/deallocation (managed by buf)
  wire [BUF_ENTRIES-1:0] ent_alloc_sel_base;
  priarb #(BUF_ENTRIES) u_ent_alloc_sel_base (
    .req(ent_state_idle),
    .grant_valid(buf_intf_cmd_rdy),
    .grant(ent_alloc_sel_base));
  assign buf_intf_cmd_2rdy = buf_intf_cmd_rdy & (|(ent_state_idle & ~ent_alloc_sel_base));

  wire [BUF_ENTRIES-1:0] ent_dealloc_sel_base;
  priarb #(BUF_ENTRIES) u_ent_dealloc_sel_base (
    .req(ent_state_done),
    .grant_valid(buf_intf_cmd_v),
    .grant(ent_dealloc_sel_base));
  assign buf_intf_cmd_2v = buf_intf_cmd_v & (|(ent_state_done & ~ent_dealloc_sel_base));

  wire ent_alloc_beat, ent_dealloc_beat;
  assign ent_alloc_beat = intf_buf_cmd_v & buf_intf_cmd_rdy;
  assign ent_dealloc_beat = buf_intf_cmd_v & intf_buf_cmd_done;

  wire [BUF_ENTRIES-1:0] ent_alloc_sel, ent_dealloc_sel;
  assign ent_alloc_sel   = {BUF_ENTRIES{ent_alloc_beat}}   & ent_alloc_sel_base;
  assign ent_dealloc_sel = {BUF_ENTRIES{ent_dealloc_beat}} & ent_dealloc_sel_base;

  premux #(TAG_WIDTH,BUF_ENTRIES) u_buf_intf_cmd_tag (
    .sel(ent_dealloc_sel_base),
    .in(ent_tag),
    .out(buf_intf_cmd_tag));
  premux #(ADDR_MSB-5,BUF_ENTRIES) u_buf_intf_cmd_addr (
    .sel(ent_dealloc_sel_base),
    .in(ent_addr),
    .out(buf_intf_cmd_addr));

  // command beat
  // accept is delayed by a cycle so we need to stage some fields of the request
  wire [BUF_ENTRIES-1:0] last_cmd_sel_r, last_cmd_sel;
  dffr                 u_use_addr       (use_addr,       use_addr_nxt,      memc_clk, 1'b1, memc_rst);
  dff  #(CMD_ID_WIDTH) u_data_buf_addr  (data_buf_addr,  data_buf_addr_nxt, memc_clk, use_addr_nxt);
  dff  #(BUF_ENTRIES)  u_last_cmd_sel_r (last_cmd_sel_r, ent_cmd_beat_base, memc_clk, use_addr_nxt);

  wire ent_cmd_beat_v;
  assign ent_cmd_beat_v = use_addr & accept;
  assign ent_cmd_beat = {BUF_ENTRIES{ent_cmd_beat_v}} & last_cmd_sel_r;

  // wire [BUF_ENTRIES-1:0] ent_cmd_beat_base, ent_cmd_beat;
  // priarb #(BUF_ENTRIES) u_ent_cmd_beat_base (
  //   .req(ent_state_cmd),
  //   .grant_valid(use_addr_nxt),
  //   .grant(ent_cmd_beat_base));

  // age-based priority for sending commands
  // REVISIT: is handling needed here for the clock-domain-crossing?
  // no since inserting new entries will not change the output?
  wire [BUF_ENTRIES-1:0] ent_cmd_beat_base, ent_cmd_beat;
  agemat #(BUF_ENTRIES) u_cmd_age (
    .clk(bus_clk),
    .rst(rst),
    .insert_valid(ent_alloc_beat),
    .insert_sel(ent_alloc_sel),
    .req(ent_state_cmd),
    .grant_valid(use_addr_nxt),
    .grant(ent_cmd_beat_base));

  wire [ENT_ID_WIDTH-1:0]        data_buf_addr_nxt_hi;
  wire [$clog2(CMD_PER_ENT)-1:0] data_buf_addr_nxt_lo;
  wire [CMD_ID_WIDTH-1:0]        data_buf_addr_nxt;
  encoder #(BUF_ENTRIES) u_data_buf_addr_nxt_hi (
    .in(ent_cmd_beat_base),
    .invalid(),
    .out(data_buf_addr_nxt_hi));
  premux #($clog2(CMD_PER_ENT),BUF_ENTRIES) u_data_buf_addr_nxt_lo (
    .sel(ent_cmd_beat_base),
    .in(ent_state_cnt),
    .out(data_buf_addr_nxt_lo));
  assign data_buf_addr_nxt = {data_buf_addr_nxt_hi,data_buf_addr_nxt_lo};

  premux #(1) u_cmd (
    .sel(ent_cmd_beat_base),
    .in(ent_write),
    .out(cmd_write));
  assign cmd = {2'b0,~cmd_write};

  assign hi_priority = 0;

  wire [ADDR_MSB:6] cmd_addr_hi;
  wire [ADDR_MSB:0] cmd_addr;
  premux #(ADDR_MSB-5) u_cmd_addr_hi (
    .sel(ent_cmd_beat_base),
    .in(ent_addr),
    .out(cmd_addr_hi));
  assign cmd_addr = {cmd_addr_hi,data_buf_addr_nxt_lo,{6-$clog2(CMD_PER_ENT){1'b0}}};
  assign col = cmd_addr[0+:COL_WIDTH];
  assign bank = cmd_addr[COL_WIDTH+:BANK_WIDTH];
  assign row = cmd_addr[COL_WIDTH+BANK_WIDTH+:ROW_WIDTH];

  // read data buffer
  wire [$clog2(CMD_PER_ENT):0] rd_buf_rd_addr_lo_r, rd_buf_rd_addr_lo_nxt;
  dffr #($clog2(CMD_PER_ENT)+1) u_rd_buf_rd_addr_lo_r (rd_buf_rd_addr_lo_r, rd_buf_rd_addr_lo_nxt,
                                                       bus_clk, intf_buf_rd_v, rst);
  assign rd_buf_rd_addr_lo_nxt = rd_buf_rd_addr_lo_r + 1;

  wire [ENT_ID_WIDTH-1:0] rd_buf_rd_addr_hi, rd_buf_rd_addr_hi_base;
  encoder #(BUF_ENTRIES) u_rd_buf_rd_addr_hi_base (
    .in(ent_dealloc_sel_base),
    .invalid(),
    .out(rd_buf_rd_addr_hi_base));

  // hold the index until the entry is deallocated
  wire                    rd_buF_rd_addr_hi_v_r;
  wire [ENT_ID_WIDTH-1:0] rd_buf_rd_addr_hi_r;
  dffr                 u_rd_buf_rd_addr_hi_v_r (rd_buf_rd_addr_hi_v_r, rd_buf_rd_addr_hi_v_nxt,
                                                bus_clk, 1'b1, rst);
  dff  #(ENT_ID_WIDTH) u_rd_buf_rd_addr_hi_r   (rd_buf_rd_addr_hi_r, rd_buf_rd_addr_hi_base,
                                                bus_clk, ~rd_buf_rd_addr_hi_v_r);
  assign rd_buf_rd_addr_hi_v_nxt = (rd_buf_rd_addr_hi_v_r | buf_intf_cmd_v) & ~intf_buf_cmd_done;
  assign rd_buf_rd_addr_hi = rd_buf_rd_addr_hi_v_r ? rd_buf_rd_addr_hi_r : rd_buf_rd_addr_hi_base;

  wire [CMD_ID_WIDTH:0] rd_buf_rd_addr, rd_buf_wr_addr;
  assign rd_buf_rd_addr = {rd_buf_rd_addr_hi,rd_buf_rd_addr_lo_r};
  assign rd_buf_wr_addr = {rd_data_addr,rd_data_offset};

  sram_1r1w #(
    .ADDRW(CMD_ID_WIDTH+1),
    .DATAW(64)
  ) u_rd_buf_ram (
    .rd_clk(bus_clk),
    .rd_en(intf_buf_rd_v),
    .rd_addr(rd_buf_rd_addr),
    .rd_data(buf_intf_rd_data),
    .wr_clk(memc_clk),
    .wr_en(rd_data_en),
    .wr_addr(rd_buf_wr_addr),
    .wr_data(rd_data));

  // response beats
  wire ent_rd_rsp_beat_v, ent_wr_rsp_beat_v;
  assign ent_rd_rsp_beat_v = rd_data_en & rd_data_offset;
  assign ent_wr_rsp_beat_v = wr_data_en & wr_data_offset;

  wire [BUF_ENTRIES-1:0] ent_rd_rsp_beat_base;
  wire [BUF_ENTRIES-1:0] ent_wr_rsp_beat_base;
  wire [BUF_ENTRIES-1:0] ent_rsp_beat;
  decoder #(ENT_ID_WIDTH) u_ent_rd_rsp_beat_base (
    .in(rd_data_addr[$clog2(CMD_PER_ENT)+:ENT_ID_WIDTH]),
    .out(ent_rd_rsp_beat_base));
  decoder #(ENT_ID_WIDTH) u_ent_wr_rsp_beat_base (
    .in(wr_data_addr[$clog2(CMD_PER_ENT)+:ENT_ID_WIDTH]),
    .out(ent_wr_rsp_beat_base));
  assign ent_rsp_beat = {BUF_ENTRIES{ent_rd_rsp_beat_v}} & ent_rd_rsp_beat_base |
                        {BUF_ENTRIES{ent_wr_rsp_beat_v}} & ent_wr_rsp_beat_base;

  // write data buffer
  wire wr_buf_wr_v;
  assign wr_buf_wr_v = intf_buf_wr_v & buf_intf_cmd_rdy;

  wire [$clog2(CMD_PER_ENT):0] wr_buf_wr_addr_lo_r, wr_buf_wr_addr_lo_nxt;
  dffr #($clog2(CMD_PER_ENT)+1) u_wr_buf_wr_addr_lo_r (wr_buf_wr_addr_lo_r, wr_buf_wr_addr_lo_nxt,
                                                       bus_clk, wr_buf_wr_v, rst);
  assign wr_buf_wr_addr_lo_nxt = wr_buf_wr_addr_lo_r + 1;

  wire [ENT_ID_WIDTH-1:0] wr_buf_wr_addr_hi;
  encoder #(BUF_ENTRIES) u_wr_buf_wr_addr_hi (
    .in(ent_alloc_sel_base),
    .invalid(),
    .out(wr_buf_wr_addr_hi));

  wire [CMD_ID_WIDTH:0] wr_buf_rd_addr, wr_buf_wr_addr;
  assign wr_buf_rd_addr = {wr_data_addr,wr_data_offset};
  assign wr_buf_wr_addr = {wr_buf_wr_addr_hi,wr_buf_wr_addr_lo_r};

  // 0 = written to memory
  assign wr_data_mask = 8'b0;

  sram_1r1w #(
    .ADDRW(CMD_ID_WIDTH+1),
    .DATAW(64),
    .DELAY(1)
  ) u_wr_buf_ram (
    .rd_clk(memc_clk),
    .rd_en(wr_data_en),
    .rd_addr(wr_buf_rd_addr),
    .rd_data(wr_data),
    .wr_clk(bus_clk),
    .wr_en(wr_buf_wr_v),
    .wr_addr(wr_buf_wr_addr),
    .wr_data(intf_buf_wr_data));

endmodule
