lui $v1 0xbfc0
lw $t1 0x0028($v1)
sb $t1 0x002F($v1)
lw $v0 0x002C($v1)
jr $zero
nop

# bcf0 0028 = 3456bcba
# assert(v0==ba000000)
