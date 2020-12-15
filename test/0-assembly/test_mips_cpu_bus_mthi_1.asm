lui $t0, 0xBA6A
mthi $t0
mfhi $v0
jr $zero
sll $zero, $zero, 0x0000

#assert v0 == 0xba6a0000
