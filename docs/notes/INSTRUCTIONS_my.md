 
*OPCODE_ORI = 6'b001101, // does a bitwise logical or with constant rt<--rs | immediate
 I-type instruction, rt = rs || instr_imm
Can be implemented directly using register file:

FETCH:
- Fetch instruction

EXEC:
- Calculate rs || instr_imm
- pc <= pc + 4

WRITE_BACK:
- rt <= result

*FUNCTION_OR = 6'b100101, // does bitwise logical OR rd<--rs OR rt (shift == 0)
R-type instruction, rd = rs || rt
Can be implemented directly using register file:
FETCH:
- Fetch instruction

EXEC:
- Calculate rs || rt
- pc <= pc + 4

WRITE_BACK:
- rd <= result
  	
*OPCODE_SB = 6'b101000,//stores a byte to memory memory(base+offset) = rt?
FETCH:
- Fetch instruction

EXEC:
- address = base/rs + offset; //reg_readdata1 contains the value stored in rs
- pc <= pc + 4

WRITE_BACK:
write = 1;
    
writedata = rt[7:0];
- mem[address]<= result
    	
 *OPCODE_SH = 6'b101001, //store a halfword to memory memory(base+offset)=rt?
 
FETCH:
- Fetch instruction

EXEC:
- address = base/rs + offset; //reg_readdata1 contains the value stored in rs
- pc <= pc + 4

WRITE_BACK:
write = 1;
    
writedata = rt[15:0];
- mem[address]<= result
 *OPCODE_SLTI = 6'b001010, // to record the result of a less than comparison with a const rt=(rs<immediate)
   I-type instruction
Can be implemented directly using register file:

FETCH:
- Fetch instruction

EXEC:
- Calculate rs - instr_imm
- pc <= pc + 4

WRITE_BACK:
- rt <= result[31]
 *OPCODE_SLTIU = 6'b001011, //to record the result of an unsigned less than comparison with a conse rt=(rs<immediate)
 I-type instruction,
Can be implemented directly using register file:

FETCH:
- Fetch instruction

EXEC:
- Calculate rs - instr_imm(sign extended)
- pc <= pc + 4

WRITE_BACK:
- rt <= result[31]
   
				state <= FETCH;

*FUNCTION_SLL = 6'b000000, // to left shift a word by a fixed number of bits rd=rt<<sa (shift amt) (rs == 0)
    R-type instruction,
Can be implemented directly using register file:

FETCH:
- Fetch instruction

EXEC:
- rd<=rt<< sa; 
- pc <= pc + 4
- Assert shift != 00000

WRITE_BACK:
- rd <= result
 
 *FUNCTION_SLLV = 6'b000100, // to left shift by the 5 LSB of rs rd=rt<<rs[4:0] (shift == 0)
  R-type instruction,
Can be implemented directly using register file:

FETCH:
- Fetch instruction

EXEC:
- rd<=rt<< rs; 
- pc <= pc + 4
- Assert shift == 00000

WRITE_BACK:
- rd <= result
*FUNCTION_SLT = 6'b101010, // to record the result of a less than comparison rd=(rs<rt) (shift == 0)
  R-type instruction,
Can be implemented directly using register file:

FETCH:
- Fetch instruction

EXEC:
- rd<=rs-rt; 
- pc <= pc + 4
- Assert shift != 00000

WRITE_BACK:
- rd <= result[31]

