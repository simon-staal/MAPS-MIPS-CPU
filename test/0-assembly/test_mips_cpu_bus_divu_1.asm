ADDIU $t0 $t0 0x0005
ADDIU $t1 $t1 0x0002
DIV $t0 $t1
JR $zero
MFHI v0

assert v0 = 00000002