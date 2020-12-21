lui $v1 0x7a1a
sw $v1 0x0000($zero)
lw $v0 0x0000($zero)
jr $zero
nop
assert(v0==7a1a0000)
