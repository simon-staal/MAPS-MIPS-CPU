lui $v0, 0xbfc0
lw $v1, 0x0028($v0)
mult $v1, $v1
mflo $v0
jr $zero
nop

#address BFC0 0028 = ffffffff
#assert v0 == 0X00000001
