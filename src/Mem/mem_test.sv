module mem_test;

  // ==========================================
  // clock
  // ==========================================
  logic clk;
  initial clk = 0;
  always #5 clk = ~clk;

  // ==========================================
  // DUT signals
  // ==========================================
  logic        read;
  logic        write;
  logic [4:0]  addr;
  logic [7:0]  data_in;
  wire  [7:0]  data_out;

  // ==========================================
  // Instantiate DUT
  // ==========================================
  mem dut (
    .clk      (clk),
    .read     (read),
    .write    (write),
    .addr     (addr),
    .data_in  (data_in),
    .data_out (data_out)
  );

  // ==========================================
  // SystemVerilog settings
  // ==========================================
  timeunit      1ns;
  timeprecision 1ps;

  bit         debug = 1;
  logic [7:0] rdata;

  // ==========================================
  // 🔥 RANDOM TEST VARIABLES（統一宣告在 module 區）
  // ==========================================
  int RANDOM_TEST_COUNT = 5000;
  int rand_addr;
  int rand_data;
  logic [7:0] read_back;

  // ==========================================
  // timeout
  // ==========================================
  initial begin
    $timeformat(-9, 0, " ns", 9);
    #400000ns $display("MEMORY TEST TIMEOUT");
    $stop;
  end

  // ==========================================
  // default output
  // ==========================================
  initial begin
    read    = 1'b0;
    write   = 1'b0;
    addr    = '0;
    data_in = '0;
  end

  // ==========================================
  // MAIN TEST
  // ==========================================
  initial begin : memtest
    int error_status;

    // ======================================================
    // Test 1: Clear memory
    // ======================================================
    $display("\n==== Clear Memory Test ====");
    for (int i = 0; i < 32; i++)
      write_mem(.a(i[4:0]), .d(8'h00), .dbg(debug));

    error_status = 0;
    for (int i = 0; i < 32; i++) begin
      read_mem(.a(i[4:0]), .d(rdata), .dbg(debug));
      if (rdata !== 8'h00) begin
        error_status++;
        $display("%t ERROR: addr=%0d expected=00 got=%02h",
                  $time, i, rdata);
      end
    end
    printstatus(error_status, "Clear Memory Test");

    // ======================================================
    // Test 2: Data = Address
    // ======================================================
    $display("\n==== Data = Address Test ====");
    for (int i = 0; i < 32; i++)
      write_mem(.a(i[4:0]), .d(8'(i)), .dbg(debug));

    error_status = 0;
    for (int i = 0; i < 32; i++) begin
      read_mem(.a(i[4:0]), .d(rdata), .dbg(debug));
      if (rdata !== 8'(i)) begin
        error_status++;
        $display("%t ERROR: addr=%0d expected=%02h got=%02h",
                 $time, i, 8'(i), rdata);
      end
    end
    printstatus(error_status, "Data = Address Test");

    // ======================================================
    // 🔥 Test 3: Random Stress Test
    // ======================================================
    $display("\n==== Random Stress Test (%0d iterations) ====",
             RANDOM_TEST_COUNT);

    for (int j = 0; j < RANDOM_TEST_COUNT; j++) begin

      rand_addr = $urandom_range(0, 31);
      rand_data = $urandom_range(0, 255);

      if ($urandom_range(0,1)) begin
        // do write
        write_mem(.a(rand_addr[4:0]), .d(rand_data[7:0]), .dbg(0));

        // verify
        read_mem(.a(rand_addr[4:0]), .d(read_back), .dbg(0));
        if (read_back !== rand_data[7:0]) begin
          $display("%t RANDOM ERROR: addr=%0d expected=%02h got=%02h",
                   $time, rand_addr, rand_data, read_back);
        end
      end else begin
        // random read
        read_mem(.a(rand_addr[4:0]), .d(read_back), .dbg(0));
      end
    end

    $display("\n==== Random Stress Test DONE ====");
    $stop;
  end


  // ==========================================
  // TASKS (不動)
  // ==========================================
  task automatic write_mem(
    input  logic [4:0] a,
    input  logic [7:0] d,
    input  bit         dbg = 0
  );
  begin
    @(negedge clk);
    addr    <= a;
    data_in <= d;
    read    <= 1'b0;
    write   <= 1'b1;

    @(posedge clk);

    @(negedge clk);
    write   <= 1'b0;
  end
  endtask


  task automatic read_mem(
    input  logic [4:0] a,
    output logic [7:0] d,
    input  bit         dbg = 0
  );
  begin
    @(negedge clk);
    addr <= a;
    write <= 1'b0;
    read  <= 1'b1;

    @(posedge clk);
    #1 d = data_out;

    @(negedge clk);
    read <= 1'b0;
  end
  endtask


  function void printstatus(input int status, input string name);
    if (status == 0)
      $display(">>> %s PASSED", name);
    else
      $display(">>> %s FAILED (%0d errors)", name, status);
  endfunction


  // ==========================================
  // Coverage (不動)
  // ==========================================
  logic [4:0] last_wr_addr;
  logic [31:0] addr_written;

  always_ff @(posedge clk) begin
    if (write && !read) begin
      last_wr_addr <= addr;
      addr_written[addr] <= 1'b1;
    end
  end

  covergroup mem_cg @(posedge clk);
    cp_addr: coverpoint addr { bins all_addr[] = {[0:31]}; }
    cp_write: coverpoint write { bins w0 = {0}; bins w1 = {1}; }
    cp_read:  coverpoint read  { bins r0 = {0}; bins r1 = {1}; }
    cp_illegal: coverpoint {read, write} {
      illegal_bins both_high = {2'b11};
    }
    cr_addr_write: cross cp_addr, cp_write;
    cr_addr_read: cross cp_addr, cp_read;

    cp_read_after_write: coverpoint addr_written[addr] iff (read) {
      bins after_write = {1};
      bins before_write = default;
    }
  endgroup

  mem_cg mem_cov = new();

endmodule
