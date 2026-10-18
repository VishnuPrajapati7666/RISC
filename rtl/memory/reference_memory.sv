// File: rtl/memory/reference_memory.sv
`ifndef REFERENCE_MEMORY_SV
`define REFERENCE_MEMORY_SV

`timescale 1ns / 1ps

module reference_memory #(
  parameter int WORDS = 1024
)(
  input  logic        i_clk,

  // Instruction Read Port (Combinational Read)
  input  logic [31:0] i_imem_addr,
  output logic [31:0] o_imem_data,

  // Data Read/Write Port
  input  logic        i_dmem_req,
  input  logic        i_dmem_we,
  input  logic [3:0]  i_dmem_be,
  input  logic [31:0] i_dmem_addr,
  input  logic [31:0] i_dmem_wdata,
  output logic [31:0] o_dmem_rdata
);

  // 4 byte-wide lanes for sub-word accesses
  logic [7:0] mem0 [0:WORDS-1];
  logic [7:0] mem1 [0:WORDS-1];
  logic [7:0] mem2 [0:WORDS-1];
  logic [7:0] mem3 [0:WORDS-1];

  wire [29:0] word_idx_imem = i_imem_addr[31:2];
  wire [29:0] word_idx_dmem = i_dmem_addr[31:2];

  // Instruction Fetch (Read)
  assign o_imem_data = (word_idx_imem < WORDS) ?
                       {mem3[word_idx_imem], mem2[word_idx_imem],
                        mem1[word_idx_imem], mem0[word_idx_imem]} : 32'h00000013; // default NOP

  // Data Memory Write (Synchronous)
  always_ff @(posedge i_clk) begin
    if (i_dmem_req && i_dmem_we && (word_idx_dmem < WORDS)) begin
      if (i_dmem_be[0]) mem0[word_idx_dmem] <= i_dmem_wdata[7:0];
      if (i_dmem_be[1]) mem1[word_idx_dmem] <= i_dmem_wdata[15:8];
      if (i_dmem_be[2]) mem2[word_idx_dmem] <= i_dmem_wdata[23:16];
      if (i_dmem_be[3]) mem3[word_idx_dmem] <= i_dmem_wdata[31:24];
    end
  end

  // Data Memory Read (Combinational)
  assign o_dmem_rdata = (i_dmem_req && !i_dmem_we && (word_idx_dmem < WORDS)) ?
                        {mem3[word_idx_dmem], mem2[word_idx_dmem],
                         mem1[word_idx_dmem], mem0[word_idx_dmem]} : 32'd0;

endmodule : reference_memory

`endif // REFERENCE_MEMORY_SV