LUI $v1 0xBFC0
LW $t0 0x0028 $v1
JALR $ra $t0
ADDIU $ra $ra 0x0001
ADDIU $ra $ra 0x0001
ADD   $v0 $v0 $ra
JR $zero




mem location from line 2: BFC00005

assert v0 = 0000000A