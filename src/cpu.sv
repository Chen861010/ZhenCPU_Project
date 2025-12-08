//==============================================================
//  cpu.sv — Top-Level CPU Module
//
//  Components:
//    • Accumulator register (AC)
//    • Instruction register (IR)
//    • Program counter (PC)
//    • ALU
//    • Memory
//    • Control unit
//    • 5-bit address multiplexer (PC/IR → memory)
//
//  Behavior:
//    The CPU executes instructions fetched from memory using a
//    Harvard-like sequencing split across clk, cntrl_clk, and alu_clk.
//==============================================================

import typedefs::*;

module cpu (
    output logic halt,          // Halt flag from controller
    output logic load_ir,       // Load-enable for instruction register
    output state_t state,       // Exposed FSM state (for testbench/coverage)

    input  logic clk,           // Main CPU clock
    input  logic cntrl_clk,     // Controller clock (state machine)
    input  logic alu_clk,       // ALU update clock (negedge-based ALU)
    input  logic fetch,         // Address-select signal for instruction fetch
    input  logic rst_           // Asynchronous active-low reset
);

    // ------------------------------------------------------------
    // Time precision
    // ------------------------------------------------------------
    timeunit 1ns;
    timeprecision 100ps;

    // ------------------------------------------------------------
    // Internal CPU signals
    // ------------------------------------------------------------
    logic  [7:0] data_out, alu_out, accum, ir_out;
    logic  [4:0] pc_addr, ir_addr, addr;
    opcode_t     opcode;

    logic load_ac, mem_rd, mem_wr, inc_pc, load_pc, zero;


    // ============================================================
    //  Accumulator Register (AC)
    // ============================================================
    register ac (
        .out    (accum),
        .data   (alu_out),
        .clk    (clk),
        .enable (load_ac),
        .rst_   (rst_)
    );


    // ============================================================
    //  Instruction Register (IR)
    // ============================================================
    register ir (
        .out    (ir_out),
        .data   (data_out),
        .clk    (clk),
        .enable (load_ir),
        .rst_   (rst_)
    );

    // Extract opcode and instruction address
    assign opcode  = opcode_t'(ir_out[7:5]);
    assign ir_addr = ir_out[4:0];


    // ============================================================
    // Program Counter (PC) — 5-bit counter with load + increment
    // ============================================================
    counter pc (
        .count  (pc_addr),
        .data   (ir_addr),
        .clk    (clk),
        .load   (load_pc),
        .enable (inc_pc),
        .rst_   (rst_)
    );


    // ============================================================
    // ALU
    // ============================================================
    alu alu1 (
        .out   (alu_out),
        .zero  (zero),
        .clk   (alu_clk),
        .accum (accum),
        .data  (data_out),
        .opcode(opcode)
    );


    // ============================================================
    // Address Select Mux: PC vs. IR address
    // ============================================================
    scale_mux #5 smx (
        .out   (addr),
        .in_a  (pc_addr),
        .in_b  (ir_addr),
        .sel_a (fetch)
    );


    // ============================================================
    // Memory (32x8)
    //   • Read/write driven by controller
    //   • Clock is inverted control clock (~cntrl_clk)
    // ============================================================
    mem mem1 (
        .clk     (~cntrl_clk),
        .read    (mem_rd),
        .write   (mem_wr),
        .addr    (addr),
        .data_in (alu_out),
        .data_out(data_out)
    );


    // ============================================================
    // Control Unit (FSM)
    // ============================================================
    control cntl (
        .load_ac,
        .mem_rd,
        .mem_wr,
        .inc_pc,
        .load_pc,
        .load_ir,
        .halt,
        .state   (state),    // Exposed CPU state → testbench coverage
        .opcode  (opcode),
        .zero    (zero),
        .clk     (cntrl_clk),
        .rst_    (rst_)
    );

endmodule
