`ifndef FORWARDING_UNIT_SV
`define FORWARDING_UNIT_SV

import rv32i_pkg::*;

module forwarding_unit (
  input  logic [4:0] i_rs1,
  input  logic [4:0] i_rs2,
  input  logic [4:0] i_ex_mem_rd,
  input  logic       i_ex_mem_reg_write,
  input  logic       i_ex_mem_mem_read,
  input  logic [4:0] i_mem_wb_rd,
  input  logic       i_mem_wb_reg_write,
  output fwd_sel_e   o_forward_a,
  output fwd_sel_e   o_forward_b
);
  always_comb begin
    o_forward_a = FWD_NONE;
    o_forward_b = FWD_NONE;

    if (i_ex_mem_reg_write && !i_ex_mem_mem_read &&
        (i_ex_mem_rd != 5'd0) && (i_ex_mem_rd == i_rs1))
      o_forward_a = FWD_MEM;
    else if (i_mem_wb_reg_write && (i_mem_wb_rd != 5'd0) &&
             (i_mem_wb_rd == i_rs1))
      o_forward_a = FWD_WB;

    if (i_ex_mem_reg_write && !i_ex_mem_mem_read &&
        (i_ex_mem_rd != 5'd0) && (i_ex_mem_rd == i_rs2))
      o_forward_b = FWD_MEM;
    else if (i_mem_wb_reg_write && (i_mem_wb_rd != 5'd0) &&
             (i_mem_wb_rd == i_rs2))
      o_forward_b = FWD_WB;
  end
endmodule

`endif
