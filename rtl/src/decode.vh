`ifndef __DECODE_VH__
`define __DECODE_VH__

typedef struct packed {
  logic branch;
  logic csr;
  logic jump;
  logic store;
  logic [2:0] funct3;
} retop_t;

typedef enum logic [2:0] {
  FUNCT3_LS_LB_SB = 3'b000, // Load/Store Byte
  FUNCT3_LS_LH_SB = 3'b001, // Load/Store Halfword
  FUNCT3_LS_LW_SW = 3'b010, // Load/Store Word
  FUNCT3_LS_LBU = 3'b100, // Load Byte Unsigned
  FUNCT3_LS_LHU = 3'b101, // Load Halfword Unsigned

  FUNCT3_LS_LBCMP = 3'b011 // Load Bytes and Compare (custom extension)
} funct3_ls_t;

typedef struct packed {
  logic rsvd;
  logic store;
  funct3_ls_t funct3;
} rsop_ls_t;

typedef enum logic [1:0] {
  CSROP_GET = 2'b00,
  CSROP_SET = 2'b01,
  CSROP_BIT_SET = 2'b10,
  CSROP_BIT_CLR = 2'b11
} csrop_t;

typedef struct packed {
  logic [2:0] rsvd;
  csrop_t csrop;
} rsop_csr_t;

typedef enum logic [2:0] {
  FUNCT3_ALU_ADD_SUB = 3'b000,
  FUNCT3_ALU_SLL = 3'b001,
  FUNCT3_ALU_SLT = 3'b010,
  FUNCT3_ALU_SLTU = 3'b011,
  FUNCT3_ALU_XOR_SEQ = 3'b100,
  FUNCT3_ALU_SRL_SRA = 3'b101,
  FUNCT3_ALU_OR = 3'b110,
  FUNCT3_ALU_AND = 3'b111
} funct3_alu_t;

typedef enum logic [2:0] {
  FUNCT3_ALUEXT_PFIND = 3'b000,
  FUNCT3_ALUEXT_PCLEAR = 3'b001
} funct3_aluext_t;

typedef struct packed {
  logic aluext;
  logic altop;
  funct3_alu_t funct3;
} rsop_alu_t;

typedef union packed {
  rsop_ls_t ls;
  rsop_csr_t csr;
  rsop_alu_t alu;
} rsop_t;

`endif
