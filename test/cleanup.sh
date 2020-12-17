#!/bin/bash

# This script is to empty out the garbage in 2-simulator and 3-output

set -euo pipefail

rm 2-simulator/test_mips_cpu_bus_*
rm 3-output/test_mips_cpu_bus_*
