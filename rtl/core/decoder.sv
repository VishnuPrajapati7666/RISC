// File: rtl/core/decoder.sv
`ifndef DECODER_SV
`define DECODER_SV

`timescale 1ns / 1ps
import rv32i_pkg::*;

module decoder (
  input  logic [XLEN-1:0]       i_instr,
  output ctrl_signals_t         o_ctrl,
  output imm_sel_e              o_imm_sel,
  output logic [REG_ADDR_WIDTH-1:0] o_rs1_addr,
  output logic [REG_ADDR_WIDTH-1:0] o_rs2_addr,
  output logic [REG_ADDR_WIDTH-1:0] o_rd_addr
);

  logic [6:0] opcode;
  logic [2:0] funct3;
  logic [6:0] funct7;

  assign opcode     = i_instr[6:0];
  assign o_rd_addr  = i_instr[11:7];
  assign funct3     = i_instr[14:12];
  assign o_rs1_addr = i_instr[19:15];
  assign o_rs2_addr = i_instr[24:20];
  assign funct7     = i_instr[31:25];

  always_comb begin
    // Default assignments
    o_ctrl.reg_write     = 1'b0;
    o_ctrl.mem_read      = 1'b0;
    o_ctrl.mem_write     = 1'b0;
    o_ctrl.branch        = 1'b0;
    o_ctrl.jump          = 1'b0;
    o_ctrl.jalr          = 1'b0;
    o_ctrl.alu_op        = ALU_ADD;
    o_ctrl.alu_src_a     = ALU_SRC_A_RS1;
    o_ctrl.alu_src_b     = ALU_SRC_B_RS2;
    o_ctrl.wb_sel        = WB_SEL_ALU;
    o_ctrl.mem_op        = MEM_WORD;
    o_ctrl.illegal_instr = 1'b0;
    o_imm_sel            = IMM_I;

    case (opcode)
      // R-type: Register Arithmetic/Logic
      OPCODE_OP: begin
        o_ctrl.reg_write = 1'b1;
        o_ctrl.alu_src_a = ALU_SRC_A_RS1;
        o_ctrl.alu_src_b = ALU_SRC_B_RS2;
        o_ctrl.wb_sel    = WB_SEL_ALU;
        case (funct3)
          3'b000: begin
            if (funct7 == 7'b0000000) o_ctrl.alu_op = ALU_ADD;
            else if (funct7 == 7'b0100000) o_ctrl.alu_op = ALU_SUB;
            else o_ctrl.illegal_instr = 1'b1;
          end
          3'b001: begin
            o_ctrl.alu_op = ALU_SLL;
            if (funct7 != 7'b0000000) o_ctrl.illegal_instr = 1'b1;
          end
          3'b010: begin
            o_ctrl.alu_op = ALU_SLT;
            if (funct7 != 7'b0000000) o_ctrl.illegal_instr = 1'b1;
          end
          3'b011: begin
            o_ctrl.alu_op = ALU_SLTU;
            if (funct7 != 7'b0000000) o_ctrl.illegal_instr = 1'b1;
          end
          3'b100: begin
            o_ctrl.alu_op = ALU_XOR;
            if (funct7 != 7'b0000000) o_ctrl.illegal_instr = 1'b1;
          end
          3'b101: begin
            if (funct7 == 7'b0000000) o_ctrl.alu_op = ALU_SRL;
            else if (funct7 == 7'b0100000) o_ctrl.alu_op = ALU_SRA;
            else o_ctrl.illegal_instr = 1'b1;
          end
          3'b110: begin
            o_ctrl.alu_op = ALU_OR;
            if (funct7 != 7'b0000000) o_ctrl.illegal_instr = 1'b1;
          end
          3'b111: begin
            o_ctrl.alu_op = ALU_AND;
            if (funct7 != 7'b0000000) o_ctrl.illegal_instr = 1'b1;
          end
          default: o_ctrl.illegal_instr = 1'b1;
        endcase
      end

      // I-type: Immediate Arithmetic/Logic
      OPCODE_OP_IMM: begin
        o_ctrl.reg_write = 1'b1;
        o_ctrl.alu_src_a = ALU_SRC_A_RS1;
        o_ctrl.alu_src_b = ALU_SRC_B_IMM;
        o_imm_sel        = IMM_I;
        o_ctrl.wb_sel    = WB_SEL_ALU;
        case (funct3)
          3'b000: o_ctrl.alu_op = ALU_ADD; // ADDI
          3'b001: begin // SLLI
            o_ctrl.alu_op = ALU_SLL;
            if (funct7 != 7'b0000000) o_ctrl.illegal_instr = 1'b1;
          end
          3'b010: o_ctrl.alu_op = ALU_SLT; // SLTI
          3'b011: o_ctrl.alu_op = ALU_SLTU; // SLTIU
          3'b100: o_ctrl.alu_op = ALU_XOR; // XORI
          3'b101: begin // SRAI / SRLI
            if (funct7 == 7'b0000000) o_ctrl.alu_op = ALU_SRL;
            else if (funct7 == 7'b0100000) o_ctrl.alu_op = ALU_SRA;
            else o_ctrl.illegal_instr = 1'b1;
          end
          3'b110: o_ctrl.alu_op = ALU_OR;  // ORI
          3'b111: o_ctrl.alu_op = ALU_AND; // ANDI
          default: o_ctrl.illegal_instr = 1'b1;
        endcase
      end

      // Loads
      OPCODE_LOAD: begin
        o_ctrl.reg_write = 1'b1;
        o_ctrl.mem_read  = 1'b1;
        o_ctrl.alu_src_a = ALU_SRC_A_RS1;
        o_ctrl.alu_src_b = ALU_SRC_B_IMM;
        o_imm_sel        = IMM_I;
        o_ctrl.alu_op    = ALU_ADD;
        o_ctrl.wb_sel    = WB_SEL_MEM;
        case (funct3)
          3'b000:  o_ctrl.mem_op = MEM_BYTE;  // LB
          3'b001:  o_ctrl.mem_op = MEM_HALF;  // LH
          3'b010:  o_ctrl.mem_op = MEM_WORD;  // LW
          3'b100:  o_ctrl.mem_op = MEM_BYTEU; // LBU
          3'b101:  o_ctrl.mem_op = MEM_HALFU; // LHU
          default: o_ctrl.illegal_instr = 1'b1;
        endcase
      end

      // Stores
      OPCODE_STORE: begin
        o_ctrl.mem_write = 1'b1;
        o_ctrl.alu_src_a = ALU_SRC_A_RS1;
        o_ctrl.alu_src_b = ALU_SRC_B_IMM;
        o_imm_sel        = IMM_S;
        o_ctrl.alu_op    = ALU_ADD;
        case (funct3)
          3'b000:  o_ctrl.mem_op = MEM_BYTE; // SB
          3'b001:  o_ctrl.mem_op = MEM_HALF; // SH
          3'b010:  o_ctrl.mem_op = MEM_WORD; // SW
          default: o_ctrl.illegal_instr = 1'b1;
        endcase
      end

      // Conditional Branches
      OPCODE_BRANCH: begin
        o_ctrl.branch    = 1'b1;
        o_imm_sel        = IMM_B;
        o_ctrl.alu_src_a = ALU_SRC_A_RS1;
        o_ctrl.alu_src_b = ALU_SRC_B_RS2;
        if ((funct3 != BR_BEQ) && (funct3 != BR_BNE) &&
            (funct3 != BR_BLT) && (funct3 != BR_BGE) &&
            (funct3 != BR_BLTU) && (funct3 != BR_BGEU)) begin
          o_ctrl.illegal_instr = 1'b1;
        end
      end

      // JAL: Jump and Link
      OPCODE_JAL: begin
        o_ctrl.jump      = 1'b1;
        o_ctrl.reg_write = 1'b1;
        o_imm_sel        = IMM_J;
        o_ctrl.wb_sel    = WB_SEL_PC4; // Must store PC + 4 in rd
      end

      // JALR: Jump and Link Register
      OPCODE_JALR: begin
        o_ctrl.jump      = 1'b1;
        o_ctrl.jalr      = 1'b1;
        o_ctrl.reg_write = 1'b1;
        o_imm_sel        = IMM_I;
        o_ctrl.wb_sel    = WB_SEL_PC4; // Must store PC + 4 in rd
        if (funct3 != 3'b000) o_ctrl.illegal_instr = 1'b1;
      end

      // LUI: Load Upper Immediate
      OPCODE_LUI: begin
        o_ctrl.reg_write = 1'b1;
        o_ctrl.alu_src_a = ALU_SRC_A_RS1;
        o_ctrl.alu_src_b = ALU_SRC_B_IMM;
        o_ctrl.alu_op    = ALU_COPY_B;
        o_imm_sel        = IMM_U;
        o_ctrl.wb_sel    = WB_SEL_ALU;
      end

      // AUIPC: Add Upper Immediate to PC
      OPCODE_AUIPC: begin
        o_ctrl.reg_write = 1'b1;
        o_ctrl.alu_src_a = ALU_SRC_A_PC;
        o_ctrl.alu_src_b = ALU_SRC_B_IMM;
        o_ctrl.alu_op    = ALU_ADD;
        o_imm_sel        = IMM_U;
        o_ctrl.wb_sel    = WB_SEL_ALU;
      end

      // NOP / FENCE
      OPCODE_FENCE: begin
        // Treated as NOP in uniprocessor core
      end

      default: begin
        o_ctrl.illegal_instr = 1'b1;
      end
    endcase

    // Illegal encodings must have no architectural side effects.
    if (o_ctrl.illegal_instr) begin
      o_ctrl.reg_write = 1'b0;
      o_ctrl.mem_read  = 1'b0;
      o_ctrl.mem_write = 1'b0;
      o_ctrl.branch    = 1'b0;
      o_ctrl.jump      = 1'b0;
      o_ctrl.jalr      = 1'b0;
    end
  end

endmodule : decoder

`endif // DECODER_SV