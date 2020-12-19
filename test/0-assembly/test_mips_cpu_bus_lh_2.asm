lui $v1 0xBFC0
lh $v0 0x002A($v1)
jr $zero
nop

#BCF00028=ea7a4d31
#assert(v0==ffffea7a)
