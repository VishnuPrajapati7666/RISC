// File: rtl/common/imm_gen.sv
`ifndef IMM_GEN_SV
`define IMM_GEN_SV

`timescale 1ns / 1ps
import rv32i_pkg::*;

module imm_gen (
  input  logic [XLEN-1:0] i_instr,
  input  imm_sel_e        i_imm_sel,
  output logic [XLEN-1:0] o_imm
);

  always_comb begin
    case (i_imm_sel)
      // I-type: rd = rs1 + imm (e.g. ADDI, LW, JALR)
      IMM_I: o_imm = {{20{i_instr[31]}}, i_instr[31:20]};

      // S-type: SW rs2, imm(rs1)
      IMM_S: o_imm = {{20{i_instr[31]}}, i_instr[31:25], i_instr[11:7]};

      // B-type: BEQ rs1, rs2, offset
      IMM_B: o_imm = {{19{i_instr[31]}}, i_instr[31], i_instr[7], i_instr[30:25], i_instr[11:8], 1'b0};

      // U-type: LUI, AUIPC
      IMM_U: o_imm = {i_instr[31:12], 12'b0};

      // J-type: JAL rd, offset
      IMM_J: o_imm = {{11{i_instr[31]}}, i_instr[31], i_instr[19:12], i_instr[20], i_instr[30:21], 1'b0};

      default: o_imm = 32'd0;
    endcase
  end

endmodule : imm_gen

`endif // IMM_GEN_SV