lui v1 0xbfc0
bgez v1 0x13
nop (sll zero zero 0x0)
jr zero
lw v0 0x28(v1)

0x50: jr zero
      lw v0 0x2c(v1)

# assert(register_v0==32'he3c863c7)
