ADDIU $t0 $t0 0x0010
ADDIU $t1 $t1 0x0002
DIVU $t0 $t1
JR $zero
MFLO v0

assert v0 = 00000008