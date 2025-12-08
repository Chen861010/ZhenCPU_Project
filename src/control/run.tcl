clear -all

analyze -sv \
    typedefs.sv \
    8S_control.sv \
    control_fpv.sv \
    control_bind.sv

elaborate -top control

clock clk
reset ~rst_

prove -all

