// =========================================================
// assertion.sv  —  Formal + Simulation Assertions
// =========================================================

timeunit 1ns;
timeprecision 100ps;

module mem_properties (
  input  logic        clk,
  input  logic        read,
  input  logic        write,
  input  logic [4:0]  addr,
  input  logic [7:0]  data_in,
  input  logic [7:0]  data_out,

  // For checking read-after-write correctness
  input  logic [7:0]  memory [0:31]
);

  assume property (@(posedge clk) !(read && write));
  // Memory can only be modified during valid write
  assume property(
    @(posedge clk)
      (!(write && !read)) |-> (memory == $past(memory))
  );
  // ---------------------------------------------
  // 1. Illegal condition: read & write cannot both be 1
  // ---------------------------------------------
  property no_read_write_same_time;
    @(posedge clk)
      !(read && write);
  endproperty
  assert property(no_read_write_same_time)
    else $error("[ASSERT] read & write cannot both be 1 at %0t", $time);


  // ---------------------------------------------
  // 2. Write correctness:
  //    If write=1 (and read=0)，memory must be updated next cycle
  // ---------------------------------------------
  property write_behavior;
    @(posedge clk)
      (write && !read)
        |=> (memory[$past(addr)] == $past(data_in));
  endproperty

  assert property(write_behavior)
    else $error("[ASSERT] Write mismatch at addr %0d @ %0t",
                $past(addr), $time);



  // ---------------------------------------------
  // 3. Read correctness:
  //    If read=1 (and write=0)，data_out must equal memory[addr] next cycle
  // ---------------------------------------------
  property read_behavior;
    @(posedge clk)
      (read && !write) |=> (data_out == memory[$past(addr)]);
  endproperty
  assert property(read_behavior)
    else $error("[ASSERT] Read mismatch: expect=%0h got=%0h @ %0t",
                memory[$past(addr)], data_out, $time);


  // ---------------------------------------------
  // 4. Stability: If neither read nor write，memory cant change
  // ---------------------------------------------
  property memory_stable;
    @(posedge clk)
      (!read && !write) |-> (memory == $past(memory));
  endproperty
  assert property(memory_stable)
    else $error("[ASSERT] Memory changed without read/write at %0t", $time);

endmodule

