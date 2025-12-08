#!/bin/sh
# Compile with coverage enabled
vlog 5bit_count.sv
vlog counter_test.sv +fcover -cover sbceft +cover=f -O0  

# Run simulation in command-line mode with coverage enabled
vsim work.counter_test -coverage +acc -c -do cover.do


