lui $v1 0xBFC0
lh $v0 0x0028($v1)
jr $zero
nop 

#BCF00028=ea7a4d31
#assert(v0==00004d31)
