// 32 x 32 multiplier, behavioral implementation
module mul_behav #(
  parameter LATENCY = 4
  )(
  input         clk,
  input         rst,

  input         req,
  input [1:0]   op,
  input [31:0]  op1,
  input [31:0]  op2,

  output        done,
  output [31:0] result,
  input         stall);

  // op encoding
  // 00 = MUL    (multiply, return result[31:0])
  // 01 = MULH   (multiply signed   *   signed, return result[63:32])
  // 10 = MULHSU (multiply signed   * unsigned, return result[63:32])
  // 11 = MULHU  (multiply unsigned * unsigned, return result[63:32])
  wire op1_sign, op2_sign;
  assign op1_sign = op1[31] & (op[1] ^ op[0]);
  assign op2_sign = op2[31] & ~op[1];

  reg [LATENCY:1]  done_pipe_r;
  reg [65:0]       result_pipe_r [1:LATENCY];

  wire [LATENCY:0] done_pipe;
  wire [65:0]      result_pipe [0:LATENCY];

  assign done_pipe[0] = req;
  assign result_pipe[0] = $signed({op1_sign,op1}) * $signed({op2_sign,op2});

  genvar i;
  generate
    for(i = 1; i <= LATENCY; i=i+1) begin
      assign done_pipe[i] = done_pipe_r[i];
      assign result_pipe[i] = result_pipe_r[i];
      always @(posedge clk) begin
        done_pipe_r[i] <= done_pipe[i-1] & (~done | stall);
        result_pipe_r[i] <= result_pipe[i-1];
      end
    end
  endgenerate

  assign done = done_pipe[LATENCY];
  assign result = (op == 2'b00) ? result_pipe[LATENCY][31:0] : result_pipe[LATENCY][63:32];

endmodule
