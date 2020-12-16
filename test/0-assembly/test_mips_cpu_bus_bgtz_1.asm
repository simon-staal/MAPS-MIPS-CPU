bgtz v0 0x13
lui v1 0xbfc0
jr zero
lw v0 0x28(v1)

0x50: jr zero
      lw v0 0x2c(v1)

assert(register_v0==32'ha0345f7d)
