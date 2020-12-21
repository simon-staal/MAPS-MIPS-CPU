lui $v0 0xbfc0
lh $v0 0x0000($zero)
jr $zero
addiu $v0 $v0 0x0065

#assert v0 == 00000065
