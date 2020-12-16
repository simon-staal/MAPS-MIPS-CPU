lui v1 0xbfc0
lw t1 0x28(v1)
jr zero
addu v0 t1 t1

# assert(register_v0==32'h05ED8BEE)
