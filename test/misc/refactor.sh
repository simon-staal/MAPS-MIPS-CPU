#!/bin/bash
set -euo pipefail

TESTCASES="test_mips_cpu_bus_*.v"

for i in ${TESTCASES}; do
  echo ${i}
  TESTNAME=$(basename ${i} .v)
  touch 0-assembly/${TESTNAME}.asm
  touch 1-hex/${TESTNAME}.hex.txt
  touch 4-reference/${TESTNAME}.txt
done
