// File: rtl/core/single_cycle_core.sv
`ifndef SINGLE_CYCLE_CORE_SV
`define SINGLE_CYCLE_CORE_SV

`timescale 1ns / 1ps
import rv32i_pkg::*;

module single_cycle_core (
  input  logic        i_clk,
  input  logic        i_rst_n,

  // Instruction Memory Interface
  output logic [31:0] o_imem_addr,
  input  logic [31:0] i_imem_data,

  // Data Memory Interface
  output logic        o_dmem_req,
  output logic        o_dmem_we,
  output logic [3:0]  o_dmem_be,
  output logic [31:0] o_dmem_addr,
  output logic [31:0] o_dmem_wdata,
  input  logic [31:0] i_dmem_rdata
);

  // PC and Control
  logic [31:0] pc;
  logic [31:0] pc_next;
  logic [31:0] pc_plus_4;
  assign pc_plus_4   = pc + 32'd4;
  assign o_imem_addr = pc;

  // Decoder signals
  ctrl_signals_t         ctrl;
  imm_sel_e              imm_sel;
  logic [REG_ADDR_WIDTH-1:0] rs1_addr, rs2_addr, rd_addr;

  decoder u_decoder (
    .i_instr      (i_imem_data),
    .o_ctrl       (ctrl),
    .o_imm_sel   (imm_sel),
    .o_rs1_addr   (rs1_addr),
    .o_rs2_addr   (rs2_addr),
    .o_rd_addr    (rd_addr)
  );

  // Register File
  logic [31:0] rs1_data, rs2_data, wb_data;

  regfile u_regfile (
    .i_clk        (i_clk),
    .i_rst_n      (i_rst_n),
    .i_rs1_addr   (rs1_addr),
    .o_rs1_data   (rs1_data),
    .i_rs2_addr   (rs2_addr),
    .o_rs2_data   (rs2_data),
    .i_rd_we      (ctrl.reg_write),
    .i_rd_addr    (rd_addr),
    .i_rd_data    (wb_data)
  );

  // Immediate Generator
  logic [31:0] imm;
  imm_gen u_imm_gen (
    .i_instr      (i_imem_data),
    .i_imm_sel   (imm_sel),
    .o_imm        (imm)
  );

  // ALU Operand Muxes
  logic [31:0] alu_op_a, alu_op_b, alu_result;
  logic        alu_zero;

  assign alu_op_a = (ctrl.alu_src_a == ALU_SRC_A_PC) ? pc : rs1_data;
  assign alu_op_b = (ctrl.alu_src_b == ALU_SRC_B_IMM) ? imm : rs2_data;

  alu u_alu (
    .i_op_a       (alu_op_a),
    .i_op_b       (alu_op_b),
    .i_alu_op     (ctrl.alu_op),
    .o_result     (alu_result),
    .o_zero       (alu_zero)
  );

  // Branch Unit
  logic        take_branch;
  logic [31:0] target_pc;

  branch_unit u_branch_unit (
    .i_pc          (pc),
    .i_imm         (imm),
    .i_rs1_data    (rs1_data),
    .i_rs2_data    (rs2_data),
    .i_funct3      (i_imem_data[14:12]),
    .i_is_branch   (ctrl.branch),
    .i_is_jump     (ctrl.jump),
    .i_is_jalr     (ctrl.jalr),
    .o_take_branch (take_branch),
    .o_target_pc   (target_pc)
  );

  assign pc_next = (take_branch) ? target_pc : pc_plus_4;

  // Program Counter Register
  always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      pc <= 32'd0;
    end else begin
      pc <= pc_next;
    end
  end

  // Data Memory Formatting (Address, BE, and Write Data)
  assign o_dmem_addr = alu_result;
  assign o_dmem_req  = ctrl.mem_read | ctrl.mem_write;
  assign o_dmem_we   = ctrl.mem_write;

  always_comb begin
    o_dmem_be    = 4'b0000;
    o_dmem_wdata = rs2_data;
    case (ctrl.mem_op)
      MEM_BYTE, MEM_BYTEU: begin
        case (alu_result[1:0])
          2'b00: begin o_dmem_be = 4'b0001; o_dmem_wdata[7:0]   = rs2_data[7:0]; end
          2'b01: begin o_dmem_be = 4'b0010; o_dmem_wdata[15:8]  = rs2_data[7:0]; end
          2'b10: begin o_dmem_be = 4'b0100; o_dmem_wdata[23:16] = rs2_data[7:0]; end
          2'b11: begin o_dmem_be = 4'b1000; o_dmem_wdata[31:24] = rs2_data[7:0]; end
        endcase
      end
      MEM_HALF, MEM_HALFU: begin
        if (alu_result[1]) begin
          o_dmem_be = 4'b1100;
          o_dmem_wdata[31:16] = rs2_data[15:0];
        end else begin
          o_dmem_be = 4'b0011;
          o_dmem_wdata[15:0]  = rs2_data[15:0];
        end
      end
      MEM_WORD: begin
        o_dmem_be    = 4'b1111;
        o_dmem_wdata = rs2_data;
      end
      default: begin
        o_dmem_be    = 4'b1111;
        o_dmem_wdata = rs2_data;
      end
    endcase
  end

  // Load Data Sign/Zero Extension
  logic [31:0] mem_rdata_formatted;
  always_comb begin
    case (ctrl.mem_op)
      MEM_BYTE: begin
        case (alu_result[1:0])
          2'b00: mem_rdata_formatted = {{24{i_dmem_rdata[7]}},  i_dmem_rdata[7:0]};
          2'b01: mem_rdata_formatted = {{24{i_dmem_rdata[15]}}, i_dmem_rdata[15:8]};
          2'b10: mem_rdata_formatted = {{24{i_dmem_rdata[23]}}, i_dmem_rdata[23:16]};
          2'b11: mem_rdata_formatted = {{24{i_dmem_rdata[31]}}, i_dmem_rdata[31:24]};
        endcase
      end
      MEM_BYTEU: begin
        case (alu_result[1:0])
          2'b00: mem_rdata_formatted = {24'd0, i_dmem_rdata[7:0]};
          2'b01: mem_rdata_formatted = {24'd0, i_dmem_rdata[15:8]};
          2'b10: mem_rdata_formatted = {24'd0, i_dmem_rdata[23:16]};
          2'b11: mem_rdata_formatted = {24'd0, i_dmem_rdata[31:24]};
        endcase
      end
      MEM_HALF: begin
        mem_rdata_formatted = alu_result[1] ? {{16{i_dmem_rdata[31]}}, i_dmem_rdata[31:16]} :
                                              {{16{i_dmem_rdata[15]}}, i_dmem_rdata[15:0]};
      end
      MEM_HALFU: begin
        mem_rdata_formatted = alu_result[1] ? {16'd0, i_dmem_rdata[31:16]} :
                                              {16'd0, i_dmem_rdata[15:0]};
      end
      MEM_WORD: begin
        mem_rdata_formatted = i_dmem_rdata;
      end
      default: mem_rdata_formatted = i_dmem_rdata;
    endcase
  end

  // Writeback Multiplexer (CRITICAL: JAL / JALR link address uses pc_plus_4)
  always_comb begin
    case (ctrl.wb_sel)
      WB_SEL_ALU: wb_data = alu_result;
      WB_SEL_MEM: wb_data = mem_rdata_formatted;
      WB_SEL_PC4: wb_data = pc_plus_4;
      default:    wb_data = alu_result;
    endcase
  end

endmodule : single_cycle_core

`endif // SINGLE_CYCLE_CORE_SV