lui v1 0xbfc0
lw t1 0x28(v1)
jr zero
sltiu v0 t1 0xFFFF

# assert(register_v0==32'h00000001)
