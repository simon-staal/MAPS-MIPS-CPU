# Meeting Notes 25/11

- Decided to pursue multi-cycle processor with instruction and data memory as a single state element (i.e. bus CPU)

- Went through our respective instructions, explaining what they do and possible implementations.

- Discussed FSM Logic. 

Areas we are unclear how they work:
- Multiplication/Division 
- Byte addressing

We believe there will be a maximum of 4 cycles on an instruction:
- Fetch 
- Exec
- Memory Access
- Write Back

REGIMM type opcodes:
- Encodes conditional branch and trap immediate instructions
- Depicted by 6'b000001 on MSB of instruction
- $rt is used to signify specific REGIMM operation, e.g. BGEZ has 5'b00001 in $rt field.

## TO DO Tasks
- For each of our respective instructions, identify required control signals. 


