#!/bin/bash
# libiconv, uchardet, SDL_sound, pixman -> out/nx  (runs the repo's build-deps.sh with Linux paths)
. "$(dirname "$0")/env.sh"
need="libiconv.a libuchardet.a libSDL2_sound.a libpixman-1.a"
have_all=1; for l in $need; do [ -f "$WS/out/nx/lib/$l" ] || have_all=0; done
[ $have_all = 1 ] && { echo "dependencies already built"; exit 0; }

say "build-deps.sh (linuxized)"
cd "$WS"
linuxize build-deps.sh > build/build-deps.linux.sh
bash build/build-deps.linux.sh 2>&1 | tee logs/build-deps.log || true

# build-deps.sh exports LDFLAGS with -specs=switch.specs, which clashes with the CMake toolchain file
# ("linker script ... appears multiple times"), so its uchardet and SDL_sound steps fail on Linux.
# build-deps2.sh builds those two the working way (static try-compile, no LDFLAGS).
say "build-deps2.sh (linuxized): uchardet + SDL_sound"
linuxize build-deps2.sh > build/build-deps2.linux.sh
bash build/build-deps2.linux.sh 2>&1 | tee logs/build-deps2.log || true

# uchardet's own *test program* fails to link (C test, C++ library, no libstdc++), which aborts
# `make install` even though libuchardet.a itself built fine. Install the library and header by hand.
# The engine does `#include <uchardet.h>`, so the header goes in include/ and include/uchardet/.
if [ ! -f out/nx/lib/libuchardet.a ]; then
  built="$(find build/uchardet -name libuchardet.a 2>/dev/null | head -1)"
  if [ -n "$built" ]; then
    echo "installing uchardet by hand from $built"
    cp "$built" out/nx/lib/libuchardet.a
  fi
fi
if [ -f out/nx/lib/libuchardet.a ]; then
  mkdir -p out/nx/include/uchardet
  cp src/uchardet/src/uchardet.h out/nx/include/uchardet.h
  cp src/uchardet/src/uchardet.h out/nx/include/uchardet/uchardet.h
fi

missing=""
for l in $need; do [ -f "$WS/out/nx/lib/$l" ] || missing="$missing $l"; done
if [ -n "$missing" ]; then
  echo "---- missing:$missing ; tails of the dependency logs ----"
  for f in docs/dep-*.log; do echo "## $f"; tail -25 "$f"; done
  die "dependency build failed:$missing"
fi
ls -la out/nx/lib/*.a
