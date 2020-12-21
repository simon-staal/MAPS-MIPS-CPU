#DATA SHEET
4 topics:
- Overall architecture + CPU diagrams
- Design decisions
- Testing approach + test flow diagrams
- Area and timing summary for the "Cyclone IV E ‘Auto’" variant in Quartus

## Overall architecture and design

- We chose to implement the bus version of the CPU, thus we have a signle instruction and data memory.

- 3 cycle design for loads, and 2 cycles for everything else. Cycles are fetch, execute, and memory access if necessary.

- Pipelining was not implemented although it is possible with our design.

## Design decisions

- Decided straight away to skip harvard implementation and instead implement bus. This is due to bus similarities to the multi cycle architecture of the MU0 CPU done in 1st year.

- Decided to include the register file as part of the mips_cpu_bus file as this simplified the syntax of the instructions and readability.

- Chose 3 cycles for loads and 2 for everything else as decode and execute can be done in the same cycle, while fetch and mem access need their own cycles as they are accessing our RAM.

## Testing approach

- Generic test bench for all instructions except load and store. For these instructions, an assert is done to check the value at v0 is as expected.

- Script used to compile and run all test cases.

## Area and timing summary
