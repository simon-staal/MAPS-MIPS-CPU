addiu $t1, $zero, 0xdeed
mtlo $t1
mflo $v0
jr $zero
sll $zero, $zero, 0x0000

#assert v0 == 0xffffdeed
