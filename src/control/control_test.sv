///////////////////////////////////////////////////////////////////////////
// Control Testbench Module (Universal Coverage Version — Questa + Cadence)
///////////////////////////////////////////////////////////////////////////

module control_test;
timeunit 1ns;
timeprecision 100ps;

import typedefs::*;

// ------------------------------------------------------------
// DUT Signals
// ------------------------------------------------------------
logic        rst_ = 1'b1;
logic        zero;

opcode_t opcode;
state_t  lstate;

logic load_ac, mem_rd, mem_wr, inc_pc, load_pc, load_ir, halt;

integer      response_num;
integer      stimulus_num;
logic [6:0]  response_mem[1:550];
logic [3:0]  stimulus_mem[1:64];
logic [3:0]  stimulus_reg;
logic [6:0]  response_net;

// ------------------------------------------------------------
// Clock Gen
// ------------------------------------------------------------
`define PERIOD 10
logic clk = 1'b1;
always #(`PERIOD/2) clk = ~clk;

// ------------------------------------------------------------
// DUT Instance — FIXED (added .state(lstate))
// ------------------------------------------------------------
control ctrl(
  .load_ac(load_ac),
  .mem_rd(mem_rd),
  .mem_wr(mem_wr),
  .inc_pc(inc_pc),
  .load_pc(load_pc),
  .load_ir(load_ir),
  .halt(halt),
  .state(lstate),     // <── FIXED: previously missing!
  .opcode(opcode),
  .zero(zero),
  .clk(clk),
  .rst_(rst_)
);

assign response_net = {mem_rd,load_ir,halt,inc_pc,load_ac,load_pc,mem_wr};
assign zero = stimulus_reg[3];
assign opcode = opcode_t'(stimulus_reg[2:0]);

// ==========================================================================
//                         COVERAGE GROUPS
// ==========================================================================
covergroup cg_opcode @(posedge clk);
  cp_opcode : coverpoint opcode {
    bins HLT = {HLT};
    bins LDA = {LDA};
    bins ADD = {ADD};
    bins AND = {AND};
    bins XOR = {XOR};
    bins SKZ = {SKZ};
    bins STO = {STO};
    bins JMP = {JMP};

    bins ALU_ops[] = {ADD, AND, XOR, LDA};
    bins nonALU[]  = {HLT, SKZ, STO, JMP};
  }
endgroup

covergroup cg_state_opcode @(posedge clk);
  cp_state  : coverpoint lstate;
  cp_opcode : coverpoint opcode;
  cx_state_opcode : cross cp_state, cp_opcode;
endgroup

cg_opcode       opcode_cov  = new();
cg_state_opcode state_cov   = new();


// ------------------------------------------------------------
// Monitor Output
// ------------------------------------------------------------
initial begin
  $timeformat(-9, 1, "ns", 9);
  $monitor("%t rst_=%b st=%s zero=%b op=%s rd=%b l_ir=%b hlt=%b inc=%b l_ac=%b l_pc=%b wr=%b",
      $time, rst_, lstate.name(), zero, opcode.name(),
      mem_rd, load_ir, halt, inc_pc, load_ac, load_pc, mem_wr);

  #12000ns;
  $display("CONTROLLER TEST TIMEOUT");
  $finish;
end

// ------------------------------------------------------------
// Stimulus + Checking
// ------------------------------------------------------------
initial begin
  $readmemb("stimulus.pat", stimulus_mem);
  $readmemb("response.pat", response_mem);

  stimulus_reg = 0;
  stimulus_num = 0;
  response_num = 0;

  @(negedge clk) rst_ = 0;
  @(negedge clk) rst_ = 1;

  do begin : ApplyStim
    @(negedge clk);

    response_num++;

    if (response_net !== response_mem[response_num]) begin
      $display("CONTROLLER TEST FAILED");
      $display("resp_net:  %b", response_net);
      $display("expected:  %b", response_mem[response_num]);
      $display("state=%s opcode=%s zero=%b", lstate.name(), opcode.name(), zero);
      $stop;
    end

    if (response_num[2:0] == 3'b111) begin
      stimulus_num++;
      stimulus_reg = stimulus_mem[stimulus_num];
    end

  end while (stimulus_num <= 64);

  $display("CONTROLLER TEST PASSED");
  $stop;
end

endmodule
