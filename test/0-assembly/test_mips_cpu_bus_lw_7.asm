lui $v1 0xbfc0
addiu $v1 0x0001($v1)
lw $v0 0x0003($v1)
jr $zero
nop

#assert v0 == 24630001
