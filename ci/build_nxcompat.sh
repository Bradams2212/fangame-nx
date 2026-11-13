#!/bin/bash
# libnxcompat.a: the POSIX functions newlib declares but does not implement (sysconf, waitpid, ...).
# The original repo never scripted this step.
. "$(dirname "$0")/env.sh"
[ -f "$WS/out/lib/libnxcompat.a" ] && { echo "libnxcompat.a already built"; exit 0; }
say "libnxcompat.a"
cd "$WS"
aarch64-none-elf-gcc -g -O2 -std=gnu11 $ARCH -D__SWITCH__ -include patches/include/nxshim.h \
  -ffunction-sections -fdata-sections -Ipatches/include -I"$DEVKITPRO/libnx/include" \
  -c patches/nxcompat.c -o build/nxcompat.o
aarch64-none-elf-ar rcs out/lib/libnxcompat.a build/nxcompat.o
cp out/lib/libnxcompat.a out/nx/lib/libnxcompat.a        # the engine Makefile looks in out/nx/lib
aarch64-none-elf-nm out/lib/libnxcompat.a | grep -E " T (sysconf|waitpid|setmode)$"
