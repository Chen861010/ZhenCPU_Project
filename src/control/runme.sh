#!/bin/tcsh

source xrun.cshrc

xrun typedefs.sv 8S_control.sv control_test.sv \
     -access +rwc -gui
