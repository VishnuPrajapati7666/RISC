`timescale 1ns / 1ps

module soc_tb;
  logic clk, rst_n;
  risc_soc_top #(.MEMORY_WORDS(256)) dut (.i_clk(clk), .i_rst_n(rst_n));

  initial begin clk = 0; forever #5 clk = ~clk; end

  task automatic write_instr(input int word_addr, input logic [31:0] instr);
    dut.u_memory.mem0[word_addr] = instr[7:0];
    dut.u_memory.mem1[word_addr] = instr[15:8];
    dut.u_memory.mem2[word_addr] = instr[23:16];
    dut.u_memory.mem3[word_addr] = instr[31:24];
  endtask

  initial begin
    rst_n = 0;
    for (int i = 0; i < 256; i++) begin
      dut.u_memory.mem0[i] = 0;
      dut.u_memory.mem1[i] = 0;
      dut.u_memory.mem2[i] = 0;
      dut.u_memory.mem3[i] = 0;
    end
    write_instr(0, 32'h02A00093);
    write_instr(1, 32'h00000013);
    write_instr(2, 32'h00000013);
    write_instr(3, 32'h04102023);
    write_instr(4, 32'h00000013);
    write_instr(5, 32'h00000013);
    write_instr(6, 32'h04002203);
    write_instr(7, 32'h00000013);
    write_instr(8, 32'h00000013);
    #20; rst_n = 1;
    repeat (35) @(posedge clk);
    #1;
    assert(dut.u_core.u_regfile.regs[1] === 32'd42)
      else $fatal(1, "SoC x1 mismatch: %0d", dut.u_core.u_regfile.regs[1]);
    assert(dut.u_core.u_regfile.regs[4] === 32'd42)
      else $fatal(1, "SoC load result mismatch: %0d", dut.u_core.u_regfile.regs[4]);
    assert({dut.u_memory.mem3[16], dut.u_memory.mem2[16],
            dut.u_memory.mem1[16], dut.u_memory.mem0[16]} === 32'd42)
      else $fatal(1, "SoC memory result mismatch");
    $display("MILESTONE 7: FULL SOC VERIFIED SUCCESSFULLY!");
    $finish;
  end
endmodule
