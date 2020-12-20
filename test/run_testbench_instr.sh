#!/bin/bash
set -eou pipefail

SOURCE="$1" #Source directory containing RTL implementation
TEST_DIRECTORY="test"
INSTR="${2}"

TESTCASES="${TEST_DIRECTORY}/1-hex/test_mips_cpu_bus_${INSTR}_*.hex.txt"

for TESTCASE in ${TESTCASES}; do

  TESTNAME=$(basename ${TESTCASE} .hex.txt)
  # TESTNAME_PARTIAL_DIR=${TESTNAME_FULL_DIR#$TEST_DIRECTORY}
  # TESTNAME=${TESTNAME_PARTIAL_DIR#/1-hex/}

  NUM=$(echo $TESTNAME | cut -d'_' -f 6)
  CODE="${INSTR}_${NUM}"

  >&2 echo "  1 - Compiling test-bench"
  # Compile a specific simulator for this testbench.
  # -s specifies exactly which testbench should be top-level
  # The -P command is used to modify the RAM_INIT_FILE parameter on the test-bench at compile-time
  # Note currently must be compiled inside source folder for include to work
  iverilog -g 2012 \
     -s  mips_cpu_bus_tb \
     -P mips_cpu_bus_tb.RAM_INIT_FILE=\"${TESTCASE}\" \
     -P mips_cpu_bus_tb.TESTCASE_ID=\"${CODE}\" \
     -P mips_cpu_bus_tb.INSTRUCTION=\"${INSTR}\" \
     -o ${TEST_DIRECTORY}/2-simulator/${TESTNAME} \
     -I ${SOURCE} \
     ${SOURCE}/mips_cpu_*.v ${SOURCE}/mips_cpu_*.vh ${SOURCE}/mips_cpu/*.v ${TEST_DIRECTORY}/src/test_mips_cpu_bus_generic.v ${TEST_DIRECTORY}/src/mips_cpu_ram_wait.v

  >&2 echo "  2 - Running test-bench"
  # Run the simulator, simulator should output appropriate message
  # Disable e in case simulation returns with error code
  set +e
  ${TEST_DIRECTORY}/2-simulator/${TESTNAME} > ${TEST_DIRECTORY}/3-output/${TESTNAME}.stdout
  RESULT=$?
  set -e

  if [[ "${RESULT}" -ne 0 ]] ; then
    echo "${CODE} ${INSTR} Fail"
    exit 1
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
    exit 1
  else
    echo "${CODE} ${INSTR} Pass"
  fi

done

bash test/cleanup.sh
