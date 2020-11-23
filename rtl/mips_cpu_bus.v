module mips_cpu_bus(
    /* Standard signals */
    input logic clk,
    input logic reset,
    output logic active,
    output logic[31:0] register_v0,

    /* Avalon memory mapped bus controller (master) */
    output logic[31:0] address,
    output logic write,
    output logic read,
    input logic waitrequest,
    output logic[31:0] writedata,
    output logic[3:0] byteenable,
    output logic[31:0] readdata
  );

    typedef enum logic[5:0] {
        OPCODE_R = 6'b00000, // Register type instructions
        OPCODE_ADDIU = 6'b001001,
        OPCODE_ANDI = 6'b001100,

    } opdocde_t;

    typedef enum logic[5:0] {
        FUNCTION_ADDU = 6'b100001,
        FUNCTION_AND = 6'b100100,
    } function_t;
