lui $v1 0xbfc0
lw $t1 0x0028($v1)
sh $t1 0x002C($v1)
lw $v0 0x002C($v1)
jr $zero
nop

# bcf0 0028 = 1a2b3c4d
# assert(v0==00003c4d)
