lui $v1 0xBCF0
lwr $v0 0x002A($v1)
jr $zero
sll $zero, $zero, 0x0000

#BCF00028=ad4d6ee9
#assert(v0==0000ad4d)
