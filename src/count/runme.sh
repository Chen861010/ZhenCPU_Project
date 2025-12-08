#!/bin/tcsh

source xrun.cshrc

xrun counter_test.sv 5bit_count.sv\
     -access +rwc -gui
