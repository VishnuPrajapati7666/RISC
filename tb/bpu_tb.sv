`timescale 1ns / 1ps

module bpu_tb;
  logic clk;
  logic rst_n;
  logic [31:0] fetch_pc;
  logic [31:0] fetch_instr;
  logic predict_taken;
  logic [31:0] predict_target;
  logic update_valid;
  logic [31:0] update_pc;
  logic update_taken;

  bpu u_bpu (
    .i_clk(clk),
    .i_rst_n(rst_n),
    .i_fetch_pc(fetch_pc),
    .i_fetch_instr(fetch_instr),
    .o_predict_taken(predict_taken),
    .o_predict_target(predict_target),
    .i_update_valid(update_valid),
    .i_update_pc(update_pc),
    .i_update_taken(update_taken)
  );

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  initial begin
    rst_n = 1'b0;
    fetch_pc = 32'd0;
    fetch_instr = 32'h00000463; // beq x0, x0, +8
    update_valid = 1'b0;
    update_pc = 32'd0;
    update_taken = 1'b0;

    #12;
    rst_n = 1'b1;
    #1;
    assert(predict_taken === 1'b0)
      else $fatal(1, "BPU reset state should be weakly not taken");
    assert(predict_target === 32'd8)
      else $fatal(1, "BPU branch target mismatch: 0x%08h", predict_target);

    update_valid = 1'b1;
    update_taken = 1'b1;
    @(posedge clk);
    @(posedge clk);
    #1;
    assert(predict_taken === 1'b1)
      else $fatal(1, "BPU did not learn taken branch");

    update_taken = 1'b0;
    @(posedge clk);
    @(posedge clk);
    #1;
    assert(predict_taken === 1'b0)
      else $fatal(1, "BPU did not saturate back to not taken");

    fetch_instr = 32'h0080006F; // jal x0, +8
    update_valid = 1'b0;
    #1;
    assert(predict_taken === 1'b1)
      else $fatal(1, "JAL must be predicted taken");
    assert(predict_target === 32'd8)
      else $fatal(1, "JAL target mismatch: 0x%08h", predict_target);

    $display("MILESTONE 5: BRANCH PREDICTOR VERIFIED SUCCESSFULLY!");
    $finish;
  end
endmodule
