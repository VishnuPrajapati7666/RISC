`timescale 1ns / 1ps
import rv32i_pkg::*;

module hazard_tb;
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

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

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
    write_instr(1, 32'h01400113); // addi x2, x0, 20
    write_instr(2, 32'h002081B3); // add  x3, x1, x2 = 30
    write_instr(3, 32'h00118233); // add  x4, x3, x1 = 40
    write_instr(4, 32'h04402023); // sw   x4, 64(x0)
    write_instr(5, 32'h04002283); // lw   x5, 64(x0)
    write_instr(6, 32'h00328333); // add  x6, x5, x3 = 70 (load-use stall)
    write_instr(7, 32'h00630463); // beq  x6, x6, +8 (forwarded branch)
    write_instr(8, 32'h06300413); // skipped: addi x8, x0, 99
    write_instr(9, 32'h00100493); // addi x9, x0, 1

    #20;
    rst_n = 1'b1;
    repeat (24) @(posedge clk);
    #1;

    assert(u_core.u_regfile.regs[3] === 32'd30)
      else $fatal(1, "ALU forwarding failed for x3: %0d", u_core.u_regfile.regs[3]);
    assert(u_core.u_regfile.regs[4] === 32'd40)
      else $fatal(1, "ALU forwarding failed for x4: %0d", u_core.u_regfile.regs[4]);
    assert(u_core.u_regfile.regs[5] === 32'd40)
      else $fatal(1, "load result mismatch for x5: %0d", u_core.u_regfile.regs[5]);
    assert(u_core.u_regfile.regs[6] === 32'd70)
      else $fatal(1, "load-use interlock failed for x6: %0d", u_core.u_regfile.regs[6]);
    assert(u_core.u_regfile.regs[8] === 32'd0)
      else $fatal(1, "taken branch failed to flush x8: %0d", u_core.u_regfile.regs[8]);
    assert(u_core.u_regfile.regs[9] === 32'd1)
      else $fatal(1, "branch target failed for x9: %0d", u_core.u_regfile.regs[9]);
    assert({u_mem.mem3[16], u_mem.mem2[16], u_mem.mem1[16], u_mem.mem0[16]} === 32'd40)
      else $fatal(1, "forwarded store data mismatch");

    $display("MILESTONE 4: HAZARDS AND FORWARDING VERIFIED SUCCESSFULLY!");
    $finish;
  end
endmodule
