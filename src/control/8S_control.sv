// ============================================================
// control.sv  (FINAL — unique case removed to avoid warnings)
// ============================================================
timeunit 1ns;
timeprecision 100ps;

import typedefs::*;

module control (
  output logic load_ac,
  output logic mem_rd,
  output logic mem_wr,
  output logic inc_pc,
  output logic load_pc,
  output logic load_ir,
  output logic halt,
  output state_t state,
  input  opcode_t opcode,
  input  logic    zero,
  input  logic    clk,
  input  logic    rst_
);

  // ------------------------------------------------------------
  // Controller states
  // ------------------------------------------------------------
  state_t ps, ns;
  assign state = ps;

  // ============================================================
  // 1. State register
  // ============================================================
  always_ff @(posedge clk or negedge rst_) begin
    if (!rst_)
      ps <= INST_ADDR;
    else
      ps <= ns;
  end

  // ============================================================
  // 2. Unconditional 8-state cycle (NO branching allowed)
  //    → unique case removed to avoid simulator warnings
  // ============================================================
  always_comb begin
    case (ps)
      INST_ADDR  : ns = INST_FETCH;
      INST_FETCH : ns = INST_LOAD;
      INST_LOAD  : ns = IDLE;
      IDLE       : ns = OP_ADDR;
      OP_ADDR    : ns = OP_FETCH;
      OP_FETCH   : ns = ALU_OP;
      ALU_OP     : ns = STORE;
      STORE      : ns = INST_ADDR;
      default    : ns = INST_ADDR;
    endcase
  end

  // ============================================================
  // 3. Output decode — EXACTLY per the spec table
  //    → unique case removed here too
  // ============================================================
  always_comb begin
    // default outputs
    load_ac = 0;
    mem_rd  = 0;
    mem_wr  = 0;
    inc_pc  = 0;
    load_pc = 0;
    load_ir = 0;
    halt    = 0;

    case (ps)

      // --------------------------------------------------------
      // INST_FETCH : mem_rd = 1
      // --------------------------------------------------------
      INST_FETCH: begin
        mem_rd = 1;
      end

      // --------------------------------------------------------
      // INST_LOAD : mem_rd = 1, load_ir = 1
      // --------------------------------------------------------
      INST_LOAD: begin
        mem_rd  = 1;
        load_ir = 1;
      end

      // --------------------------------------------------------
      // IDLE : mem_rd = 1, load_ir = 1
      // (per spec table)
      // --------------------------------------------------------
      IDLE: begin
        mem_rd  = 1;
        load_ir = 1;
      end

      // --------------------------------------------------------
      // OP_ADDR : inc_pc = 1
      //           halt = 1 iff opcode == HLT
      // --------------------------------------------------------
      OP_ADDR: begin
        inc_pc = 1;
        if (opcode == HLT)
          halt = 1;
      end

      // --------------------------------------------------------
      // OP_FETCH : mem_rd = ALUOP
      // --------------------------------------------------------
      OP_FETCH: begin
        if (opcode inside {ADD, AND, XOR, LDA})
          mem_rd = 1;
      end

      // --------------------------------------------------------
      // ALU_OP :
      //   mem_rd  = ALUOP
      //   load_ac = ALUOP
      //   inc_pc  = SKZ && zero
      //   load_pc = JMP
      // --------------------------------------------------------
      ALU_OP: begin
        if (opcode inside {ADD, AND, XOR, LDA}) begin
          mem_rd  = 1;
          load_ac = 1;
        end

        if (opcode == SKZ && zero)
          inc_pc = 1;

        if (opcode == JMP)
          load_pc = 1;
      end

      // --------------------------------------------------------
      // STORE:
      //   mem_wr = STO
      //   load_ac = ALUOP
      //   mem_rd  = ALUOP
      //   load_pc, inc_pc for JMP
      // --------------------------------------------------------
      STORE: begin
        if (opcode inside {ADD, AND, XOR, LDA}) begin
          mem_rd  = 1;
          load_ac = 1;
        end

        if (opcode == STO) begin
          mem_wr = 1;
        end
        if (opcode == JMP) begin
          load_pc = 1;
          inc_pc  = 1;
        end
      end

    endcase
  end

endmodule
