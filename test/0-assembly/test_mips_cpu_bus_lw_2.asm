lui $v1 0xBCF0
lw $v0 0x0028($v1)
jr $zero
addiu $v0 $v0 0x0000

#0XBCF00028 = 0XCAFE2105
#assert v0 = 0XCAFE2105
