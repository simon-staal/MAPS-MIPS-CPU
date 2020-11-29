Instruction Notes
=================
This document will detail the control signals and physical components needed for the instructions covered by Simon Staal.
Note: For now letting verilog optimise the use of ALUs, will make no specific
instances, instead using operators directly.

ADDIU
-----
I-type instruction, rt := rs + instr_imm
Can be implemented directly using register file:

FETCH:
- Fetch instruction

EXEC:
- Calculate rs + instr_imm
- pc <= pc + 4

WRITE_BACK:
- rt <= result

ADDU
----
R-type instruction, rd := rs + rt
Can be implemented directly using register file:
FETCH:
- Fetch instruction
EXEC:
- Calculate rs + rt
- pc <= pc + 4
- Assert shift == 00000
WRITE_BACK:
- rd <= result

AND
---
R-type instruction, rd = rs & rt
Can be implemented directly using register file:
FETCH:
- Fetch instruction
EXEC:
- Calculate rs & rt
- pc <= pc + 4
- Assert shift == 00000
WRITE_BACK:
- rd <= result

ANDI
----
I-type instruction, rt = rs & instr_imm
Can be implemented directly using register file:
FETCH:
- Fetch instruction
EXEC:
- Calculate rs & instr_imm
- pc <= pc + 4
WRITE_BACK:
- rt <= result

BEQ
---
I-type instruction, if(rs == rt) then pc <= pc + imm>>2
Recall delay slots!! This means we will need to store the address that the pc
should jump to and a flag indicating a jump will take place.
i.e.
logic[31:0] pc_jmp to store the address for a jump/branch
logic delay to indicate if we are performing the instruction in the delay slot

Instruction could be implemented as follows:
FETCH:
- Fetch instruction
EXEC:
- Calculate (rs==rt)
- Calculate pc + 4 + imm>>2 (address we will jump to)
- pc <= pc + 4
WRITE_BACK:
- Store values in delay and pc_jmp

DELAY_INSTR: (USED BY ALL BRANCH / JMP)
FETCH:
- Fetch instruction
EXEC:
- if delay: pc <= pc_jmp else: pc <= pc + 4
- Performs remainder of instruction

BGEZ
----
I-type REGIMM instruction (i.e. check rt for which instruction it is),
if(rs >= 0) then pc <= pc + imm>>2
Uses same logic as BEQ, could be implemented as follows:
FETCH:
- Fetch instruction
EXEC:
- Calculate (rs >= 0)
- Calculate pc + 4 + imm>>2
- pc <= pc + 4
WRITE_BACK:
- Store values into delay and pc_jmp


BGEZAL
------
I-type REGIMM instruction
if(rs >= 0) then pc <= pc + imm>>2 && $ra <= pc + 8
Uses same logic as BEQ, could be implemented as follows:
FETCH:
- Fetch instruction
EXEC:
- Calculate (rs >= 0)
- Calculate pc + 4 + imm>>2
- pc <= pc + 4
WRITE_BACK:
- Store values into delay and pc_jmp
- $ra <= pc + 4 (note pc has already been incremented by 4 in EXEC)

BGTZ
----
I-type instruction, if(rs > 0) then pc <= pc + imm>>2
Uses same logic as BEQ, could be implemented as follows:
FETCH:
- Fetch instruction
EXEC:
- Assert rt == 00000
- Calculate (rs > 0)
- Calculate pc + 4 + imm>>2
- pc <= pc + 4
WRITE_BACK:
- Store values into delay and pc_jmp

BLEZ
----
I-type instruction, if (rs <= 0) then pc <= pc + imm>>2
Uses same logic as BEQ, could be implemented as follows:
FETCH:
- Fetch instruction
EXEC:
- Assert rt == 00000
- Calculate rs <= 0
- Calculate pc + 4 + imm>>2
- pc <= pc + 4
WRITE_BACK:
- Store values into delay and pc_jmp

BLTZ
----
I-type REGIMM instruction, if (rs < 0) then pc <= pc + imm>>2
Uses same logic as BEQ, could be implemented as follows:
FETCH:
- Fetch instruction
EXEC:
- Calculate (rs < 0)
- Calculate pc + 4 + imm>>2
- pc <= pc + 4
WRITE_BACK:
- Store values into delay and pc_jmp

BLTZAL
------
I-type REGIMM instruction, if (rs < 0) then pc <= pc + imm>>2 and $ra <= pc + 8
Uses same logic as BEQ, could be implemented as follows:
FETCH:
- Fetch instruction
EXEC:
- Calculate rs < 0
- Calculate pc + 4 + imm>>2
- pc <= pc + 4
WRITE_BACK
- Store values into delay and pc_jmp
- $ra <= pc + 4

BNE
---
I-type instruction, if (rs != rt) then pc <= pc + imm>>2
Uses same logic as BEQ, could be implemented as follows:
FETCH:
- Fetch instruction
EXEC:
- Calculate (rs != rt)
- Calculate pc + 4 + imm>>2
- pc <= pc + 4
WRITE_BACK:
- Store values into delay and pc_jmp

SUMMARY OF CHANGES MADE
-----------------------
Added the following logic to mips_cpu_bus.v:
```
logic[31:0] pc_jmp;
logic delay;
```
Updated the logic in mips_cpu_reg_file for when writing into registers:
```
else if(opcode == OPCODE_REGIMM) begin
  regs[31] <= writedata;
end
```
So far any instructions which link are REGIMM type instructions, meaning that
values will be stored in $ra (register 31)

Considering changes to the state machine:
- Going from CPU_MU0_shared.v, it is possible to perform many operations in 2 cycles,
  even when writing back to register:
  ```
  OPCODE_ADD: begin
      acc <= acc + readdata;
      pc <= pc_increment;
      state <= FETCH;
  end
  ```
  This instruction is completed in only 2 cycles, so it may be possible to remove the
  WRITE_BACK cycle and directly complete instructions in EXEC.
