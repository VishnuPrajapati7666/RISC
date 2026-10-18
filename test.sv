// File: test.v
`timescale 1ns / 1ps
import rv32i_pkg::*;

module tb_common_sanity;

  logic clk;
  logic rst_n;
  int errors = 0;

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Test signals
  logic [31:0] alu_a, alu_b, alu_out;
  alu_op_e alu_op;
  logic alu_zero;

  alu u_alu (
    .i_op_a(alu_a),
    .i_op_b(alu_b),
    .i_alu_op(alu_op),
    .o_result(alu_out),
    .o_zero(alu_zero)
  );

  logic [4:0] rs1, rs2, rd;
  logic rd_we;
  logic [31:0] rd_data, rs1_data, rs2_data;

  regfile u_regfile (
    .i_clk(clk),
    .i_rst_n(rst_n),
    .i_rs1_addr(rs1),
    .o_rs1_data(rs1_data),
    .i_rs2_addr(rs2),
    .o_rs2_data(rs2_data),
    .i_rd_we(rd_we),
    .i_rd_addr(rd),
    .i_rd_data(rd_data)
  );

  initial begin
    rst_n = 0;
    rd_we = 0;
    rs1 = 0; rs2 = 0; rd = 0; rd_data = 0;
    alu_a = 0; alu_b = 0; alu_op = ALU_ADD;

    #20;
    rst_n = 1;

    // Test 1: ALU ADD and SUB
    alu_a = 32'd15; alu_b = 32'd25; alu_op = ALU_ADD; #1;
    if (alu_out !== 32'd40) begin
      $display("[FAIL] ALU ADD expected 40, got %0d", alu_out);
      errors++;
    end

    alu_a = 32'd40; alu_b = 32'd40; alu_op = ALU_SUB; #1;
    if (alu_out !== 32'd0 || alu_zero !== 1'b1) begin
      $display("[FAIL] ALU SUB expected 0 and zero=1");
      errors++;
    end

    // Test 2: Regfile x0 invariant
    @(posedge clk);
    rd_we = 1; rd = 5'd0; rd_data = 32'hDEADBEEF;
    @(posedge clk);
    rd_we = 0; rs1 = 5'd0; #1;
    if (rs1_data !== 32'd0) begin
      $display("[FAIL] x0 write occurred, expected 0, got 0x%08h", rs1_data);
      errors++;
    end

    // Test 3: Regfile write and read back
    @(posedge clk);
    rd_we = 1; rd = 5'd5; rd_data = 32'hCAFE1234;
    @(posedge clk);
    rd_we = 0; rs1 = 5'd5; #1;
    if (rs1_data !== 32'hCAFE1234) begin
      $display("[FAIL] Regfile x5 expected 0xCAFE1234, got 0x%08h", rs1_data);
      errors++;
    end

    #10;
    if (errors == 0) begin
      $display("\n==========================================");
      $display("  ALL COMMON UNIT TESTS PASSED (100%%)   ");
      $display("==========================================\n");
    end else begin
      $display("\n[ERROR] Encountered %0d failures.", errors);
    end
    $finish;
  end

endmodule
