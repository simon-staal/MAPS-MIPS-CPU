typedef enum logic[5:0] {
		FUNCTION_DIV=6'b011010, //s divides two 32bit signed integers, rs, rt. quotient to LO, Remainder to HI
		FUNCTION_DIVU=6'b011011, //s same thing, for unsigned integers.\
		FUNCTION_JALR = 6'b001001, //s Jumps to RS, return adress stored in RD.
		FUNCTION_JR = 6'b001000, //s branch to an Instruction address in rs, presumably after FUNCTION_JALR
    } function_t;

    typedef enum logic[5:0] {
OPCODE_J = 6'b000010, //jumps to specified target instr_index.
OPCODE_JAL = 6'b000011, //stores next instruction address in GPR (during procedure call,) executes subroutine.
OPCODE_LB = 6'b100000, //load a byte from memory to rt as a signed value
OPCODE_LBU = 6'100100, //same thing but as an unsigned value
OPCODE_LH = 6'b100001, //load a halfword as a signed value (to rt)
    } opcode_t;




//beginning instruction implementation, copied simons initializations
		always_ff @ (posedge clk) begin
		    if(reset) begin
		        state <= FETCH;
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
								regs[rd] <= pc + 8;
								pc <= regs[rs];
								end
								FUNCTION_JR: begin
								pc <= regs[rs];
								end
								OPCODE_J: begin
								//unsure here, require help
								pc <= instr_mem;
								end
							  OPCODE_JAL: begin
								//unsure of this implementation
								regs[31] <= pc + 8;
								pc <= instr_mem;
								//may have to deine instr_index in main CPU file. EDIT: found its defined as instr_mem
								end
								OPCODE_LB: begin
								regs[rt] <= memory[instr_rs + instr_imm];
								//not sure about instr_rs being considered as the base, also sign extensions.
								end
								OPCODE_LBU: begin
								regs[rt] <= memory[instr_rs + instr_imm];
								//not sure about instr_rs being considered as the base, also sign extensions (unsigned here.)
								end
								OPCODE_LH: begin
								regs[rt] <= memory[instr_rs + instr_imm];
								//not sure about instr_rs being considered as the base, also sign extensions.
								end
								end
								else if(state == MEM_ACCESS) begin
			 state <= (waitrequest) ? MEM_ACCESS : FETCH
	 end
	 else if(state == HALTED) begin
			 //Do nothing
	 end
	 else begin
			 $fatal(1, "CPU : ERROR : Processor in unexpected state %b", state);
	 end
end
