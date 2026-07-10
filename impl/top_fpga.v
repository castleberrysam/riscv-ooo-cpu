`timescale 1ns/1ps

module top_fpga(
  input         sys_clk_i,
  input         clk_12mhz,

  input         icache_wr,
  input [9:0]   icache_wr_addr,
  input [31:0]  icache_wr_data,

  input         rom_wr,
  input [8:0]   rom_wr_addr,
  input [63:0]  rom_wr_data,

  output [13:0] ddr3_addr,
  output [2:0]  ddr3_ba,
  output        ddr3_ras_n,
  output        ddr3_cas_n,
  output        ddr3_we_n,
  output        ddr3_reset_n,
  output        ddr3_ck_p,
  output        ddr3_ck_n,
  output        ddr3_cke,
  output        ddr3_cs_n,
  output [1:0]  ddr3_dm,
  output        ddr3_odt,
  inout [15:0]  ddr3_dq,
  inout [1:0]   ddr3_dqs_p,
  inout [1:0]   ddr3_dqs_n);

  wire clk_core, clk_mig_sys, clk_mig_ref;
  assign clk_mig_sys = sys_clk_i;

  wire locked;
  MMCME2_BASE #(
    .CLKIN1_PERIOD(83.333),
    .STARTUP_WAIT("TRUE"),

    // resulting base clock needs to be 600-1200MHz
    .CLKFBOUT_MULT_F(50.000), // 600MHz
    .DIVCLK_DIVIDE(1),

    .CLKOUT0_DIVIDE_F(6.000), // 100MHz
    .CLKOUT1_DIVIDE(3), // 200MHz
    .CLKOUT2_DIVIDE(),
    .CLKOUT3_DIVIDE(),
    .CLKOUT4_DIVIDE(),
    .CLKOUT5_DIVIDE(),
    .CLKOUT6_DIVIDE()
    ) mmcm(
    .CLKIN1(clk_12mhz),
    .RST(0),

    .LOCKED(locked),
    .PWRDWN(0),

    .CLKFBOUT(clk_fb),
    .CLKFBOUTB(),
    .CLKFBIN(clk_fb),

    .CLKOUT0(clk_core),
    .CLKOUT0B(),
    .CLKOUT1(clk_mig_ref),
    .CLKOUT1B(),
    .CLKOUT2(),
    .CLKOUT2B(),
    .CLKOUT3(),
    .CLKOUT3B(),
    .CLKOUT4(),
    .CLKOUT5(),
    .CLKOUT6()
    );

  wire rst;
  assign rst = ~locked;

  top top (
    .clk(clk_core),
    .clk_ref_i(clk_mig_ref),
    .sys_clk_i(clk_mig_sys),
    .rst_in(rst),
    .rom_wr(rom_wr),
    .rom_wr_addr(rom_wr_addr),
    .rom_wr_data(rom_wr_data),
    .icache_wr(icache_wr),
    .icache_wr_addr(icache_wr_addr),
    .icache_wr_data(icache_wr_data),
    .ddr_addr(ddr3_addr),
    .ddr_ba(ddr3_ba),
    .ddr_ras_n(ddr3_ras_n),
    .ddr_cas_n(ddr3_cas_n),
    .ddr_we_n(ddr3_we_n),
    .ddr_reset_n(ddr3_reset_n),
    .ddr_ck(ddr3_ck_p),
    .ddr_ck_n(ddr3_ck_n),
    .ddr_cke(ddr3_cke),
    .ddr_cs_n(ddr3_cs_n),
    .ddr_dm(ddr3_dm),
    .ddr_odt(ddr3_odt),
    .ddr_dq(ddr3_dq),
    .ddr_dqs(ddr3_dqs_p),
    .ddr_dqs_n(ddr3_dqs_n),
    .ddr_parity());

endmodule
