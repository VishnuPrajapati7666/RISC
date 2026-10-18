`ifndef FIVE_STAGE_CORE_SV
`define FIVE_STAGE_CORE_SV

`timescale 1ns / 1ps
import rv32i_pkg::*;

module five_stage_core (
  input  logic        i_clk,
  input  logic        i_rst_n,
  output logic [31:0] o_imem_addr,
  input  logic [31:0] i_imem_data,
  output logic        o_dmem_req,
  output logic        o_dmem_we,
  output logic [3:0]  o_dmem_be,
  output logic [31:0] o_dmem_addr,
  output logic [31:0] o_dmem_wdata,
  input  logic [31:0] i_dmem_rdata
);

  localparam logic [31:0] NOP = 32'h00000013;

  logic [31:0] pc;
  logic        if_id_valid;
  logic [31:0] if_id_pc;
  logic [31:0] if_id_instr;

  logic        id_ex_valid;
  logic [31:0] id_ex_pc;
  logic [31:0] id_ex_rs1_data;
  logic [31:0] id_ex_rs2_data;
  logic [31:0] id_ex_imm;
  logic [31:0] id_ex_pc_plus_4;
  logic [2:0]  id_ex_funct3;
  logic [4:0]  id_ex_rd;
  ctrl_signals_t id_ex_ctrl;

  logic        ex_mem_valid;
  logic [31:0] ex_mem_alu_result;
  logic [31:0] ex_mem_store_data;
  logic [31:0] ex_mem_pc_plus_4;
  logic [4:0]  ex_mem_rd;
  ctrl_signals_t ex_mem_ctrl;

  logic        mem_wb_valid;
  logic [31:0] mem_wb_alu_result;
  logic [31:0] mem_wb_load_data;
  logic [31:0] mem_wb_pc_plus_4;
  logic [4:0]  mem_wb_rd;
  ctrl_signals_t mem_wb_ctrl;

  logic [31:0] id_imm;
  logic [31:0] id_rs1_data;
  logic [31:0] id_rs2_data;
  logic [4:0]  id_rs1_addr;
  logic [4:0]  id_rs2_addr;
  logic [4:0]  id_rd_addr;
  logic [31:0] wb_data;
  logic [31:0] mem_load_data_comb;

  ctrl_signals_t id_ctrl;
  imm_sel_e id_imm_sel;

  decoder u_decoder (
    .i_instr    (if_id_instr),
    .o_ctrl     (id_ctrl),
    .o_imm_sel  (id_imm_sel),
    .o_rs1_addr (id_rs1_addr),
    .o_rs2_addr (id_rs2_addr),
    .o_rd_addr  (id_rd_addr)
  );

  imm_gen u_imm_gen (
    .i_instr   (if_id_instr),
    .i_imm_sel (id_imm_sel),
    .o_imm     (id_imm)
  );

  regfile u_regfile (
    .i_clk      (i_clk),
    .i_rst_n    (i_rst_n),
    .i_rs1_addr (id_rs1_addr),
    .o_rs1_data (id_rs1_data),
    .i_rs2_addr (id_rs2_addr),
    .o_rs2_data (id_rs2_data),
    .i_rd_we    (mem_wb_valid && mem_wb_ctrl.reg_write),
    .i_rd_addr  (mem_wb_rd),
    .i_rd_data  (wb_data)
  );

  logic [31:0] ex_op_a;
  logic [31:0] ex_op_b;
  logic [31:0] ex_alu_result;
  logic        branch_taken;
  logic [31:0] branch_target;

  assign ex_op_a = (id_ex_ctrl.alu_src_a == ALU_SRC_A_PC) ?
                   id_ex_pc : id_ex_rs1_data;
  assign ex_op_b = (id_ex_ctrl.alu_src_b == ALU_SRC_B_IMM) ?
                   id_ex_imm : id_ex_rs2_data;

  alu u_alu (
    .i_op_a    (ex_op_a),
    .i_op_b    (ex_op_b),
    .i_alu_op  (id_ex_ctrl.alu_op),
    .o_result  (ex_alu_result),
    .o_zero    ()
  );

  branch_unit u_branch_unit (
    .i_pc          (id_ex_pc),
    .i_imm         (id_ex_imm),
    .i_rs1_data    (id_ex_rs1_data),
    .i_rs2_data    (id_ex_rs2_data),
    .i_funct3      (id_ex_funct3),
    .i_is_branch   (id_ex_valid && id_ex_ctrl.branch),
    .i_is_jump     (id_ex_valid && id_ex_ctrl.jump),
    .i_is_jalr     (id_ex_valid && id_ex_ctrl.jalr),
    .o_take_branch (branch_taken),
    .o_target_pc   (branch_target)
  );

  assign o_imem_addr = pc;
  assign o_dmem_req  = ex_mem_valid &&
                       (ex_mem_ctrl.mem_read || ex_mem_ctrl.mem_write);
  assign o_dmem_we   = ex_mem_valid && ex_mem_ctrl.mem_write;
  assign o_dmem_addr = ex_mem_alu_result;

  always_comb begin
    o_dmem_be = 4'b0000;
    o_dmem_wdata = ex_mem_store_data;
    case (ex_mem_ctrl.mem_op)
      MEM_BYTE, MEM_BYTEU: begin
        case (ex_mem_alu_result[1:0])
          2'b00: begin
            o_dmem_be = 4'b0001;
            o_dmem_wdata = {24'd0, ex_mem_store_data[7:0]};
          end
          2'b01: begin
            o_dmem_be = 4'b0010;
            o_dmem_wdata = {16'd0, ex_mem_store_data[7:0], 8'd0};
          end
          2'b10: begin
            o_dmem_be = 4'b0100;
            o_dmem_wdata = {8'd0, ex_mem_store_data[7:0], 16'd0};
          end
          2'b11: begin
            o_dmem_be = 4'b1000;
            o_dmem_wdata = {ex_mem_store_data[7:0], 24'd0};
          end
        endcase
      end
      MEM_HALF, MEM_HALFU: begin
        if (ex_mem_alu_result[1]) begin
          o_dmem_be = 4'b1100;
          o_dmem_wdata = {ex_mem_store_data[15:0], 16'd0};
        end else begin
          o_dmem_be = 4'b0011;
          o_dmem_wdata = {16'd0, ex_mem_store_data[15:0]};
        end
      end
      MEM_WORD: o_dmem_be = 4'b1111;
      default: o_dmem_be = 4'b0000;
    endcase
    if (!ex_mem_valid || !ex_mem_ctrl.mem_write) begin
      o_dmem_be = 4'b0000;
      o_dmem_wdata = 32'd0;
    end
  end

  always_comb begin
    case (ex_mem_ctrl.mem_op)
      MEM_BYTE: begin
        case (ex_mem_alu_result[1:0])
          2'b00: mem_load_data_comb = {{24{i_dmem_rdata[7]}}, i_dmem_rdata[7:0]};
          2'b01: mem_load_data_comb = {{24{i_dmem_rdata[15]}}, i_dmem_rdata[15:8]};
          2'b10: mem_load_data_comb = {{24{i_dmem_rdata[23]}}, i_dmem_rdata[23:16]};
          default: mem_load_data_comb = {{24{i_dmem_rdata[31]}}, i_dmem_rdata[31:24]};
        endcase
      end
      MEM_BYTEU: begin
        case (ex_mem_alu_result[1:0])
          2'b00: mem_load_data_comb = {24'd0, i_dmem_rdata[7:0]};
          2'b01: mem_load_data_comb = {24'd0, i_dmem_rdata[15:8]};
          2'b10: mem_load_data_comb = {24'd0, i_dmem_rdata[23:16]};
          default: mem_load_data_comb = {24'd0, i_dmem_rdata[31:24]};
        endcase
      end
      MEM_HALF: mem_load_data_comb = ex_mem_alu_result[1] ?
                                    {{16{i_dmem_rdata[31]}}, i_dmem_rdata[31:16]} :
                                    {{16{i_dmem_rdata[15]}}, i_dmem_rdata[15:0]};
      MEM_HALFU: mem_load_data_comb = ex_mem_alu_result[1] ?
                                    {16'd0, i_dmem_rdata[31:16]} :
                                    {16'd0, i_dmem_rdata[15:0]};
      default: mem_load_data_comb = i_dmem_rdata;
    endcase
  end

  always_comb begin
    case (mem_wb_ctrl.wb_sel)
      WB_SEL_MEM: wb_data = mem_wb_load_data;
      WB_SEL_PC4: wb_data = mem_wb_pc_plus_4;
      default: wb_data = mem_wb_alu_result;
    endcase
  end

  always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      pc <= 32'd0;
      if_id_valid <= 1'b0;
      if_id_pc <= 32'd0;
      if_id_instr <= NOP;
      id_ex_valid <= 1'b0;
      id_ex_pc <= 32'd0;
      id_ex_rs1_data <= 32'd0;
      id_ex_rs2_data <= 32'd0;
      id_ex_imm <= 32'd0;
      id_ex_pc_plus_4 <= 32'd0;
      id_ex_funct3 <= 3'd0;
      id_ex_rd <= 5'd0;
      id_ex_ctrl <= '0;
      ex_mem_valid <= 1'b0;
      ex_mem_alu_result <= 32'd0;
      ex_mem_store_data <= 32'd0;
      ex_mem_pc_plus_4 <= 32'd0;
      ex_mem_rd <= 5'd0;
      ex_mem_ctrl <= '0;
      mem_wb_valid <= 1'b0;
      mem_wb_alu_result <= 32'd0;
      mem_wb_load_data <= 32'd0;
      mem_wb_pc_plus_4 <= 32'd0;
      mem_wb_rd <= 5'd0;
      mem_wb_ctrl <= '0;
    end else begin
      mem_wb_valid <= ex_mem_valid;
      mem_wb_alu_result <= ex_mem_alu_result;
      mem_wb_load_data <= mem_load_data_comb;
      mem_wb_pc_plus_4 <= ex_mem_pc_plus_4;
      mem_wb_rd <= ex_mem_rd;
      mem_wb_ctrl <= ex_mem_ctrl;

      ex_mem_valid <= id_ex_valid;
      ex_mem_alu_result <= ex_alu_result;
      ex_mem_store_data <= id_ex_rs2_data;
      ex_mem_pc_plus_4 <= id_ex_pc_plus_4;
      ex_mem_rd <= id_ex_rd;
      ex_mem_ctrl <= id_ex_ctrl;

      if (branch_taken) begin
        pc <= branch_target;
        if_id_valid <= 1'b0;
        if_id_pc <= 32'd0;
        if_id_instr <= NOP;
        id_ex_valid <= 1'b0;
        id_ex_ctrl <= '0;
      end else begin
        pc <= pc + 32'd4;
        if_id_valid <= 1'b1;
        if_id_pc <= pc;
        if_id_instr <= i_imem_data;
        id_ex_valid <= if_id_valid;
        id_ex_pc <= if_id_pc;
        id_ex_rs1_data <= id_rs1_data;
        id_ex_rs2_data <= id_rs2_data;
        id_ex_imm <= id_imm;
        id_ex_pc_plus_4 <= if_id_pc + 32'd4;
        id_ex_funct3 <= if_id_instr[14:12];
        id_ex_rd <= id_rd_addr;
        id_ex_ctrl <= id_ctrl;
      end
    end
  end

endmodule : five_stage_core

`endif
