addiu $t1, $zero, 0xdeed
mtlo $t1
mflo $zero
jr $zero
addiu v0 zero 0x0

#assert v0 == 0xffffdeed
