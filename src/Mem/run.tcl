clear -all

analyze -sv \
    Mem.sv \
    mem_fpv.sv \
    mem_bind.sv

elaborate -top mem

clock clk
reset -none

prove -all

