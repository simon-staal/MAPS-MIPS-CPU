LUI t0 0xBFC0
J 0x3F00014
nop
JR zero
LW v0 t0 0x2C
JR zero
LW  v0 v0 0x30

at mem 0x2C = 00000001
at mem 0x30 = 00000002
assert v0 = 00000002