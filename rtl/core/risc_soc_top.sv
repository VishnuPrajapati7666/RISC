`ifndef RISC_SOC_TOP_SV
`define RISC_SOC_TOP_SV

module risc_soc_top #(
  parameter int MEMORY_WORDS = 1024
) (
  input logic i_clk,
  input logic i_rst_n
);
  logic [31:0] imem_addr, imem_data;
  logic dmem_req, dmem_we;
  logic [3:0] dmem_be;
  logic [31:0] dmem_addr, dmem_wdata, dmem_rdata;

  five_stage_core u_core (
    .i_clk(i_clk), .i_rst_n(i_rst_n),
    .o_imem_addr(imem_addr), .i_imem_data(imem_data),
    .o_dmem_req(dmem_req), .o_dmem_we(dmem_we), .o_dmem_be(dmem_be),
    .o_dmem_addr(dmem_addr), .o_dmem_wdata(dmem_wdata),
    .i_dmem_rdata(dmem_rdata)
  );

  reference_memory #(.WORDS(MEMORY_WORDS)) u_memory (
    .i_clk(i_clk), .i_imem_addr(imem_addr), .o_imem_data(imem_data),
    .i_dmem_req(dmem_req), .i_dmem_we(dmem_we), .i_dmem_be(dmem_be),
    .i_dmem_addr(dmem_addr), .i_dmem_wdata(dmem_wdata),
    .o_dmem_rdata(dmem_rdata)
  );

  soc_checker u_checker (
    .i_clk(i_clk), .i_rst_n(i_rst_n),
    .i_dmem_req(dmem_req), .i_dmem_we(dmem_we),
    .i_dmem_be(dmem_be), .i_dmem_addr(dmem_addr),
    .i_dmem_wdata(dmem_wdata)
  );
endmodule

`endif
