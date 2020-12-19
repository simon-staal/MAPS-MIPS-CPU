lui $t0, 0x3546
mthi $t0
mfhi $v0
jr $zero
sll $zero, $zero, 0x0000

#assert v0 == 0x35460000
