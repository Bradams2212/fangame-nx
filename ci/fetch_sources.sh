#!/bin/bash
# Download upstream sources into src/ at the versions the patches were written against.
. "$(dirname "$0")/env.sh"
cd "$WS/src"

dl() {  # dl <out-file> <url> [<fallback-url>...]
  local out="$1"; shift
  for u in "$@"; do
    echo "download $u"
    curl -fL --retry 3 --connect-timeout 20 -o "$out" "$u" && return 0
  done
  return 1
}

# --- CRuby 3.1.7 (release tarball: includes ./configure and generated parser) ---
if [ ! -d ruby-3.1.7 ]; then
  if dl ruby-3.1.7.tar.gz https://cache.ruby-lang.org/pub/ruby/3.1/ruby-3.1.7.tar.gz; then
    tar xzf ruby-3.1.7.tar.gz && rm ruby-3.1.7.tar.gz
  else
    echo "tarball failed; falling back to git + autogen"
    git clone -q --depth 1 --branch v3_1_7 https://github.com/ruby/ruby.git ruby-3.1.7
    (cd ruby-3.1.7 && ./autogen.sh)
  fi
fi

# --- mkxp-z 2.4.2 ---
if [ ! -d mkxp-z ]; then
  git clone -q --depth 1 --branch v2.4.2 https://github.com/mkxp-z/mkxp-z.git mkxp-z
fi

# --- SDL_sound 2.0.x ---
if [ ! -d SDL_sound ]; then
  git clone -q --depth 1 --branch v2.0.4 https://github.com/icculus/SDL_sound.git SDL_sound
fi

# --- libiconv 1.16 ---
if [ ! -d libiconv-1.16 ]; then
  dl libiconv-1.16.tar.gz https://ftpmirror.gnu.org/libiconv/libiconv-1.16.tar.gz https://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.16.tar.gz \
    || die "cannot download libiconv"
  tar xzf libiconv-1.16.tar.gz && rm libiconv-1.16.tar.gz
fi

# --- uchardet 0.0.8 ---
if [ ! -d uchardet ]; then
  dl uchardet.tar.xz https://www.freedesktop.org/software/uchardet/releases/uchardet-0.0.8.tar.xz || die "cannot download uchardet"
  mkdir uchardet && tar xJf uchardet.tar.xz -C uchardet --strip-components=1 && rm uchardet.tar.xz
fi

# --- pixman 0.42.2 ---
if [ ! -d pixman ]; then
  dl pixman.tar.gz https://cairographics.org/releases/pixman-0.42.2.tar.gz https://www.x.org/releases/individual/lib/pixman-0.42.2.tar.gz \
    || die "cannot download pixman"
  mkdir pixman && tar xzf pixman.tar.gz -C pixman --strip-components=1 && rm pixman.tar.gz
fi

ls -d "$WS"/src/*/ 
