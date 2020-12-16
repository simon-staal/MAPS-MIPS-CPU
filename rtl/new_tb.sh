#!/bin/bash

# Usage: bash new_tb.sh old_id new_id
# Creates files for new_id, copying the old_id assembly code / ram hex file

set -euo pipefail

OLD="$1"
NEW="$2"
T_D="../test"
PREFIX="test_mips_cpu_bus_"

cp ${T_D}/0-assembly/${PREFIX}${OLD}.asm ${T_D}/0-assembly/${PREFIX}${NEW}.asm
cp ${T_D}/1-hex/${PREFIX}${OLD}.hex.txt ${T_D}/1-hex/${PREFIX}${NEW}.hex.txt
touch ${T_D}/4-reference/${PREFIX}${NEW}.txt

git add ${T_D}/0-assembly/${PREFIX}${NEW}.asm ${T_D}/1-hex/${PREFIX}${NEW}.hex.txt ${T_D}/4-reference/${PREFIX}${NEW}.txt

# optional line, remove if you don't use atom
atom ${T_D}/0-assembly/${PREFIX}${NEW}.asm ${T_D}/1-hex/${PREFIX}${NEW}.hex.txt ${T_D}/4-reference/${PREFIX}${NEW}.txt
