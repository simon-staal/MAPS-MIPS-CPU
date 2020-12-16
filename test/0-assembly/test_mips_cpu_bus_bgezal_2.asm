lui v1 0xbfc0
lw t0 0x28(v1)
bgezal t0 0x11
nop
jr zero
addiu v0 ra 0x2

0x50: addiu v0 ra 0x1
      jr zero
      nop

assert(register_v0==32'hbfc00012)
