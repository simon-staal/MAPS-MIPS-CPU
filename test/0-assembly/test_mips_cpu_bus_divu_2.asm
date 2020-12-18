ADDIU $t0 $t0 0x0006
ADDIU $t1 $t1 0x0002
DIVU $t0 $t1
JR $zero
MFHI v0

assert v0 = 00000000