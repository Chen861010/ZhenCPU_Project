///////////////////////////////////////////////////////////////////////////
//  control_test.sv — Universal Controller Testbench
//  (Fully compatible with Cadence Xcelium + QuestaSim)
// 
//  Features:
//    • Automated stimulus and response checking using pattern files
//    • Opcode and FSM state coverage
//    • Cross coverage for state × opcode combinations
//    • Continuous monitoring with time formatting
//    • Fully self-checking testbench with pass/fail termination
///////////////////////////////////////////////////////////////////////////

module control_test;
timeunit 1ns;
timeprecision 100ps;

import typedefs::*;


// ============================================================
// DUT Signals
// ============================================================
logic        rst_ = 1'b1;
logic        zero;

opcode_t     opcode;
state_t      lstate;

logic load_ac, mem_rd, mem_wr, inc_pc, load_pc, load_ir, halt;

// Pattern memory for guided stimulus & response checking
integer      response_num;
integer      stimulus_num;
logic [6:0]  response_mem[1:550];
logic [3:0]  stimulus_mem[1:64];
logic [3:0]  stimulus_reg;

// Combinational response signal from DUT
logic [6:0]  response_net;


// ============================================================
// Clock Generation
// ============================================================
`define PERIOD 10
logic clk = 1'b1;
always #(`PERIOD/2) clk = ~clk;


// ============================================================
// DUT Instantiation
// Added: .state(lstate) to expose FSM state for coverage/monitoring
// ============================================================
control ctrl(
  .load_ac (load_ac),
  .mem_rd  (mem_rd),
  .mem_wr  (mem_wr),
  .inc_pc  (inc_pc),
  .load_pc (load_pc),
  .load_ir (load_ir),
  .halt    (halt),
  .state   (lstate),   // Required for coverage and debugging
  .opcode  (opcode),
  .zero    (zero),
  .clk     (clk),
  .rst_    (rst_)
);

// Response bit mapping (matches response.pat encoding)
assign response_net = {mem_rd, load_ir, halt, inc_pc, load_ac, load_pc, mem_wr};

// Drive zero and opcode from stimulus patterns
assign zero   = stimulus_reg[3];
assign opcode = opcode_t'(stimulus_reg[2:0]);


// ==========================================================================
//                               COVERAGE GROUPS
// ==========================================================================

// ------------------------------------------------------------
// Opcode coverage
// ------------------------------------------------------------
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

// ------------------------------------------------------------
// Cross coverage: FSM state × opcode
// Useful for measuring controller decode completeness
// ------------------------------------------------------------
covergroup cg_state_opcode @(posedge clk);
  cp_state  : coverpoint lstate;
  cp_opcode : coverpoint opcode;
  cx_state_opcode : cross cp_state, cp_opcode;
endgroup

cg_opcode       opcode_cov = new();
cg_state_opcode state_cov  = new();


// ==========================================================================
// Monitor and Timeout
// ==========================================================================

initial begin
  $timeformat(-9, 1, "ns", 9);

  $monitor("%t rst_=%b st=%s zero=%b op=%s rd=%b l_ir=%b hlt=%b inc=%b l_ac=%b l_pc=%b wr=%b",
      $time, rst_, lstate.name(), zero, opcode.name(),
      mem_rd, load_ir, halt, inc_pc, load_ac, load_pc, mem_wr);

  #12000ns;
  $display("CONTROLLER TEST TIMEOUT");
  $finish;
end


// ==========================================================================
// Stimulus Application + Self-checking Logic
// Reads stimulus.pat and response.pat to validate DUT
// ==========================================================================

initial begin
  // Load pattern files
  $readmemb("stimulus.pat", stimulus_mem);
  $readmemb("response.pat", response_mem);

  stimulus_reg = 0;
  stimulus_num = 0;
  response_num = 0;

  // Reset sequence
  @(negedge clk) rst_ = 0;
  @(negedge clk) rst_ = 1;

  // Main test loop
  do begin : ApplyStim
    @(negedge clk);

    response_num++;

    //------------------------------------------------------------
    // Compare DUT output with expected encoded response
    //------------------------------------------------------------
    if (response_net !== response_mem[response_num]) begin
      $display("CONTROLLER TEST FAILED");
      $display("resp_net:  %b", response_net);
      $display("expected:  %b", response_mem[response_num]);
      $display("state=%s opcode=%s zero=%b",
               lstate.name(), opcode.name(), zero);
      $stop;
    end

    //------------------------------------------------------------
    // Apply next stimulus every 8 cycles (response_num LSB = 7)
    //------------------------------------------------------------
    if (response_num[2:0] == 3'b111) begin
      stimulus_num++;
      stimulus_reg = stimulus_mem[stimulus_num];
    end

  end while (stimulus_num <= 64);

  $display("CONTROLLER TEST PASSED");
  $stop;
end

endmodule
