`ifndef SOC_CHECKER_SV
`define SOC_CHECKER_SV

module soc_checker (
  input logic i_clk,
  input logic i_rst_n,
  input logic i_dmem_req,
  input logic i_dmem_we,
  input logic [3:0] i_dmem_be,
  input logic [31:0] i_dmem_addr,
  input logic [31:0] i_dmem_wdata
);
  property no_unaligned_word_store;
    @(posedge i_clk) disable iff (!i_rst_n)
      i_dmem_req && i_dmem_we && (i_dmem_be == 4'b1111) |-> (i_dmem_addr[1:0] == 2'b00);
  endproperty
  assert property (no_unaligned_word_store);
endmodule

`endif
