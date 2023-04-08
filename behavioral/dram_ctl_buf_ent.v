module dram_ctl_buf_ent #(
  parameter TAG_WIDTH = 5,
  parameter ADDR_MSB = 31,
  parameter ADDR_LSB = 6,
  parameter CMD_PER_ENT = 4
  )(
  input                      bus_clk,
  input                      rst,

  input                      memc_clk,
  input                      memc_rst,

  input                      wr_v,
  input                      wr_write,
  input [TAG_WIDTH-1:0]      wr_tag,
  input [ADDR_MSB:ADDR_LSB]  wr_addr,

  input                      cmd_beat,
  input                      rsp_beat,
  input                      dealloc,

  output                     state_idle,
  output                     state_cmd,
  output                     state_done,

  output [CMD_CNT_WIDTH-1:0] state_cnt,

  output                     write,
  output [TAG_WIDTH-1:0]     tag,
  output [ADDR_MSB:ADDR_LSB] addr);

  localparam CMD_CNT_WIDTH = $clog2(CMD_PER_ENT);

  wire                     valid_r, valid_nxt;
  wire                     write_r;
  wire [TAG_WIDTH-1:0]     tag_r;
  wire [ADDR_MSB:ADDR_LSB] addr_r;
  dffr                        u_valid_r (valid_r, valid_nxt, bus_clk, 1'b1, rst);
  dff                         u_write_r (write_r, wr_write,  bus_clk, wr_v);
  dff  #(TAG_WIDTH)           u_tag_r   (tag_r,   wr_tag,    bus_clk, wr_v);
  dff  #(ADDR_MSB-ADDR_LSB+1) u_addr_r  (addr_r,  wr_addr,   bus_clk, wr_v);

  wire valid_sync;
  syncr u_valid_sync (valid_sync, valid_r, memc_clk, memc_rst);

  // writes do not need to wait for dealloc signal from intf
  assign dealloc_v = dealloc | valid_r & write_r & rsp_done_sync;
  assign valid_nxt = (valid_r | wr_v) & ~dealloc_v;

  wire [CMD_CNT_WIDTH:0] cmd_cnt_r, cmd_cnt_nxt;
  wire [CMD_CNT_WIDTH:0] rsp_cnt_r, rsp_cnt_nxt;
  dffr #(CMD_CNT_WIDTH+1) u_cmd_cnt_r (cmd_cnt_r, cmd_cnt_nxt, memc_clk, 1'b1, memc_rst);
  dffr #(CMD_CNT_WIDTH+1) u_rsp_cnt_r (rsp_cnt_r, rsp_cnt_nxt, memc_clk, 1'b1, memc_rst);

  wire rsp_done_sync;
  syncr u_rsp_done_sync (rsp_done_sync, rsp_cnt_r[CMD_CNT_WIDTH], bus_clk, rst);

  assign cmd_cnt_nxt = ~valid_sync ? 0 : (cmd_cnt_r + cmd_beat);
  assign rsp_cnt_nxt = ~valid_sync ? 0 : (rsp_cnt_r + rsp_beat);

  assign state_idle = ~valid_sync & (cmd_cnt_r == 0) & (rsp_cnt_r == 0);
  // writes do not need to indicate state_done to be sent to intf
  assign state_done =  valid_sync & ~write_r & rsp_cnt_r[CMD_CNT_WIDTH];

  // these need to update immediately due to accept being staged one cycle
  assign state_cmd = valid_sync & ~cmd_cnt_nxt[CMD_CNT_WIDTH];
  assign state_cnt = cmd_cnt_nxt[CMD_CNT_WIDTH-1:0];

  assign write = write_r;
  assign tag  = tag_r;
  assign addr = addr_r;

endmodule
