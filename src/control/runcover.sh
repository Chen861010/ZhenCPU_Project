#!/bin/sh
# Compile with coverage enabled
vlog typedefs.sv
vlog 8S_control.sv
vlog control_test.sv +fcover -cover sbceft +cover=f -O0  

# Run simulation in command-line mode with coverage enabled
vsim work.control_test -coverage +acc -c -do cover.do


