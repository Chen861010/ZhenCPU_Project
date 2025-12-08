timeunit 1ns;
timeprecision 100ps;

import typedefs::*;

module testbench;

  // =====================================
  // Clock, reset, DUT ports
  // =====================================
  logic clk, cntrl_clk, alu_clk, fetch;
  logic rst_;
  logic halt;
  logic load_ir;

  `define PERIOD 10
  logic master_clk = 1'b1;
  logic [3:0] count;

  always #(`PERIOD/2) master_clk = ~master_clk;

  always @(posedge master_clk or negedge rst_) begin
    if (!rst_) count <= 4'b0;
    else       count <= count + 1;
  end

  assign cntrl_clk = ~count[0];
  assign clk       = count[1];
  assign fetch     = ~count[3];
  assign alu_clk   = ~(count == 4'hC);

  // =====================================
  // DUT
  // =====================================
  cpu dut (
      .halt      (halt),
      .load_ir   (load_ir),
      .clk       (clk),
      .cntrl_clk (cntrl_clk),
      .alu_clk   (alu_clk),
      .fetch     (fetch),
      .rst_      (rst_)
  );

  // =====================================
  // Memory write helper
  // =====================================
  task automatic mem_write(input int idx, input [7:0] val);
    dut.mem1.memory[idx] = val;
  endtask

  // =====================================
  // RESET
  // =====================================
  task automatic do_reset();
    rst_ = 0;
    repeat (5) @(posedge master_clk);
    rst_ = 1;
    repeat (5) @(posedge master_clk);
  endtask

  // =====================================
  // WAIT UNTIL HALT
  // =====================================
  task automatic run_until_halt(input int max_cycles,
                                output int final_pc);
    int cycles = 0;

    while (!halt && cycles < max_cycles) begin
      @(posedge clk);
      cycles++;
    end

    final_pc = dut.pc_addr;
  endtask

  // =====================================
  // LOAD TEST1 PROGRAM
  // =====================================
  task automatic load_test1();
    int i;
    for (i = 0; i < 32; i++) mem_write(i, 8'h00);

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

    mem_write(8'h1A, 8'b00000000);
    mem_write(8'h1B, 8'b11111111);
    mem_write(8'h1C, 8'b10101010);
    mem_write(8'h1E, 8'b111_00011);
    mem_write(8'h1F, 8'b000_00000);
  endtask

  // =====================================
  // LOAD TEST2 PROGRAM
  // =====================================
  task automatic load_test2();
    int i; 
    for (i = 0; i < 32; i++) mem_write(i, 8'h00);

    mem_write(8'h00, 8'b101_11011);
    mem_write(8'h01, 8'b011_11100);
    mem_write(8'h02, 8'b100_11011);
    mem_write(8'h03, 8'b001_00000);
    mem_write(8'h04, 8'b000_00000);
    mem_write(8'h05, 8'b010_11010);
    mem_write(8'h06, 8'b001_00000);
    mem_write(8'h07, 8'b111_01001);
    mem_write(8'h08, 8'b000_00000);
    mem_write(8'h09, 8'b100_11100);
    mem_write(8'h0A, 8'b010_11010);
    mem_write(8'h0B, 8'b110_11101);
    mem_write(8'h0C, 8'b101_11010);
    mem_write(8'h0D, 8'b010_11101);
    mem_write(8'h0E, 8'b001_00000);
    mem_write(8'h0F, 8'b000_00000);
    mem_write(8'h10, 8'b000_00000);
    mem_write(8'h11, 8'b111_00000);

    mem_write(8'h1A, 8'b00000001);
    mem_write(8'h1B, 8'b10101010);
    mem_write(8'h1C, 8'b11111111);
    mem_write(8'h1D, 8'b00000000);
  endtask

  // =====================================
  // LOAD TEST3 (Fibonacci)
  // =====================================
  task automatic load_test3();
    int i;
    for (i = 0; i < 32; i++) mem_write(i, 8'h00);

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
    mem_write(8'h0C, 8'b000_00000);
    mem_write(8'h0D, 8'b101_11111);
    mem_write(8'h0E, 8'b110_11010);
    mem_write(8'h0F, 8'b101_11110);
    mem_write(8'h10, 8'b110_11011);
    mem_write(8'h11, 8'b111_00011);

    mem_write(8'h1A, 8'b00000001);
    mem_write(8'h1B, 8'b00000000);
    mem_write(8'h1C, 8'b00000000);
    mem_write(8'h1D, 8'b10010000);
    mem_write(8'h1E, 8'b00000000);
    mem_write(8'h1F, 8'b00000001);
  endtask

  // =====================================
  // TEST SELECTION
  // =====================================
  int TEST_SELECTION = 0;
  // 0 = ALL tests
  // 1 = only Test1
  // 2 = only Test2
  // 3 = only Test3

  initial begin
    bit pass1, pass2, pass3;
    int pc;

    $display("\n========= CPU FULL TEST SUITE =========");

    // -------------------------------
    // TEST 1
    // -------------------------------
    if (TEST_SELECTION == 0 || TEST_SELECTION == 1) begin
      do_reset();
      load_test1();
      run_until_halt(3000, pc);
      pass1 = (pc == 8'h17);
      $display("Test1 Result: %s", pass1 ? "PASS" : "FAIL");
    end

    // -------------------------------
    // TEST 2
    // -------------------------------
    if (TEST_SELECTION == 0 || TEST_SELECTION == 2) begin
      do_reset();
      load_test2();
      run_until_halt(3000, pc);
      pass2 = (pc == 8'h10);
      $display("Test2 Result: %s", pass2 ? "PASS" : "FAIL");
    end

    // -------------------------------
    // TEST 3
    // -------------------------------
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
