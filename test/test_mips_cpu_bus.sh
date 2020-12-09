#!/bin/bash
set -eou pipefail

# Can be used to echo commands
# set -o xtrace


# Specific test-case.
# $1, $2, $2, ... represent the arguments passed to the script
SOURCE="$1" #Source directory containing RTL implementation
INSTRUCTION="$2" #lower-case name of instruction being tested
TESTCASES= "test/1-hex/${2:-*}*.hex.txt" #list of testcases being tested either starting with instruction being tested or all if no instruction is specified
TEST_DIRECTORY="test/"

# Redirect output to stder (&2) so that it seperate from genuine outputs
# Using ${VARIANT} substitutes in the value of the variable VARIANT
for i in ${TESTCASES}; do
  TESTNAME=$(basename ${i} .hex.txt)
  >&2 echo " 1 - Compiling test-bench"
  # Compile a specific simulator for this testbench.
  # -s specifies exactly which testbench should be top-level
  # The -P command is used to modify the RAM_INIT_FILE parameter on the test-bench at compile-time
  iverilog -g 2012 \
     ${SOURCE}/mips_cpu_*.v ${TEST_DIRECTORY}test_mips_cpu_bus_${TESTNAME}.v rtl/mips_cpu_ram.v \
     -s test_mips_cpu_bus_${TESTCASE} \
     -P test_mips_cpu_bus_${TESTCASE}.RAM_INIT_FILE=\"test/hex/${TESTCASE}.hex.txt\" \
     -o test/simulator/mips_cpu_bus_${TESTCASE}

  >&2 echo "  2 - Running test-bench"
  # Run the simulator, and capture all output to a file
  # Use +e to disable automatic script failure if the command fails, as
  # it is possible the simulation might go wrong.
  set +e
  test/2-simulator/mips_cpu_bus_${TESTCASE} > test/3-output/mips_cpu_bus_${TESTCASE}.stdout
  # Capture the exit code of the simulator in a variable
  RESULT=$?
  set -e

  # Check whether the simulator returned a failure code, and immediately quit
  if [[ "${RESULT}" -ne 0 ]] ; then
     echo " ${TESTCASE}, FAIL"
     exit
  fi

  >&2 echo "    Extracting result of OUT instructions"
  # This is the prefix for simulation output lines containing result of OUT instruction
  PATTERN="CPU : OUT   :"
  NOTHING=""
  # Use "grep" to look only for lines containing PATTERN
  set +e
  grep "${PATTERN}" test/3-output/mips_cpu_bus_${TESTCASE}.stdout > test/3-output/mips_cpu_bus_${TESTCASE}.out-lines
  set -e
  # Use "sed" to replace "CPU : OUT   :" with nothing
  sed -e "s/${PATTERN}/${NOTHING}/g" test/3-output/mips_cpu_bus_${TESTCASE}.out-lines > test/3-output/mips_cpu_bus_${TESTCASE}.out

  >&2 echo "  4 - Running reference simulator"
  # This is the
  set +e
  bin/simulator < test/1-hex/${TESTCASE}.hex.txt > test/4-reference/${TESTCASE}.out
  set -e

  >&2 echo "  b - Comparing output"
  # Note the -w to ignore whitespace
  set +e
  diff -w test/4-reference/${TESTCASE}.out test/3-output/mips_cpu_bus_${TESTCASE}.out
  RESULT=$?
  set -e

  # Based on whether differences were found, either pass or fail
  if [[ "${RESULT}" -ne 0 ]] ; then
     echo "  ${TESTCASE}, FAIL"
  else
     echo "  ${TESTCASE}, pass"
  fi
done
