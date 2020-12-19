lui $v1 0xbfc0
beq zero zero 0x26 (line 41)
addiu v1 v1 0xa00 (v1 now at 2560 past reset vector = line 641)
jr $zero
nop

0xa0: lb $v0 0xF62B($v1) (should go back to line 11)
      jr $zero
      nop
