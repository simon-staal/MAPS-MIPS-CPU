lui $v1 0xBFC0
lhu zero 0x0028($v1)
jr $zero
addiu v0 zero 0x0

#BCF00028=ea7a4d31
#assert(v0==00000000)
