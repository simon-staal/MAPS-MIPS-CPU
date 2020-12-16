bltzal v0 0x13
lui v1 0xbfc0
jr zero
addiu v0 ra 0x2

0x50: addiu v0 ra 0x1
      jr zero
      nop

assert(register_v0==32'hbfc0000a)
