clear -all

analyze -sv \
    5bit_count.sv \
    count_fpv.sv \
    count_bind.sv

elaborate -top counter

clock clk
reset ~rst_


prove -all

