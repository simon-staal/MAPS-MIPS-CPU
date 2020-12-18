lui t2 0xfabc
bltzal t2 0x27
addiu v0 ra 0x1
lw v0 0x28(v1)
jr zero
nop

0x54: jr zero
      addiu v0 v0 0x1

0xa4: bltzal t1 0xfffeb (-20) (won't jump)
      addiu v0 ra 0x5
      jr zero
      addiu v0 v0 0x5

assert(register_v0==32'hbfc000b6)
