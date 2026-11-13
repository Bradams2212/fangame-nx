#!/bin/bash
# Install the Switch libraries the engine links against, one package at a time so a single
# wrong package name does not abort the whole transaction (the original author hit this).
. "$(dirname "$0")/env.sh"
say "Switch portlibs"
dkp-pacman -Syu --noconfirm || dkp-pacman -Sy --noconfirm || true

REQUIRED="switch-dev switch-cmake devkitpro-pkgbuild-helpers
 switch-sdl2 switch-sdl2_image switch-sdl2_ttf switch-mesa switch-libdrm_nouveau switch-openal-soft
 switch-libogg switch-libvorbis switch-libtheora switch-mpg123 switch-libmodplug
 switch-physfs switch-freetype switch-harfbuzz switch-curl
 switch-libpng switch-libjpeg-turbo switch-libwebp switch-zlib switch-bzip2"

bad=""
for p in $REQUIRED; do
  if dkp-pacman -S --needed --noconfirm "$p" >"$WS/logs/pacman-$p.log" 2>&1; then echo "ok      $p"
  else echo "MISSING $p"; bad="$bad $p"; fi
done
[ -z "$bad" ] || echo "WARNING: could not install:$bad  (see logs/pacman-*.log; the engine link step will say if it matters)"

for l in libSDL2.a libphysfs.a libopenal.a libvorbisfile.a libtheora.a libcurl.a libEGL.a libfreetype.a; do
  [ -f "$PORTLIBS/lib/$l" ] && echo "have $l" || echo "NOT FOUND $l"
done
