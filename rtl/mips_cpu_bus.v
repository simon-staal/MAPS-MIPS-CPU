`include "mips_cpu_definitions.v"

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
    input logic[31:0] readdata
    );

    //Creates basic registers
    logic[31:0] pc, pc_increment;
    assign pc_increment = pc + 4;
    logic[31:0] ir;
    logic ir_write;

    //Divide intruction into seperate signals
    logic[31:0] instr;
    opcode_t instr_opcode;
    function_t instr_function;
    logic[4:0] rs, rt, rd, shift;
    logic[15:0] instr_imm;
    logic[25:0] instr_index;

    assign instr = (state==FETCH) ? readdata : ir;
    assign intr_opcode = instr[31:26];
    assign rs = instr[25:21];
    assign rt = instr[20:16];
    assign rd = instr[15:11];
    assign shift = instr[10:6];
    assign instr_function = instr[5:0];
    assign instr_imm = instr[15:0];
    assign instr_index = intr[25:0];

    //Register file
    logic[31:0] reg_writedata, reg_readdata1, reg_readdata2;
    logic reg_write_en;

    mips_cpu_reg_file reg(clk, reset, rs, rt, rd, reg_writedata, reg_write_en, reg_readdata1, reg_readdata2);

    //Stores values for branch / jmp instructions
    logic[31:0] pc_jmp;
    logic delay;

    //Used for 2 cycle memory access instructions (stores) for waitrequest logic in controlling pc
    logic mem_access;

    initial begin
        state = HALTED;
        active = 0;
    end
endmodule
