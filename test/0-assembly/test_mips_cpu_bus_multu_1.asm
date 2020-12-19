lui $v0, 0xbfc0
lw $v1, 0x0028($v0)
multu $v1, $v0
mflo $v0
jr $zero
sll $zero, $zero, 0x0000

#bfc00028=deadcafe
#assert v0 == c080000000
