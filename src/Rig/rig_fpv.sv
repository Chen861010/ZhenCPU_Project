//==============================================================
//  register_assertions.sv — Assertions for 8-bit Register
//
//  This module contains formal checks for:
//    • Asynchronous active-low reset behavior
//    • Update behavior when enable=1
//    • Hold behavior when enable=0
//    • Combined reset + enable timing condition
//
//  These properties are suitable for both simulation and
//  formal tools (Cadence JasperGold, Questa Formal, Synopsys VC-F).
//==============================================================

module register_assertions(
    input logic        clk,
    input logic        rst_,     // Asynchronous active-low reset
    input logic        enable,   // Write-enable signal
    input logic [7:0]  data,     // Register input
    input logic [7:0]  out       // Register state / output
);

    // ------------------------------------------------------------
    // 1) Asynchronous reset:
    //    Whenever rst_ falls (reset asserted), out must become 0.
    //    This property does not rely on the clock.
    // ------------------------------------------------------------
    property p_async_reset;
        @(negedge rst_) out == 8'h00;
    endproperty
    a_async_reset : assert property(p_async_reset);


    // ------------------------------------------------------------
    // 2) Update behavior when enable=1:
    //    On the next rising edge of clk:
    //      out(next) == data(current)
    //
    //    Reset disables the implication via disable iff.
    // ------------------------------------------------------------
    property p_enable_update;
        @(posedge clk) disable iff (!rst_)
            enable |=> out == $past(data);
    endproperty
    a_enable_update : assert property(p_enable_update);


    // ------------------------------------------------------------
    // 3) Hold behavior when enable=0:
    //    On the next rising edge of clk:
    //      out(next) == out(previous)
    //
    //    As with all sequential checks, reset disables the property.
    // ------------------------------------------------------------
    property p_hold_value;
        @(posedge clk) disable iff (!rst_)
            !enable |=> out == $past(out);
    endproperty
    a_hold_value : assert property(p_hold_value);


    // ------------------------------------------------------------
    // 4) Update behavior when reset is deasserted & enable=1:
    //    This is similar to property (2), but explicitly checks
    //    that both rst_ and enable are high at the triggering edge.
    // ------------------------------------------------------------
    property p_enable_rst__update;
        @(posedge clk)
            rst_ && enable |=> out == $past(data);
    endproperty
    a_enable_rst__update : assert property(p_enable_rst__update);

endmodule
