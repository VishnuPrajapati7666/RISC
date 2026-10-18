// File: rtl/common/alu.sv
`ifndef ALU_SV
`define ALU_SV

`timescale 1ns / 1ps
import rv32i_pkg::*;

module alu (
  input  logic [XLEN-1:0]   i_op_a,
  input  logic [XLEN-1:0]   i_op_b,
  input  alu_op_e           i_alu_op,
  output logic [XLEN-1:0]   o_result,
  output logic              o_zero
);

  logic [4:0] shamt;
  assign shamt = i_op_b[4:0];

  always_comb begin
    case (i_alu_op)
      ALU_ADD:    o_result = i_op_a + i_op_b;
      ALU_SUB:    o_result = i_op_a - i_op_b;
      ALU_SLL:    o_result = i_op_a << shamt;
      ALU_SLT:    o_result = ($signed(i_op_a) < $signed(i_op_b)) ? 32'd1 : 32'd0;
      ALU_SLTU:   o_result = (i_op_a < i_op_b) ? 32'd1 : 32'd0;
      ALU_XOR:    o_result = i_op_a ^ i_op_b;
      ALU_SRL:    o_result = i_op_a >> shamt;
      ALU_SRA:    o_result = $signed(i_op_a) >>> shamt;
      ALU_OR:     o_result = i_op_a | i_op_b;
      ALU_AND:    o_result = i_op_a & i_op_b;
      ALU_COPY_B: o_result = i_op_b;
      default:    o_result = 32'd0;
    endcase
  end

  assign o_zero = (o_result == 32'd0);

endmodule : alu

`endif // ALU_SV