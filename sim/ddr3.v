module ddr3 (
  rst_n,
  ck,
  ck_n,
  cke,
  cs_n,
  ras_n,
  cas_n,
  we_n,
  dm_tdqs,
  ba,
  addr,
  dq,
  dqs,
  dqs_n,
  tdqs_n,
  odt);

`ifdef den1024Mb
    `include "1024Mb_ddr3_parameters.vh"
`elsif den2048Mb
    `include "2048Mb_ddr3_parameters.vh"
`elsif den4096Mb
    `include "4096Mb_ddr3_parameters.vh"
`elsif den8192Mb
    `include "8192Mb_ddr3_parameters.vh"
`else
    // NOTE: Intentionally cause a compile fail here to force the users
    //       to select the correct component density before continuing
    ERROR: You must specify component density with +define+den____Mb.
`endif

  // Declare Ports
  input   rst_n;
  input   ck;
  input   ck_n;
  input   cke;
  input   cs_n;
  input   ras_n;
  input   cas_n;
  input   we_n;
  inout   [DM_BITS-1:0]   dm_tdqs;
  input   [BA_BITS-1:0]   ba;
  input   [ADDR_BITS-1:0] addr;
  inout   [DQ_BITS-1:0]   dq;
  inout   [DQS_BITS-1:0]  dqs;
  inout   [DQS_BITS-1:0]  dqs_n;
  output  [DQS_BITS-1:0]  tdqs_n;
  input   odt;

endmodule
