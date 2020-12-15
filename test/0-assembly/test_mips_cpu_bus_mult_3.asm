lui $v1, 0xBCF0
lw $t1, 0x0028($v1)
lw $t2, 0x002C($v1)
mult $t1, $t2
mfhi $v0
mflo $v1
add $v0, $v0, $v1
jr $zero
sll $zero, $zero, 0x0000

#BCF0 0028 = 5AFEEF01
#BCF0 002C = 27B26150
#assert v0 = 0x6c084f92
