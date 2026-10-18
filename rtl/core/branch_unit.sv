// File: rtl/core/branch_unit.sv
`ifndef BRANCH_UNIT_SV
`define BRANCH_UNIT_SV

`timescale 1ns / 1ps
import rv32i_pkg::*;

module branch_unit (
  input  logic [XLEN-1:0] i_pc,
  input  logic [XLEN-1:0] i_imm,
  input  logic [XLEN-1:0] i_rs1_data,
  input  logic [XLEN-1:0] i_rs2_data,
  input  logic [2:0]      i_funct3,
  input  logic            i_is_branch,
  input  logic            i_is_jump,
  input  logic            i_is_jalr,
  output logic            o_take_branch,
  output logic [XLEN-1:0] o_target_pc
);

  logic condition_met;

  always_comb begin
    case (i_funct3)
      BR_BEQ:  condition_met = (i_rs1_data == i_rs2_data);
      BR_BNE:  condition_met = (i_rs1_data != i_rs2_data);
      BR_BLT:  condition_met = ($signed(i_rs1_data) < $signed(i_rs2_data));
      BR_BGE:  condition_met = ($signed(i_rs1_data) >= $signed(i_rs2_data));
      BR_BLTU: condition_met = (i_rs1_data < i_rs2_data);
      BR_BGEU: condition_met = (i_rs1_data >= i_rs2_data);
      default: condition_met = 1'b0;
    endcase
  end

  assign o_take_branch = (i_is_branch && condition_met) || i_is_jump;

  // JALR target has LSB cleared to 0 according to RISC-V spec
  always_comb begin
    if (i_is_jalr) begin
      o_target_pc = (i_rs1_data + i_imm) & ~32'd1;
    end else begin
      o_target_pc = i_pc + i_imm;
    end
  end

endmodule : branch_unit

`endif // BRANCH_UNIT_SV