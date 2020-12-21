lui $v1 0xbfc0
lw $t1 0x28($v1)
lw $t2 0x2C($v1)
jr $zero
xor $v0 $t1 $t2
