# CPU_Project
A SystemVerilog-based verification environment for the ZhenCPU, including FSM, ALU, register, memory testing, waveform analysis, and functional coverage.

---

## Overview
ZhenCPU is a simplified CPU designed for instruction-level execution and hardware verification learning.  
This repository contains:

- RTL source code (SystemVerilog) organized per module  
- Self-checking testbenches for each module (ALU, Mem, Mux, Rig, Controller, Counter)  
- CPU-level integration testbench  
- Waveform analysis using **Cadence Xcelium + SimVision**  
- Functional coverage and simulation support using **QuestaSim / ModelSim**  
- Formal property verification (FPV) for FSM, registers, counters, and ALU  
- Instruction program testing environment  

---

## CPU Modules

- **ALU** – arithmetic & logic operations  
- **MUX Units** – data-path selection  
- **Register / Rig** – accumulator & intermediate registers  
- **Controller** – 8-state Moore FSM for instruction sequencing  
- **Memory** – 8-bit data memory with 5-bit address  
- **Program Counter** – 5-bit counter with enable & reset  

All module directories include RTL + testbench + coverage + FPV assertions.

---

## Verification Features

- ✔ Module-level testbenches (ALU, Mem, Mux, Rig, Control, Counter)  
- ✔ CPU integration testing under CPUwave/  
- ✔ Directed + randomized stimulus  
- ✔ Waveform tracing (VCD/FSDB via SimVision or Questa GUI)  
- ✔ Functional coverage using **QuestaSim UCDB**  
- ✔ Simulation logs & automated scripts (`runme.sh`, `runcover.sh`, `clean.sh`)  
- ✔ Formal verification (FPV) with bind files  

---

## 📁 Project Structure

```
src/                         # RTL modules + per-module verification environment
  ALU/                       # ALU RTL, ALU testbench, FPV assertions, bind files,
                             # QuestaSim coverage scripts, runme.sh & runcover.sh
  Mem/                       # Memory RTL + memory testbench + FPV + coverage
  Mux/                       # 2-to-1 multiplexer RTL + testbench + coverage
  Rig/                       # 8-bit register RTL + testbench + FPV + coverage
  control/                   # 8-state controller FSM RTL + testbench + FPV + coverage
  count/                     # 5-bit counter / PC RTL + testbench + FPV + coverage
  cpu.sv                     # Top-level CPU module integrating all submodules
  typedefs.sv                # Shared typedefs, enums, opcodes, state definitions

CPUwave/                     # CPU-level waveform simulation environment (Xcelium)
  cpu_tb.sv                  # Full CPU testbench (instruction-level execution)
  runme.sh                   # Launch full CPU simulation + SimVision wave viewer

programs/                    # Instruction program tests + TCL automation scripts
coverage/                    # Consolidated functional coverage reports (UCDB/text)
tb/                          # Additional standalone or experimental testbenches
waves/                       # User-generated waveform screenshots or FSDB exports
.gitignore                   # Files excluded from version control
README.md                    # Project documentation (this file)
```

```

---

## 🖥️ Simulation Tools

### **Cadence Xcelium + SimVision (default for waveform debugging)**

Used for main simulation of RTL + TB:

```bash
./runme.sh      # compile + simulate full CPU with SimVision
```

Features:
- Fast compile/runtime  
- FSDB waveform viewing  
- Excellent SVA/assertion support  

---

## **QuestaSim Functional Coverage (`runcover.sh`)**

`runcover.sh` is designed for **QuestaSim**, not Xcelium.  
It runs UCDB functional coverage and uses `cover.do`.

Typical flow:

```bash
./runcover.sh    # compile + simulate + generate UCDB coverage
```

Internally this script performs:

```bash
vlib work
vlog *.sv
vsim -c top_tb -do "do cover.do; run -all; coverage report -output cov.rpt; quit"
```

Coverage output:
- `cov.rpt` (text report)
- `work.ucdb` (complete coverage database)

You can also view coverage in Questa GUI:

```bash
vsim -viewcov work.ucdb
```
