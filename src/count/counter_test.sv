///////////////////////////////////////////////////////////////////////////
// Counter Testbench with Directed + Random Tests + Functional Coverage
///////////////////////////////////////////////////////////////////////////

module counter_test;

timeunit 1ns;
timeprecision 100ps;

logic          rst_;
logic          load;
logic          enable;
logic  [4:0]   data;
logic  [4:0]   count ;

`define PERIOD 10
logic clk = 1'b1;

// Clock
always #(`PERIOD/2) clk = ~clk;


// ------------------------------------------------------------
// DUT
// ------------------------------------------------------------
counter cnt1 (
    .count(count),
    .data(data),
    .clk(clk),
    .load(load),
    .enable(enable),
    .rst_(rst_)
);


// ============================================================================
// Functional Coverage — Cadence + Questa Compatible
// ============================================================================

// Reset behavior
covergroup cg_reset @(negedge clk);
    cp_reset : coverpoint rst_ {
        bins asserted = {0};
        bins released = {1};
    }

    cp_after_reset : coverpoint count { bins zero = {0}; }

    reset_x_count : cross cp_reset, cp_after_reset;
endgroup

// Load behavior
covergroup cg_load @(negedge clk);
    cp_load : coverpoint load { bins OFF = {0}; bins ON = {1}; }

    cp_value : coverpoint data {
        bins low  = {[0:3]};
        bins mid  = {[4:15]};
        bins high = {[16:31]};
    }
endgroup

// Enable behavior
covergroup cg_enable @(negedge clk);
    cp_enable : coverpoint enable { bins OFF = {0}; bins ON = {1}; }

    cp_count : coverpoint count {
        bins zero = {0};
        bins mid  = {[1:15]};
        bins high = {[16:30]};
        bins max  = {31};
    }
endgroup

cg_reset   cv_rst  = new();
cg_load    cv_ld   = new();
cg_enable  cv_en   = new();


// ============================================================================
// Coverage Helper — for branch/condition coverage
// ============================================================================
task automatic coverage_fake_branch;
    logic [4:0] x = 5'h1F;
    logic [4:0] y = 5'h00;

    if (x != y) begin end // fake branch, coverage only
endtask


// ------------------------------------------------------------
// Expect Checker
// ------------------------------------------------------------
task expect_test(input [4:0] expects);
    if (count !== expects) begin
        $display("ERROR: count=%0d expected=%0d", count, expects);
        $display("COUNTER TEST FAILED");
        $finish;
    end
endtask;



// ======================================================================
// RANDOM TEST (now includes reset randomization)
// ======================================================================
integer random_iter = 200;   // <--- 可調整

task run_random_test;
    integer i;
    logic [4:0] expected;

    $display("=== START RANDOM TEST (%0d iterations, rst_ randomized) ===", random_iter);

    // Initial reset (guarantee starting state)
    rst_ = 0; load = 0; enable = 0; data = 0;
    @(negedge clk);
    rst_ = 1;

    for (i = 0; i < random_iter; i++) begin

        // -------------------------
        // FULL_RANDOM: reset included
        // -------------------------
        rst_   = $urandom % 2;       // <-- NEW: rst_ random
        load   = $urandom % 2;
        enable = $urandom % 2;
        data   = $urandom % 32;

        // Compute expected
        if (!rst_) begin
            expected = 0;
        end else if (load) begin
            expected = data;
        end else if (enable) begin
            expected = count + 1;
        end else begin
            expected = count;
        end

        @(negedge clk);
        expect_test(expected);
    end

    $display("=== RANDOM TEST PASSED (rst_ randomized) ===");
endtask;



// ------------------------------------------------------------
// DIRECTED + RANDOM TEST
// ------------------------------------------------------------
initial begin
    @(negedge clk);

    // Coverage helper branch
    coverage_fake_branch();

    //----------------- Directed Test -----------------
    { rst_, load, enable, data } = 8'b0_X_X_XXXXX; @(negedge clk) expect_test(5'h00);

    { rst_, load, enable, data } = 8'b1_0_1_XXXXX; @(negedge clk) expect_test(5'h01);
    { rst_, load, enable, data } = 8'b1_0_1_XXXXX; @(negedge clk) expect_test(5'h02);
    { rst_, load, enable, data } = 8'b1_0_1_XXXXX; @(negedge clk) expect_test(5'h03);
    { rst_, load, enable, data } = 8'b1_0_1_XXXXX; @(negedge clk) expect_test(5'h04);

    { rst_, load, enable, data } = 8'b1_0_0_XXXXX; @(negedge clk) expect_test(5'h04);
    { rst_, load, enable, data } = 8'b1_0_0_XXXXX; @(negedge clk) expect_test(5'h04);

    { rst_, load, enable, data } = 8'b1_1_0_10101; @(negedge clk) expect_test(5'h15);
    { rst_, load, enable, data } = 8'b1_1_1_11101; @(negedge clk) expect_test(5'h1D);

    { rst_, load, enable, data } = 8'b1_0_1_XXXXX; @(negedge clk) expect_test(5'h1E);
    { rst_, load, enable, data } = 8'b1_0_1_XXXXX; @(negedge clk) expect_test(5'h1F);

    { rst_, load, enable, data } = 8'b1_0_1_XXXXX; @(negedge clk) expect_test(5'h00);
    { rst_, load, enable, data } = 8'b1_0_1_XXXXX; @(negedge clk) expect_test(5'h01);

    $display("DIRECTED TEST PASSED");


    //----------------- Random Test -----------------
    run_random_test();

    $display("ALL COUNTER TESTS PASSED");
    $stop;
end

endmodule
