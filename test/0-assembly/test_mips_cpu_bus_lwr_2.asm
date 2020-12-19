lui $v1 0xBFC0
lwl $v0 0x0028($v1)
lwr $v0 0x002D($v1)
jr $zero
sll $zero, $zero, 0x0000

#BCF00028=ff4a5250
#BCF0002C=5a1234ec
#assert(v0==505a1234)
