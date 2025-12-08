// ============================================================================
// cpu_testbench.sv — Directed Testbench for CPU (Tests 1–3)
// 
// Provides:
//   • Multi-phase clock-generation system (master → clk/cntrl_clk/alu_clk)
//   • Reset sequence controller
//   • Memory preload task for test program injection
//   • run_until_halt() for automatic termination
//   • Directed test programs: Test1, Test2, Test3
// 
// Supports waveform debugging and easy extension for random/stress testing.
// ============================================================================

timeunit 1ns;
timeprecision 100ps;

import typedefs::*;

module testbench;

  // ==========================================================================
  // Clock, Reset, and DUT Interface Signals
  // ==========================================================================
  logic clk, cntrl_clk, alu_clk, fetch;
  logic rst_;
  logic halt;
  logic load_ir;

  `define PERIOD 10
  logic master_clk = 1'b1;
  logic [3:0] count;

  // Master clock
  always #(`PERIOD/2) master_clk = ~master_clk;

  // Clock divider network (matches project specification)
  always @(posedge master_clk or negedge rst_) begin
    if (!rst_)
      count <= 4'b0;
    else
      count <= count + 1;
  end

  assign cntrl_clk = ~count[0];         // Controller FSM clock
  assign clk       = count[1];          // Main CPU clock
  assign fetch     = ~count[3];         // PC/IR select for memory addressing
  assign alu_clk   = ~(count == 4'hC);  // ALU negedge-trigger window


  // ==========================================================================
  // DUT Instance
  // ==========================================================================
  cpu dut (
      .halt      (halt),
      .load_ir   (load_ir),
      .clk       (clk),
      .cntrl_clk (cntrl_clk),
      .alu_clk   (alu_clk),
      .fetch     (fetch),
      .rst_      (rst_)
  );


  // ==========================================================================
  // Memory Write Helper (direct write into internal memory array)
  // ==========================================================================
  task automatic mem_write(input int idx, input [7:0] val);
    dut.mem1.memory[idx] = val;
  endtask


  // ==========================================================================
  // Reset Sequence
  // ==========================================================================
  task automatic do_reset();
    rst_ = 0;
    repeat (5) @(posedge master_clk);
    rst_ = 1;
    repeat (5) @(posedge master_clk);
  endtask


  // ==========================================================================
  // Execute CPU Program Until HALT or Timeout
  // ==========================================================================
  task automatic run_until_halt(input int max_cycles,
                                output int final_pc);
    int cycles = 0;

    while (!halt && cycles < max_cycles) begin
      @(posedge clk);
      cycles++;
    end

    final_pc = dut.pc_addr;
  endtask


  // ==========================================================================
  // TEST 1 — Official CPUtest1 Program
  // ==========================================================================
  task automatic load_test1();
    int i;
    for (i = 0; i < 32; i++)
      mem_write(i, 8'h00);

    mem_write(8'h00, 8'b111_11110);
    mem_write(8'h01, 8'b000_00000);
    mem_write(8'h02, 8'b000_00000);
    mem_write(8'h03, 8'b101_11010);
    mem_write(8'h04, 8'b001_00000);
    mem_write(8'h05, 8'b000_00000);
    mem_write(8'h06, 8'b101_11011);
    mem_write(8'h07, 8'b001_00000);
    mem_write(8'h08, 8'b111_01010);
    mem_write(8'h09, 8'b000_00000);
    mem_write(8'h0A, 8'b110_11100);
    mem_write(8'h0B, 8'b101_11010);
    mem_write(8'h0C, 8'b110_11100);
    mem_write(8'h0D, 8'b101_11100);
    mem_write(8'h0E, 8'b001_00000);
    mem_write(8'h0F, 8'b000_00000);
    mem_write(8'h10, 8'b100_11011);
    mem_write(8'h11, 8'b001_00000);
    mem_write(8'h12, 8'b111_10100);
    mem_write(8'h13, 8'b000_00000);
    mem_write(8'h14, 8'b100_11011);
    mem_write(8'h15, 8'b001_00000);
    mem_write(8'h16, 8'b000_00000);
    mem_write(8'h17, 8'b000_00000);
    mem_write(8'h18, 8'b111_00000);

    // Test data
    mem_write(8'h1A, 8'h00);
    mem_write(8'h1B, 8'hFF);
    mem_write(8'h1C, 8'hAA);
    mem_write(8'h1E, 8'b111_00011);
    mem_write(8'h1F, 8'h00);
  endtask


  // ==========================================================================
  // TEST 2 — Official CPUtest2 Program
  // ==========================================================================
  task automatic load_test2();
    int i;
    for (i = 0; i < 32; i++)
      mem_write(i, 8'h00);

    mem_write(8'h00, 8'b101_11011);
    mem_write(8'h01, 8'b011_11100);
    mem_write(8'h02, 8'b100_11011);
    mem_write(8'h03, 8'b001_00000);
    mem_write(8'h04, 8'h00);
    mem_write(8'h05, 8'b010_11010);
    mem_write(8'h06, 8'b001_00000);
    mem_write(8'h07, 8'b111_01001);
    mem_write(8'h08, 8'h00);
    mem_write(8'h09, 8'b100_11100);
    mem_write(8'h0A, 8'b010_11010);
    mem_write(8'h0B, 8'b110_11101);
    mem_write(8'h0C, 8'b101_11010);
    mem_write(8'h0D, 8'b010_11101);
    mem_write(8'h0E, 8'b001_00000);
    mem_write(8'h0F, 8'h00);
    mem_write(8'h10, 8'h00);
    mem_write(8'h11, 8'b111_00000);

    // Test data
    mem_write(8'h1A, 8'h01);
    mem_write(8'h1B, 8'hAA);
    mem_write(8'h1C, 8'hFF);
    mem_write(8'h1D, 8'h00);
  endtask


  // ==========================================================================
  // TEST 3 — Fibonacci Program (Official CPUtest3)
  // ==========================================================================
  task automatic load_test3();
    int i;
    for (i = 0; i < 32; i++)
      mem_write(i, 8'h00);

    mem_write(8'h00, 8'b111_00011);
    mem_write(8'h03, 8'b101_11011);
    mem_write(8'h04, 8'b110_11100);
    mem_write(8'h05, 8'b010_11010);
    mem_write(8'h06, 8'b110_11011);
    mem_write(8'h07, 8'b101_11100);
    mem_write(8'h08, 8'b110_11010);
    mem_write(8'h09, 8'b100_11101);
    mem_write(8'h0A, 8'b001_00000);
    mem_write(8'h0B, 8'b111_00011);
    mem_write(8'h0C, 8'h00);
    mem_write(8'h0D, 8'b101_11111);
    mem_write(8'h0E, 8'b110_11010);
    mem_write(8'h0F, 8'b101_11110);
    mem_write(8'h10, 8'b110_11011);
    mem_write(8'h11, 8'b111_00011);

    // Fibonacci data memory
    mem_write(8'h1A, 8'h01);
    mem_write(8'h1B, 8'h00);
    mem_write(8'h1C, 8'h00);
    mem_write(8'h1D, 8'h90);
    mem_write(8'h1E, 8'h00);
    mem_write(8'h1F, 8'h01);
  endtask


  // ==========================================================================
  // TEST SUITE EXECUTION
  // ==========================================================================
  int TEST_SELECTION = 0;
  // 0 = run all tests
  // 1 = only Test1
  // 2 = only Test2
  // 3 = only Test3

  initial begin
    bit pass1, pass2, pass3;
    int pc;

    $display("\n========= CPU FULL TEST SUITE =========");

    // ---------------------------------------------------------
    // TEST 1
    // ---------------------------------------------------------
    if (TEST_SELECTION == 0 || TEST_SELECTION == 1) begin
      do_reset();
      load_test1();
      run_until_halt(3000, pc);
      pass1 = (pc == 8'h17);
      $display("Test1 Result: %s", pass1 ? "PASS" : "FAIL");
    end

    // ---------------------------------------------------------
    // TEST 2
    // ---------------------------------------------------------
    if (TEST_SELECTION == 0 || TEST_SELECTION == 2) begin
      do_reset();
      load_test2();
      run_until_halt(3000, pc);
      pass2 = (pc == 8'h10);
      $display("Test2 Result: %s", pass2 ? "PASS" : "FAIL");
    end

    // ---------------------------------------------------------
    // TEST 3
    // ---------------------------------------------------------
    if (TEST_SELECTION == 0 || TEST_SELECTION == 3) begin
      do_reset();
      load_test3();
      run_until_halt(8000, pc);
      pass3 = (pc == 8'h0C);
      $display("Test3 Result: %s", pass3 ? "PASS" : "FAIL");
    end

    $display("========================================");
    $stop;
  end

endmodule
