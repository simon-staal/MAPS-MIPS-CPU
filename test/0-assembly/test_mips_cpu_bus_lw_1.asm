lw $v0 0x0003($zero)
jr $zero
sll $v1 $zero 0x0000
0x01234567

#assert v0 == 0x01234567
