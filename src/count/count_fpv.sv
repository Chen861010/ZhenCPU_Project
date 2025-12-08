// ============================================================================
// counter_assertions.sv  — Formal Assertions for counter.sv
// ============================================================================

timeunit 1ns;
timeprecision 100ps;

module counter_assertions (
    input logic        clk,
    input logic        rst_,     // async active-low reset
    input logic        load,
    input logic        enable,
    input logic [4:0]  data,
    input logic [4:0]  count
);


    assume_no_overlap: assume property (
        @(posedge clk) !(load && enable)
    );

    assume_stable_data_on_load: assume property (
        @(posedge clk)
            load |-> $stable(data)
    );

    // A1. reset active-low 時 count=0
    cover_release_reset: cover property (
        @(posedge clk) $rose(rst_)
    );
    

    // A2. load 優先權：前一拍 load=1 → 本拍 count 要等於 data
    a_load_priority: assert property (
        @(posedge clk) disable iff (!rst_)
            ($past(rst_) && $past(load)) |-> 
                (count == $past(data))
    ) else $error("A2: load did not update count to data");

    // A3. enable=1 且 load=0 → count + 1（含 rollover）
    a_increment: assert property (
        @(posedge clk) disable iff (!rst_)
            ($past(rst_) && $past(enable) && !$past(load)) |-> 
                (count == $past(count) + 1) ||
                ($past(count) == 5'd31 && count == 5'd0)
    ) else $error("A3: enable did not increment count correctly");

    // A4. hold：load=0 enable=0 → count 不變
    a_hold: assert property (
        @(posedge clk) disable iff (!rst_)
            (!$past(load) && !$past(enable)) |-> 
                (count == $past(count))
    ) else $error("A4: count changed unexpectedly when hold");

    // A5. 非 reset 期間不得有 X/Z
    a_no_xz: assert property (
        @(posedge clk) disable iff (!rst_)
            (count === count)
    ) else $error("A5: count contains X/Z");

endmodule
