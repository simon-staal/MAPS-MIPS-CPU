#!/bin/bash

set -euo pipefail

echo "Files in 0-assembly: "
ls 0-assembly | wc -l

echo "Files in 1-hex: "
ls 1-hex | wc -l

echo "Files in reference: "
ls 4-reference | wc -l

echo "Checking files in 0-assembly have matching files"
TESTCASES="0-assembly/test_mips_cpu_bus_*.asm"
for TESTCASE in ${TESTCASES}; do
  TESTNAME=$(basename ${TESTCASE} .asm)
  if [ ! -f "1-hex/${TESTNAME}.hex.txt" ]; then
    echo "1-hex/${TESTNAME}.hex.txt not found"
  fi
  if [ ! -f "4-reference/${TESTNAME}.txt" ]; then
    echo "4-reference/${TESTNAME}.txt not found"
  fi
done

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

echo "Checking files in 4-reference have matching files"
TESTCASES="4-reference/test_mips_cpu_bus_*.txt"
for TESTCASE in ${TESTCASES}; do
  TESTNAME=$(basename ${TESTCASE} .txt)
  if [ ! -f "0-assembly/${TESTNAME}.asm" ]; then
    echo "0-assembly/${TESTNAME}.asm not found"
  fi
  if [ ! -f "1-hex/${TESTNAME}.hex.txt" ]; then
    echo "1-hex/${TESTNAME}.hex.txt not found"
  fi
done
