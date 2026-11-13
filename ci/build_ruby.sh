#!/bin/bash
# Cross-compile CRuby 3.1.7 for Horizon and assemble out/nx (libruby-static.a + headers).
# Follows build-ruby-switch.sh + finalize-ruby.sh and the manual fixes documented in
# docs/bitacora-anil.md 5.11-5.19 (the repo never scripted those).
. "$(dirname "$0")/env.sh"
[ -f "$WS/out/nx/lib/libruby-static.a" ] && [ -f "$WS/out/nx/include/ruby.h" ] && { echo "ruby already built"; exit 0; }

SRC="$WS/src/ruby-3.1.7"; BUILD="$WS/build/ruby-switch"; SHIM="$WS/patches/include"
BASERUBY="$(command -v ruby)" || die "no host ruby (apt install ruby)"
echo "BASERUBY: $($BASERUBY --version)"

export CC=aarch64-none-elf-gcc CXX=aarch64-none-elf-g++ AR=aarch64-none-elf-ar RANLIB=aarch64-none-elf-ranlib
export STRIP=aarch64-none-elf-strip NM=aarch64-none-elf-nm OBJCOPY=aarch64-none-elf-objcopy LD=aarch64-none-elf-ld
INC="-I$SHIM -I$DEVKITPRO/libnx/include -I$PORTLIBS/include"
export CFLAGS="-g -O2 -std=gnu11 $ARCH -D__SWITCH__ -include $SHIM/nxshim.h -ffunction-sections -fdata-sections $INC"
export CPPFLAGS="-D__SWITCH__ -include $SHIM/nxshim.h $INC"
export LDFLAGS="-specs=$DEVKITPRO/libnx/switch.specs $ARCH -L$WS/out/lib -L$DEVKITPRO/libnx/lib -L$PORTLIBS/lib"
export LIBS="-lnxcompat -lnx"

[ -f "$WS/out/lib/libnxcompat.a" ] || die "libnxcompat.a missing (run build_nxcompat.sh first)"

say "Prepare Ruby tree (5.12, 5.13)"
rm -rf "$SRC/ext/-test-"          # 54 test-only extensions that abort the build
: > "$SRC/gems/bundled_gems"      # bundled gems link as shared objects; there is no dlopen here

say "configure"
rm -rf "$BUILD"; mkdir -p "$BUILD"; cd "$BUILD"
"$SRC/configure" \
  --host=aarch64-none-elf --target=aarch64-none-elf \
  --prefix="$WS/out/ruby-switch" \
  --disable-shared --disable-install-doc --disable-install-rdoc \
  --disable-dtrace --disable-jit-support --disable-yjit \
  --with-static-linked-ext \
  --with-baseruby="$BASERUBY" \
  --without-gmp \
  --with-out-ext=openssl,fiddle,pty,syslog,readline,dbm,gdbm,win32,win32ole,socket,etc \
  ac_cv_func_fork=no ac_cv_func_vfork=no ac_cv_func_daemon=no ac_cv_func_waitpid=yes \
  ac_cv_func_execv=no ac_cv_func_execve=no \
  ac_cv_func_dlopen=no ac_cv_lib_dl_dlopen=no \
  ac_cv_func_mmap_fixed_mapped=no \
  ac_cv_func_getcontext=no ac_cv_func_setcontext=no ac_cv_func_makecontext=no \
  ac_cv_header_ucontext_h=no ac_cv_header_sys_mman_h=no ac_cv_header_dlfcn_h=no \
  rb_cv_binary_elf=yes 2>&1 | tee "$WS/logs/ruby-configure.log" | tail -5
[ -f Makefile ] || { tail -40 "$WS/logs/ruby-configure.log"; die "Ruby configure failed (see config.log artifact)"; }

say "make -k (the final 'ruby' executable is EXPECTED to fail to link -- 5.16 -- we only need the libraries)"
make -k -j"$NPROC" LD=aarch64-none-elf-ld > "$WS/logs/ruby-make.log" 2>&1 || true
tail -15 "$WS/logs/ruby-make.log"
[ -f libruby-static.a ] || { grep -nE "error:|Error [0-9]" "$WS/logs/ruby-make.log" | head -30; die "libruby-static.a was not produced"; }
ls -la libruby-static.a

say "Extension objects: zlib, stringio, strscan + the hand-written extinit.c (5.17, 5.19)"
EXTOBJ="$WS/out/nx/extobj"; rm -rf "$EXTOBJ"; mkdir -p "$EXTOBJ"
RBARCH_INC="$(dirname "$(dirname "$(find "$BUILD/.ext/include" -name config.h -path '*/ruby/config.h' | head -1)")")"
[ -n "$RBARCH_INC" ] && [ -d "$RBARCH_INC" ] || die "cannot find generated ruby/config.h under $BUILD/.ext/include"
aarch64-none-elf-gcc $CFLAGS -I"$SRC/include" -I"$RBARCH_INC" -I"$SRC" -c "$WS/patches/extinit.c" -o "$EXTOBJ/extinit.o"
for e in zlib stringio strscan; do
  objs="$(find "$BUILD/ext/$e" -maxdepth 1 -name '*.o' 2>/dev/null)"
  [ -n "$objs" ] || { ls -la "$BUILD/ext/$e" 2>&1 | head; die "extension $e produced no object (see logs/ruby-make.log)"; }
  cp $objs "$EXTOBJ/"
done
ls -la "$EXTOBJ"

say "finalize: replace empty dmyext.o with the real extension registry (5.19)"
cp libruby-static.a "$WS/out/nx/lib/libruby-static.a"
cd "$WS/out/nx/lib"
aarch64-none-elf-ar d libruby-static.a dmyext.o || echo "(no dmyext.o to remove)"
aarch64-none-elf-ar r libruby-static.a "$EXTOBJ"/*.o
aarch64-none-elf-ar s libruby-static.a
for s in Init_zlib Init_stringio Init_strscan ruby_init_ext ruby_init; do
  printf "  %-16s : " "$s"; aarch64-none-elf-nm libruby-static.a 2>/dev/null | grep -qE " T $s$" && echo OK || echo MISSING
done
aarch64-none-elf-nm libruby-static.a 2>/dev/null | grep -qE " T Init_zlib$" || die "Init_zlib missing from libruby-static.a -- RPG Maker data files could not be read"

say "Ruby headers -> out/nx/include (flat layout the engine Makefile expects)"
rm -rf "$WS/out/nx/include/ruby" "$WS/out/nx/include/ruby.h"
cp -r "$SRC/include/ruby" "$SRC/include/ruby.h" "$WS/out/nx/include/"
cp "$RBARCH_INC/ruby/config.h" "$WS/out/nx/include/ruby/config.h"
ls "$WS/out/nx/include" | head
