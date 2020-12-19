lui $v1 0xbfc0
lw $t1 0x0028($v1)
sh $t1 0x002E($v1)
lw $v0 0x002C($v1)
jr $zero
nop

# bcf0 0028 = 111111cc
# assert(v0==11cc0000)
