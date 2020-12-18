lui v1 0xbfc0
lw t1 0x28(v1)
lw t2 0x2c(v1)
jr zero
SRAV $v0 $t1 $t2

# v0 = a >> b5 = 0
