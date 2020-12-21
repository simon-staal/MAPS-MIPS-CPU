#!/bin/bash

# Run testbench on given hex file, full hex file name as input

set -eou pipefail

SOURCE=$1
TESTCASE="test_mips_cpu_bus_$2.hex.txt"
TEST_DIRECTORY="test"

TESTNAME=$(basename ${TESTCASE} .hex.txt)
INSTR=$(echo $TESTNAME | cut -d'_' -f 5)
NUM=$(echo $TESTNAME | cut -d'_' -f 6)
CODE="${INSTR}_${NUM}"
# Redirect output to stder (&2) so that it seperate from genuine outputs
# Using ${VARIANT} substitutes in the value of the variable VARIANT

iverilog -g 2012 \
  -s  mips_cpu_bus_tb \
  -P mips_cpu_bus_tb.RAM_INIT_FILE=\"${TEST_DIRECTORY}/1-hex/${TESTCASE}\" \
  -P mips_cpu_bus_tb.TESTCASE_ID=\"${CODE}\" \
  -P mips_cpu_bus_tb.INSTRUCTION=\"${INSTR}\" \
  -o ${TEST_DIRECTORY}/2-simulator/${TESTNAME} \
  -I ${SOURCE} \
  ${SOURCE}/mips_cpu_*.v ${SOURCE}/mips_cpu_*.vh ${SOURCE}/mips_cpu/*.v ${TEST_DIRECTORY}/src/test_mips_cpu_bus_generic.v ${TEST_DIRECTORY}/src/mips_cpu_ram_wait.v

 set +e
 ${TEST_DIRECTORY}/2-simulator/${TESTNAME} > ${TEST_DIRECTORY}/3-output/${TESTNAME}.stdout
 RESULT=$?
 set -e

# cat ${TEST_DIRECTORY}/3-output/${TESTNAME}.stdout

 if [[ "${RESULT}" -ne 0 ]] ; then
   echo "${CODE} ${INSTR} Fail"
   exit
 fi

 PATTERN="FINAL OUT: "
 NOTHING=""

 set +e
 grep "${PATTERN}" ${TEST_DIRECTORY}/3-output/${TESTNAME}.stdout > ${TEST_DIRECTORY}/3-output/${TESTNAME}.out-v0
 set -e

 sed -e "s/${PATTERN}/${NOTHING}/g" ${TEST_DIRECTORY}/3-output/${TESTNAME}.out-v0 > ${TEST_DIRECTORY}/3-output/${TESTNAME}.out

echo "Testbench output"
cat ${TEST_DIRECTORY}/3-output/${TESTNAME}.out

echo "Reference output"
cat ${TEST_DIRECTORY}/4-reference/${TESTNAME}.txt

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

bash test/cleanup.sh
