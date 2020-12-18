lui $v1 0xbfc0
lw $v0 0x28($v1)
jr $zero
nop
0x01234567

#assert v0 == 0x01234567
