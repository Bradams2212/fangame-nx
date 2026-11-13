#!/bin/bash
# mkxp-z-nx -> rgss-switch.nro / .elf
. "$(dirname "$0")/env.sh"
cd "$WS"
[ -f out/nx/lib/libruby-static.a ] || die "libruby-static.a missing"
command -v python >/dev/null || ln -sf "$(command -v python3)" /usr/local/bin/python   # Makefile calls `python`

say "shaders / embedded assets (gen-xxd.sh, linuxized)"
if [ ! -d mkxp-z-nx/generated ]; then
  linuxize gen-xxd.sh > build/gen-xxd.linux.sh
  bash build/gen-xxd.linux.sh
fi

say "make"
# RAIZ/DEVKITPRO are overridden: the Makefile hard-codes Windows forms of both.
make -C mkxp-z-nx -j"$NPROC" RAIZ="$WS" DEVKITPRO="$DEVKITPRO" 2>&1 | tee logs/engine-make.log | grep -vE "valid for C\+\+" | tail -40
[ -f mkxp-z-nx/rgss-switch.nro ] || { grep -nE "error|undefined reference|cannot find" logs/engine-make.log | head -40; die "rgss-switch.nro was not produced"; }
ls -la mkxp-z-nx/rgss-switch.nro mkxp-z-nx/rgss-switch.elf
