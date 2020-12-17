JAL 0x3F00014
nop
JR $zero
ADDIU $v0 $ra 0x0002

0x50: jr $zero
      addiu $v0 $ra 0x1


assert v0 = bfc00009
