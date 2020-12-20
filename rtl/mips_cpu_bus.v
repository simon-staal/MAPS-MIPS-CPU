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
        OPCODE_J = 6'b000010, //jumps to specified target instr_index.
        OPCODE_JAL = 6'b000011, //stores next instruction address in GPR (during procedure call,) executes subroutine.
        OPCODE_LB = 6'b100000, //load a byte from memory to rt as a signed value
        OPCODE_LBU = 6'b100100, //same thing but as an unsigned value
        OPCODE_LH = 6'b100001, //load a halfword as a signed value (to rt)
        OPCODE_LHU = 6'b100101, // $rt = mem[rs+imm] ; dest=rt, source=base
        OPCODE_LUI = 6'b001111, // $rt = imm||0000000000000000 (rs == 00000)
        OPCODE_LW = 6'b100011, // $rt = mem[rs+imm] (note this is signed fullword)
        OPCODE_LWL = 6'b100010, // $rt = rt MERGE mem[base+imm] loads MSB (replaces 16 MSB of rt with the 16MSB of mem[base+imm])
        OPCODE_LWR = 6'b100110, // $rt = rt MERGE mem[base+imm] loads LSB (same as above but LSB)
        OPCODE_ORI = 6'b001101, // does a bitwise logical or with constant rt<--rs | immediate
        OPCODE_SB = 6'b101000,//stores a byte to memory memory(base+offset) = rt?
        OPCODE_SH = 6'b101001, //store a halfword to memory memory(base+offset)=rt?
        OPCODE_SLTI = 6'b001010, // to record the result of a less than comparison with a const rt=(rs<immediate)
        OPCODE_SLTIU = 6'b001011, //to record the result of an unsigned less than comparison with a conse rt=(rs<immediate)
        OPCODE_SW = 6'b101011, // memory[base+offset] := $rt. Stores register rt in memory with an offset.
        OPCODE_XORI = 6'b001110 // $rt := $rs XORI c. Logical XOR between $rs and constant c.
    } opcode_t;

    typedef enum logic[5:0] {
        FUNCTION_ADDU = 6'b100001, //rd = rs + rt (shift == 0)
        FUNCTION_AND = 6'b100100, //rd = rs & rt (shift == 0)
        FUNCTION_DIV=6'b011010, //divides two 32bit signed integers, rs, rt. quotient to LO, Remainder to HI
        FUNCTION_DIVU=6'b011011, //same thing, for unsigned integers.
        FUNCTION_JALR = 6'b001001, //Jumps to RS, return adress stored in RD.
        FUNCTION_JR = 6'b001000, //branch to an Instruction address in rs, presumably after FUNCTION_JALR
        FUNCTION_MTHI = 6'b010001, // $HI = $rs (rt, rd, shift == 0)
        FUNCTION_MTLO = 6'b010011, // $LO = $rs (rt, rd, shift == 0)
        FUNCTION_MFHI = 6'b010000, // $rd = $HI
        FUNCTION_MFLO = 6'b010010, // $rd = $LO
        FUNCTION_MULT = 6'b011000, // $(LO,HI) = $rs * $rt (rd, shift == 0)
        FUNCTION_MULTU = 6'b011001, // $(LO,HI) = $rs * $rt (rd, shift == 0)
        FUNCTION_OR = 6'b100101, // does bitwise logical OR rd<--rs OR rt (shift == 0)
        FUNCTION_SLL = 6'b000000, // to left shift a word by a fixed number of bits rd=rt<<sa (shift amt) (rs == 0)
        FUNCTION_SLLV = 6'b000100, // to left shift by the 5 LSB of rs rd=rt<<rs[4:0] (shift == 0)
        FUNCTION_SLT = 6'b101010, // to record the result of a less than comparison rd=(rs<rt) (shift == 0)
        FUNCTION_SLTU = 6'b101011, // $rd := $rs < $rt. Unsigned less-than comparison.
        FUNCTION_SRA = 6'b000011, // $rd := rt >> shift. Arithmetic shift right by shift bits. (rs == 00000)
        FUNCTION_SRAV = 6'b000111, // $rd := $rt >> $rs[4:0]. Variable Arithmetic shift right, i.e. by a register variable. (shift == 00000)
        FUNCTION_SRL = 6'b000010, // $rd := $rt >> shift. Logical shift right by constant shift bits. (rs == 00000)
        FUNCTION_SRLV = 6'b000110, // $rd := $rt >> $rs[4:0]. Variable logical shift right, i.e. by a register variable (shift == 00000)
        FUNCTION_SUBU = 6'b100011, // $rd := $rs - $rt. Subtract 2 registers. (shift == 0)
        FUNCTION_XOR = 6'b100110 // $rd := $rs XOR $rt. Logical XOR between $rs and $rt.
    } function_t;

    //This logic is used for the rt field of instructions with the REGIMM opcode
    typedef enum logic[4:0] {
        BGEZ = 5'b00001, //if(rs >= 0) then pc <= pc + imm>>2
        BGEZAL = 5'b10001, //$ra <= pc + 8, if(rs >= 0) then pc <= pc + imm>>2 (places return address in $ra)
        BLTZ = 5'b00000, //if(rs < 0) then pc <= pc + imm>>2
        BLTZAL = 5'b10000 //$ra <= pc + 8, if(rs < 0) then pc <= pc + imm>>2
    } REGIMM_t;

    //TODO: discuss logic for FSM and implement
    typedef enum logic[2:0] {
        FETCH = 3'b000,
        EXEC = 3'b001,
        MEM_ACCESS = 3'b010,
        HALTED = 3'b111
    } state_t;

    /* Defines an array of 32 registers used by MIPS with the following purposes:
    $zero (0): constant 0
    $at (1): assembler temporary
    $v0-$v1 (2-3): values for function returns and expression evaluation
    $a0-$a3 (4-7): function arguments
    $t0-$t7 (8-15): temporaries
    $s0-$s7 (16-23): saved temporaries
    $t8-$t9 (24-25): temporaries
    $k0-$k1 (26-27): reserved for OS kernel
    $gp (28): global pointer
    $sp (29): stack pointer
    $fp (30): frame pointer
    $ra (31): return address
    */
    reg signed [31:0] regs [31:0];
    assign register_v0 = regs[2];

    //Creates basic registers (pc and ir)
    logic[31:0] pc, pc_increment;
    assign pc_increment = pc + 4;
    logic[31:0] ir;

    //Indicates whether the CPU is experiencing a stall cycle due to memory
    logic stall;

    //Create non GPR HI and LO registers
    logic[31:0] HI;
    logic[31:0] LO;
    //Intermediary logic for mult operations
    logic[63:0] mult_temp, multu_temp;
    assign mult_temp = ((state==EXEC)&&((instr_opcode==OPCODE_R)&&(instr_function==FUNCTION_MULT))) ? (regs[rs]*regs[rt]) : 0;
    assign multu_temp = ((state==EXEC)&&((instr_opcode==OPCODE_R)&&(instr_function==FUNCTION_MULTU))) ? ($unsigned(regs[rs])*$unsigned(regs[rt])) : 0;

    //Intermediary signals to process instructions
    logic[31:0] instr;
    opcode_t instr_opcode;
    function_t instr_function;
    state_t state;
    logic[4:0] rs, rt, rd, shift;
    logic[15:0] instr_imm;
    logic[25:0] instr_index;

    assign instr = (state==EXEC && stall==0) ? readdata : ir;
    assign instr_opcode = instr[31:26];
    assign rs = instr[25:21];
    assign rt = instr[20:16];
    assign rd = instr[15:11];
    assign shift = instr[10:6];
    assign instr_function = instr[5:0];
    assign instr_imm = instr[15:0];
    assign instr_index = instr[25:0];

    //Stores values for branch / jmp instructions
    logic[31:0] pc_jmp;
    logic delay; //Indicates delay slot instruction

    //Used to indicate memory access in EXEC to control waitrequest
    logic mem_access;
    assign mem_access = ((instr_opcode==OPCODE_SW)||(instr_opcode==OPCODE_SB)||(instr_opcode==OPCODE_SH)||(instr_opcode==OPCODE_LB)||(instr_opcode==OPCODE_LBU)||(instr_opcode==OPCODE_LHU)||(instr_opcode==OPCODE_LH)||(instr_opcode==OPCODE_LW)||(instr_opcode==OPCODE_LWL)||(instr_opcode==OPCODE_LWR));

    //Intermediary logic for aligning addresses
    logic [31:0] address_calc;
    assign address_calc = $unsigned(regs[rs]) + {{16{instr_imm[15]}}, (instr_imm)};
    logic [1:0] alignment;
    assign alignment = address_calc[1:0];

    //Intermediary logic for SB and SH
    logic [31:0] regs_byte, regs_hw;
    assign regs_byte = (state==EXEC)&&(instr_opcode==OPCODE_SB)? {4{regs[rt][7:0]}} : 0;
    assign regs_hw = (state==EXEC)&&(instr_opcode==OPCODE_SH)?  {2{regs[rt][15:0]}} : 0;

    integer i;
    initial begin
        state = HALTED;
        active = 0;
        delay = 0;
        stall = 0;
        for(i = 0; i < 32; i++) begin
          regs[i] = 0;
        end
    end

    //Combinatorial loop to manage the outputs of the CPU
    always_comb begin
        if(state == FETCH) begin
            byteenable = 4'b1111;
            read = 1;
            write = 0;
            address = pc;
        end
        if(state == EXEC || state == MEM_ACCESS) begin
      			if(instr_opcode==OPCODE_SW) begin
              if(alignment==2'b00) begin
        				byteenable = 4'b1111;
              end
              else begin //Unaligned memory
                byteenable = 4'b0000;
              end
              write = 1;
      				read = 0;
              address = address_calc & 32'hFFFFFFFC;
              writedata = regs[rt];
      			end
            else if(instr_opcode==OPCODE_SB) begin
              case(alignment)
                2'b00: begin
                  writedata = 32'h000000FF&regs_byte;
                  byteenable = 4'b0001;
                end
                2'b01: begin
                  writedata = 32'h0000FF00&regs_byte;
                  byteenable = 4'b0010;
                end
                2'b10: begin
                  writedata = 32'h00FF0000&regs_byte;
                  byteenable = 4'b0100;
                end
                2'b11: begin
                  writedata = 32'hFF000000&regs_byte;
                  byteenable = 4'b1000;
                end
              endcase
              write = 1;
              read = 0;
              address = address_calc & 32'hFFFFFFFC;
            end
            else if(instr_opcode==OPCODE_SH) begin
              if(alignment==2'b00) begin
                byteenable = 4'b0011;
                writedata = 32'h0000FFFF&regs_hw;
              end
              else if(alignment==2'b10) begin
                byteenable = 4'b1100;
                writedata = 32'hFFFF0000&regs_hw;
              end
              else begin //Writing to unaligned memory, do nothing
                byteenable = 4'b0000;
              end
              write = 1;
              read = 0;
              address = address_calc & 32'hFFFFFFFC;
            end
            else if(instr_opcode==OPCODE_LB) begin
              read = 1;
              write = 0;
              case(alignment)
                2'b00: byteenable = 4'b0001;
                2'b01: byteenable = 4'b0010;
                2'b10: byteenable = 4'b0100;
                2'b11: byteenable = 4'b1000;
              endcase
              address = address_calc & 32'hFFFFFFFC;
            end
            else if(instr_opcode==OPCODE_LBU) begin
              read = 1;
              write = 0;
              case(alignment)
                2'b00: byteenable = 4'b0001;
                2'b01: byteenable = 4'b0010;
                2'b10: byteenable = 4'b0100;
                2'b11: byteenable = 4'b1000;
              endcase
              address = address_calc & 32'hFFFFFFFC;
            end
            else if(instr_opcode==OPCODE_LH) begin
              read = 1;
              write = 0;
              //alignment==00 or 01 --> LSHalfword, 10 or 11 --> MSHalfword
              if(alignment==2'b00) begin
                byteenable = 4'b0011;
              end
              else if(alignment==2'b10) begin
                byteenable = 4'b1100;
              end
              //Accessing unaligned memory, do nothing
              else begin
                byteenable = 4'b0000;
              end
              address = address_calc & 32'hFFFFFFFC;
            end
            else if(instr_opcode==OPCODE_LHU) begin
              read = 1;
              write = 0;
              //alignment==00 or 01 --> LSHalfword, 10 or 11 MSHalfword
              if(alignment==2'b00) begin
                byteenable = 4'b0011;
              end
              else if(alignment==2'b10) begin
                byteenable = 4'b1100;
              end
              //Accessing unaligned memory, do nothing
              else begin
                byteenable = 4'b0000;
              end
              address = address_calc & 32'hFFFFFFFC;
            end
            else if(instr_opcode==OPCODE_LW) begin
              read = 1;
              write = 0;
              if(alignment==2'b00) begin
                byteenable = 4'b1111;
              end
              else begin
                byteenable = 4'b0000;
              end
              address = address_calc & 32'hFFFFFFFC;
            end
            else if(instr_opcode==OPCODE_LWL) begin
              read = 1;
              write = 0;
              case(alignment)
                2'b00: byteenable = 4'b0001;
                2'b01: byteenable = 4'b0011;
                2'b10: byteenable = 4'b0111;
                2'b11: byteenable = 4'b1111;
              endcase
              address = address_calc & 32'hFFFFFFFC;
            end
            else if(instr_opcode==OPCODE_LWR) begin
              read = 1;
              write = 0;
              case(alignment)
                2'b00: byteenable = 4'b1111;
                2'b01: byteenable = 4'b1110;
                2'b10: byteenable = 4'b1100;
                2'b11: byteenable = 4'b1000;
              endcase
              address = address_calc & 32'hFFFFFFFC;
            end
            else begin //Default behaviour
              read = 0;
              write = 0;
              byteenable = 4'b000;
              address = 32'hXXXXXXXX;
            end
        end
    end

    //Sequential loop to manage computer state and registers
    always @ (posedge clk) begin
        if(reset) begin
            state <= FETCH;
            active <= 1;
            pc <= 32'hBFC00000;
            for(i = 0; i < 32; i++) begin
              regs[i] <= 0;
            end
        end
        else if(address == 32'h00000000) begin
            state <= HALTED;
            active <= 0;
        end
        else if(state == FETCH) begin
            state <= (waitrequest) ? FETCH : EXEC;
        end
        else if(state == EXEC) begin
            ir <= (stall) ? ir : readdata;
            assert(regs[0]==32'h00000000) else $fatal(2, "$zero is no longer 0");
            state <= (waitrequest && mem_access) ? EXEC : ((instr_opcode==OPCODE_LB)||(instr_opcode==OPCODE_LBU)||(instr_opcode==OPCODE_LHU)||(instr_opcode==OPCODE_LH)||(instr_opcode==OPCODE_LW)||(instr_opcode==OPCODE_LWL)||(instr_opcode==OPCODE_LWR)) ? MEM_ACCESS : FETCH;
            pc <= (waitrequest && mem_access) ? pc : (delay) ? pc_jmp : pc_increment;
            delay <= (waitrequest && mem_access) ? delay : (delay) ? 0 : delay; //Resets the value of delay
            stall <= (waitrequest && mem_access);
            case(instr_opcode)
              OPCODE_R: begin
                case(instr_function)
                  FUNCTION_ADDU: begin
                    assert(shift == 5'b00000) else $fatal(2, "CPU : ERROR : Invalid instruction %b at pc %h", instr, pc);
                    regs[rd] <= (rd == 0) ? 0 : $unsigned(regs[rs]) + $unsigned(regs[rt]);
                  end
                  FUNCTION_AND: begin
                    assert(shift == 5'b00000) else $fatal(2, "CPU : ERROR : Invalid instruction %b at pc %h", instr, pc);
                    regs[rd] <= (rd == 0) ? 0 : regs[rs] & regs[rt];
                  end
                  FUNCTION_DIV: begin
            		    assert({rd,shift} == 10'b00000) else $fatal(2, "CPU : ERROR : Invalid instruction %b at pc %h", instr, pc);
                    LO <= (regs[rs]/regs[rt]);
            		    HI <= (regs[rs]%regs[rt]);
            		  end
            		  FUNCTION_DIVU: begin
                    assert({rd,shift} == 10'b00000) else $fatal(2, "CPU : ERROR : Invalid instruction %b at pc %h", instr, pc);
                    LO <= ($unsigned(regs[rs])/$unsigned(regs[rt]));
            		    HI <= ($unsigned(regs[rs])%$unsigned(regs[rt]));
            		  end
                  FUNCTION_JALR: begin
                    assert({rt,shift} == 10'b00000) else $fatal(2, "CPU : ERROR : Invalid instruction %b at pc %h", instr, pc);
            		    assert(delay == 0) else $fatal(2, "CPU : ERROR : Branch / Jump instruction %b in delay slot at pc %h", instr, pc);
                    assert(rs != rd) else $fatal(2, "CPU : ERROR : Invalid instruction %b at pc %h, rs cannot equal rd for JALR", instr, pc);
                    regs[rd] <= (rd == 0) ? 0 : pc + 8;
            		    pc_jmp <= regs[rs];
            		    delay <= 1;
            		  end
            		  FUNCTION_JR: begin
                    assert({rt,rd,shift} == 15'b00000) else $fatal(2, "CPU : ERROR : Invalid instruction %b at pc %h", instr, pc);
            		    assert(delay == 0) else $fatal(2, "CPU : ERROR : Branch / Jump instruction %b in delay slot at pc %h", instr, pc);
            		    pc_jmp <= regs[rs];
            		    delay <= 1;
            		  end
                  FUNCTION_MTHI:begin
                    assert(({rd,rt,shift}==15'h0000)) else $fatal(2, "CPU : ERROR: Invalid instruction %b at pc %h", instr, pc);
                    HI <= regs[rs];
                  end
                  FUNCTION_MTLO:begin
                    assert(({rd,rt,shift}==15'h0000)) else $fatal(2, "CPU : ERROR: Invalid instruction %b at pc %h", instr, pc);
                    LO <= regs[rs];
                  end
                  FUNCTION_MULT:begin
                    assert(({rd,shift}==10'h000)) else $fatal(2, "CPU : ERROR: Invalid instruction %b at pc %h", instr, pc);
                    LO <= mult_temp[31:0];
                    HI <= mult_temp[63:32];
                  end
                  FUNCTION_MULTU:begin
                    assert(({rd,shift}==10'h000)) else $fatal(2, "CPU : ERROR: Invalid instruction %b at pc %h", instr, pc);
                    LO <= multu_temp[31:0];
                    HI <= multu_temp[63:32];
                  end
                  FUNCTION_MFHI:begin
                    assert(({rs,rt,shift}==15'h0000)) else $fatal(2, "CPU : ERROR: Invalid instruction %b at pc %h", instr, pc);
                    regs[rd] <= (rd == 0) ? 0 : HI;
                  end
                  FUNCTION_MFLO:begin
                    assert(({rs,rt,shift}==15'h0000)) else $fatal(2, "CPU : ERROR: Invalid instruction %b at pc %h", instr, pc);
                    regs[rd] <= (rd == 0) ? 0 : LO;
                  end
                  FUNCTION_OR: begin
                    assert(shift == 5'b00000) else $fatal(2, "CPU : ERROR : Invalid instruction %b at pc %h", instr, pc);
                    regs[rd] <= (rd == 0) ? 0 : regs[rs] | regs[rt];
                  end
                  FUNCTION_SLT: begin
                    assert(shift == 5'b00000) else $fatal(2, "CPU : ERROR : Invalid instruction %b at pc %h", instr, pc);
                    regs[rd] <= (rd == 0) ? 0 : (regs[rs] < regs[rt]);
                  end
                  FUNCTION_SLL: begin
                    assert(rs == 5'b00000) else $fatal(2, "CPU : ERROR : Invalid instruction %b at pc %h", instr, pc);
                    regs[rd] <= (rd == 0) ? 0 : regs[rt] << shift;
                  end
                  FUNCTION_SLLV: begin
                    assert(shift == 5'b00000) else $fatal(2, "CPU : ERROR : Invalid instruction %b at pc %h", instr, pc);
                    regs[rd] <= (rd == 0) ? 0 : regs[rt] << (regs[rs] & 32'h0000001f);
                  end
                  FUNCTION_SLTU: begin
                    assert(shift == 5'b00000) else $fatal(2, "CPU : ERROR : Invalid instruction %b at pc %h", instr, pc);
                    regs[rd] <= (rd == 0) ? 0 : ($unsigned(regs[rs]) < $unsigned(regs[rt]));
                  end
                  FUNCTION_SRA: begin
                    assert(rs == 5'b00000) else $fatal(2, "CPU : ERROR : Invalid instruction %b at pc %h", instr, pc);
        						regs[rd] <= (rd == 0) ? 0 : regs[rt] >>> shift;
        				  end
                  FUNCTION_SRAV: begin
                    assert(shift == 5'b00000) else $fatal(2, "CPU : ERROR : Invalid instruction %b at pc %h", instr, pc);
                    regs[rd] <= (rd == 0) ? 0 : regs[rt] >>> (regs[rs] & 32'h0000001f);
        				  end
        					FUNCTION_SRL: begin
                    assert(rs == 5'b00000) else $fatal(2, "CPU : ERROR : Invalid instruction %b at pc %h", instr, pc);
        						regs[rd] <= (rd == 0) ? 0 : regs[rt] >> shift;
        				  end
        					FUNCTION_SRLV: begin
                    assert(shift == 5'b00000) else $fatal(2, "CPU : ERROR : Invalid instruction %b at pc %h", instr, pc);
        					  regs[rd] <= (rd == 0) ? 0 : regs[rt] >> (regs[rs] & 32'h0000001f);
        				  end
        					FUNCTION_SUBU: begin
                    assert(shift == 5'b00000) else $fatal(2, "CPU : ERROR : Invalid instruction %b at pc %h", instr, pc);
        					  regs[rd] <= (rd == 0) ? 0 : $unsigned(regs[rs]) - $unsigned(regs[rt]);
        				  end
                  FUNCTION_XOR: begin
                    assert(shift == 5'b00000) else $fatal(2, "CPU : ERROR : Invalid instruction %b at pc %h", instr, pc);
                    regs[rd] <= (rd == 0) ? 0 : (regs[rs] ^ regs[rt]);
        				  end
                endcase
              end
              OPCODE_ADDIU: begin
                regs[rt] <= (rt == 0) ? 0 : $unsigned(regs[rs]) + ({{16{instr_imm[15]}}, instr_imm});
              end
              OPCODE_ANDI: begin
                regs[rt] <= (rt == 0) ? 0 : regs[rs] & instr_imm;
              end
              OPCODE_BEQ: begin
                assert(delay == 0) else $fatal(2, "CPU : ERROR : Branch / Jump instruction %b in delay slot at pc %h", instr, pc);
                if(regs[rs] == regs[rt]) begin
                  pc_jmp <= pc_increment + ({{16{instr_imm[15]}}, (instr_imm << 2)});
                  delay <= 1;
                end
              end
              //SD instructions
              OPCODE_LUI: begin
                assert(rs==5'b00000) else $fatal(2, "CPU : ERROR : Invalid instruction %b at pc %h", instr, pc );
                regs[rt] <= (rt == 0) ? 0 : {instr_imm, 16'h0000};
              end
              OPCODE_REGIMM: begin
                assert(delay == 0) else $fatal(2, "CPU : ERROR : Branch / Jump instruction %b in delay slot at pc %h", instr, pc);
                case(rt)
                  BGEZ: begin
                    if(regs[rs] >= 0) begin
                      pc_jmp <= pc_increment + ({{16{instr_imm[15]}}, (instr_imm << 2)});
                      delay <= 1;
                    end
                  end
                  BGEZAL: begin
                    assert(rs!=31) else $fatal(2, "CPU : ERROR : Cannot use $ra as rs, instr %b at pc %h", instr, pc );
                    regs[31] <= (pc_increment + 32'd4);
                    if(regs[rs] >= 0) begin
                      pc_jmp <= pc_increment + ({{16{instr_imm[15]}}, (instr_imm << 2)});
                      delay <= 1;
                    end
                  end
                  BLTZ: begin
                    if(regs[rs] < 0) begin
                      pc_jmp <= pc_increment + ({{16{instr_imm[15]}}, (instr_imm << 2)});
                      delay <= 1;
                    end
                  end
                  BLTZAL: begin
                    assert(rs!=31) else $fatal(2, "CPU : ERROR : Cannot use $ra as rs, instr %b at pc %h", instr, pc );
                    regs[31] <= (pc_increment + 4);
                    if(regs[rs] < 0) begin
                      pc_jmp <= pc_increment + ({{16{instr_imm[15]}}, (instr_imm << 2)});
                      delay <= 1;
                    end
                  end
                endcase
              end
              OPCODE_BGTZ: begin
                if(regs[rs] > 0) begin
                  pc_jmp <= pc_increment + ({{16{instr_imm[15]}}, (instr_imm << 2)});
                  delay <= 1;
                end
              end
              OPCODE_BLEZ: begin
                if(regs[rs] <= 0) begin
                  pc_jmp <= pc_increment + ({{16{instr_imm[15]}}, (instr_imm << 2)});
                  delay <= 1;
                end
              end
              OPCODE_BNE: begin
                if(regs[rs] != regs[rt]) begin
                  pc_jmp <= pc_increment + ({{16{instr_imm[15]}}, (instr_imm << 2)});
                  delay <= 1;
                end
              end
              OPCODE_J: begin
            		assert(delay == 0) else $fatal(2, "CPU : ERROR : Branch / Jump instruction %b in delay slot at pc %h", instr, pc);
                pc_jmp <= {{pc_increment[31:28]}, instr_index, {2'b00}};
            		delay <= 1;
      	      end
      	      OPCODE_JAL: begin
            		assert(delay == 0) else $fatal(2, "CPU : ERROR : Branch / Jump instruction %b in delay slot at pc %h", instr, pc);
            		regs[31] <= pc + 8;
            		pc_jmp <= {{pc_increment[31:28]}, instr_index, {2'b00}};
            		delay <= 1;
            	end
              OPCODE_ORI: begin
                regs[rt] <= (rt == 0) ? 0 : regs[rs] | instr_imm;
              end
              OPCODE_SLTI: begin
                regs[rt] <= (rt == 0) ? 0 : (regs[rs] < $signed(instr_imm));
              end
              OPCODE_SLTIU: begin
                regs[rt] <= (rt == 0) ? 0 : (regs[rs] < $unsigned(instr_imm));
              end
      			  OPCODE_XORI: begin
      					regs[rt] <= (rt == 0) ? 0 : regs[rs] ^ instr_imm;
      			  end
          endcase
        end
        else if(state == MEM_ACCESS) begin
            state <= FETCH;
            case(instr_opcode)
              OPCODE_LB: begin
                if (alignment==2'b00) begin
                  regs[rt] <= (rt == 0) ? 0 : {{24{readdata[7]}},readdata[7:0]};
                end
                else if (alignment==2'b01) begin
                  regs[rt] <= (rt == 0) ? 0 : {{24{readdata[15]}},readdata[15:8]};
                end
                else if (alignment==2'b10) begin
                  regs[rt] <= (rt == 0) ? 0 : {{24{readdata[23]}},readdata[23:16]};
                end
                else if (alignment==2'b11) begin
                  regs[rt] <= (rt == 0) ? 0 : {{24{readdata[31]}},readdata[31:24]};
                end
              end
              OPCODE_LBU: begin
                if (alignment==2'b00) begin
                  regs[rt] <= (rt == 0) ? 0 : {24'h000000,readdata[7:0]};
                end
                else if (alignment==2'b01) begin
                  regs[rt] <= (rt == 0) ? 0 : {24'h000000,readdata[15:8]};
                end
                else if (alignment==2'b10) begin
                  regs[rt] <= (rt == 0) ? 0 : {24'h000000,readdata[23:16]};
                end
                  else if (alignment==2'b11) begin //error was here, compiles now, still ensure of the implementation of byte enable
                  regs[rt] <= (rt == 0) ? 0 : {24'h000000,readdata[31:24]};
                end
              end
              OPCODE_LH: begin
                if(alignment[1]==1'b0) begin
                  regs[rt] <= (rt == 0) ? 0 : {{16{readdata[15]}},readdata[15:0]};
                end
                else if(alignment[1]==1'b1) begin
                  regs[rt] <= (rt == 0) ? 0 : {{16{readdata[31]}},readdata[31:16]};
                end
              end
              OPCODE_LHU:begin
                if(alignment[1]==2'b0) begin
                  regs[rt] <= (rt == 0) ? 0 : {16'h0000,readdata[15:0]};
                end
                else if(alignment[1]==2'b1) begin
                  regs[rt] <= (rt == 0) ? 0 : {16'h0000,readdata[31:16]};
                end
              end
              OPCODE_LW: regs[rt] <= (rt == 0) ? 0 : readdata;
              OPCODE_LWL: begin
                case(alignment)
                  2'b00: regs[rt] <= (rt == 0) ? 0 : {readdata[7:0],regs[rt][23:0]};
                  2'b01: regs[rt] <= (rt == 0) ? 0 : {readdata[15:0],regs[rt][15:0]};
                  2'b10: regs[rt] <= (rt == 0) ? 0 : {readdata[23:0], regs[rt][7:0]};
                  2'b11: regs[rt] <= (rt == 0) ? 0 : readdata;
                endcase
              end
              OPCODE_LWR:begin
                case(alignment)
                  2'b00: regs[rt] <= (rt == 0) ? 0 : readdata;
                  2'b01: regs[rt] <= (rt == 0) ? 0 : {regs[rt][31:24],readdata[31:8]};
                  2'b10: regs[rt] <= (rt == 0) ? 0 : {regs[rt][31:16], readdata[31:16]};
                  2'b11: regs[rt] <= (rt == 0) ? 0 : {regs[rt][31:8], readdata[31:24]};
                endcase
              end
            endcase
        end
        else if(state == HALTED) begin
            //Do nothing
        end
        else begin
            $fatal(1, "CPU : ERROR : Processor in unexpected state %b", state);
        end
    end

endmodule
