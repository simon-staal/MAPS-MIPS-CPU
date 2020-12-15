#!/bin/bash
set -eou pipefail

# Can be used to echo commands
# set -o xtrace


# Specific test-case.
# $1, $2, $2, ... represent the arguments passed to the script
SOURCE="$1" #Source directory containing RTL implementation
INSTRUCTION="$2" #lower-case name of instruction being tested
TESTCASES= "test/test_mips_cpu_bus_${2:-*}_*.v" #list of testcases being tested either starting with instruction being tested or all if no instruction is specified
TEST_DIRECTORY="test"

# Redirect output to stder (&2) so that it seperate from genuine outputs
# Using ${VARIANT} substitutes in the value of the variable VARIANT
for TESTCASE in ${TESTCASES}; do

  TESTNAME=$(basename ${TESTCASE} .v)
  INSTR=$(echo $TESTNAME | cut -d'_' -f 5)
  NUM=$(echo $TESTNAME | cut -d'_' -f 6)
  CODE="${INSTR}_${NUM}"

  >&2 echo " 1 - Compiling test-bench"
  # Compile a specific simulator for this testbench.
  # -s specifies exactly which testbench should be top-level
  # The -P command is used to modify the RAM_INIT_FILE parameter on the test-bench at compile-time
  # Note currently must be compiled inside source folder for include to work
  iverilog -g 2012 \
     ${SOURCE}/mips_cpu_*.v ${SOURCE}/mips_cpu_definitions.vh ${TESTCASE}  \
     -s  mips_cpu_bus_tb \
     -P mips_cpu_bus_tb.RAM_INIT_FILE=\"${TEST_DIRECTORY}/1-hex/${TESTNAME}.hex.txt\" \
     -o ${TEST_DIRECTORY}/2-simulator/${TESTNAME}



  >&2 echo "  2 - Running test-bench"
  # Run the simulator, simulator should output appropriate message
  # Disable e in case simulation returns with error code
  set +e
  test/2-simulator/${TESTNAME} > ${TEST_DIRECTORY}/3-output/${TESTNAME}.stdout
  RESULT=$?
  set -e

  if [["${RESULT}" -ne 0]] ; then
    echo "${CODE} ${INSTR} Fail"
    exit
  fi

  echo "${CODE} ${INSTR} Pass"

done
