lui v1 0xbfc0
lw t1 0x28(v1)
blez t1 0x11
nop (sll zero zero 0x0)
jr zero
lw v0 0x30(v1)

0x50: jr zero
      lw v0 0x34(v1)

# assert(register_v0==32'hbefaccb3)
