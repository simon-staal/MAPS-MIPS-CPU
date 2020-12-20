lui $v1 0xBfc0
lw $v0 0x0028($v1)
lwl $v0 0x002d($v1)
jr $zero
sll $zero, $zero, 0x0000

#BCF00028=076d589c
#BCF0002C=1a2b3e1f
#assert(v0==3e1f589c)
