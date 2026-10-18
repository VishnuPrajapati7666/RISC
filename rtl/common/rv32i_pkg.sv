// File: rtl/common/rv32i_pkg.sv
`ifndef RV32I_PKG_SV
`define RV32I_PKG_SV

package rv32i_pkg;

  // Base Architecture Parameters
  localparam int XLEN = 32;
  localparam int REG_ADDR_WIDTH = 5;

  // Base RV32I Primary Opcodes (opcode[6:0])
  typedef enum logic [6:0] {
    OPCODE_LUI      = 7'b0110111,
    OPCODE_AUIPC    = 7'b0010111,
    OPCODE_JAL      = 7'b1101111,
    OPCODE_JALR     = 7'b1100111,
    OPCODE_BRANCH   = 7'b1100011,
    OPCODE_LOAD     = 7'b0000011,
    OPCODE_STORE    = 7'b0100011,
    OPCODE_OP_IMM   = 7'b0010011,
    OPCODE_OP       = 7'b0110011,
    OPCODE_FENCE    = 7'b0001111,
    OPCODE_SYSTEM   = 7'b1110011
  } opcode_e;

  // ALU Operations
  typedef enum logic [3:0] {
    ALU_ADD  = 4'b0000,
    ALU_SUB  = 4'b0001,
    ALU_SLL  = 4'b0010,
    ALU_SLT  = 4'b0011,
    ALU_SLTU = 4'b0100,
    ALU_XOR  = 4'b0101,
    ALU_SRL  = 4'b0110,
    ALU_SRA  = 4'b0111,
    ALU_OR   = 4'b1000,
    ALU_AND  = 4'b1001,
    ALU_COPY_B = 4'b1010
  } alu_op_e;

  // Branch / Comparison Types (funct3[2:0])
  typedef enum logic [2:0] {
    BR_BEQ  = 3'b000,
    BR_BNE  = 3'b001,
    BR_BLT  = 3'b100,
    BR_BGE  = 3'b101,
    BR_BLTU = 3'b110,
    BR_BGEU = 3'b111
  } branch_op_e;

  // Memory Access Width / Format (funct3[2:0])
  typedef enum logic [2:0] {
    MEM_BYTE  = 3'b000, // LB / SB
    MEM_HALF  = 3'b001, // LH / SH
    MEM_WORD  = 3'b010, // LW / SW
    MEM_BYTEU = 3'b100, // LBU
    MEM_HALFU = 3'b101  // LHU
  } mem_op_e;

  // Immediate Format Selector
  typedef enum logic [2:0] {
    IMM_I,
    IMM_S,
    IMM_B,
    IMM_U,
    IMM_J
  } imm_sel_e;

  // ALU Operand Source Selectors
  typedef enum logic {
    ALU_SRC_A_RS1 = 1'b0,
    ALU_SRC_A_PC  = 1'b1
  } alu_src_a_e;

  typedef enum logic {
    ALU_SRC_B_RS2 = 1'b0,
    ALU_SRC_B_IMM = 1'b1
  } alu_src_b_e;

  // Writeback Target Multiplexer
  typedef enum logic [1:0] {
    WB_SEL_ALU = 2'b00,
    WB_SEL_MEM = 2'b01,
    WB_SEL_PC4 = 2'b10
  } wb_sel_e;

  // Forwarding Control Source Mux
  typedef enum logic [1:0] {
    FWD_NONE = 2'b00, // Original ID/EX register data
    FWD_MEM  = 2'b01, // Forward from EX/MEM stage
    FWD_WB   = 2'b10  // Forward from MEM/WB stage
  } fwd_sel_e;

  // Instruction Decode Control Signals Bundle
  typedef struct packed {
    logic       reg_write;
    logic       mem_read;
    logic       mem_write;
    logic       branch;
    logic       jump;
    logic       jalr;
    alu_op_e    alu_op;
    alu_src_a_e alu_src_a;
    alu_src_b_e alu_src_b;
    wb_sel_e    wb_sel;
    mem_op_e    mem_op;
    logic       illegal_instr;
  } ctrl_signals_t;

endpackage : rv32i_pkg

`endif // RV32I_PKG_SV