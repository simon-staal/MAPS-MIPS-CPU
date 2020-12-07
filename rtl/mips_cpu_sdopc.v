/* Instruction formats:
R-type: opcode (6) source1 (5) source2 (5) dest (5) shift (5) function (5)
I-tyoe: opcode (6) source (5) dest (5) imm (16)
J-type: opcode (6) mem (26)
*/
typedef enum logic[5:0] {
    OPCODE_LHU = 6'b100101, // $rt = mem[base+imm] ; dest=rt, source=base
    OPCODE_LUI = 6'b001111, // $rt = imm||0000000000000000
    OPCODE_LW = 6'b100011, // $rt = mem[base+imm] (note this is signed fullword)
    OPCODE_LWL = 6'b100010, // $rt = rt MERGE mem[base+imm] loads MSB
    OPCODE_LWR = 6'b100110, // $rt = rt MERGE mem[base+imm] loads LSB
} opcode_t;

typedef enum logic[5:0] {
    FUNCTION_MTHI = 6'b010001, // $HI = $rs
    FUNCTION_MTLO = 6'b100100, // $LO = $rs
    FUNCTION_MULT = 6'b011000, // $(LO,HI) = $rs * $rt
    FUNCTION_MULTU = 6'b011001, // $(LO,HI) = $rs * $rt
} function_t;

/*
Load instructions transfer information from the memory to the GPRs in the CPU
Address of halfword or word is the smallest byte of the object
Big-endian encoding use so it will be the MSB byte adress
Address not an even multiple of the object size read -> Address Error exception
*/
