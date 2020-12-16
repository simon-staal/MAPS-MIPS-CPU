lui v1 0xbfc0
lw t1 0x28(v1)
jr zero
andi v0 t1 0x34AE

# assert(register_v0==32'h000030AE)
