ADDIU $t0 $t0 0x0007
ADDIU $t1 $t1 0x0002
DIV $t0 $t1
MFLO $v0
JR $zero

assert v0 = 00000003