JAL 0x3F00018
nop
JR $zero
ADDIU $v0 $ra 0x0003

line 24: jr $zero
      addiu $v0 $ra 0x2


assert v0 = bfc0000a
