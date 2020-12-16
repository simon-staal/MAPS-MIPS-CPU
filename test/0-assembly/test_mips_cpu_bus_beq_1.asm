beq v0 v1 0x14
lui v1 0xbfc0
lw v0 0x28(v1)
jr zero
nop

0x50: lw v0 0x2c(v1)
      jr zero
      nop

assert(register_v0==32'h1ca759fe)
