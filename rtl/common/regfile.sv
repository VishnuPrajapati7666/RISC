// File: rtl/common/regfile.sv
`ifndef REGFILE_SV
`define REGFILE_SV

`timescale 1ns / 1ps
import rv32i_pkg::*;

module regfile (
  input  logic                      i_clk,
  input  logic                      i_rst_n,

  // Read Port 1
  input  logic [REG_ADDR_WIDTH-1:0] i_rs1_addr,
  output logic [XLEN-1:0]           o_rs1_data,

  // Read Port 2
  input  logic [REG_ADDR_WIDTH-1:0] i_rs2_addr,
  output logic [XLEN-1:0]           o_rs2_data,

  // Write Port
  input  logic                      i_rd_we,
  input  logic [REG_ADDR_WIDTH-1:0] i_rd_addr,
  input  logic [XLEN-1:0]           i_rd_data
);

  logic [XLEN-1:0] regs [31:1];

  // Synchronous Write
  always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      for (int i = 1; i < 32; i++) begin
        regs[i] <= 32'd0;
      end
    end else if (i_rd_we && (i_rd_addr != 5'd0)) begin
      regs[i_rd_addr] <= i_rd_data;
    end
  end

  // Asynchronous Read with internal forwarding (same-cycle bypass)
  always_comb begin
    // Port 1
    if (i_rs1_addr == 5'd0) begin
      o_rs1_data = 32'd0;
    end else if (i_rd_we && (i_rd_addr == i_rs1_addr)) begin
      o_rs1_data = i_rd_data;
    end else begin
      o_rs1_data = regs[i_rs1_addr];
    end

    // Port 2
    if (i_rs2_addr == 5'd0) begin
      o_rs2_data = 32'd0;
    end else if (i_rd_we && (i_rd_addr == i_rs2_addr)) begin
      o_rs2_data = i_rd_data;
    end else begin
      o_rs2_data = regs[i_rs2_addr];
    end
  end

endmodule : regfile

`endif // REGFILE_SV