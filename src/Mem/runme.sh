#!/bin/tcsh

source xrun.cshrc

xrun Mem.sv mem_test.sv \
     -access +rwc -gui
