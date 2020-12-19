LUI $v1 0xBFC0
LW $t0 0x0028($v1)
JALR $zero $t0
nop
jr $zero
addiu $v0 $v0 0x1

0x50: jr $zero
      addiu $v0 $zero 0x0

mem location from line 2: BFC00050

assert v0 = bfc00012
