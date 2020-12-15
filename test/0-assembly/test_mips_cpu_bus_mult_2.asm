lui $v1, 0xBCF0
lw $t1, 0x0028($v1)
lw $t2, 0x002C($v1)
mult $t1, $t2
mflo $v0
jr $zero
sll $zero, $zero, 0x0000

#BCF0 0028 = 123ABC76
#BCF0 002C = 3EED6DB2
#assert v0 = 0xbc53480c
