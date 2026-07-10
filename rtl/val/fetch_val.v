  always @(negedge clk)
    if(!rst) begin
      if($isunknown(fetch_de_valid) || $isunknown(decode_stall))
        $error("IF-ID handshake contains X");
      if(fetch_de_valid && decode_stall && !rob_flush) begin
        if($isunknown(fetch_de_error) ||
           $isunknown(fetch_de_addr) ||
           $isunknown(fetch_de_insn) ||
           $isunknown(fetch_de_bptaken) ||
           $isunknown(fetch_de_bpattr))
          $error("IF-ID interface contains X");
        if(fetch_de_bptaken && $isunknown(fetch_de_target))
          $error("IF-ID target contains X");
      end
    end

  wire zval_beat;
  wire zval_beat_nt;
  wire zval_beat_t;
  assign zval_beat = fetch_de_valid & ~decode_stall;
  assign zval_beat_nt = zval_beat & ~fetch_de_error & ~fetch_de_bptaken;
  assign zval_beat_t = zval_beat & ~fetch_de_error & fetch_de_bptaken;

  wire [31:2] zval_last_beat_addr_r;
  wire [31:2] zval_last_beat_target_r;
  dff #(30) u_zval_last_beat_addr_r (zval_last_beat_addr_r, fetch_de_addr, clk, zval_beat);
  dff #(30) u_zval_last_beat_target_r (zval_last_beat_target_r, fetch_de_target, clk, zval_beat);

  reg zval_beat_nt_seen;
  reg zval_beat_t_seen;
  always @(negedge clk)
    if(rst | rob_flush) begin
      zval_beat_nt_seen <= 0;
      zval_beat_t_seen <= 0;
    end else begin
      zval_beat_nt_seen <= zval_beat_nt;
      zval_beat_t_seen <= zval_beat_t;
      if(zval_beat_nt_seen && zval_beat && fetch_de_addr != (zval_last_beat_addr_r + 30'd1))
        $error("Sequential fetch is not to PC+4 (expected %8x, got %8x)",
               {zval_last_beat_addr_r,2'b0}, {fetch_de_addr,2'b0});
      if(zval_beat_t_seen && zval_beat && fetch_de_addr != zval_last_beat_target_r)
        $error("Fetch after bptaken is not to the target (expected %8x, got %8x)",
               {zval_last_beat_target_r,2'b0}, {fetch_de_addr,2'b0});
    end
