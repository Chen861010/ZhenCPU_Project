//============================================================
// Testbench for Control FSM
//============================================================
timeunit 1ns;
timeprecision 100ps;

import typedefs::*;

module tb_control;

  // DUT IO
  logic load_ac, mem_rd, mem_wr, inc_pc, load_pc, load_ir, halt, fetch;
  logic clk, rst_, zero;
  opcode_t opcode;

  // Instantiate DUT
  control dut(
    .load_ac(load_ac),
    .mem_rd(mem_rd),
    .mem_wr(mem_wr),
    .inc_pc(inc_pc),
    .load_pc(load_pc),
    .load_ir(load_ir),
    .halt(halt),
    .fetch(fetch),
    .opcode(opcode),
    .zero(zero),
    .clk(clk),
    .rst_(rst_)
  );

  //============================================================
  // Clock generation
  //============================================================
  initial clk = 0;
  always #5 clk = ~clk;   // 10ns period

  //============================================================
  // Task 用於打一個完整 FSM 週期（8 cycles）
  //============================================================
  task run_one_instruction(input opcode_t opc, input logic zero_flag);
    begin
      opcode = opc;
      zero   = zero_flag;
      $display("\n=== RUN OPCODE = %0s (zero=%0d) ===", opc.name(), zero_flag);

      // FSM 需要 8 個 clock 走完微指令
      repeat (8) @(posedge clk);
    end
  endtask

  //============================================================
  // Test sequence
  //============================================================
  initial begin
    rst_ = 0;
    opcode = ADD;
    zero   = 0;

    // 兩個 cycle reset
    repeat(2) @(posedge clk);
    rst_ = 1;

    //==========================
    // Run every instruction
    //==========================
    run_one_instruction(ADD, 0);
    run_one_instruction(AND, 0);
    run_one_instruction(XOR, 0);
    run_one_instruction(LDA, 0);

    // SKZ zero=0 → 不 skip
    run_one_instruction(SKZ, 0);

    // SKZ zero=1 → skip
    run_one_instruction(SKZ, 1);

    // STORE opcode
    run_one_instruction(STO, 0);

    // JMP opcode
    run_one_instruction(JMP, 0);

    // HLT opcode
    run_one_instruction(HLT, 0);

    $display("\n*** ALL TESTS COMPLETED ***");
    $stop;
  end

endmodule
