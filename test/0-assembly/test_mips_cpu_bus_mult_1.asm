lui $v0, 0x1A52
lui $v1, 0x09B7
mult $v1, $v0
mfhi $v0
jr $zero
sll $zero, $zero, 0x0000

#assert v0 == 0x00ffb29e
