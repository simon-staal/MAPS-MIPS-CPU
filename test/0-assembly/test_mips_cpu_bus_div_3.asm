ADDIU $t0 $t0 0x0012
ADDIU $t1 $t1 0x0003
DIV t0 t1
JR $zero
MFLO v0

assert v0 = 0x0006