LUI t0 0xBFC0
LW t1 0x28 t0
jr t1
nop
jr zero
addui v0 v0 0x1

mem location 28: BFC00014: jr zero
addui v0 v0 0x2


assert v0 = 00000002
