MIPS CPU DESIGN PROJECT
=======================
This repository contains the MIPS CPU designed as part of the instruction set
architecture (ISA) module for 2nd year EIE at Imperial College London. All verilog
files adhere to the subset of SystemVerilog 2012 supported by Icarus verilog 11.0.

**Contributors:**
- Simon Staal
- Salman Dhaif
- Adam Horsler
- Myriam Yaaqoubi
- Pranav Viswanathan

DOCS
----
This folder contains the initial project specification, as well as the final
report for the project, and should provide a thorough outline of how the CPU
functions.

RTL
---
This folder contains the source files for synthesising the MIPS CPU core, written
in verilog, as well as some intemediary scripts used during the development
and testing of the CPU.

TEST
----
This folder houses all the required files for asserting the functional correctness
of the CPU (or any other MIPS I Revision 3.2 ISA CPU). All test-cases have a unique
identifier in the form `opcode_ID` where `ID` is an integer.
There are 4 scripts located in the base directory:
*Note: All scripts are intended to be called from the base directory of the repository*

**test_mips_cpu_bus.sh**
Usage: `bash test/test_mips_cpu_bus.sh $SOURCE_DIRECTORY $INSTRUCTION_OPCODE(optional)`
This script (when called without the second parameter) performs an overall functional
analysis of the CPU found in the `$SOURCE_DIRECTORY` (*Note: will include all files prefixed
with mips_cpu_bus in compilation*). When run successfully any temporary files created
by the script will be automatically removed.

**run_testbench_code**

Usage: `bash test/run_testbench_code.sh $SOURCE_DIRECTORY $TESTBENCH_CODE`
This script will run a single testcase specified by the `$TESTBENCH CODE` parameter.

**run_testbench_instr**

Usage: `bash test/run_testbench_code.sh $SOURCE_DIRECTORY $INSTRUCTION_OPCODE`
This script will run all testcases associated with a particular instruction.
(*Note: test_mips_cpu_bus.sh can also be used to run tests on particular instructions*)

**cleanup.sh**

Usage: `bash test/cleanup.sh`
This script will remove any files created by any of the previous testing scripts.
