#!/bin/bash

# Run testbench on given hex file, full hex file name as input

set -eou pipefail

SOURCE=$1
TESTCASE="$2.hex.txt"
TEST_DIRECTORY="."
TB_DIR=".."

TESTNAME=$(basename ${TESTCASE} .hex.txt)
# Redirect output to stder (&2) so that it seperate from genuine outputs
# Using ${VARIANT} substitutes in the value of the variable VARIANT

iverilog -g 2012 \
  -s  mips_cpu_bus_tb \
  -P mips_cpu_bus_tb.RAM_INIT_FILE=\"${TEST_DIRECTORY}/1-hex/${TESTCASE}\" \
  -P mips_cpu_bus_tb.TESTCASE_ID=\"${TESTNAME}\" \
  -P mips_cpu_bus_tb.INSTRUCTION=\"test\" \
  -o ${TEST_DIRECTORY}/2-simulator/${TESTNAME} \
  -I ${SOURCE} \
  ${SOURCE}/mips_cpu_*.v ${SOURCE}/mips_cpu_*.vh ${SOURCE}/mips_cpu/*.v ${TB_DIR}/src/test_mips_cpu_bus_generic.v ${TB_DIR}/src/mips_cpu_ram_wait.v

 set +e
 ${TEST_DIRECTORY}/2-simulator/${TESTNAME} > ${TEST_DIRECTORY}/3-output/${TESTNAME}.stdout
 RESULT=$?
 set -e

# cat ${TEST_DIRECTORY}/3-output/${TESTNAME}.stdout

 if [[ "${RESULT}" -ne 0 ]] ; then
   echo "${TESTCASE} Fail"
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
  echo "${TESTCASE} Fail"
  exit 1
else
  echo "${TESTCASE} Pass"
fi

bash ${TEST_DIRECTORY}/cleanup.sh
