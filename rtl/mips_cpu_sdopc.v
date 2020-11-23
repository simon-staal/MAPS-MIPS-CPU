/* Instruction formats:
R-type: opcode (6) source1 (5) source2 (5) dest (5) shift (5) function (5)
I-tyoe: opcode (6) source (5) dest (5) imm (16)
J-type: opcode (6) mem (26)
*/
typedef enum logic[5:0] {
    OPCODE_LHU = 6'b100101,
    OPCODE_LUI = 6'b001111,
    OPCODE_LW = 6'b100011,
    OPCODE_LWL = 6'b100010,
    OPCODE_LWL = 6'b100010,
    OPCODE_LWR = 6'b100110,

} opcode_t;

typedef enum logic[5:0] {
    FUNCTION_MTHI = 6'b010001,
    FUNCTION_MTLO = 6'b100100,
    FUNCTION_MULT = 6'b011000,
    FUNCTION_MULTU = 6'b011001,

} function_t;
