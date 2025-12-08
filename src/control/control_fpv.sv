// ============================================================================
// control_assertions.sv  — JasperGold-compatible assertion module (FINAL)
// ============================================================================

timeunit 1ns;
timeprecision 100ps;

import typedefs::*;

module control_assertions (
    input logic clk,
    input logic rst_,

    input opcode_t opcode,
    input state_t  ps,
    input logic    zero,

    input logic load_ac,
    input logic mem_rd,
    input logic mem_wr,
    input logic inc_pc,
    input logic load_pc,
    input logic load_ir,
    input logic halt
);

  `define DISABLE_IF_RESET disable iff (!rst_)


  // ============================================================================
  // A1. After reset deassertion, controller must be in INST_ADDR
  // ============================================================================
  a_reset_state: assert property (
    @(posedge clk)
      $rose(rst_) |-> (ps == INST_ADDR)
  ) else $error("A1: Controller must enter INST_ADDR right after reset");



  // ============================================================================
  // A2. Fixed 8-state FSM sequence (unconditional)
  // ============================================================================
  a_fsm_1: assert property(`DISABLE_IF_RESET
    @(posedge clk)
      (ps == INST_ADDR) |-> ##1 (ps == INST_FETCH)
  ) else $error("A2.1: INST_ADDR → INST_FETCH violation");

  a_fsm_2: assert property(`DISABLE_IF_RESET
    @(posedge clk)
      (ps == INST_FETCH) |-> ##1 (ps == INST_LOAD)
  ) else $error("A2.2: INST_FETCH → INST_LOAD violation");

  a_fsm_3: assert property(`DISABLE_IF_RESET
    @(posedge clk)
      (ps == INST_LOAD) |-> ##1 (ps == IDLE)
  ) else $error("A2.3: INST_LOAD → IDLE violation");

  a_fsm_4: assert property(`DISABLE_IF_RESET
    @(posedge clk)
      (ps == IDLE) |-> ##1 (ps == OP_ADDR)
  ) else $error("A2.4: IDLE → OP_ADDR violation");

  a_fsm_5: assert property(`DISABLE_IF_RESET
    @(posedge clk)
      (ps == OP_ADDR) |-> ##1 (ps == OP_FETCH)
  ) else $error("A2.5: OP_ADDR → OP_FETCH violation");

  a_fsm_6: assert property(`DISABLE_IF_RESET
    @(posedge clk)
      (ps == OP_FETCH) |-> ##1 (ps == ALU_OP)
  ) else $error("A2.6: OP_FETCH → ALU_OP violation");

  a_fsm_7: assert property(`DISABLE_IF_RESET
    @(posedge clk)
      (ps == ALU_OP) |-> ##1 (ps == STORE)
  ) else $error("A2.7: ALU_OP → STORE violation");

  a_fsm_8: assert property(`DISABLE_IF_RESET
    @(posedge clk)
      (ps == STORE) |-> ##1 (ps == INST_ADDR)
  ) else $error("A2.8: STORE → INST_ADDR violation");



  // ============================================================================
  // A3. HALT only valid in OP_ADDR when opcode == HLT
  // ============================================================================
  a_halt_rule: assert property(`DISABLE_IF_RESET
    @(posedge clk)
      halt |-> (ps == OP_ADDR && opcode == HLT)
  ) else $error("A3: HALT asserted illegally");



  // ============================================================================
  // A4. SKZ rule: zero=1 & opcode=SKZ in ALU_OP ⇒ inc_pc
  // ============================================================================
  a_skz_rule: assert property(`DISABLE_IF_RESET
    @(posedge clk)
      (opcode == SKZ && zero == 1 && ps == ALU_OP) |-> inc_pc
  ) else $error("A4: SKZ inc_pc rule violation");



  // ============================================================================
  // A5. JMP must assert load_pc only in ALU_OP/STORE
  // ============================================================================
  a_jmp_rule: assert property(`DISABLE_IF_RESET
    @(posedge clk)
      load_pc |-> ((opcode == JMP) && (ps == ALU_OP || ps == STORE))
  ) else $error("A5: load_pc illegal assert");



  // ============================================================================
  // A6. STO must assert mem_wr only in STORE
  // ============================================================================
  a_sto_rule: assert property(`DISABLE_IF_RESET
    @(posedge clk)
      mem_wr |-> (opcode == STO && ps == STORE)
  ) else $error("A6: mem_wr illegal assert");



  // ============================================================================
  // A7. CORRECT ALU INSTRUCTION BEHAVIOR (corrected from your buggy version)
  // SPEC:
  //   OP_FETCH → mem_rd = 1
  //   ALU_OP   → mem_rd = 1 & load_ac = 1
  //   STORE    → mem_rd = 1 & load_ac = 1
  // ============================================================================

  // A7.1 In OP_FETCH, ALU ops must assert mem_rd only
  a_alu_opfetch: assert property(`DISABLE_IF_RESET
    @(posedge clk)
      (opcode inside {ADD, AND, XOR, LDA} && ps == OP_FETCH)
        |-> mem_rd
  ) else $error("A7.1: OP_FETCH must assert mem_rd for ALU ops");


  // A7.2 In ALU_OP, ALU ops must assert mem_rd + load_ac
  a_alu_aluop: assert property(`DISABLE_IF_RESET
    @(posedge clk)
      (opcode inside {ADD, AND, XOR, LDA} && ps == ALU_OP)
        |-> (mem_rd && load_ac)
  ) else $error("A7.2: ALU_OP must assert mem_rd & load_ac");


  // A7.3 In STORE, ALU ops must assert mem_rd + load_ac
  a_alu_store: assert property(`DISABLE_IF_RESET
    @(posedge clk)
      (opcode inside {ADD, AND, XOR, LDA} && ps == STORE)
        |-> (mem_rd && load_ac)
  ) else $error("A7.3: STORE must assert mem_rd & load_ac for ALU ops");



  // ============================================================================
  // A8. load_ir must be 1 in INST_LOAD and IDLE
  // ============================================================================
  a_loadir_rule: assert property(`DISABLE_IF_RESET
    @(posedge clk)
      (ps inside {INST_LOAD, IDLE}) |-> load_ir
  ) else $error("A8: load_ir missing");



  // ============================================================================
  // A9. inc_pc & load_pc cannot BOTH be 1 except for JMP in STORE
  // ============================================================================
  a_pc_onehot: assert property(`DISABLE_IF_RESET
    @(posedge clk)
      !(load_pc && inc_pc && !(opcode == JMP && ps == STORE))
  ) else $error("A9: illegal PC signals combination");

endmodule
