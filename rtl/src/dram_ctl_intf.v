module dram_ctl_intf #(
  parameter BANK_WIDTH = 3,
  parameter ROW_WIDTH = 14,
  parameter COL_WIDTH = 10,
  parameter TAG_WIDTH = 5
  )(
  input                      clk,
  input                      rst,

  // bus interface
  input                      bus_valid,
  input                      bus_nack,
  input                      bus_hit,
  input [2:0]                bus_cmd,
  input [TAG_WIDTH-1:0]      bus_tag,
  input [31:6]               bus_addr,
  input [63:0]               bus_data,

  output reg                 dramctl_bus_req,
  output [2:0]               dramctl_bus_cmd,
  output reg [TAG_WIDTH-1:0] dramctl_bus_tag,
  output reg [31:6]          dramctl_bus_addr,
  output [63:0]              dramctl_bus_data,
  output reg                 dramctl_bus_nack,
  input                      bus_dramctl_grant,

  // buf interface
  output                     intf_buf_cmd_v,
  output                     intf_buf_write,
  output [TAG_WIDTH-1:0]     intf_buf_tag,
  output [ADDR_MSB:6]        intf_buf_addr,
  input                      buf_intf_cmd_rdy,
  input                      buf_intf_cmd_2rdy,

  output                     intf_buf_wr_v,
  output [63:0]              intf_buf_wr_data,

  input                      buf_intf_cmd_v,
  input                      buf_intf_cmd_2v,
  input [TAG_WIDTH-1:0]      buf_intf_cmd_tag,
  input [ADDR_MSB:6]         buf_intf_cmd_addr,
  output                     intf_buf_cmd_done,

  output                     intf_buf_rd_v,
  input [63:0]               buf_intf_rd_data);

  localparam ADDR_BASE = 32'h20000000;
  localparam ADDR_MSB = BANK_WIDTH + ROW_WIDTH + COL_WIDTH - 1;

  wire cmd_relevant, cmd_write;
  assign cmd_relevant = bus_valid & ~bus_nack & (~bus_hit | (bus_cmd == `CMD_FLUSH)) &
                        ((bus_cmd == `CMD_BUSRD) | (bus_cmd == `CMD_BUSRDX) | (bus_cmd == `CMD_FLUSH)) &
                        (bus_addr[31:ADDR_MSB+1] == ADDR_BASE[31:ADDR_MSB+1]);
  assign cmd_write = (bus_cmd == `CMD_FLUSH);

  reg [2:0] bus_cycle_r;
  always @(posedge clk)
    if(rst)
      bus_cycle_r <= 0;
    else
      bus_cycle_r <= bus_cycle_r + 1;

  // | Cycle | Read  | Resp0 | Resp1        | Write      |
  // |     0 |       | Req   | Data         | Data/Req   |
  // |     1 |       |       | Data         | Data       |
  // |     2 |       |       | Data         | Data       |
  // |     3 | NACK  | NACK  | Data         | Data/NACK  |
  // |     4 |       |       | Data         | Data       |
  // |     5 |       |       | Data/Dealloc | Data       |
  // |     6 |       |       | Data         | Data       |
  // |     7 | Alloc |       | Data         | Data/Alloc |

  reg                 alloc_v_r;
  reg                 alloc_write_r;
  reg [TAG_WIDTH-1:0] alloc_tag_r;
  reg [ADDR_MSB:6]    alloc_addr_r;
  always @(posedge clk)
    if(rst) begin
      alloc_v_r <= 0;
      dramctl_bus_nack <= 0;
    end else if(bus_cycle_r == 3)
      dramctl_bus_nack <= cmd_relevant & ~buf_intf_cmd_rdy;
    else if(bus_cycle_r == 7) begin
      alloc_v_r <= cmd_relevant;
      alloc_write_r <= cmd_write;
      alloc_tag_r <= bus_tag;
      alloc_addr_r <= bus_addr[ADDR_MSB:6];
    end

  assign intf_buf_cmd_v = alloc_v_r & (bus_cycle_r == 0);
  assign intf_buf_write = alloc_write_r;
  assign intf_buf_tag = alloc_tag_r;
  assign intf_buf_addr = alloc_addr_r;

  // the bus command appears at the same time as the data, so we must speculatively write
  assign intf_buf_wr_v = cmd_relevant & cmd_write & buf_intf_cmd_rdy;
  assign intf_buf_wr_data = bus_data;

  reg read_data_v_r;
  assign dramctl_bus_cmd = `CMD_FILL;
  always @(posedge clk)
    if(rst) begin
      dramctl_bus_req <= 0;
      read_data_v_r <= 0;
    end else if(bus_cycle_r == 7) begin
      dramctl_bus_req <= buf_intf_cmd_v & (~read_data_v_r | buf_intf_cmd_2v);
      dramctl_bus_tag <= buf_intf_cmd_tag;
      dramctl_bus_addr <= {ADDR_BASE[31:ADDR_MSB+1],buf_intf_cmd_addr};
    end else if(bus_cycle_r == 5)
      read_data_v_r <= dramctl_bus_req & bus_dramctl_grant;

  assign intf_buf_rd_v = read_data_v_r;
  assign intf_buf_cmd_done = read_data_v_r & (bus_cycle_r == 5);
  assign dramctl_bus_data = buf_intf_rd_data;

endmodule
