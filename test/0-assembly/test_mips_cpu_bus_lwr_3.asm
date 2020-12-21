lui $v1 0xbfc0
beq zero zero 0x26 (line 41)
addiu v1 v1 0xa00 (v1 now at 2560 past reset vector = line 641)
jr $zero
nop

0xa0: lw $v0 0xF628($v1) (should go back to line 11)
      jr $zero
      lwr v0  0xF62c($v1) (line 12, byte 1)

assert v0 = 6d36d673
