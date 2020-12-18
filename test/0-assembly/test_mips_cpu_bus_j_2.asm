LUI v0 0x0001
J 0x3F00010
nop
JR $zero
ADDIU v0 v0 0x001
JR $zero
ADDIU v0 v0 0x002



assert v0 = 00010002