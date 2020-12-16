lui v1 0xbfc0
lw t1 0x28(v1)
jr zero
SRA $v0 $t1 0x5

# v0 = t1 >> 5 = 6
