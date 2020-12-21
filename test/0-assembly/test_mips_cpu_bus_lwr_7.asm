lui $v1 0xbfc0
lw $v0 0x0028($v1)
sw $v0 0x0000($zero)
lwr $v0 0x0003($zero)
jr $zero
nop

# bcf0 0028 = caff0011
# assert(v0==caff00ca)
