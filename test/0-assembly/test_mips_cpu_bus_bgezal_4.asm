bgezal v0 0x27
addiu v0 ra 0x1
lw v0 0x28(v1)
jr zero
nop

0x50: jr zero
      addiu v0 v0 0x1

0xa0: bgezal v0 0xfffeb (-20) (note v0 is now negative)
      addiu v0 ra 0x5
      jr zero
      addiu v0 v0 0x5

assert(register_v0==32'hbfc000b2)
