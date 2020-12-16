lui t1 0x7fa3
bgtz t1 0x12
lui v1 0xbfc0
jr zero
lw v0 0x28(v1)

0x50: jr zero
      lw v0 0x2c(v1)

# assert(register_v0==32'he3c863c7)
