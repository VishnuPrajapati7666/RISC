`ifndef DCACHE_SV
`define DCACHE_SV

`timescale 1ns / 1ps

module dcache #(
  parameter int SETS = 4,
  parameter int WAYS = 1
) (
  input  logic        i_clk,
  input  logic        i_rst_n,
  input  logic        i_cpu_valid,
  input  logic        i_cpu_we,
  input  logic [3:0]  i_cpu_be,
  input  logic [31:0] i_cpu_addr,
  input  logic [31:0] i_cpu_wdata,
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
  typedef enum logic [1:0] {IDLE, WRITEBACK, REFILL} state_e;
  state_e state;
  logic [31:0] data [0:WAYS-1][0:SETS-1];
  logic [31:0] tags [0:WAYS-1][0:SETS-1];
  logic valid [0:WAYS-1][0:SETS-1];
  logic dirty [0:WAYS-1][0:SETS-1];
  logic lru [0:SETS-1];
  logic [31:0] miss_addr, miss_wdata;
  logic [3:0] miss_be;
  logic miss_we, miss_way;
  logic [INDEX_BITS-1:0] miss_index;
  logic [TAG_BITS-1:0] miss_tag;
  logic [INDEX_BITS-1:0] cpu_index;
  logic [TAG_BITS-1:0] cpu_tag;
  logic hit, hit_way;
  logic [31:0] victim_addr;

  assign cpu_index = i_cpu_addr[INDEX_BITS+1:2];
  assign cpu_tag = i_cpu_addr[31:INDEX_BITS+2];
  assign victim_addr = {tags[miss_way][miss_index], miss_index, 2'b00};

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
    o_mem_req = (state != IDLE);
    o_mem_we = (state == WRITEBACK);
    o_mem_be = (state == WRITEBACK) ? 4'b1111 :
               ((state == REFILL) ? 4'b1111 : 4'b0000);
    o_mem_addr = (state == WRITEBACK) ? victim_addr : {miss_addr[31:2], 2'b00};
    o_mem_wdata = (state == WRITEBACK) ? data[miss_way][miss_index] : 32'd0;
  end

  always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      state <= IDLE;
      for (int s = 0; s < SETS; s++) begin
        lru[s] <= 1'b0;
        for (int w = 0; w < WAYS; w++) begin
          valid[w][s] <= 1'b0;
          dirty[w][s] <= 1'b0;
        end
      end
    end else begin
      if (state == IDLE) begin
        if (i_cpu_valid && !hit) begin
          miss_addr <= i_cpu_addr;
          miss_wdata <= i_cpu_wdata;
          miss_be <= i_cpu_be;
          miss_we <= i_cpu_we;
          miss_index <= cpu_index;
          miss_tag <= cpu_tag;
          miss_way <= (WAYS == 1) ? 1'b0 :
                      (!valid[0][cpu_index] ? 1'b0 :
                       (!valid[1][cpu_index] ? 1'b1 : lru[cpu_index]));
          if ((WAYS > 1 || valid[0][cpu_index]) &&
              valid[((WAYS == 1) ? 0 : ((!valid[0][cpu_index]) ? 1 : lru[cpu_index]))][cpu_index] &&
              dirty[((WAYS == 1) ? 0 : ((!valid[0][cpu_index]) ? 1 : lru[cpu_index]))][cpu_index])
            state <= WRITEBACK;
          else
            state <= REFILL;
        end else if (i_cpu_valid && hit) begin
          if (i_cpu_we) begin
            if (i_cpu_be[0]) data[hit_way][cpu_index][7:0] <= i_cpu_wdata[7:0];
            if (i_cpu_be[1]) data[hit_way][cpu_index][15:8] <= i_cpu_wdata[15:8];
            if (i_cpu_be[2]) data[hit_way][cpu_index][23:16] <= i_cpu_wdata[23:16];
            if (i_cpu_be[3]) data[hit_way][cpu_index][31:24] <= i_cpu_wdata[31:24];
            dirty[hit_way][cpu_index] <= 1'b1;
          end
          lru[cpu_index] <= ~hit_way;
        end
      end else if (state == WRITEBACK && i_mem_ready) begin
        dirty[miss_way][miss_index] <= 1'b0;
        state <= REFILL;
      end else if (state == REFILL && i_mem_rvalid) begin
        data[miss_way][miss_index] <= i_mem_rdata;
        tags[miss_way][miss_index] <= miss_tag;
        valid[miss_way][miss_index] <= 1'b1;
        if (miss_we) begin
          if (miss_be[0]) data[miss_way][miss_index][7:0] <= miss_wdata[7:0];
          if (miss_be[1]) data[miss_way][miss_index][15:8] <= miss_wdata[15:8];
          if (miss_be[2]) data[miss_way][miss_index][23:16] <= miss_wdata[23:16];
          if (miss_be[3]) data[miss_way][miss_index][31:24] <= miss_wdata[31:24];
        end
        dirty[miss_way][miss_index] <= miss_we;
        lru[miss_index] <= ~miss_way;
        state <= IDLE;
      end
    end
  end
endmodule

`endif
