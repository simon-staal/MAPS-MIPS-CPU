#!/bin/bash

set -euo pipefail

OLD="$1"
NEW="$2"
T_D="../test"
PREFIX="test_mips_cpu_bus_"

cp ${T_D}/0-assembly/${PREFIX}${OLD}.asm ${T_D}/0-assembly/${PREFIX}${NEW}.asm
cp ${T_D}/1-hex/${PREFIX}${OLD}.hex.txt ${T_D}/1-hex/${PREFIX}${NEW}.hex.txt
touch ${T_D}/4-reference/${PREFIX}${NEW}.txt

git add ${T_D}/0-assembly/${PREFIX}${NEW}.asm ${T_D}/1-hex/${PREFIX}${NEW}.hex.txt {T_D}/4-reference/${PREFIX}${NEW}.txt
