lui t1 0x0ae2
bgtz t1 0x27
lui v1 0xbfc0
lw v0 0x28(v1)
jr zero
nop

0x54: jr zero
      addiu v0 v0 0x1

0xa4: bgtz t1 0xfffeb (-20)
      addiu v0 v0 0x2
      jr zero
      addiu v0 v0 0x5

assert(register_v0==32'h00000003)
