lui $v1 0xBFC0
lw $v0 0x0028($v1)
lwr $v0 0x002A($v1)
jr $zero
sll $zero, $zero, 0x0000

#BCF00028=0xdad1baba
#assert(v0==dad1dad1)
