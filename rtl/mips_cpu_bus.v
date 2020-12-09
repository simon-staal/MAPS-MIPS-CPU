`include "mips_cpu_definitions.vh"

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

    //Defining constants
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
        OPCODE_LBU = 6'100100, //same thing but as an unsigned value
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
        FUNCTION_MTLO = 6'b100100, // $LO = $rs (rt, rd, shift == 0)
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
    } REGIMM_t

    //States in FSM
    typedef enum logic[3:0] {
        FETCH = 3'b000,
        EXEC = 3'b001,
        MEM_ACCESS = 3'b010,
        HALTED = 3'b111
    } state_t;


    //Creates basic registers
    logic[31:0] pc, pc_increment;
    assign pc_increment = pc + 4;
    logic[31:0] ir;
    logic ir_write;

    //Create non GPR HI and LO registers
    logic[31:0] HI;
    logic[31:0] LO;

    //Divide intruction into seperate signals
    logic[31:0] instr;
    opcode_t instr_opcode;
    function_t instr_function;
    state_t state;
    logic[4:0] rs, rt, rd, shift;
    logic[15:0] instr_imm;
    logic[25:0] instr_index;

    assign instr = (state==FETCH) ? readdata : ir;
    assign instr_opcode = instr[31:26];
    assign rs = instr[25:21];
    assign rt = instr[20:16];
    assign rd = instr[15:11];
    assign shift = instr[10:6];
    assign instr_function = instr[5:0];
    assign instr_imm = instr[15:0];
    assign instr_index = intr[25:0];

    /* Defines an array of 32 registers used by MIPS whit the following purposes:
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
    logic[31:0] regs[31:0];
    assign regs[0] = 32'h00000000;
    assign register_v0 = regs[2];

    //Stores values for branch / jmp instructions
    logic[31:0] pc_jmp;
    logic delay;

    //Used for 2 cycle memory access instructions (stores) for waitrequest logic in controlling pc
    logic mem_access;

    initial begin
        state = HALTED;
        active = 0;
    end


    always_comb begin
        if(state == FETCH) begin
            byteenable = 4'b1111;
            read = 1;
            write = 0;
            address = pc;
        end
        if(state == EXEC) begin
            //ADD LOGIC FOR LOAD / STORE INSTRUCTIONS
      			if(instr_opcode == OPCODE_SW) begin
      				write = 1;
      				read = 0;
      				byteenable = 4'b1111;
      				address = regs[rs] + instr_imm;
      				writedata = regs[rt];
      			end
            if(instr_opcode==OPCODE_SB) begin
              byteenable = 4'b0001;
              write = 1;
              read = 0;
              address = regs[rs] + instr_imm;
              writedata = (regs[rt])[7:0];
            end
            else if(instr_opcode==OPCODE_SH) begin
              byteenable = 4'b0011;
              write = 1;
              read = 0;
              address = regs[rs] + instr_imm;
              writedata = (regs[rt])[15:0];
            end
            else if(instr_opcode==OPCODE_LB) begin
              read = 1;
              write = 0;
              byteenable = 4'b0001;
              //TO-DO: add signal exception for address error (address[0]==0)
              address = regs[rs]+instr_imm;
            end
            else if(instr_opcode==OPCODE_LBU) begin
              read = 1;
              write = 0;
              byteenable = 4'b0001;
              //TO-DO: add signal exception for address error (address[0]==0)
              address = regs[rs]+instr_imm;
            end
            else if(instr_opcode==OPCODE_LH) begin
              read = 1;
              write = 0;
              byteenable = 4'b1100;
              //TO-DO: add signal exception for address error (address[0]==0)
              address = regs[rs]+instr_imm;
            end
            else if(instr_opcode==OPCODE_LHU) begin
              read = 1;
              write = 0;
              byteenable = 4'b1100;
              //TO-DO: add signal exception for address error (address[0]==0)
              address = regs[rs]+instr_imm;
            end
            else if(instr_opcode==OPCODE_LW) begin
              read = 1;
              write = 0;
              byteenable = 4'b1111;
              //TO-DO: add signal exception for address error (address[0]==0)
              address = regs[rs]+instr_imm;
            end
            else if(instr_opcode==OPCODE_LWL) begin
              read = 1;
              write = 0;
              byteenable = 4'b1100;
              //TO-DO: add signal exception for address error (address[0]==0)
              address = regs[rs]+instr_imm;
            end
            else if(instr_opcode==OPCODE_LWR) begin
              read = 1;
              write = 0;
              byteenable = 4'b0011;
              //TO-DO: add signal exception for address error (address[0]==0)
              address = regs[rs]+instr_imm;
            end
            else begin
              read = 0;
              write = 0;
              byteenable = 0;
              address = pc;
            end
        end
    end


    always_ff @ (posedge clk) begin
        if(reset) begin
            state <= FETCH;
            active <= 1;
            pc <= 32'hBFC00000;
        end
        else if(pc == 32'h00000000) begin
            state <= HALTED;
            active <= 0;
        end
        else if(state == FETCH) begin
            state <= (waitrequest) ? FETCH : EXEC;
        end
        else if(state == EXEC) begin
            state <= (waitrequest && mem_access) ? EXEC : () ? MEM_ACCESS : FETCH; //Add condition if instruction requires mem access / if instruction requires writing back to a register
            pc <= (waitrequest) ? pc : (delay) ? pc_jmp : pc_increment;
            delay <= 0; //Resets the value of delay
            case(instr_opcode)
              OPCODE_R: begin
                case(instr_function)
                  FUNCTION_ADDU: begin
                    assert(shift == 5'b00000) else $fatal(3, "CPU : ERROR : Invalid instruction %b at pc %b", instr, pc);
                    regs[rd] <= regs[rs] + regs[rt];
                  end
                  FUNCTION_AND: begin
                    assert(shift == 5'b00000) else $fatal(3, "CPU : ERROR : Invalid instruction %b at pc %b", instr, pc);
                    regs[rd] <= regs[rs] & regs[rt];
                  end
                  FUNCTION_DIV: begin
		    //not sure whether an assert is required here
		    regs[LO] <= regs[rs]/regs[rt];
		    regs[HI] <= regs[rs]%regs[rt];
		    //does verilog automatically sign extend?
		  end
		  FUNCTION_DIVU: begin
		    //not sure whether an assert is required here
		    regs[LO] <= regs[rs]/regs[rt];
		    regs[HI] <= regs[rs]%regs[rt];
		  end
                  FUNCTION_JALR: begin
		    assert(delay == 0) else $fatal(4, "CPU : ERROR : Branch / Jump instruction %b in delay slot at pc %b", instr, pc);
		    regs[rd] <= pc + 8;
		    pc_jmp <= regs[rs];
		    delay <= 1;
		  end
		  FUNCTION_JR: begin
		    assert(delay == 0) else $fatal(4, "CPU : ERROR : Branch / Jump instruction %b in delay slot at pc %b", instr, pc);
		    pc_jmp <= regs[rs];
		    delay <= 1;
		  end
                  FUNCTION_MTHI:begin
                    assert(({rd,rt,shift}==15'h0000)) else $fatal(3, "CPU : ERROR: Invalid instruction %b at pc %b", instr, pc);
                    HI <= regs[rs];
                  end
                  FUNCTION_MTLO:begin
                    assert(({rd,rt,shift}==15'h0000)) else $fatal(3, "CPU : ERROR: Invalid instruction %b at pc %b", instr, pc);
                    LO <= regs[rs];
                  end
                  FUNCTION_MULT:begin
                    assert(({rd,shift}==10'h000)) else $fatal(3, "CPU : ERROR: Invalid instruction %b at pc %b", instr, pc);
                    LO <= regs[rs][15:0]*regs[rt][15:0];
                    HI <= regs[rs][31:16]*regs[rt][31:16];
                  end
                  FUNCTION_MULTU:begin
                    assert(({rd,shift}==10'h000)) else $fatal(3, "CPU : ERROR: Invalid instruction %b at pc %b", instr, pc);
                    LO <= regs[rs][15:0]*regs[rt][15:0];
                    HI <= regs[rs][31:16]*regs[rt][31:16];
                  end
                  FUNCTION_MFHI:begin
                    assert(({rs,rt,shift}==15'h0000)) else $fatal(3, "CPU : ERROR: Invalid instruction %b at pc %b", instr, pc);
                    regs[rd] <= HI;
                  end
                  FUNCTION_MFLO:begin
                    assert(({rs,rt,shift}==15'h0000)) else $fatal(3, "CPU : ERROR: Invalid instruction %b at pc %b", instr, pc);
                    regs[rd] <= LO;
                  end
                  FUNCTION_OR: begin
                    assert(shift == 5'b00000) else $fatal(3, "CPU : ERROR : Invalid instruction %b at pc %b", instr, pc);
                    regs[rd] <= regs[rs] || regs[rt];
                  end
                  FUNCTION_SLT: begin
                    assert(shift == 5'b00000) else $fatal(3, "CPU : ERROR : Invalid instruction %b at pc %b", instr, pc);
                    regs[rd] <= (regs[rs] - regs[rt])>>32;
                  end
                  FUNCTION_SLL: begin
                    assert(shift != 5'b00000) else $fatal(3, "CPU : ERROR : Invalid instruction %b at pc %b", instr, pc);
                    regs[rd] <= regs[rs] << shift;
                  end
                  FUNCTION_SLLV: begin
                    regs[rd] <= regs[rs] << regs[rt];
                  end
				  FUNCTION_XOR: begin
						regs[rd] <= regs[rs] ^ regs[rt];
				  end
					  FUNCTION_SRL: begin
						regs[rd] <= regs[rt] >> shift;
				  end
					  FUNCTION_SRA: begin
						regs[rd] <= regs[rt] >>> shift;
				  end
					  FUNCTION_SRLV: begin
					  regs[rd] <= regs[rt] >> regs[rs];
				  end
					  FUNCTION_SRAV: begin
					  regs[rd] <= regs[rt] >>> regs[rs];
				  end
					  FUNCTION_SLTU: begin
						if (regs[rs] < regs[rt]) begin
							regs[rd] <= 1;
						end
						else begin
							regs[rd] <= 0;
						end
				  end
					  FUNCTION_SUBU: begin
					  regs[rd] <= regs[rs] - regs[rt];
				  end
                endcase
              end
              OPCODE_ADDIU: begin
                regs[rt] <= regs[rs] + instr_imm;
              end
              OPCODE_ANDI: begin
                regs[rt] <= regs[rs] & instr_imm;
              end
              OPCODE_BEQ: begin
                assert(delay == 0) else $fatal(4, "CPU : ERROR : Branch / Jump instruction %b in delay slot at pc %b", instr, pc);
                if(regs[rs] == regs[rt]) begin
                  pc_jmp <= pc_increment + instr_imm << 2;
                  delay <= 1;
                end
              end
              //SD instructions
              OPCODE_LUI: begin
                assert(rs==5'b00000) else $fatal(3, "CPU : ERROR : Invalid instruction %b at pc %b", instr, pc );
                regs[rt] <= {instr_imm, 16'h0000};
              end
              OPCODE_REGIMM: begin
                assert(delay == 0) else $fatal(4, "CPU : ERROR : Branch / Jump instruction %b in delay slot at pc %b", instr, pc);
                case(rt)
                  BGEZ: begin
                    if(regs[rs] >= 0) begin
                      pc_jmp <= pc_increment + instr_imm << 2;
                      delay <= 1;
                    end
                  end
                  BGEZAL: begin
                    if(regs[rs] >= 0) begin
                      pc_jmp <= pc_increment + instr_imm << 2;
                      delay <= 1;
                      regs[31] <= pc_increment + 4;
                    end
                  end
                  BLTZ: begin
                    if(regs[rs] < 0) begin
                      pc_jmp <= pc_increment + instr_imm << 2;
                      delay <= 1;
                    end
                  end
                  BLTZAL: begin
                    if(regs[rs] < 0) begin
                      pc_jmp <= pc_increment + instr_imm << 2;
                      delay <= 1;
                      regs[31] <= pc_increment + 4;
                    end
                  end
              end
              OPCODE_BGTZ: begin
                if(regs[rs] > 0) begin
                  pc_jmp <= pc_increment + instr_imm << 2;
                  delay <= 1;
                end
              end
              OPCODE_BLEZ: begin
                if(regs[rs] <= 0) begin
                  pc_jmp <= pc_increment + instr_imm << 2;
                  delay <= 1;
                end
              end
              OPCODE_BNE: begin
                if(regs[rs] != regs[rt]) begin
                  pc_jmp <= pc_increment + instr_imm << 2;
                  delay <= 1;
                end
              end
              OPCODE_J: begin
		assert(delay == 0) else $fatal(4, "CPU : ERROR : Branch / Jump instruction %b in delay slot at pc %b", instr, pc);
		pc_jmp <= instr_imm;
		delay <= 1;
	      end
	      OPCODE_JAL: begin
		assert(delay == 0) else $fatal(4, "CPU : ERROR : Branch / Jump instruction %b in delay slot at pc %b", instr, pc);
		regs[31] <= pc + 8;
		pc_jmp <= instr_imm;
		delay <= 1;
	      end
              OPCODE_ORI: begin
                regs[rt] <= regs[rs] || instr_imm;
              end
              OPCODE_SB: begin
                mem_access <= 1;
              end
              OPCODE_SH: begin
                mem_access <= 1;
              end
              OPCODE_SLTI: begin
                if (instr_imm[15]==1)begin
                  regs[rt] <= (regs[rs] - {16'h0001,instr_imm})>>32;
                end
                else if (instr_imm[15]==O)begin
                  regs[rt] <= (regs[rs] - { 16'h0000,instr_imm})>>32;
                end
              end
              OPCODE_SLTIU: begin
                regs[rt] <= (regs[rs] - { 16'h0000,instr_imm})>>32;
              end
			  OPCODE_XORI: begin
					regs[rs] <= regs[rt] ^ instr_imm;
			  end
			  OPCODE_SW: begin
			    mem_access <= 1;
			  end
          endcase
        end
        else if(state == MEM_ACCESS) begin
            state <= (waitrequest) ? MEM_ACCESS : FETCH
            case (instr_opcode)
            OPCODE_LB: begin
              if ((regs[rs]+instr_imm)[1:0]==0'b00) begin
                regs[rt] <= {24[readdata[7]],readdata[7:0]};
              end
              else if ((regs[rs]+instr_imm)[1:0]==0'b01) begin
                regs[rt] <= {16[readdata[15]],readdata[15:8],8'h00};
              end
              else if ((regs[rs]+instr_imm)[1:0]==0'b10) begin
                regs[rt] <= {8[readdata[23]],readdata[23:16],16'h0000};
              end
              else if ((regs[rs]+instr_imm)[1:0]==0'b10) begin
                regs[rt] <= {readdata[31:24],24'h000000};
              end
            end
            OPCODE_LBU: begin
              if ((regs[rs]+instr_imm)[1:0]==0'b00) begin
                regs[rt] <= {24'h000000,readdata[7:0]};
              end
              else if ((regs[rs]+instr_imm)[1:0]==0'b01) begin
                regs[rt] <= {16'h0000,readdata[15:8],8'h00};
              end
              else if ((regs[rs]+instr_imm)[1:0]==0'b10) begin
                regs[rt] <= {8'h00,readdata[23:16],16'h0000};
              end
              else if ((regs[rs]+instr_imm)[1:0]==0'b10) begin
                regs[rt] <= {readdata[31:24],24'h000000};
              end
            end
              OPCODE_LH: begin
                if((regs[rs]+instr_imm)[1:0]==0'b00) begin
                  regs[rt] <= {16[readdata[15]],readdata[15:0]};
                end
                else if((regs[rs]+instr_imm)[1:0]==0'b10) begin
                  regs[rt] <= {16[readdata[31]],readdata[31:16]};
                end
                else begin
                  //TO-DO: accessing invalid memory? assert nonetheless?
                end
              end
              OPCODE_LHU:begin
                if((regs[rs]+instr_imm)[1:0]==0'b00) begin
                  regs[rt] <= {16'h0000,readdata[15:0]};
                end
                else if((regs[rs]+instr_imm)[1:0]==0'b10) begin
                  regs[rt] <= {16'h0000,readdata[31:16]};
                end
              end
              OPCODE_LW: regs[rt] <= readdata;
              OPCODE_LWL:regs[rt] <= {readdata[31:16],regs[rt][15:0]};
              OPCODE_LWR:regs[rt] <= {regs[rt][31:16], readdata[15:0]};
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
