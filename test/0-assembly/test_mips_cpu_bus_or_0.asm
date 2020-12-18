lui v1 0xbfc0
    lw t1 0x28(v1)
    jr zero (jumps to address==0)
     or v0 t1 $zero
     # assert(register_v0==32'h00000000)
