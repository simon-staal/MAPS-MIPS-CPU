lui v1 0xbfc0
lw t1 0x28(v1)
lw t2 0x2c(v1)
and zero t1 t2
jr zero
and v0 zero zero

# assert(register_v0==32'h00000000)
