`ifndef ICACHE_SV
`define ICACHE_SV

`timescale 1ns / 1ps

module icache #(
  parameter int SETS = 4,
  parameter int WAYS = 1
) (
  input  logic        i_clk,
  input  logic        i_rst_n,
  input  logic        i_cpu_valid,
  input  logic [31:0] i_cpu_addr,
  output logic        o_cpu_ready,
  output logic [31:0] o_cpu_rdata,
  output logic        o_mem_req,
  output logic        o_mem_we,
  output logic [3:0]  o_mem_be,
  output logic [31:0] o_mem_addr,
  output logic [31:0] o_mem_wdata,
  input  logic        i_mem_ready,
  input  logic        i_mem_rvalid,
  input  logic [31:0] i_mem_rdata
);
  localparam int INDEX_BITS = $clog2(SETS);
  localparam int TAG_BITS = 30 - INDEX_BITS;
  typedef enum logic {IDLE, REFILL} state_e;
  state_e state;
  logic [31:0] data [0:WAYS-1][0:SETS-1];
  logic [TAG_BITS-1:0] tags [0:WAYS-1][0:SETS-1];
  logic valid [0:WAYS-1][0:SETS-1];
  logic lru [0:SETS-1];
  logic [31:0] miss_addr;
  logic [INDEX_BITS-1:0] miss_index;
  logic [TAG_BITS-1:0] miss_tag;
  logic miss_way;
  logic hit;
  logic hit_way;
  logic [INDEX_BITS-1:0] cpu_index;
  logic [TAG_BITS-1:0] cpu_tag;

  assign cpu_index = i_cpu_addr[INDEX_BITS+1:2];
  assign cpu_tag = i_cpu_addr[31:INDEX_BITS+2];
  always_comb begin
    hit = 1'b0;
    hit_way = 1'b0;
    for (int w = 0; w < WAYS; w++) begin
      if (valid[w][cpu_index] && (tags[w][cpu_index] == cpu_tag)) begin
        hit = 1'b1;
        hit_way = w[0];
      end
    end
    o_cpu_ready = i_cpu_valid && (state == IDLE) && hit;
    o_cpu_rdata = hit ? data[hit_way][cpu_index] : 32'd0;
    o_mem_req = (state == REFILL);
    o_mem_we = 1'b0;
    o_mem_be = 4'b1111;
    o_mem_addr = miss_addr;
    o_mem_wdata = 32'd0;
  end

  always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      state <= IDLE;
      miss_addr <= 32'd0;
      miss_index <= '0;
      miss_tag <= '0;
      miss_way <= 1'b0;
      for (int s = 0; s < SETS; s++) begin
        lru[s] <= 1'b0;
        for (int w = 0; w < WAYS; w++) valid[w][s] <= 1'b0;
      end
    end else begin
      if (state == IDLE) begin
        if (i_cpu_valid && !hit) begin
          miss_addr <= {i_cpu_addr[31:2], 2'b00};
          miss_index <= cpu_index;
          miss_tag <= cpu_tag;
          miss_way <= (WAYS == 1) ? 1'b0 :
                      (!valid[0][cpu_index] ? 1'b0 :
                       (!valid[1][cpu_index] ? 1'b1 : lru[cpu_index]));
          state <= REFILL;
        end else if (i_cpu_valid && hit) begin
          lru[cpu_index] <= ~hit_way;
        end
      end else if (i_mem_rvalid) begin
        data[miss_way][miss_index] <= i_mem_rdata;
        tags[miss_way][miss_index] <= miss_tag;
        valid[miss_way][miss_index] <= 1'b1;
        lru[miss_index] <= ~miss_way;
        state <= IDLE;
      end
    end
  end
endmodule

`endif
