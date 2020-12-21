lui $v1 0xbfc0
lw $v0 0x0028($v1)
sw $v0 0x0000($zero)
lwl $v0 0x0002($zero)
jr $zero
nop

# bcf0 0028 = caff0011
# assert(v0==ff001111)
