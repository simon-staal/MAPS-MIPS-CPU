#!/bin/bash

set -euo pipefail

echo "Files in 0-assembly: "
ls 0-assembly | wc -l

echo "Files in 1-hex: "
ls 1-hex | wc -l

echo "Files in reference: "
ls 4-reference | wc -l

echo "Checking files in 1-hex have matching files"
TESTCASES="1-hex/test_mips_cpu_bus_*.hex.txt"
for TESTCASE in ${TESTCASES}; do
  TESTNAME=$(basename ${TESTCASE} .hex.txt)
  if [ ! -f "0-assembly/${TESTNAME}.asm" ]; then
    echo "0-assembly/${TESTNAME}.asm not found"
  fi
  if [ ! -f "4-reference/${TESTNAME}.txt" ]; then
    echo "4-reference/${TESTNAME}.txt not found"
  fi
done
