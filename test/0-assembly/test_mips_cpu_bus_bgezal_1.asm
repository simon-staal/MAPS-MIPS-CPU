bgezal v0 0x13
lui v1 0xbfc0
jr zero
lw v0 0x28(v1)

0x50: addiu v0 ra 0x1
      jr zero      
      nop

assert(register_v0==32'hbfc00009)
