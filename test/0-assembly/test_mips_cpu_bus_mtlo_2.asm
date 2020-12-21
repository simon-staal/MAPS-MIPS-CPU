addiu $t1, $zero, 0xba6a
mtlo $t1
mflo $v0
jr $zero
nop

#assert v0 == 0xffffba6a
