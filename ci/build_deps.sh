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

missing=""
for l in $need; do [ -f "$WS/out/nx/lib/$l" ] || missing="$missing $l"; done
if [ -n "$missing" ]; then
  echo "---- missing:$missing ; tails of the dependency logs ----"
  for f in docs/dep-*.log; do echo "## $f"; tail -25 "$f"; done
  die "dependency build failed:$missing"
fi
ls -la out/nx/lib/*.a
