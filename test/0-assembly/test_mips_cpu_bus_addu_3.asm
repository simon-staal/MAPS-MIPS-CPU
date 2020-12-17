lui v1 0xbfc0
lw t1 0x28(v1)
jr zero
addu v0 zero t1

# assert(register_v0==32'h9F6875BB)
