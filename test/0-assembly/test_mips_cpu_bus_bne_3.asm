lui v1 0xbfc0
lw t1 0x28(v1)
lw t2 0x2c(v1)
bne t2 t1 0x10
nop (sll zero zero 0x0)
lw v0 0x30(v1)
jr zero
nop

0x50: lw v0 0x34(v1)
      jr zero

# assert(register_v0==32'h26095e87)
