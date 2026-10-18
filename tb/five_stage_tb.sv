`timescale 1ns / 1ps
import rv32i_pkg::*;

module five_stage_tb;
  logic clk;
  logic rst_n;
  logic [31:0] imem_addr, imem_data;
  logic dmem_req, dmem_we;
  logic [3:0] dmem_be;
  logic [31:0] dmem_addr, dmem_wdata, dmem_rdata;

  five_stage_core u_core (
    .i_clk(clk), .i_rst_n(rst_n),
    .o_imem_addr(imem_addr), .i_imem_data(imem_data),
    .o_dmem_req(dmem_req), .o_dmem_we(dmem_we), .o_dmem_be(dmem_be),
    .o_dmem_addr(dmem_addr), .o_dmem_wdata(dmem_wdata),
    .i_dmem_rdata(dmem_rdata)
  );

  reference_memory #(.WORDS(256)) u_mem (
    .i_clk(clk), .i_imem_addr(imem_addr), .o_imem_data(imem_data),
    .i_dmem_req(dmem_req), .i_dmem_we(dmem_we), .i_dmem_be(dmem_be),
    .i_dmem_addr(dmem_addr), .i_dmem_wdata(dmem_wdata),
    .o_dmem_rdata(dmem_rdata)
  );

  initial begin clk = 1'b0; forever #5 clk = ~clk; end

  task automatic write_instr(input int word_addr, input logic [31:0] instr);
    u_mem.mem0[word_addr] = instr[7:0];
    u_mem.mem1[word_addr] = instr[15:8];
    u_mem.mem2[word_addr] = instr[23:16];
    u_mem.mem3[word_addr] = instr[31:24];
  endtask

  initial begin
    rst_n = 1'b0;
    for (int i = 0; i < 256; i++) begin
      u_mem.mem0[i] = 8'd0;
      u_mem.mem1[i] = 8'd0;
      u_mem.mem2[i] = 8'd0;
      u_mem.mem3[i] = 8'd0;
    end

    write_instr(0, 32'h00A00093); // addi x1, x0, 10
    write_instr(1, 32'h00000013); // NOP
    write_instr(2, 32'h00000013); // NOP
    write_instr(3, 32'h01400113); // addi x2, x0, 20
    write_instr(4, 32'h00000013); // NOP
    write_instr(5, 32'h00000013); // NOP
    write_instr(6, 32'h002081B3); // add x3, x1, x2
    write_instr(7, 32'h00000013); // NOP
    write_instr(8, 32'h00000013); // NOP
    write_instr(9, 32'h04302023); // sw x3, 64(x0)
    write_instr(10, 32'h00000013);
    write_instr(11, 32'h00000013);
    write_instr(12, 32'h04002203); // lw x4, 64(x0)
    write_instr(13, 32'h00000013);
    write_instr(14, 32'h00000013);
    write_instr(15, 32'h00418463); // beq x3, x4, +8
    write_instr(16, 32'h06300293); // skipped: addi x5, x0, 99
    write_instr(17, 32'h0080066F); // jal x12, +8
    write_instr(18, 32'h03700313); // skipped by JAL
    write_instr(19, 32'h00100393); // addi x7, x0, 1

    #20;
    rst_n = 1'b1;
    repeat (30) @(posedge clk);
    #1;
    assert(u_core.u_regfile.regs[1] === 32'd10)
      else $fatal(1, "x1 mismatch: %0d", u_core.u_regfile.regs[1]);
    assert(u_core.u_regfile.regs[2] === 32'd20)
      else $fatal(1, "x2 mismatch: %0d", u_core.u_regfile.regs[2]);
    assert(u_core.u_regfile.regs[3] === 32'd30)
      else $fatal(1, "x3 mismatch: %0d", u_core.u_regfile.regs[3]);
    assert(u_core.u_regfile.regs[4] === 32'd30)
      else $fatal(1, "x4 mismatch: %0d", u_core.u_regfile.regs[4]);
    assert(u_core.u_regfile.regs[5] === 32'd0)
      else $fatal(1, "x5 should be skipped: %0d", u_core.u_regfile.regs[5]);
    assert(u_core.u_regfile.regs[12] === 32'h48)
      else $fatal(1, "x12 JAL link mismatch: %0d", u_core.u_regfile.regs[12]);
    assert(u_core.u_regfile.regs[7] === 32'd1)
      else $fatal(1, "x7 mismatch: %0d", u_core.u_regfile.regs[7]);
    $display("MILESTONE 3: FIVE-STAGE PIPELINE VERIFIED SUCCESSFULLY!");
    $finish;
  end
endmodule
