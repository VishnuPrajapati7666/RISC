`ifndef CACHE_ARBITER_SV
`define CACHE_ARBITER_SV

module cache_arbiter (
  input  logic        i_clk,
  input  logic        i_rst_n,
  input  logic        i_i_req,
  input  logic        i_i_we,
  input  logic [3:0]  i_i_be,
  input  logic [31:0] i_i_addr,
  input  logic [31:0] i_i_wdata,
  output logic        o_i_ready,
  output logic        o_i_rvalid,
  output logic [31:0] o_i_rdata,
  input  logic        i_d_req,
  input  logic        i_d_we,
  input  logic [3:0]  i_d_be,
  input  logic [31:0] i_d_addr,
  input  logic [31:0] i_d_wdata,
  output logic        o_d_ready,
  output logic        o_d_rvalid,
  output logic [31:0] o_d_rdata,
  output logic        o_mem_req,
  output logic        o_mem_we,
  output logic [3:0]  o_mem_be,
  output logic [31:0] o_mem_addr,
  output logic [31:0] o_mem_wdata,
  input  logic        i_mem_ready,
  input  logic        i_mem_rvalid,
  input  logic [31:0] i_mem_rdata
);
  logic owner_d;
  logic active;
  always_comb begin
    o_i_ready = i_mem_ready && !i_d_req && i_i_req && !active;
    o_d_ready = i_mem_ready && i_d_req && !active;
    o_mem_req = !active && (i_d_req || i_i_req);
    o_mem_we = i_d_req ? i_d_we : i_i_we;
    o_mem_be = i_d_req ? i_d_be : i_i_be;
    o_mem_addr = i_d_req ? i_d_addr : i_i_addr;
    o_mem_wdata = i_d_req ? i_d_wdata : i_i_wdata;
    o_i_rvalid = i_mem_rvalid && active && !owner_d;
    o_d_rvalid = i_mem_rvalid && active && owner_d;
    o_i_rdata = i_mem_rdata;
    o_d_rdata = i_mem_rdata;
  end
  always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      active <= 1'b0;
      owner_d <= 1'b0;
    end else begin
      if (!active && i_mem_ready && (i_d_req || i_i_req)) begin
        active <= 1'b1;
        owner_d <= i_d_req;
      end else if (active && i_mem_rvalid) begin
        active <= 1'b0;
      end
    end
  end
endmodule

`endif
