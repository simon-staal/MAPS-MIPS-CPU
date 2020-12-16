addiu $t1, $zero, 0x4EEB
mtlo $t1
mflo $v0
jr $zero
sll $zero, $zero, 0x0000

#assert v0 == 0x00004eeb
