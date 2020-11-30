## MIPS book Chapter 7 notes

# Design Process

Divide microarchitecture into 2 parts:
- Data path
- Control path

Datapath contains:
- Memory
- Registers
- ALU's
- Multiplexers

Control unit:
- Multiplexer select
- Register enable
- Memory write
i.e. Controls operation of datapath. 

Often simpler to partition memory into instruction and data.

State elements:
- Program Counter (PC)
- Register file
- Instruction and data memory.

PC:
- 32-bit register
- Output points to current instruction
- Input points to next instruction

Instruction Memory:
- Single read port, 32 bits (not sure why?) - surely it would depend on how many instructions the instruction memory can hold?
- RD = read data output

Register file
- 2 read ports, representing the source operands
- 32 register memory 
- 1 write port
- write enable input
- clk

## Multi-cycle Processor

### Control Path

- Can compute PC + 4 during fetch of instruction to utilise unused ALU. 

- After fetch, next step is to decode (1 cycle). 

- Decode:
	- Reg file always reads 2 sources specified by rs and rt. 
	- Opcode is examined. No control signals necessary. 
	- Next state depends on opcode.
	
- If lw or sw:
	- Computes address & stores in ALU Out register.
	- 
