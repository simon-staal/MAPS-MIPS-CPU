lui v1 0xbfc0
lw t4 0x28(v1)
lw t5 0x2c(v1)
jr zero
addu v0 t4 t5

# assert(register_v0==32'h2682290e)
