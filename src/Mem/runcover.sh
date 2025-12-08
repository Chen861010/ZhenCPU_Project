#!/bin/sh
# Compile with coverage enabled
vlog Mem.sv
vlog mem_test.sv +fcover -cover sbceft +cover=f -O0  

# Run simulation in command-line mode with coverage enabled
vsim work.mem_test -coverage +acc -c -do cover.do



