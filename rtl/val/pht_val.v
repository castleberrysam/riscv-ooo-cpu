  reg [PHT_IDX_MSB:0] zval_bhr_queue [0:127];
  reg [6:0] zval_bhr_queue_head, zval_bhr_queue_tail;

  always @(negedge clk)
    if(rst | rob_flush)
      zval_bhr_queue_tail <= 0;
    else if(spec_bhr_update) begin
      if(zval_bhr_queue_tail + 1 == zval_bhr_queue_head)
        $error("BHR queue overflow");
      zval_bhr_queue[zval_bhr_queue_tail] <= spec_bhr_nxt;
      zval_bhr_queue_tail <= zval_bhr_queue_tail + 1;
    end

  always @(negedge clk)
    if(rst | rob_flush)
      zval_bhr_queue_head <= 0;
    else if(arch_bhr_update) begin
      if(zval_bhr_queue_head == zval_bhr_queue_tail)
        $error("BHR queue underflow");
      if(arch_bhr_nxt != zval_bhr_queue[zval_bhr_queue_head])
        $error("Mismatch between speculative and architectural BHR (expected %0h, got %0h)",
               zval_bhr_queue[zval_bhr_queue_head], arch_bhr_nxt);
      zval_bhr_queue_head <= zval_bhr_queue_head + 1;
    end
