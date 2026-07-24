`include "decode.vh"

// Single Cycle ALU operations
module alu_simple(
  // exec unit interface
  input rsop_alu_t  op,
  input [31:0]      op1,
  input [31:0]      op2,
  output [31:0] sc_result);

  wire [31:0] p_vector;
  wire p_vec_zero;
  privector #(32, 1) p_vector_prippf (.in(op1 & ~op2), .invalid(p_vec_zero),
    .out(p_vector));

  wire [4:0] p_index;
  encoder #(32) p_index_enc (.in(p_vector), .invalid(), .out(p_index));
  
  
  wire [31:0] add_res;
  rca #(32) adder(.sub(op.altop), .a(op1), .b(op2), .c(add_res)); // ADD,SUB
  
  wire [31:0] sll_res;
  shf #(32, 0) lshf(.sgn(1'b0), .a(op1), .b(op2[4:0]), .c(sll_res)); // SLL
  
  wire sltu_res, slt_res;
  cmp #(32,4,0) u_sltu_res (
    .a(op1),
    .b(op2),
    .eq(),
    .lt(sltu_res));
  assign slt_res = sltu_res ^ op1[31] ^ op2[31];
  
  wire [31:0] xorseq_res;
  mux #(32, 2) xor_mux (.sel(op.altop), .in({{31'b0,op1 == op2}, op1^op2}), .out(xorseq_res)); // XOR, SEQ

  wire [31:0] srl_res;
  shf #(32, 1) rshf(.sgn(op.altop), .a(op1), .b(op2[4:0]), .c(srl_res));
  
  wire [31:0] or_res = op1 | op2;
  wire [31:0] and_res = op1 & op2;

  wire [31:0] pfind_res = {p_vec_zero, 26'b0, p_index};
  wire [31:0] pclear_res = op1 ^ p_vector;

  always @(*)
    if (op.aluext)
      case (op.funct3)
        FUNCT3_ALUEXT_PFIND: sc_result = pfind_res;
        FUNCT3_ALUEXT_PCLEAR: sc_result = pclear_res;
        default: sc_result = '0;
      endcase
    else
      case (op.funct3)
        FUNCT3_ALU_ADD_SUB: sc_result = add_res;
        FUNCT3_ALU_SLL: sc_result = sll_res;
        FUNCT3_ALU_SLT: sc_result = {31'b0,slt_res};
        FUNCT3_ALU_SLTU: sc_result = {31'b0,sltu_res};
        FUNCT3_ALU_XOR_SEQ: sc_result = xorseq_res;
        FUNCT3_ALU_SRL_SRA: sc_result = srl_res;
        FUNCT3_ALU_OR: sc_result = or_res;
        FUNCT3_ALU_AND: sc_result = and_res;
        default: sc_result = '0;
      endcase

endmodule
