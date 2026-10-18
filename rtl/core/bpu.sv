`ifndef BPU_SV
`define BPU_SV

`timescale 1ns / 1ps

module bpu #(
  parameter int ENTRIES = 16
) (
  input  logic        i_clk,
  input  logic        i_rst_n,
  input  logic [31:0] i_fetch_pc,
  input  logic [31:0] i_fetch_instr,
  output logic        o_predict_taken,
  output logic [31:0] o_predict_target,
  input  logic        i_update_valid,
  input  logic [31:0] i_update_pc,
  input  logic        i_update_taken
);

  logic [1:0] counters [0:ENTRIES-1];
  logic [$clog2(ENTRIES)-1:0] fetch_index;
  logic [$clog2(ENTRIES)-1:0] update_index;
  logic [6:0] opcode;
  logic [31:0] branch_imm;
  logic [31:0] jump_imm;

  assign fetch_index = i_fetch_pc[$clog2(ENTRIES)+1:2];
  assign update_index = i_update_pc[$clog2(ENTRIES)+1:2];
  assign opcode = i_fetch_instr[6:0];

  assign branch_imm = {{19{i_fetch_instr[31]}}, i_fetch_instr[31],
                       i_fetch_instr[7], i_fetch_instr[30:25],
                       i_fetch_instr[11:8], 1'b0};
  assign jump_imm = {{11{i_fetch_instr[31]}}, i_fetch_instr[31],
                     i_fetch_instr[19:12], i_fetch_instr[20],
                     i_fetch_instr[30:21], 1'b0};

  always_comb begin
    o_predict_taken = 1'b0;
    o_predict_target = i_fetch_pc + 32'd4;
    case (opcode)
      7'b1100011: begin
        o_predict_taken = counters[fetch_index][1];
        o_predict_target = i_fetch_pc + branch_imm;
      end
      7'b1101111: begin
        o_predict_taken = 1'b1;
        o_predict_target = i_fetch_pc + jump_imm;
      end
      default: begin
        o_predict_taken = 1'b0;
      end
    endcase
  end

  always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      for (int i = 0; i < ENTRIES; i++) counters[i] <= 2'b01;
    end else if (i_update_valid) begin
      if (i_update_taken && (counters[update_index] != 2'b11))
        counters[update_index] <= counters[update_index] + 2'b01;
      else if (!i_update_taken && (counters[update_index] != 2'b00))
        counters[update_index] <= counters[update_index] - 2'b01;
    end
  end
endmodule

`endif
