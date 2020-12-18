lui v1 0xbfc0
lw t1 0x28(v1)
lw t2 0x2c(v1)
jr zero
SLTU $v0 $t2 $t1

# v0 = 05 SLTU 192 = 1
