// mem.sv
timeunit 1ns;
timeprecision 100ps;

// 和 cpu_v1 & testbench 對齊：
//   - 模組名稱： mem
//   - 內部陣列： memory[0:31]
//   - 位址寬度： 5 bit (對應 pc_addr / ir_addr)

module mem (
  input  logic        clk,
  input  logic        read,
  input  logic        write,
  input  logic [4:0]  addr,      // 32 addresses: 0..31
  input  logic [7:0]  data_in,
  output logic [7:0]  data_out
);

  // 跟 testbench 對齊：dut.u_mem.memory[i]
  logic [7:0] memory [0:31];

  // Write：在 write=1、read=0 時寫入
  always_ff @(posedge clk) begin
    if (write && !read)
      memory[addr] <= data_in;
  end

  // Read：在 read=1、write=0 時讀出
  always_ff @(posedge clk) begin
    if (read && !write)
      data_out <= memory[addr];
  end

endmodule

