lui v1 0xbfc0
lw t1 0x28(v1)
lw t2 0x2c(v1)
jr zero
and v0 t1 t2

# assert(register_v0==32'hc0844081)
