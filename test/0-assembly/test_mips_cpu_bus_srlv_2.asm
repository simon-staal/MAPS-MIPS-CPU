lui v1 0xbfc0
lw t1 0x28(v1)
lw t2 0x2c(v1)
jr zero
SRLV v0 t1 t2

# v0 = 5 >> 192 = 6
