`timescale 1ns / 1ps

module arbiter_tb;
  logic clk, rst_n;
  logic i_req, i_we, d_req, d_we, mem_req, mem_we, mem_ready, mem_rvalid;
  logic i_ready, i_rvalid, d_ready, d_rvalid;
  logic [3:0] i_be, d_be, mem_be;
  logic [31:0] i_addr, i_wdata, i_rdata, d_addr, d_wdata, d_rdata;
  logic [31:0] mem_addr, mem_wdata, mem_rdata;

  cache_arbiter dut (
    .i_clk(clk), .i_rst_n(rst_n),
    .i_i_req(i_req), .i_i_we(i_we), .i_i_be(i_be), .i_i_addr(i_addr),
    .i_i_wdata(i_wdata), .o_i_ready(i_ready), .o_i_rvalid(i_rvalid),
    .o_i_rdata(i_rdata), .i_d_req(d_req), .i_d_we(d_we), .i_d_be(d_be),
    .i_d_addr(d_addr), .i_d_wdata(d_wdata), .o_d_ready(d_ready),
    .o_d_rvalid(d_rvalid), .o_d_rdata(d_rdata), .o_mem_req(mem_req),
    .o_mem_we(mem_we), .o_mem_be(mem_be), .o_mem_addr(mem_addr),
    .o_mem_wdata(mem_wdata), .i_mem_ready(mem_ready),
    .i_mem_rvalid(mem_rvalid), .i_mem_rdata(mem_rdata)
  );

  initial begin clk = 0; forever #5 clk = ~clk; end
  initial begin
    rst_n = 0; i_req = 0; d_req = 0; i_we = 0; d_we = 0;
    i_be = 4'hf; d_be = 4'hf; i_addr = 0; d_addr = 0;
    i_wdata = 0; d_wdata = 0; mem_ready = 0; mem_rvalid = 0;
    mem_rdata = 0;
    #20; rst_n = 1;
    @(negedge clk);
    i_req = 1; d_req = 1; i_addr = 32'h10; d_addr = 32'h20;
    mem_ready = 1;
    @(posedge clk);
    #1;
    assert(d_ready && !i_ready && mem_req && mem_addr == 32'h20)
      else $fatal(1, "arbiter did not prioritize data request");
    @(negedge clk);
    d_req = 0; mem_ready = 0; mem_rvalid = 1; mem_rdata = 32'hDADA2020;
    @(posedge clk);
    #1;
    assert(d_rvalid && d_rdata == 32'hDADA2020 && !i_rvalid)
      else $fatal(1, "data response was not routed correctly");
    mem_rvalid = 0;
    @(negedge clk);
    i_req = 1; mem_ready = 1;
    @(posedge clk);
    #1;
    assert(i_ready && mem_addr == 32'h10)
      else $fatal(1, "instruction request was not accepted");
    @(negedge clk);
    mem_ready = 0; mem_rvalid = 1; mem_rdata = 32'h12345678;
    @(posedge clk);
    #1;
    assert(i_rvalid && i_rdata == 32'h12345678 && !d_rvalid)
      else $fatal(1, "instruction response was not routed correctly");
    $display("MILESTONE 6: CACHE ARBITER VERIFIED SUCCESSFULLY!");
    $finish;
  end
endmodule
