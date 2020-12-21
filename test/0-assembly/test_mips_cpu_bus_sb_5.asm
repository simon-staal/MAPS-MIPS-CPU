lui $v1 0xbfc0
lw $v1 0x0028($v1)
sb $v1 0x0001($zero)
lw $v0 0x0000($zero)
jr $zero
nop

# bcf0 0028 = b00619ae
# assert(v0==0000ae00)
