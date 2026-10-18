`ifndef HAZARD_UNIT_SV
`define HAZARD_UNIT_SV

module hazard_unit (
  input  logic       i_if_id_valid,
  input  logic [4:0] i_if_id_rs1,
  input  logic [4:0] i_if_id_rs2,
  input  logic       i_uses_rs1,
  input  logic       i_uses_rs2,
  input  logic       i_id_ex_valid,
  input  logic       i_id_ex_mem_read,
  input  logic [4:0] i_id_ex_rd,
  output logic       o_stall
);
  always_comb begin
    o_stall = i_if_id_valid && i_id_ex_valid && i_id_ex_mem_read &&
              (i_id_ex_rd != 5'd0) &&
              ((i_uses_rs1 && (i_if_id_rs1 == i_id_ex_rd)) ||
               (i_uses_rs2 && (i_if_id_rs2 == i_id_ex_rd)));
  end
endmodule

`endif
