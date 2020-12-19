lui v1 0xbfc0
    lw t1 0x28(v1)
    xor zero t1 $zero
    jr zero (jumps to address==0)
    addiu v0 zero 0x0
     # assert(register_v0==32'h00000000)
