lui $zero 0xDEAD
jr $zero
addiu v0 zero 0x0

#assert v0 == 0xDEAD0000
