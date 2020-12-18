LUI t0 0xBFC0
JAL 0x3F00012
nop
lw t1 t0(0x28)
addu ra ra t1
jr zero 
addu v0 v0 ra

line 18: lw t1 t0 (0x2C)
addu ra ra t1
jr zero
addu v0 v0 ra

assert v0 = bfc0000e


