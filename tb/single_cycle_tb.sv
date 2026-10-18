// File: tb/single_cycle_tb.sv
`timescale 1ns / 1ps
import rv32i_pkg::*;

module single_cycle_tb;

  logic clk;
  logic rst_n;

  // Interconnect signals
  logic [31:0] imem_addr;
  logic [31:0] imem_data;
  logic        dmem_req;
  logic        dmem_we;
  logic [3:0]  dmem_be;
  logic [31:0] dmem_addr;
  logic [31:0] dmem_wdata;
  logic [31:0] dmem_rdata;

  // Core Instance
  single_cycle_core u_core (
    .i_clk        (clk),
    .i_rst_n      (rst_n),
    .o_imem_addr  (imem_addr),
    .i_imem_data  (imem_data),
    .o_dmem_req   (dmem_req),
    .o_dmem_we    (dmem_we),
    .o_dmem_be    (dmem_be),
    .o_dmem_addr  (dmem_addr),
    .o_dmem_wdata (dmem_wdata),
    .i_dmem_rdata (dmem_rdata)
  );

  // Unified Memory Model (256 32-bit words)
  reference_memory #(.WORDS(256)) u_mem (
    .i_clk        (clk),
    .i_imem_addr  (imem_addr),
    .o_imem_data  (imem_data),
    .i_dmem_req   (dmem_req),
    .i_dmem_we    (dmem_we),
    .i_dmem_be    (dmem_be),
    .i_dmem_addr  (dmem_addr),
    .i_dmem_wdata (dmem_wdata),
    .o_dmem_rdata (dmem_rdata)
  );

  // 100MHz clock
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Helper task to write instruction to memory
  task automatic write_instr(input int word_addr, input logic [31:0] instr);
    u_mem.mem0[word_addr] = instr[7:0];
    u_mem.mem1[word_addr] = instr[15:8];
    u_mem.mem2[word_addr] = instr[23:16];
    u_mem.mem3[word_addr] = instr[31:24];
  endtask

  initial begin
    rst_n = 0;

    // Zero out memory
    for (int i = 0; i < 256; i++) begin
      u_mem.mem0[i] = 8'h00;
      u_mem.mem1[i] = 8'h00;
      u_mem.mem2[i] = 8'h00;
      u_mem.mem3[i] = 8'h00;
    end

    // Load Program:
    // PC = 0x00: addi x1, x0, 10
    write_instr(0, 32'h00A00093);
    // PC = 0x04: addi x2, x0, 20
    write_instr(1, 32'h01400113);
    // PC = 0x08: add  x3, x1, x2       (x3 = 30)
    write_instr(2, 32'h002081B3);
    // PC = 0x0C: sw   x3, 64(x0)       (mem[64] = 30)
    // Data address 0x40 maps to word index 16, avoiding the instruction area.
    write_instr(3, 32'h04302023);
    // PC = 0x10: lw   x4, 64(x0)       (x4 = 30)
    write_instr(4, 32'h04002203);
    // PC = 0x14: beq  x3, x4, +8 (to PC 0x1C)
    write_instr(5, 32'h00418463);
    // PC = 0x18: addi x5, x0, 99       (skipped if branch taken)
    write_instr(6, 32'h06300293);
    // PC = 0x1C: jal  x12, +8 (to PC 0x24) -> x12 must be PC + 4 = 0x20
    write_instr(7, 32'h0080066F);
    // PC = 0x20: addi x6, x0, 55       (skipped by JAL)
    write_instr(8, 32'h03700313);
    // PC = 0x24: addi x7, x0, 1        (Flag done)
    write_instr(9, 32'h00100393);

    #20;
    rst_n = 1;

    // Wait 12 cycles for full execution
    repeat (12) @(posedge clk);

    #1;
    // Assertions
    assert(u_core.u_regfile.regs[1] === 32'd10)
      else $fatal(1, "x1 value mismatch! Expected 10, got %0d", u_core.u_regfile.regs[1]);

    assert(u_core.u_regfile.regs[2] === 32'd20)
      else $fatal(1, "x2 value mismatch! Expected 20, got %0d", u_core.u_regfile.regs[2]);

    assert(u_core.u_regfile.regs[3] === 32'd30)
      else $fatal(1, "x3 value mismatch! Expected 30, got %0d", u_core.u_regfile.regs[3]);

    assert(u_core.u_regfile.regs[4] === 32'd30)
      else $fatal(1, "x4 LW load mismatch! Expected 30, got %0d", u_core.u_regfile.regs[4]);

    assert(u_core.u_regfile.regs[5] === 32'd0)
      else $fatal(1, "x5 should remain 0 (branch skipped failed)!");

    // Verification of JAL link register (0x1C + 4 = 0x20 = 32)
    assert(u_core.u_regfile.regs[12] === 32'h20)
      else $fatal(1, "x12 JAL link mismatch! Expected 0x20, got 0x%08h", u_core.u_regfile.regs[12]);

    assert(u_core.u_regfile.regs[7] === 32'd1)
      else $fatal(1, "x7 finish flag mismatch!");

    $display("\n=======================================================");
    $display("  MILESTONE 2: SINGLE-CYCLE CORE VERIFIED SUCCESSFULLY! ");
    $display("=======================================================\n");
    $finish;
  end

endmodule