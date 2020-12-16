#!/bin/bash
set -eou pipefail

SOURCE="$1" #Source directory containing RTL implementation
INSTRUCTION="$2" #lower-case name of instruction being tested
TEST_DIRECTORY="../test"
TESTCASES="${TEST_DIRECTORY}/1-hex/test_mips_cpu_bus_${2:-*}_*.hex.txt" #list of testcases being tested either starting with instruction being tested or all if no instruction is specified

for TESTCASE in ${TESTCASES}; do

  TESTNAME=$(basename ${TESTCASE} .hex.txt)
  INSTR=$(echo $TESTNAME | cut -d'_' -f 5)
  NUM=$(echo $TESTNAME | cut -d'_' -f 6)
  CODE="${INSTR}_${NUM}"

  >&2 echo " 1 - Compiling test-bench"
  # Compile a specific simulator for this testbench.
  # -s specifies exactly which testbench should be top-level
  # The -P command is used to modify the RAM_INIT_FILE parameter on the test-bench at compile-time
  # Note currently must be compiled inside source folder for include to work
  iverilog -g 2012 \
     ${SOURCE}/mips_cpu_*.v ${SOURCE}/mips_cpu_definitions.vh ${TEST_DIRECTORY}/test_mips_cpu_bus_generic.v  \
     -s  mips_cpu_bus_tb \
     -P mips_cpu_bus_tb.RAM_INIT_FILE=\"${TEST_DIRECTORY}/1-hex/${TESTCASE}\" \
     -P mips_cpu_bus_tb.TESTCASE_ID=\"${CODE}\" \
     -P mips_cpu_bus_tb.INSTRUCTION=\"${INSTR}\" \
     -o ${TEST_DIRECTORY}/2-simulator/${TESTNAME}



  >&2 echo "  2 - Running test-bench"
  # Run the simulator, simulator should output appropriate message
  # Disable e in case simulation returns with error code
  set +e
  ${TEST_DIRECTORY}/2-simulator/${TESTNAME} > ${TEST_DIRECTORY}/3-output/${TESTNAME}.stdout
  RESULT=$?
  set -e

  if [["${RESULT}" -ne 0]] ; then
    echo "${CODE} ${INSTR} Fail"
    exit
  fi

  >&2 echo "  3 - Extracting final output of v0"
  PATTERN="FINAL OUT: "
  NOTHING=""

  set +e
  grep "${PATTERN}" ${TEST_DIRECTORY}/3-output/${TESTNAME}.stdout > ${TEST_DIRECTORY}/3-output/${TESTNAME}.out-v0
  set -e

  sed -e "s/${PATTERN}/${NOTHING}/g" ${TEST_DIRECTORY}/3-output/${TESTNAME}.out-v0 > ${TEST_DIRECTORY}/3-output/${TESTNAME}.out


  >&2 echo "  4 - Comparing reference output"

  set +e
  diff -w ${TEST_DIRECTORY}/4-reference/${TESTNAME}.txt ${TEST_DIRECTORY}/3-output/${TESTNAME}.out
  RESULT=$?
  set -e

  if [[ "${RESULT}" -ne 0 ]] ; then
    echo "${CODE} ${INSTR} Fail"
  else
    echo "${CODE} ${INSTR} Pass"
  fi

done
