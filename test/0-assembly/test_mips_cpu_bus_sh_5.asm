lui $v1 0xbfc0
lw $v1 0x0028($v1)
sh $v1 0x0002($zero)
lw $v0 0x002C($zero)
jr $zero
nop

# bcf0 0028 = 1a2b3c4d
# assert(v0==3c4d0000)
