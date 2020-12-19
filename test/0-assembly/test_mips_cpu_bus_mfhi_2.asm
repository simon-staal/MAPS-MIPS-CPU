lui $t0, 0x3546
mthi $t0
mfhi $zero
jr $zero
addiu v0 zero 0x0

#assert v0 == 0x00000000
