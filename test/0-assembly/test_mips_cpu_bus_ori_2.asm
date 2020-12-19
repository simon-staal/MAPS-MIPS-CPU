lui v1 0xbfc0
lw t1 0x28(v1)
jr zero
ori v0 t1 0xffff

# assert(register_v0==32'hBABAffff)

