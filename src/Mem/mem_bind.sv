// =========================================================
// bind_mem.sv
// =========================================================

bind mem mem_properties mem_prop_inst (
  .clk      (clk),
  .read     (read),
  .write    (write),
  .addr     (addr),
  .data_in  (data_in),
  .data_out (data_out),
  .memory   (memory)     // hierarchical internal array
);

