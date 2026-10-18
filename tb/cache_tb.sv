`timescale 1ns / 1ps

module cache_tb;
  logic clk, rst_n;
  logic i_valid, i_ready, i_rvalid;
  logic [31:0] i_addr, i_rdata;
  logic i_mem_req, i_mem_we, i_mem_ready;
  logic [3:0] i_mem_be;
  logic [31:0] i_mem_addr, i_mem_wdata, i_mem_rdata;
  logic d_valid, d_we, d_ready, d_rvalid;
  logic [3:0] d_be;
  logic [31:0] d_addr, d_wdata, d_rdata;
  logic d_mem_req, d_mem_we, d_mem_ready;
  logic [3:0] d_mem_be;
  logic [31:0] d_mem_addr, d_mem_wdata, d_mem_rdata;
  logic [31:0] backing [0:255];
  logic pending_i, pending_d;
  logic [31:0] pending_addr;

  icache #(.SETS(2), .WAYS(2)) u_icache (
    .i_clk(clk), .i_rst_n(rst_n), .i_cpu_valid(i_valid), .i_cpu_addr(i_addr),
    .o_cpu_ready(i_ready), .o_cpu_rdata(i_rdata),
    .o_mem_req(i_mem_req), .o_mem_we(i_mem_we), .o_mem_be(i_mem_be),
    .o_mem_addr(i_mem_addr), .o_mem_wdata(i_mem_wdata),
    .i_mem_ready(i_mem_ready), .i_mem_rvalid(i_rvalid), .i_mem_rdata(i_mem_rdata)
  );
  dcache #(.SETS(2), .WAYS(2)) u_dcache (
    .i_clk(clk), .i_rst_n(rst_n), .i_cpu_valid(d_valid), .i_cpu_we(d_we),
    .i_cpu_be(d_be), .i_cpu_addr(d_addr), .i_cpu_wdata(d_wdata),
    .o_cpu_ready(d_ready), .o_cpu_rdata(d_rdata),
    .o_mem_req(d_mem_req), .o_mem_we(d_mem_we), .o_mem_be(d_mem_be),
    .o_mem_addr(d_mem_addr), .o_mem_wdata(d_mem_wdata),
    .i_mem_ready(d_mem_ready), .i_mem_rvalid(d_rvalid), .i_mem_rdata(d_mem_rdata)
  );

  initial begin clk = 0; forever #5 clk = ~clk; end
  assign i_mem_ready = i_mem_req && !pending_i;
  assign d_mem_ready = d_mem_req && !pending_d;
  assign i_rvalid = pending_i;
  assign d_rvalid = pending_d;
  assign i_mem_rdata = backing[pending_addr[9:2]];
  assign d_mem_rdata = backing[pending_addr[9:2]];

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pending_i <= 0;
      pending_d <= 0;
      pending_addr <= 0;
    end else begin
      pending_i <= i_mem_req && i_mem_ready;
      pending_d <= d_mem_req && d_mem_ready;
      if (i_mem_req && i_mem_ready) pending_addr <= i_mem_addr;
      if (d_mem_req && d_mem_ready) pending_addr <= d_mem_addr;
      if (d_mem_req && d_mem_ready && d_mem_we)
        backing[d_mem_addr[9:2]] <= d_mem_wdata;
    end
  end

  task automatic read_i(input logic [31:0] addr, input logic [31:0] expected);
    begin
      i_addr = addr; i_valid = 1;
      do @(posedge clk); while (!i_ready);
      #1;
      if (i_rdata !== expected) $fatal(1, "I-cache read mismatch");
      i_valid = 0;
    end
  endtask

  task automatic access_d(input logic we, input logic [31:0] addr,
                          input logic [31:0] wdata, input logic [31:0] expected);
    begin
      d_we = we; d_addr = addr; d_wdata = wdata; d_be = 4'b1111; d_valid = 1;
      do @(posedge clk); while (!d_ready);
      #1;
      if (!we && d_rdata !== expected) $fatal(1, "D-cache read mismatch");
      d_valid = 0;
    end
  endtask

  initial begin
    rst_n = 0; i_valid = 0; i_addr = 0; d_valid = 0; d_we = 0;
    d_be = 4'b1111; d_addr = 0; d_wdata = 0;
    for (int n = 0; n < 256; n++) backing[n] = 32'h10000000 + n;
    #20; rst_n = 1;
    read_i(32'h00000000, 32'h10000000);
    read_i(32'h00000000, 32'h10000000);
    read_i(32'h00000008, 32'h10000002);
    access_d(0, 32'h00000040, 0, 32'h10000010);
    access_d(1, 32'h00000040, 32'hDEADBEEF, 0);
    access_d(0, 32'h00000040, 0, 32'hDEADBEEF);
    $display("MILESTONE 6: CACHE HIERARCHY VERIFIED SUCCESSFULLY!");
    $finish;
  end
endmodule
