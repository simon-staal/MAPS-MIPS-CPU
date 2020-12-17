JR $zero
ADDIU $v0 $v0 0x0001
ADDIU $v0 $v0 0x000A
JR $zero
noop

assert v0 = 00000001
