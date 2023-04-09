module dram_ctl_memc #(
   parameter BANK_WIDTH            = 3,
   parameter CK_WIDTH              = 1,
   parameter COL_WIDTH             = 10,
   parameter CS_WIDTH              = 1,
   parameter nCS_PER_RANK          = 1,
   parameter CKE_WIDTH             = 1,
   parameter DATA_BUF_ADDR_WIDTH   = 4,
   parameter DQ_CNT_WIDTH          = 4,
   parameter DQ_PER_DM             = 8,
   parameter DM_WIDTH              = 2,
   parameter DQ_WIDTH              = 16,
   parameter DQS_WIDTH             = 2,
   parameter DQS_CNT_WIDTH         = 1,
   parameter DRAM_WIDTH            = 8,
   parameter ECC                   = "OFF",
   parameter DATA_WIDTH            = 16,
   parameter ECC_TEST              = "OFF",
   parameter PAYLOAD_WIDTH         = (ECC_TEST == "OFF") ? DATA_WIDTH : DQ_WIDTH,
   parameter MEM_ADDR_ORDER        = "ROW_BANK_COLUMN",
   parameter nBANK_MACHS           = 4,
   parameter RANKS                 = 1,
   parameter ODT_WIDTH             = 1,
   parameter ROW_WIDTH             = 14,
   parameter ADDR_WIDTH            = 28,
   parameter USE_CS_PORT          = 1,
   parameter USE_DM_PORT           = 1,
   parameter USE_ODT_PORT          = 1,
   parameter IS_CLK_SHARED          = "FALSE",
   parameter PHY_CONTROL_MASTER_BANK = 0,
   parameter MEM_DENSITY           = "2Gb",
   parameter MEM_SPEEDGRADE        = "15E",
   parameter MEM_DEVICE_WIDTH      = 16,
   parameter AL                    = "0",
   parameter nAL                   = 0,
   parameter BURST_MODE            = "8",
   parameter BURST_TYPE            = "SEQ",
   parameter CL                    = 5,
   parameter CWL                   = 5,
   parameter OUTPUT_DRV            = "LOW",
   parameter RTT_NOM               = "40",
   parameter RTT_WR                = "OFF",
   parameter ADDR_CMD_MODE         = "1T" ,
   parameter REG_CTRL              = "OFF",
   parameter CA_MIRROR             = "OFF",
   parameter VDD_OP_VOLT           = "135",
   parameter CLKIN_PERIOD          = 10000,
   parameter CLKFBOUT_MULT         = 13,
   parameter DIVCLK_DIVIDE         = 1,
   parameter CLKOUT0_PHASE         = 0.0,
   parameter CLKOUT0_DIVIDE        = 2,
   parameter CLKOUT1_DIVIDE        = 4,
   parameter CLKOUT2_DIVIDE        = 64,
   parameter CLKOUT3_DIVIDE        = 8,
   parameter MMCM_VCO              = 649,
   parameter MMCM_MULT_F           = 4,
   parameter MMCM_DIVCLK_DIVIDE    = 1,
   parameter MMCM_CLKOUT0_EN       = "TRUE",
   parameter MMCM_CLKOUT1_EN       = "FALSE",
   parameter MMCM_CLKOUT2_EN       = "FALSE",
   parameter MMCM_CLKOUT3_EN       = "FALSE",
   parameter MMCM_CLKOUT4_EN       = "FALSE",
   parameter MMCM_CLKOUT0_DIVIDE   = 3.25,
   parameter MMCM_CLKOUT1_DIVIDE   = 1,
   parameter MMCM_CLKOUT2_DIVIDE   = 1,
   parameter MMCM_CLKOUT3_DIVIDE   = 1,
   parameter MMCM_CLKOUT4_DIVIDE   = 1,
   parameter tCKE                  = 5625,
   parameter tFAW                  = 45000,
   parameter tPRDI                 = 1_000_000,
   parameter tRAS                  = 36000,
   parameter tRCD                  = 13500,
   parameter tREFI                 = 7800000,
   parameter tRFC                  = 160000,
   parameter tRP                   = 13500,
   parameter tRRD                  = 7500,
   parameter tRTP                  = 7500,
   parameter tWTR                  = 7500,
   parameter tZQI                  = 128_000_000,
   parameter tZQCS                 = 64,//64,
   parameter SIM_BYPASS_INIT_CAL   = "SKIP",
   parameter SIMULATION            = "TRUE",
   parameter BYTE_LANES_B0         = 4'b1111,
   parameter BYTE_LANES_B1         = 4'b0000,
   parameter BYTE_LANES_B2         = 4'b0000,
   parameter BYTE_LANES_B3         = 4'b0000,
   parameter BYTE_LANES_B4         = 4'b0000,
   parameter DATA_CTL_B0           = 4'b1100,
   parameter DATA_CTL_B1           = 4'b0000,
   parameter DATA_CTL_B2           = 4'b0000,
   parameter DATA_CTL_B3           = 4'b0000,
   parameter DATA_CTL_B4           = 4'b0000,
   parameter PHY_0_BITLANES        = 48'h3FE_3FD_FFF_BFF,
   parameter PHY_1_BITLANES        = 48'h000_000_000_000,
   parameter PHY_2_BITLANES        = 48'h000_000_000_000,
   parameter CK_BYTE_MAP
     = 144'h00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00,
   parameter ADDR_MAP
     = 192'h000_000_000_002_004_009_007_001_005_006_003_010_012_014_011_01A,
   parameter BANK_MAP   = 36'h01B_017_013,
   parameter CAS_MAP    = 12'h015,
   parameter CKE_ODT_BYTE_MAP = 8'h00,
   parameter CKE_MAP    = 96'h000_000_000_000_000_000_000_018,
   parameter ODT_MAP    = 96'h000_000_000_000_000_000_000_008,
   parameter CS_MAP     = 120'h000_000_000_000_000_000_000_000_000_019,
   parameter PARITY_MAP = 12'h000,
   parameter RAS_MAP    = 12'h016,
   parameter WE_MAP     = 12'h00B,
   parameter DQS_BYTE_MAP
     = 144'h00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_02_03,
   parameter DATA0_MAP  = 96'h034_033_032_035_031_038_037_036,
   parameter DATA1_MAP  = 96'h023_027_022_028_025_026_020_024,
   parameter DATA2_MAP  = 96'h000_000_000_000_000_000_000_000,
   parameter DATA3_MAP  = 96'h000_000_000_000_000_000_000_000,
   parameter DATA4_MAP  = 96'h000_000_000_000_000_000_000_000,
   parameter DATA5_MAP  = 96'h000_000_000_000_000_000_000_000,
   parameter DATA6_MAP  = 96'h000_000_000_000_000_000_000_000,
   parameter DATA7_MAP  = 96'h000_000_000_000_000_000_000_000,
   parameter DATA8_MAP  = 96'h000_000_000_000_000_000_000_000,
   parameter DATA9_MAP  = 96'h000_000_000_000_000_000_000_000,
   parameter DATA10_MAP = 96'h000_000_000_000_000_000_000_000,
   parameter DATA11_MAP = 96'h000_000_000_000_000_000_000_000,
   parameter DATA12_MAP = 96'h000_000_000_000_000_000_000_000,
   parameter DATA13_MAP = 96'h000_000_000_000_000_000_000_000,
   parameter DATA14_MAP = 96'h000_000_000_000_000_000_000_000,
   parameter DATA15_MAP = 96'h000_000_000_000_000_000_000_000,
   parameter DATA16_MAP = 96'h000_000_000_000_000_000_000_000,
   parameter DATA17_MAP = 96'h000_000_000_000_000_000_000_000,
   parameter MASK0_MAP  = 108'h000_000_000_000_000_000_000_029_039,
   parameter MASK1_MAP  = 108'h000_000_000_000_000_000_000_000_000,
   parameter SLOT_0_CONFIG         = 8'b0000_0001,
   parameter SLOT_1_CONFIG         = 8'b0000_0000,
   parameter IBUF_LPWR_MODE        = "OFF",
   parameter DATA_IO_IDLE_PWRDWN   = "ON",
   parameter BANK_TYPE             = "HR_IO",
   parameter DATA_IO_PRIM_TYPE     = "HR_LP",
   parameter CKE_ODT_AUX           = "FALSE",
   parameter USER_REFRESH          = "OFF",
   parameter WRLVL                 = "ON",
   parameter ORDERING              = "NORM",
   parameter CALIB_ROW_ADD         = 16'h0000,
   parameter CALIB_COL_ADD         = 12'h000,
   parameter CALIB_BA_ADD          = 3'h0,
   parameter TCQ                   = 100,
   parameter IDELAY_ADJ            = "OFF",
   parameter FINE_PER_BIT          = "OFF",
   parameter CENTER_COMP_MODE      = "OFF",
   parameter PI_VAL_ADJ            = "OFF",
   parameter IODELAY_GRP0          = "DRAM_MIG_IODELAY_MIG0",
   parameter IODELAY_GRP1          = "DRAM_MIG_IODELAY_MIG1",
   parameter SYSCLK_TYPE           = "SINGLE_ENDED",
   parameter REFCLK_TYPE           = "NO_BUFFER",
   parameter SYS_RST_PORT          = "FALSE",
   parameter FPGA_SPEED_GRADE      = 1,
   parameter CMD_PIPE_PLUS1        = "ON",
   parameter DRAM_TYPE             = "DDR3",
   parameter CAL_WIDTH             = "HALF",
   parameter STARVE_LIMIT          = 2,
   parameter REF_CLK_MMCM_IODELAY_CTRL    = "FALSE",
   parameter REFCLK_FREQ           = 200.0,
   parameter DIFF_TERM_REFCLK      = "TRUE",
   parameter tCK                   = 3077,
   parameter nCK_PER_CLK           = 2,
   parameter DIFF_TERM_SYSCLK      = "FALSE",
   parameter DEBUG_PORT            = "OFF",
   parameter TEMP_MON_CONTROL      = "INTERNAL",
   parameter FPGA_VOLT_TYPE        = "N",
   parameter RST_ACT_LOW           = 0
) (
  // Outputs
  output memc_clk,
  output memc_rst,
  /*AUTOINPUT*/
  // Beginning of automatic inputs (from unused autoinst inputs)
  input                 app_ref_req,
  input                 app_sr_req,
  input                 app_zq_req,
  input [BANK_WIDTH-1:0] bank,
  input                 clk_ref_i,
  input [2:0]           cmd,
  input [COL_WIDTH-1:0] col,
  input [DATA_BUF_ADDR_WIDTH-1:0] data_buf_addr,
  input                 hi_priority,
  input [RANK_WIDTH-1:0] rank,
  input [ROW_WIDTH-1:0] row,
  input                 sys_clk_i,
  input                 sys_rst,
  input                 use_addr,
  input [2*nCK_PER_CLK*PAYLOAD_WIDTH-1:0] wr_data,
  input [2*nCK_PER_CLK*DATA_WIDTH/8-1:0] wr_data_mask,
  // End of automatics
  /*AUTOOUTPUT*/
  // Beginning of automatic outputs (from unused autoinst outputs)
  output                accept,
  output                accept_ns,
  output                app_ref_ack,
  output                app_sr_active,
  output                app_zq_ack,
  output [ROW_WIDTH-1:0] ddr_addr,
  output [BANK_WIDTH-1:0] ddr_ba,
  output                ddr_cas_n,
  output [CK_WIDTH-1:0] ddr_ck,
  output [CK_WIDTH-1:0] ddr_ck_n,
  output [CKE_WIDTH-1:0] ddr_cke,
  output [CS_WIDTH*nCS_PER_RANK-1:0] ddr_cs_n,
  output [DM_WIDTH-1:0] ddr_dm,
  output [ODT_WIDTH-1:0] ddr_odt,
  output                ddr_parity,
  output                ddr_ras_n,
  output                ddr_reset_n,
  output                ddr_we_n,
  output                init_calib_complete,
  output [2*nCK_PER_CLK*PAYLOAD_WIDTH-1:0] rd_data,
  output [DATA_BUF_ADDR_WIDTH-1:0] rd_data_addr,
  output                rd_data_en,
  output                rd_data_end,
  output [DATA_BUF_OFFSET_WIDTH-1:0] rd_data_offset,
  output [DATA_BUF_ADDR_WIDTH-1:0] wr_data_addr,
  output                wr_data_en,
  output [DATA_BUF_OFFSET_WIDTH-1:0] wr_data_offset,
  // End of automatics
  /*AUTOINOUT*/
  // Beginning of automatic inouts (from unused autoinst inouts)
  inout [DQ_WIDTH-1:0]  ddr_dq,
  inout [DQS_WIDTH-1:0] ddr_dqs,
  inout [DQS_WIDTH-1:0] ddr_dqs_n
  // End of automatics
);

  function integer clogb2 (input integer size);
    begin
      size = size - 1;
      for (clogb2=1; size>1; clogb2=clogb2+1)
        size = size >> 1;
    end
  endfunction // clogb2

  localparam BM_CNT_WIDTH = clogb2(nBANK_MACHS);
  localparam RANK_WIDTH = clogb2(RANKS);

  localparam ECC_WIDTH = (ECC == "OFF") ? 0 :
                      (DATA_WIDTH <= 4) ? 4 :
                     (DATA_WIDTH <= 10) ? 5 :
                     (DATA_WIDTH <= 26) ? 6 :
                     (DATA_WIDTH <= 57) ? 7 :
                    (DATA_WIDTH <= 120) ? 8 :
                    (DATA_WIDTH <= 247) ? 9 :
                                          10;
  localparam DATA_BUF_OFFSET_WIDTH = 1;
  localparam MC_ERR_ADDR_WIDTH = ((CS_WIDTH == 1) ? 0 : RANK_WIDTH)
                                 + BANK_WIDTH + ROW_WIDTH + COL_WIDTH
                                 + DATA_BUF_OFFSET_WIDTH;

  localparam APP_DATA_WIDTH        = 2 * nCK_PER_CLK * PAYLOAD_WIDTH;
  localparam APP_MASK_WIDTH        = APP_DATA_WIDTH / 8;
  localparam TEMP_MON_EN           = (SIMULATION == "FALSE") ? "ON" : "OFF";
  localparam tTEMPSAMPLE           = 10000000;   // sample every 10 us
  localparam XADC_CLK_PERIOD       = 5000;       // Use 200 MHz IODELAYCTRL clock
`ifdef SKIP_CALIB
  localparam SKIP_CALIB = "TRUE";
`else
  localparam SKIP_CALIB = "FALSE";
`endif

  localparam TAPSPERKCLK = (56*MMCM_MULT_F)/nCK_PER_CLK;

  localparam IODELAY_GRP = (tCK <= 1500)? IODELAY_GRP1 : IODELAY_GRP0;

  wire clk_ref_intfc;
  assign clk_ref_intfc = (tCK <= 1500) ? clk_ref[1] : clk_ref[0];

  /*AUTOWIRE*/
  // Beginning of automatic wires (for undeclared instantiated-module outputs)
  wire                  clk;
  wire                  clk_div2;
  wire [1:0]            clk_ref;
  wire [11:0]           device_temp;
  wire                  freq_refclk;
  wire                  iddr_rst;
  wire [1:0]            iodelay_ctrl_rdy;
  wire                  mem_refclk;
  wire                  mmcm_clk;
  wire                  mmcm_ps_clk;
  wire                  pll_locked;
  wire                  poc_sample_pd;
  wire                  psdone;
  wire                  psen;
  wire                  psincdec;
  wire                  ref_dll_lock;
  wire                  reset;
  wire                  rst;
  wire                  rst_div2;
  wire                  rst_phaser_ref;
  wire                  rst_tg_mc;
  wire                  sync_pulse;
  wire                  sys_rst_o;
  // End of automatics
  /*AUTOREG*/

  assign memc_clk = clk;
  assign memc_rst = rst;

  mig_7series_v4_2_iodelay_ctrl #(
    .TCQ                       (TCQ),
    .IODELAY_GRP0              (IODELAY_GRP0),
    .IODELAY_GRP1              (IODELAY_GRP1),
    .REFCLK_TYPE               (REFCLK_TYPE),
    .SYSCLK_TYPE               (SYSCLK_TYPE),
    .SYS_RST_PORT              (SYS_RST_PORT),
    .RST_ACT_LOW               (RST_ACT_LOW),
    .DIFF_TERM_REFCLK          (DIFF_TERM_REFCLK),
    .FPGA_SPEED_GRADE          (FPGA_SPEED_GRADE),
    .REF_CLK_MMCM_IODELAY_CTRL (REF_CLK_MMCM_IODELAY_CTRL)
    ) u_iodelay_ctrl (
    // Inputs
    .clk_ref_p(1'b0),
    .clk_ref_n(1'b0),
    /*AUTOINST*/
    // Outputs
    .clk_ref(clk_ref[1:0]),
    .iodelay_ctrl_rdy(iodelay_ctrl_rdy[1:0]),
    .sys_rst_o(sys_rst_o),
    // Inputs
    .clk_ref_i(clk_ref_i),
    .sys_rst(sys_rst));

  mig_7series_v4_2_clk_ibuf #(
    .SYSCLK_TYPE      (SYSCLK_TYPE),
    .DIFF_TERM_SYSCLK (DIFF_TERM_SYSCLK)
    ) u_clk_ibuf (
    // Inputs
    .sys_clk_p(1'b0),
    .sys_clk_n(1'b0),
    /*AUTOINST*/
    // Outputs
    .mmcm_clk(mmcm_clk),
    // Inputs
    .sys_clk_i(sys_clk_i));

  mig_7series_v4_2_tempmon #(
    .TCQ              (TCQ),
    .TEMP_MON_CONTROL (TEMP_MON_CONTROL),
    .XADC_CLK_PERIOD  (XADC_CLK_PERIOD),
    .tTEMPSAMPLE      (tTEMPSAMPLE)
    ) u_tempmon (
    // Inputs
    .xadc_clk(clk_ref[0]),
    .device_temp_i(),
    /*AUTOINST*/
    // Outputs
    .device_temp(device_temp[11:0]),
    // Inputs
    .clk(clk),
    .rst(rst));

  mig_7series_v4_2_infrastructure #(
    .TCQ                (TCQ),
    .nCK_PER_CLK        (nCK_PER_CLK),
    .CLKIN_PERIOD       (CLKIN_PERIOD),
    .SYSCLK_TYPE        (SYSCLK_TYPE),
    .CLKFBOUT_MULT      (CLKFBOUT_MULT),
    .DIVCLK_DIVIDE      (DIVCLK_DIVIDE),
    .CLKOUT0_PHASE      (CLKOUT0_PHASE),
    .CLKOUT0_DIVIDE     (CLKOUT0_DIVIDE),
    .CLKOUT1_DIVIDE     (CLKOUT1_DIVIDE),
    .CLKOUT2_DIVIDE     (CLKOUT2_DIVIDE),
    .CLKOUT3_DIVIDE     (CLKOUT3_DIVIDE),
    .MMCM_VCO           (MMCM_VCO),
    .MMCM_MULT_F        (MMCM_MULT_F),
    .MMCM_DIVCLK_DIVIDE (MMCM_DIVCLK_DIVIDE),
    .RST_ACT_LOW        (RST_ACT_LOW),
    .tCK                (tCK),
    .MEM_TYPE           (DRAM_TYPE)
    ) u_infrastructure (
    // Outputs
    .rstdiv0(rst),
    .ui_addn_clk_0(),
    .ui_addn_clk_1(),
    .ui_addn_clk_2(),
    .ui_addn_clk_3(),
    .ui_addn_clk_4(),
    .mmcm_locked(),
    // Inputs
    .sys_rst(sys_rst_o),
    /*AUTOINST*/
    // Outputs
    .clk(clk),
    .clk_div2(clk_div2),
    .freq_refclk(freq_refclk),
    .iddr_rst(iddr_rst),
    .mem_refclk(mem_refclk),
    .mmcm_ps_clk(mmcm_ps_clk),
    .pll_locked(pll_locked),
    .poc_sample_pd(poc_sample_pd),
    .psdone(psdone),
    .rst_div2(rst_div2),
    .rst_phaser_ref(rst_phaser_ref),
    .sync_pulse(sync_pulse),
    // Inputs
    .iodelay_ctrl_rdy(iodelay_ctrl_rdy[1:0]),
    .mmcm_clk(mmcm_clk),
    .psen(psen),
    .psincdec(psincdec),
    .ref_dll_lock(ref_dll_lock));

  mig_7series_v4_2_mem_intfc #(
    .ADDR_CMD_MODE         (ADDR_CMD_MODE),
    .ADDR_MAP              (ADDR_MAP),
    .AL                    (AL),
    .BANK_MAP              (BANK_MAP),
    .BANK_TYPE             (BANK_TYPE),
    .BANK_WIDTH            (BANK_WIDTH),
    .BM_CNT_WIDTH          (BM_CNT_WIDTH),
    .BURST_MODE            (BURST_MODE),
    .BURST_TYPE            (BURST_TYPE),
    .BYTE_LANES_B0         (BYTE_LANES_B0),
    .BYTE_LANES_B1         (BYTE_LANES_B1),
    .BYTE_LANES_B2         (BYTE_LANES_B2),
    .BYTE_LANES_B3         (BYTE_LANES_B3),
    .BYTE_LANES_B4         (BYTE_LANES_B4),
    .CALIB_BA_ADD          (CALIB_BA_ADD),
    .CALIB_COL_ADD         (CALIB_COL_ADD),
    .CALIB_ROW_ADD         (CALIB_ROW_ADD),
    .CAL_WIDTH             (CAL_WIDTH),
    .CAS_MAP               (CAS_MAP),
    .CA_MIRROR             (CA_MIRROR),
    .CENTER_COMP_MODE      (CENTER_COMP_MODE),
    .CKE_MAP               (CKE_MAP),
    .CKE_ODT_AUX           (CKE_ODT_AUX),
    .CKE_ODT_BYTE_MAP      (CKE_ODT_BYTE_MAP),
    .CKE_WIDTH             (CKE_WIDTH),
    .CK_BYTE_MAP           (CK_BYTE_MAP),
    .CK_WIDTH              (CK_WIDTH),
    .CL                    (CL),
    .CMD_PIPE_PLUS1        (CMD_PIPE_PLUS1),
    .COL_WIDTH             (COL_WIDTH),
    .CS_MAP                (CS_MAP),
    .CS_WIDTH              (CS_WIDTH),
    .CWL                   (CWL),
    .DATA0_MAP             (DATA0_MAP),
    .DATA10_MAP            (DATA10_MAP),
    .DATA11_MAP            (DATA11_MAP),
    .DATA12_MAP            (DATA12_MAP),
    .DATA13_MAP            (DATA13_MAP),
    .DATA14_MAP            (DATA14_MAP),
    .DATA15_MAP            (DATA15_MAP),
    .DATA16_MAP            (DATA16_MAP),
    .DATA17_MAP            (DATA17_MAP),
    .DATA1_MAP             (DATA1_MAP),
    .DATA2_MAP             (DATA2_MAP),
    .DATA3_MAP             (DATA3_MAP),
    .DATA4_MAP             (DATA4_MAP),
    .DATA5_MAP             (DATA5_MAP),
    .DATA6_MAP             (DATA6_MAP),
    .DATA7_MAP             (DATA7_MAP),
    .DATA8_MAP             (DATA8_MAP),
    .DATA9_MAP             (DATA9_MAP),
    .DATA_BUF_ADDR_WIDTH   (DATA_BUF_ADDR_WIDTH),
    .DATA_BUF_OFFSET_WIDTH (DATA_BUF_OFFSET_WIDTH),
    .DATA_CTL_B0           (DATA_CTL_B0),
    .DATA_CTL_B1           (DATA_CTL_B1),
    .DATA_CTL_B2           (DATA_CTL_B2),
    .DATA_CTL_B3           (DATA_CTL_B3),
    .DATA_CTL_B4           (DATA_CTL_B4),
    .DATA_IO_IDLE_PWRDWN   (DATA_IO_IDLE_PWRDWN),
    .DATA_IO_PRIM_TYPE     (DATA_IO_PRIM_TYPE),
    .DATA_WIDTH            (DATA_WIDTH),
    .DDR3_VDD_OP_VOLT      (VDD_OP_VOLT),
    .DEBUG_PORT            (DEBUG_PORT),
    .DM_WIDTH              (DM_WIDTH),
    .DQS_BYTE_MAP          (DQS_BYTE_MAP),
    .DQS_CNT_WIDTH         (DQS_CNT_WIDTH),
    .DQS_WIDTH             (DQS_WIDTH),
    .DQ_CNT_WIDTH          (DQ_CNT_WIDTH),
    .DQ_WIDTH              (DQ_WIDTH),
    .DRAM_TYPE             (DRAM_TYPE),
    .DRAM_WIDTH            (DRAM_WIDTH),
    .ECC                   (ECC),
    .ECC_WIDTH             (ECC_WIDTH),
    .FINE_PER_BIT          (FINE_PER_BIT),
    .FPGA_SPEED_GRADE      (FPGA_SPEED_GRADE),
    .FPGA_VOLT_TYPE        (FPGA_VOLT_TYPE),
    .IBUF_LPWR_MODE        (IBUF_LPWR_MODE),
    .IDELAY_ADJ            (IDELAY_ADJ),
    .IODELAY_GRP           (IODELAY_GRP),
    .MASK0_MAP             (MASK0_MAP),
    .MASK1_MAP             (MASK1_MAP),
    .MASTER_PHY_CTL        (PHY_CONTROL_MASTER_BANK),
    .MC_ERR_ADDR_WIDTH     (MC_ERR_ADDR_WIDTH),
    .ODT_MAP               (ODT_MAP),
    .ODT_WIDTH             (ODT_WIDTH),
    .ORDERING              (ORDERING),
    .OUTPUT_DRV            (OUTPUT_DRV),
    .PARITY_MAP            (PARITY_MAP),
    .PAYLOAD_WIDTH         (PAYLOAD_WIDTH),
    .PHY_0_BITLANES        (PHY_0_BITLANES),
    .PHY_1_BITLANES        (PHY_1_BITLANES),
    .PHY_2_BITLANES        (PHY_2_BITLANES),
    .PI_VAL_ADJ            (PI_VAL_ADJ),
    .RANKS                 (RANKS),
    .RANK_WIDTH            (RANK_WIDTH),
    .RAS_MAP               (RAS_MAP),
    .REFCLK_FREQ           (REFCLK_FREQ),
    .REG_CTRL              (REG_CTRL),
    .ROW_WIDTH             (ROW_WIDTH),
    .RTT_NOM               (RTT_NOM),
    .RTT_WR                (RTT_WR),
    .SIM_BYPASS_INIT_CAL   (SIM_BYPASS_INIT_CAL),
    .SKIP_CALIB            (SKIP_CALIB),
    .SLOT_0_CONFIG         (SLOT_0_CONFIG),
    .SLOT_1_CONFIG         (SLOT_1_CONFIG),
    .STARVE_LIMIT          (STARVE_LIMIT),
    .TAPSPERKCLK           (TAPSPERKCLK),
    .TCQ                   (TCQ),
    .TEMP_MON_EN           (TEMP_MON_EN),
    .USER_REFRESH          (USER_REFRESH),
    .USE_CS_PORT           (USE_CS_PORT),
    .USE_DM_PORT           (USE_DM_PORT),
    .USE_ODT_PORT          (USE_ODT_PORT),
    .WE_MAP                (WE_MAP),
    .WRLVL                 (WRLVL),
    .nAL                   (nAL),
    .nBANK_MACHS           (nBANK_MACHS),
    .nCK_PER_CLK           (nCK_PER_CLK),
    .nCS_PER_RANK          (nCS_PER_RANK),
    .tCK                   (tCK),
    .tCKE                  (tCKE),
    .tFAW                  (tFAW),
    .tPRDI                 (tPRDI),
    .tRAS                  (tRAS),
    .tRCD                  (tRCD),
    .tREFI                 (tREFI),
    .tRFC                  (tRFC),
    .tRP                   (tRP),
    .tRRD                  (tRRD),
    .tRTP                  (tRTP),
    .tWTR                  (tWTR),
    .tZQCS                 (tZQCS),
    .tZQI                  (tZQI)
    ) u_mem_intfc (
    // Outputs
    // calibration parameter loading interface
    .calib_tap_req(),
    // ECC error reporting
    .ecc_single(),
    .ecc_multiple(),
    .ecc_err_addr(),
    // which bank machine will accept the next request
    .bank_mach_next(),
    // unused output
    .init_wrcal_complete(),
    // debug outputs
    .dbg_calib_rd_data_offset_1(),
    .dbg_calib_rd_data_offset_2(),
    .dbg_calib_top(),
    .dbg_cpt_first_edge_cnt(),
    .dbg_cpt_second_edge_cnt(),
    .dbg_cpt_tap_cnt(),
    .dbg_data_offset(),
    .dbg_data_offset_1(),
    .dbg_data_offset_2(),
    .dbg_dq_idelay_tap_cnt(),
    .dbg_dqs_found_cal(),
    .dbg_final_po_coarse_tap_cnt(),
    .dbg_final_po_fine_tap_cnt(),
    .dbg_oclkdelay_calib_done(),
    .dbg_oclkdelay_calib_start(),
    .dbg_oclkdelay_rd_data(),
    .dbg_phy_init(),
    .dbg_phy_oclkdelay_cal(),
    .dbg_phy_rdlvl(),
    .dbg_phy_wrcal(),
    .dbg_phy_wrlvl(),
    .dbg_pi_counter_read_val(),
    .dbg_pi_dqs_found_lanes_phy4lanes(),
    .dbg_pi_dqsfound_done(),
    .dbg_pi_dqsfound_err(),
    .dbg_pi_dqsfound_start(),
    .dbg_pi_phase_locked_phy4lanes(),
    .dbg_pi_phaselock_err(),
    .dbg_pi_phaselock_start(),
    .dbg_pi_phaselocked_done(),
    .dbg_po_counter_read_val(),
    .dbg_poc(),
    .dbg_prbs_first_edge_taps(),
    .dbg_prbs_rdlvl(),
    .dbg_prbs_second_edge_taps(),
    .dbg_rd_data_edge_detect(),
    .dbg_rd_data_offset(),
    .dbg_rddata(),
    .dbg_rddata_valid(),
    .dbg_rdlvl_done(),
    .dbg_rdlvl_err(),
    .dbg_rdlvl_start(),
    .dbg_tap_cnt_during_wrlvl(),
    .dbg_wl_edge_detect_valid(),
    .dbg_wrcal_done(),
    .dbg_wrcal_err(),
    .dbg_wrcal_start(),
    .dbg_wrlvl_coarse_tap_cnt(),
    .dbg_wrlvl_done(),
    .dbg_wrlvl_err(),
    .dbg_wrlvl_fine_tap_cnt(),
    .dbg_wrlvl_start(),
    .prbs_final_dqs_tap_cnt_r(),
    // Inputs
    .clk_ref(clk_ref_intfc),
    .pll_lock(pll_locked),
    // calibration parameter loading interface
    .calib_tap_load(1'b0),
    .calib_tap_load_done(1'b0),
    .calib_tap_addr(7'b0),
    .calib_tap_val(8'b0),
    // unused input
    .error(),
    // ECC enable
    .correct_en(1'b1),
    // disable ECC modification for write
    .raw_not_ecc(4'b0),
    // fault injection (XOR applied to part of write data)
    .fi_xor_we(2'b0),
    .fi_xor_wrdata(16'b0),
    // when BUST_MODE==OTF, dynamically selects BL4 or BL8
    .size(1'b1),
    // indicates slot/rank configuration
    .slot_0_present(SLOT_0_CONFIG),
    .slot_1_present(SLOT_1_CONFIG),
    // debug inputs
    .dbg_idel_down_all(1'b0),
    .dbg_idel_down_cpt(1'b0),
    .dbg_idel_up_all(1'b0),
    .dbg_idel_up_cpt(1'b0),
    .dbg_sel_all_idel_cpt(1'b0),
    .dbg_sel_idel_cpt('b0),
    .dbg_byte_sel('d0),
    .dbg_sel_pi_incdec(1'b0),
    .dbg_pi_f_inc(1'b0),
    .dbg_pi_f_dec(1'b0),
    .dbg_po_f_inc('b0),
    .dbg_po_f_dec('b0),
    .dbg_po_f_stg23_sel('b0),
    .dbg_sel_po_incdec('b0),
    /*AUTOINST*/
    // Outputs
    .accept(accept),
    .accept_ns(accept_ns),
    .app_ref_ack(app_ref_ack),
    .app_sr_active(app_sr_active),
    .app_zq_ack(app_zq_ack),
    .ddr_addr(ddr_addr[ROW_WIDTH-1:0]),
    .ddr_ba(ddr_ba[BANK_WIDTH-1:0]),
    .ddr_cas_n(ddr_cas_n),
    .ddr_ck(ddr_ck[CK_WIDTH-1:0]),
    .ddr_ck_n(ddr_ck_n[CK_WIDTH-1:0]),
    .ddr_cke(ddr_cke[CKE_WIDTH-1:0]),
    .ddr_cs_n(ddr_cs_n[CS_WIDTH*nCS_PER_RANK-1:0]),
    .ddr_dm(ddr_dm[DM_WIDTH-1:0]),
    .ddr_odt(ddr_odt[ODT_WIDTH-1:0]),
    .ddr_parity(ddr_parity),
    .ddr_ras_n(ddr_ras_n),
    .ddr_reset_n(ddr_reset_n),
    .ddr_we_n(ddr_we_n),
    .init_calib_complete(init_calib_complete),
    .psen(psen),
    .psincdec(psincdec),
    .rd_data(rd_data[2*nCK_PER_CLK*PAYLOAD_WIDTH-1:0]),
    .rd_data_addr(rd_data_addr[DATA_BUF_ADDR_WIDTH-1:0]),
    .rd_data_en(rd_data_en),
    .rd_data_end(rd_data_end),
    .rd_data_offset(rd_data_offset[DATA_BUF_OFFSET_WIDTH-1:0]),
    .ref_dll_lock(ref_dll_lock),
    .rst_tg_mc(rst_tg_mc),
    .wr_data_addr(wr_data_addr[DATA_BUF_ADDR_WIDTH-1:0]),
    .wr_data_en(wr_data_en),
    .wr_data_offset(wr_data_offset[DATA_BUF_OFFSET_WIDTH-1:0]),
    // Inouts
    .ddr_dq(ddr_dq[DQ_WIDTH-1:0]),
    .ddr_dqs(ddr_dqs[DQS_WIDTH-1:0]),
    .ddr_dqs_n(ddr_dqs_n[DQS_WIDTH-1:0]),
    // Inputs
    .app_ref_req(app_ref_req),
    .app_sr_req(app_sr_req),
    .app_zq_req(app_zq_req),
    .bank(bank[BANK_WIDTH-1:0]),
    .clk(clk),
    .clk_div2(clk_div2),
    .cmd(cmd[2:0]),
    .col(col[COL_WIDTH-1:0]),
    .data_buf_addr(data_buf_addr[DATA_BUF_ADDR_WIDTH-1:0]),
    .device_temp(device_temp[11:0]),
    .freq_refclk(freq_refclk),
    .hi_priority(hi_priority),
    .iddr_rst(iddr_rst),
    .mem_refclk(mem_refclk),
    .mmcm_ps_clk(mmcm_ps_clk),
    .poc_sample_pd(poc_sample_pd),
    .psdone(psdone),
    .rank(rank[RANK_WIDTH-1:0]),
    .reset(reset),
    .row(row[ROW_WIDTH-1:0]),
    .rst(rst),
    .rst_div2(rst_div2),
    .rst_phaser_ref(rst_phaser_ref),
    .sync_pulse(sync_pulse),
    .use_addr(use_addr),
    .wr_data(wr_data[2*nCK_PER_CLK*PAYLOAD_WIDTH-1:0]),
    .wr_data_mask(wr_data_mask[2*nCK_PER_CLK*DATA_WIDTH/8-1:0]));

  dram_ctl_memc_misc u_memc_misc (
    /*AUTOINST*/
    // Outputs
    .reset(reset),
    // Inputs
    .clk(clk),
    .rst(rst),
    .rst_tg_mc(rst_tg_mc));

endmodule
