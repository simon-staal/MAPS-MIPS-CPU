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
    /* Instruction formats:
    R-type: opcode (6) rs (5) rt (5) rd (5) shift (5) function (5)
    I-tyoe: opcode (6) rs (5) rt (5) imm (16)
    J-type: opcode (6) mem (26)

    Delay slots:
    Jump and branch instructions all have a "delay slot", meaning that the instruction
    after the branch or jump is executed before the branch or jump is executed. The
    processor should therefore execute the branch instruction and the delay slot instruction
    as an indivisible unit. You can think of jump / branch instructions as taking 2 instructions
    to complete; first the conditionals are calculated and stored, then the next instruction is
    executed (pc <= pc + 4) and the pc value is updated based on the jump or branch instruction.
    */
    typedef enum logic[5:0] {
        OPCODE_R = 6'b00000, // Register type instructions
        OPCODE_ADDIU = 6'b001001, //rt = rs + imm
        OPCODE_ANDI = 6'b001100, //rt = rs & imm (note: & represents bitwise and)
        OPCODE_BEQ = 6'b000100, //if(rs == rt) then pc <= pc + imm>>2
        OPCODE_REGIMM = 6'b00001,  //Behaviour depends on the rt field (see below)
        OPCODE_BGTZ = 6'b000111, //if(rs > 0) then pc <= pc + imm>>2 (rt == 00000)
        OPCODE_BLEZ = 6'b000110, //if(rs <= 0) then pc <= pc + imm>>2 (rt == 00000)
        OPCODE_BNE = 6'b000101, //if(rs != rt) then pc <= pc + imm>>2
        OPCODE_LHU = 6'b100101, // $rt = mem[rs+imm] ; dest=rt, source=base
        OPCODE_LUI = 6'b001111, // $rt = imm||0000000000000000 (rs == 00000)
        OPCODE_LW = 6'b100011, // $rt = mem[rs+imm] (note this is signed fullword)
        OPCODE_LWL = 6'b100010, // $rt = rt MERGE mem[base+imm] loads MSB (replaces 16 MSB of rt with the 16MSB of mem[base+imm])
        OPCODE_LWR = 6'b100110, // $rt = rt MERGE mem[base+imm] loads LSB (same as above but LSB)
        OPCODE_ORI=6'b001101,// does a bitwise logical or with constant rd<--rs or immediate
    		OPCODE_SB=6'b101000,//stores a byte to memory memory(base+offset)=rt?
    		OPCODE_SH=6'b101001,//store a halfword to memory memory(base+offset)=rt?
    		OPCODE_SLTI=6'b001010 // to record the result of a less than comparison with a conse rt=(rs<immediate)
        OPCODE_SLTIU=6'b001011 //to record the result of an unsigned less than comparison with a conse rt=(rs<immediate)
        OPCODE_SW = 6'b101011, // memory[base+offset] := $rt. Stores register rt in memory with an offset.
      	OPCODE_XORI = 6'b001110 // $rt := $rs XORI c. Logical XOR between $rs and constant c.
    } opcode_t;

    typedef enum logic[5:0] {
        FUNCTION_ADDU = 6'b100001, //rd = rs + rt (shift == 0)
        FUNCTION_AND = 6'b100100, //rd = rs & rt (shift == 0)
        FUNCTION_MTHI = 6'b010001, // $HI = $rs (rt, rd, shift == 0)
        FUNCTION_MTLO = 6'b100100, // $LO = $rs (rt, rd, shift == 0)
        FUNCTION_MULT = 6'b011000, // $(LO,HI) = $rs * $rt (rd, shift == 0)
        FUNCTION_MULTU = 6'b011001, // $(LO,HI) = $rs * $rt (rd, shift == 0)
        FUNCTION_OR= 6'b100101, // does bitwise logical OR rd<--rs OR rt
        FUNCTION_SLL=6'b000000, // to left shift a word by a fixed number of bits rd=rt<<sa (shift amt)
        FUNCTION_SLLV=6'b000100,// to left shift by a variable nb of bits rd=rt<<rs
        FUNCTION_SLT=6'b101010,// to record the result of a less than comparison rd=(rs<rt)
        FUNCTION_SLTU = 6'b101011, // $rd := $rs < $rt. Unsigned less-than comparison.
      	FUNCTION_SRA = 6'b000011, // $rd := rt >> c. Arithmetic shift right by c bits.
      	FUNCTION_SRAV = 6'b000111, // $rd := $rt >> $rs. Variable Arithmetic shift right, i.e. by a register variable.
      	FUNCTION_SRL = 6'b000010, // $rd := $rt >> c. Logical shift right by constant c bits.
      	FUNCTION_SRLV = 6'b000110, // $rd := $rt >> $rs. Variable logical shift right, i.e. by a register variable
      	FUNCTION_SUBU = 6'b100011, // $rd := $rs - $rt. Subtract 2 registers.
      	FUNCTION_XOR = 6'b100110 // $rd := $rs XOR $rt. Logical XOR between $rs and $rt.
    } function_t;

    //This logic is used for the rt field of instructions with the REGIMM opcode
    typedef enum logic[4:0] {
        BGEZ = 5'b00001, //if(rs >= 0) then pc <= pc + imm>>2
        BGEZAL = 5'b10001, //$ra <= pc + 8, if(rs >= 0) then pc <= pc + imm>>2 (places return address in $ra)
        BLTZ = 5'b00000, //if(rs < 0) then pc <= pc + imm>>2
        BLTZAL = 5'b10000 //$ra <= pc + 8, if(rs < 0) then pc <= pc + imm>>2
    } REGIMM_t

    //TODO: discuss logic for FSM and implement
    typedef enum logic[3:0] {
        FETCH = 3'b000,
        EXEC = 3'b001,
        MEM_ACCESS = 3'b010,
        WRITE_BACK = 3'b011,
        HALTED = 3'b111
    } state_t;

    logic[31:0] pc;
    logic[31:0] ir;
    logic ir_write;

    //Divide intruction into seperate signals
    logic[31:0] instr;
    opcode_t intr_opcode;
    function_t instr_function;
    logic[4:0] rs, rt, rd, shift;
    logic[15:0] instr_imm;
    logic[25:0] instr_index;

    assign instr = (state==FETCH) ? readdata : ir;
    assign intr_opcode = instr[31:26];
    assign rs = instr[25:21];
    assign rt = instr[20:16];
    assign rd = instr[15:11];
    assign instr_function = instr[5:0];
    assign instr_imm = instr[15:0];
    assign instr_index = intr[25:0];

    logic[31:0] reg_writedata, reg_readdata1, reg_readdata2;
    logic reg_write_en;

    logic [32][31:0] regs;
    mips_cpu_reg_file reg(clk, reset, rs, rt, rd, reg_writedata, reg_write_en, reg_readdata1, reg_readdata2);


    initial begin
        state = HALTED;
        active = 0;
    end
endmodule
