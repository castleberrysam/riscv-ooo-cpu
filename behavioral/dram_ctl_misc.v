module dram_ctl_misc(
  output app_ref_req,
  output app_sr_req,
  output app_zq_req,
  output rank,
  input  accept_ns,
  input  app_ref_ack,
  input  app_sr_active,
  input  app_zq_ack,
  input  init_calib_complete);

  assign app_ref_req = 0;
  assign app_sr_req = 0;
  assign app_zq_req = 0;
  assign rank = 0;

endmodule
