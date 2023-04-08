module dram_ctl #(
  parameter CK_WIDTH = 1,
  parameter CKE_WIDTH = 1,
  parameter CS_WIDTH = 1,
  parameter nCS_PER_RANK = 1,
  parameter DM_WIDTH = 2,
  parameter ODT_WIDTH = 1,
  parameter DATA_WIDTH = 16,
  parameter BANK_WIDTH = 3,
  parameter ROW_WIDTH = 14,
  parameter COL_WIDTH = 10,
  parameter TAG_WIDTH = 5,
  parameter BUF_ENTRIES = 16,
  parameter CMD_PER_ENT = 4
  )(
  /*AUTOINPUT*/
  // Beginning of automatic inputs (from unused autoinst inputs)
  input [31:6]          bus_addr,
  input [2:0]           bus_cmd,
  input [63:0]          bus_data,
  input                 bus_dramctl_grant,
  input                 bus_hit,
  input                 bus_nack,
  input [TAG_WIDTH-1:0] bus_tag,
  input                 bus_valid,
  input                 clk,
  input                 clk_ref_i,
  input                 rst,
  input                 sys_clk_i,
  // End of automatics
  /*AUTOOUTPUT*/
  // Beginning of automatic outputs (from unused autoinst outputs)
  output [13:0]         ddr_addr,
  output [2:0]          ddr_ba,
  output                ddr_cas_n,
  output [0:0]          ddr_ck,
  output [0:0]          ddr_ck_n,
  output [0:0]          ddr_cke,
  output [0:0]          ddr_cs_n,
  output [1:0]          ddr_dm,
  output [0:0]          ddr_odt,
  output                ddr_parity,
  output                ddr_ras_n,
  output                ddr_reset_n,
  output                ddr_we_n,
  output [31:6]         dramctl_bus_addr,
  output [2:0]          dramctl_bus_cmd,
  output [63:0]         dramctl_bus_data,
  output                dramctl_bus_nack,
  output                dramctl_bus_req,
  output [TAG_WIDTH-1:0] dramctl_bus_tag,
  // End of automatics
  /*AUTOINOUT*/
  // Beginning of automatic inouts (from unused autoinst inouts)
  inout [15:0]          ddr_dq,
  inout [1:0]           ddr_dqs,
  inout [1:0]           ddr_dqs_n
  // End of automatics
);

  localparam ADDR_MSB = BANK_WIDTH + ROW_WIDTH + COL_WIDTH - 1;

  // each command reads 16 bytes, so each entry sends four commands
  localparam ENT_ID_WIDTH = $clog2(BUF_ENTRIES);
  localparam CMD_ID_WIDTH = ENT_ID_WIDTH + $clog2(CMD_PER_ENT);

  localparam nCK_PER_CLK = 2;
  localparam DATA_BUF_ADDR_WIDTH = CMD_ID_WIDTH;
  localparam DATA_BUF_OFFSET_WIDTH = 1;
  localparam PAYLOAD_WIDTH = DATA_WIDTH;
  localparam RANK_WIDTH = 1;

  wire rank;

  /*AUTOWIRE*/
  // Beginning of automatic wires (for undeclared instantiated-module outputs)
  wire                  accept;
  wire                  accept_ns;
  wire                  app_ref_ack;
  wire                  app_ref_req;
  wire                  app_sr_active;
  wire                  app_sr_req;
  wire                  app_zq_ack;
  wire                  app_zq_req;
  wire [BANK_WIDTH-1:0] bank;
  wire                  buf_intf_cmd_2rdy;
  wire                  buf_intf_cmd_2v;
  wire [ADDR_MSB:6]     buf_intf_cmd_addr;
  wire                  buf_intf_cmd_rdy;
  wire [TAG_WIDTH-1:0]  buf_intf_cmd_tag;
  wire                  buf_intf_cmd_v;
  wire [63:0]           buf_intf_rd_data;
  wire [2:0]            cmd;
  wire [COL_WIDTH-1:0]  col;
  wire [CMD_ID_WIDTH-1:0] data_buf_addr;
  wire                  hi_priority;
  wire                  init_calib_complete;
  wire [ADDR_MSB:6]     intf_buf_addr;
  wire                  intf_buf_cmd_done;
  wire                  intf_buf_cmd_v;
  wire                  intf_buf_rd_v;
  wire [TAG_WIDTH-1:0]  intf_buf_tag;
  wire [63:0]           intf_buf_wr_data;
  wire                  intf_buf_wr_v;
  wire                  intf_buf_write;
  wire                  memc_clk;
  wire                  memc_rst;
  wire [63:0]           rd_data;
  wire [DATA_BUF_ADDR_WIDTH-1:0] rd_data_addr;
  wire                  rd_data_en;
  wire                  rd_data_end;
  wire [DATA_BUF_OFFSET_WIDTH-1:0] rd_data_offset;
  wire [ROW_WIDTH-1:0]  row;
  wire                  use_addr;
  wire [63:0]           wr_data;
  wire [DATA_BUF_ADDR_WIDTH-1:0] wr_data_addr;
  wire                  wr_data_en;
  wire [7:0]            wr_data_mask;
  wire [DATA_BUF_OFFSET_WIDTH-1:0] wr_data_offset;
  // End of automatics

  dram_ctl_memc #(
    .BANK_WIDTH(3),
    .CK_WIDTH(1),
    .COL_WIDTH(10),
    .CS_WIDTH(1),
    .nCS_PER_RANK(1),
    .CKE_WIDTH(1),
    .DATA_BUF_ADDR_WIDTH(DATA_BUF_ADDR_WIDTH),
    .DQ_CNT_WIDTH(4),
    .DQ_PER_DM(8),
    .DM_WIDTH(2),
    .DQ_WIDTH(16),
    .DQS_WIDTH(2),
    .DQS_CNT_WIDTH(1),
    .DRAM_WIDTH(8),
    .ECC("OFF"),
    .DATA_WIDTH(16),
    .ECC_TEST("OFF"),
    .PAYLOAD_WIDTH(DATA_WIDTH),
    .MEM_ADDR_ORDER("ROW_BANK_COLUMN"),
    .nBANK_MACHS(4),
    .RANKS(1),
    .ODT_WIDTH(1),
    .ROW_WIDTH(14),
    .ADDR_WIDTH(28),
    .USE_CS_PORT(1),
    .USE_DM_PORT(1),
    .USE_ODT_PORT(1),
    .IS_CLK_SHARED("FALSE"),
    .PHY_CONTROL_MASTER_BANK(0),
    .MEM_DENSITY("2Gb"),
    .MEM_SPEEDGRADE("15E"),
    .MEM_DEVICE_WIDTH(16),
    .AL("0"),
    .nAL(0),
    .BURST_MODE("8"),
    .BURST_TYPE("SEQ"),
    .CL(5),
    .CWL(5),
    .OUTPUT_DRV("LOW"),
    .RTT_NOM("40"),
    .RTT_WR("OFF"),
    .ADDR_CMD_MODE("1T" ),
    .REG_CTRL("OFF"),
    .CA_MIRROR("OFF"),
    .VDD_OP_VOLT("135"),
    .CLKIN_PERIOD(10000),
    .CLKFBOUT_MULT(13),
    .DIVCLK_DIVIDE(1),
    .CLKOUT0_PHASE(0.0),
    .CLKOUT0_DIVIDE(2),
    .CLKOUT1_DIVIDE(4),
    .CLKOUT2_DIVIDE(64),
    .CLKOUT3_DIVIDE(8),
    .MMCM_VCO(649),
    .MMCM_MULT_F(4),
    .MMCM_DIVCLK_DIVIDE(1),
    .MMCM_CLKOUT0_EN("TRUE"),
    .MMCM_CLKOUT1_EN("FALSE"),
    .MMCM_CLKOUT2_EN("FALSE"),
    .MMCM_CLKOUT3_EN("FALSE"),
    .MMCM_CLKOUT4_EN("FALSE"),
    .MMCM_CLKOUT0_DIVIDE(3.25),
    .MMCM_CLKOUT1_DIVIDE(1),
    .MMCM_CLKOUT2_DIVIDE(1),
    .MMCM_CLKOUT3_DIVIDE(1),
    .MMCM_CLKOUT4_DIVIDE(1),
    .tCKE(5625),
    .tFAW(45000),
    .tPRDI(1_000_000),
    .tRAS(36000),
    .tRCD(13500),
    .tREFI(7800000),
    .tRFC(160000),
    .tRP(13500),
    .tRRD(7500),
    .tRTP(7500),
    .tWTR(7500),
    .tZQI(128_000_000),
    .tZQCS(64),
    .SIM_BYPASS_INIT_CAL("FAST"),
    .SIMULATION("TRUE"),
    .BYTE_LANES_B0(4'b1111),
    .BYTE_LANES_B1(4'b0000),
    .BYTE_LANES_B2(4'b0000),
    .BYTE_LANES_B3(4'b0000),
    .BYTE_LANES_B4(4'b0000),
    .DATA_CTL_B0(4'b1100),
    .DATA_CTL_B1(4'b0000),
    .DATA_CTL_B2(4'b0000),
    .DATA_CTL_B3(4'b0000),
    .DATA_CTL_B4(4'b0000),
    .PHY_0_BITLANES(48'h3FE_3FD_FFF_BFF),
    .PHY_1_BITLANES(48'h000_000_000_000),
    .PHY_2_BITLANES(48'h000_000_000_000),
    .CK_BYTE_MAP(144'h00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00),
    .ADDR_MAP(192'h000_000_000_002_004_009_007_001_005_006_003_010_012_014_011_01A),
    .BANK_MAP(36'h01B_017_013),
    .CAS_MAP(12'h015),
    .CKE_ODT_BYTE_MAP(8'h00),
    .CKE_MAP(96'h000_000_000_000_000_000_000_018),
    .ODT_MAP(96'h000_000_000_000_000_000_000_008),
    .CS_MAP(120'h000_000_000_000_000_000_000_000_000_019),
    .PARITY_MAP(12'h000),
    .RAS_MAP(12'h016),
    .WE_MAP(12'h00B),
    .DQS_BYTE_MAP(144'h00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_02_03),
    .DATA0_MAP(96'h034_033_032_035_031_038_037_036),
    .DATA1_MAP(96'h023_027_022_028_025_026_020_024),
    .DATA2_MAP(96'h000_000_000_000_000_000_000_000),
    .DATA3_MAP(96'h000_000_000_000_000_000_000_000),
    .DATA4_MAP(96'h000_000_000_000_000_000_000_000),
    .DATA5_MAP(96'h000_000_000_000_000_000_000_000),
    .DATA6_MAP(96'h000_000_000_000_000_000_000_000),
    .DATA7_MAP(96'h000_000_000_000_000_000_000_000),
    .DATA8_MAP(96'h000_000_000_000_000_000_000_000),
    .DATA9_MAP(96'h000_000_000_000_000_000_000_000),
    .DATA10_MAP(96'h000_000_000_000_000_000_000_000),
    .DATA11_MAP(96'h000_000_000_000_000_000_000_000),
    .DATA12_MAP(96'h000_000_000_000_000_000_000_000),
    .DATA13_MAP(96'h000_000_000_000_000_000_000_000),
    .DATA14_MAP(96'h000_000_000_000_000_000_000_000),
    .DATA15_MAP(96'h000_000_000_000_000_000_000_000),
    .DATA16_MAP(96'h000_000_000_000_000_000_000_000),
    .DATA17_MAP(96'h000_000_000_000_000_000_000_000),
    .MASK0_MAP(108'h000_000_000_000_000_000_000_029_039),
    .MASK1_MAP(108'h000_000_000_000_000_000_000_000_000),
    .SLOT_0_CONFIG(8'b0000_0001),
    .SLOT_1_CONFIG(8'b0000_0000),
    .IBUF_LPWR_MODE("OFF"),
    .DATA_IO_IDLE_PWRDWN("ON"),
    .BANK_TYPE("HR_IO"),
    .DATA_IO_PRIM_TYPE("HR_LP"),
    .CKE_ODT_AUX("FALSE"),
    .USER_REFRESH("OFF"),
    .WRLVL("ON"),
    .ORDERING("NORM"),
    .CALIB_ROW_ADD(16'h0000),
    .CALIB_COL_ADD(12'h000),
    .CALIB_BA_ADD(3'h0),
    .TCQ(100),
    .IDELAY_ADJ("OFF"),
    .FINE_PER_BIT("OFF"),
    .CENTER_COMP_MODE("OFF"),
    .PI_VAL_ADJ("OFF"),
    .IODELAY_GRP0("DRAM_MIG_IODELAY_MIG0"),
    .IODELAY_GRP1("DRAM_MIG_IODELAY_MIG1"),
    .SYSCLK_TYPE("SINGLE_ENDED"),
    .REFCLK_TYPE("NO_BUFFER"),
    .SYS_RST_PORT("FALSE"),
    .FPGA_SPEED_GRADE(1),
    .CMD_PIPE_PLUS1("ON"),
    .DRAM_TYPE("DDR3"),
    .CAL_WIDTH("HALF"),
    .STARVE_LIMIT(2),
    .REF_CLK_MMCM_IODELAY_CTRL("FALSE"),
    .REFCLK_FREQ(200.0),
    .DIFF_TERM_REFCLK("TRUE"),
    .tCK(3077),
    .nCK_PER_CLK(2),
    .DIFF_TERM_SYSCLK("FALSE"),
    .DEBUG_PORT("OFF"),
    .TEMP_MON_CONTROL("INTERNAL"),
    .FPGA_VOLT_TYPE("N"),
    .RST_ACT_LOW(0)
  ) u_memc (
    // Inputs
    .sys_rst(rst),
    .rank(rank),
    /*AUTOINST*/
    // Outputs
    .accept(accept),
    .accept_ns(accept_ns),
    .app_ref_ack(app_ref_ack),
    .app_sr_active(app_sr_active),
    .app_zq_ack(app_zq_ack),
    .ddr_addr(ddr_addr[13:0]),
    .ddr_ba(ddr_ba[2:0]),
    .ddr_cas_n(ddr_cas_n),
    .ddr_ck(ddr_ck[0:0]),
    .ddr_ck_n(ddr_ck_n[0:0]),
    .ddr_cke(ddr_cke[0:0]),
    .ddr_cs_n(ddr_cs_n[0:0]),
    .ddr_dm(ddr_dm[1:0]),
    .ddr_odt(ddr_odt[0:0]),
    .ddr_parity(ddr_parity),
    .ddr_ras_n(ddr_ras_n),
    .ddr_reset_n(ddr_reset_n),
    .ddr_we_n(ddr_we_n),
    .init_calib_complete(init_calib_complete),
    .memc_clk(memc_clk),
    .memc_rst(memc_rst),
    .rd_data(rd_data[63:0]),
    .rd_data_addr(rd_data_addr[DATA_BUF_ADDR_WIDTH-1:0]),
    .rd_data_en(rd_data_en),
    .rd_data_end(rd_data_end),
    .rd_data_offset(rd_data_offset[DATA_BUF_OFFSET_WIDTH-1:0]),
    .wr_data_addr(wr_data_addr[DATA_BUF_ADDR_WIDTH-1:0]),
    .wr_data_en(wr_data_en),
    .wr_data_offset(wr_data_offset[DATA_BUF_OFFSET_WIDTH-1:0]),
    // Inouts
    .ddr_dq(ddr_dq[15:0]),
    .ddr_dqs(ddr_dqs[1:0]),
    .ddr_dqs_n(ddr_dqs_n[1:0]),
    // Inputs
    .app_ref_req(app_ref_req),
    .app_sr_req(app_sr_req),
    .app_zq_req(app_zq_req),
    .bank(bank[2:0]),
    .clk_ref_i(clk_ref_i),
    .cmd(cmd[2:0]),
    .col(col[9:0]),
    .data_buf_addr(data_buf_addr[DATA_BUF_ADDR_WIDTH-1:0]),
    .hi_priority(hi_priority),
    .row(row[13:0]),
    .sys_clk_i(sys_clk_i),
    .use_addr(use_addr),
    .wr_data(wr_data[63:0]),
    .wr_data_mask(wr_data_mask[7:0]));

  dram_ctl_buf u_buf (
    // Inputs
    .bus_clk(clk),
    /*AUTOINST*/
    // Outputs
    .bank(bank[BANK_WIDTH-1:0]),
    .buf_intf_cmd_2rdy(buf_intf_cmd_2rdy),
    .buf_intf_cmd_2v(buf_intf_cmd_2v),
    .buf_intf_cmd_addr(buf_intf_cmd_addr[ADDR_MSB:6]),
    .buf_intf_cmd_rdy(buf_intf_cmd_rdy),
    .buf_intf_cmd_tag(buf_intf_cmd_tag[TAG_WIDTH-1:0]),
    .buf_intf_cmd_v(buf_intf_cmd_v),
    .buf_intf_rd_data(buf_intf_rd_data[63:0]),
    .cmd(cmd[2:0]),
    .col(col[COL_WIDTH-1:0]),
    .data_buf_addr(data_buf_addr[CMD_ID_WIDTH-1:0]),
    .hi_priority(hi_priority),
    .row(row[ROW_WIDTH-1:0]),
    .use_addr(use_addr),
    .wr_data(wr_data[63:0]),
    .wr_data_mask(wr_data_mask[7:0]),
    // Inputs
    .accept(accept),
    .intf_buf_addr(intf_buf_addr[ADDR_MSB:6]),
    .intf_buf_cmd_done(intf_buf_cmd_done),
    .intf_buf_cmd_v(intf_buf_cmd_v),
    .intf_buf_rd_v(intf_buf_rd_v),
    .intf_buf_tag(intf_buf_tag[TAG_WIDTH-1:0]),
    .intf_buf_wr_data(intf_buf_wr_data[63:0]),
    .intf_buf_wr_v(intf_buf_wr_v),
    .intf_buf_write(intf_buf_write),
    .memc_clk(memc_clk),
    .memc_rst(memc_rst),
    .rd_data(rd_data[63:0]),
    .rd_data_addr(rd_data_addr[CMD_ID_WIDTH-1:0]),
    .rd_data_en(rd_data_en),
    .rd_data_end(rd_data_end),
    .rd_data_offset(rd_data_offset),
    .rst(rst),
    .wr_data_addr(wr_data_addr[CMD_ID_WIDTH-1:0]),
    .wr_data_en(wr_data_en),
    .wr_data_offset(wr_data_offset));

  dram_ctl_intf u_intf (
    /*AUTOINST*/
    // Outputs
    .dramctl_bus_addr(dramctl_bus_addr[31:6]),
    .dramctl_bus_cmd(dramctl_bus_cmd[2:0]),
    .dramctl_bus_data(dramctl_bus_data[63:0]),
    .dramctl_bus_nack(dramctl_bus_nack),
    .dramctl_bus_req(dramctl_bus_req),
    .dramctl_bus_tag(dramctl_bus_tag[TAG_WIDTH-1:0]),
    .intf_buf_addr(intf_buf_addr[ADDR_MSB:6]),
    .intf_buf_cmd_done(intf_buf_cmd_done),
    .intf_buf_cmd_v(intf_buf_cmd_v),
    .intf_buf_rd_v(intf_buf_rd_v),
    .intf_buf_tag(intf_buf_tag[TAG_WIDTH-1:0]),
    .intf_buf_wr_data(intf_buf_wr_data[63:0]),
    .intf_buf_wr_v(intf_buf_wr_v),
    .intf_buf_write(intf_buf_write),
    // Inputs
    .buf_intf_cmd_2rdy(buf_intf_cmd_2rdy),
    .buf_intf_cmd_2v(buf_intf_cmd_2v),
    .buf_intf_cmd_addr(buf_intf_cmd_addr[ADDR_MSB:6]),
    .buf_intf_cmd_rdy(buf_intf_cmd_rdy),
    .buf_intf_cmd_tag(buf_intf_cmd_tag[TAG_WIDTH-1:0]),
    .buf_intf_cmd_v(buf_intf_cmd_v),
    .buf_intf_rd_data(buf_intf_rd_data[63:0]),
    .bus_addr(bus_addr[31:6]),
    .bus_cmd(bus_cmd[2:0]),
    .bus_data(bus_data[63:0]),
    .bus_dramctl_grant(bus_dramctl_grant),
    .bus_hit(bus_hit),
    .bus_nack(bus_nack),
    .bus_tag(bus_tag[TAG_WIDTH-1:0]),
    .bus_valid(bus_valid),
    .clk(clk),
    .rst(rst));

  dram_ctl_misc u_misc (
    /*AUTOINST*/
    // Outputs
    .app_ref_req(app_ref_req),
    .app_sr_req(app_sr_req),
    .app_zq_req(app_zq_req),
    .rank(rank),
    // Inputs
    .accept_ns(accept_ns),
    .app_ref_ack(app_ref_ack),
    .app_sr_active(app_sr_active),
    .app_zq_ack(app_zq_ack),
    .init_calib_complete(init_calib_complete));

endmodule
