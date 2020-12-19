lui $v0, 0xbfc0
lw $v1, 0x0028($v0)
multu $v1, $v0
mfhi $v0
jr $zero
sll $zero, $zero, 0x0000

#bfc00028=c2cf281d
#assert v0 == 91eaaa4b
