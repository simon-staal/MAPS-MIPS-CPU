
   
    typedef enum logic[5:0] {
        
        
// OR ORI SB SH SLL SLLV SLT SLTI SLIU
		OPCODE_ORI=6'b001101,// does a bitwise logical or with constant rd<--rs or immediate
		OPCODE_SB=6'b101000,//stores a byte to memory memory(base+offset)=rt?
		OPCODE_SH=6'b101001,//store a halfword to memory memory(base+offset)=rt?
		OPCODE_SLTI=6'b001010 // to record the result of a less than comparison with a conse rt=(rs<immediate)
        OPCODE_SLTIU=6'b001011 //to record the result of an unsigned less than comparison with a conse rt=(rs<immediate)
    } opcode_t;

    typedef enum logic[5:0] {
      
        FUNCTION_OR= 6'b100101,
        // does bitwise logical OR rd<--rs OR rt
        FUNCTION_SLL=6'b000000, // to left shift a word by a fixed number of bits rd=rt<<sa (shift amt)
        FUNCTION_SLLV=6'b000100,// to left shift by a variable nb of bits rd=rt<<rs
        FUNCTION_SLT=6'b101010,// to record the result of a less than comparison rd=(rs<rt)
    } function_t;
