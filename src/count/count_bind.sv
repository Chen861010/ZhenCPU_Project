// ============================================================================
// counter_bind.sv  — Bind the assertion module to counter DUT
// ============================================================================

bind counter counter_assertions COUNTER_ASSERT_I (
    .clk(clk),
    .rst_(rst_),
    .load(load),
    .enable(enable),
    .data(data),
    .count(count)
);


