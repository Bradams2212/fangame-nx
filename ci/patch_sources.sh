#!/bin/bash
# Apply the repo's patches: 0001-0005 to CRuby (the 37 syntax-transform patches 0006-0042 are
# intentionally NOT applied -- the engine handles Ruby 1.8 syntax at load time instead),
# and ORDEN.txt-ordered mkxpz-*.patch to mkxp-z.
. "$(dirname "$0")/env.sh"
cd "$WS"

if [ ! -f src/ruby-3.1.7/.nx-patched ]; then
  say "Ruby patches 0001-0005"
  for f in $(ls patches/000[1-5]-*.patch | sort); do
    patch -p0 -s -f --no-backup-if-mismatch < "$f" || die "Ruby patch failed: $f"
    echo "ok  $(basename "$f")"
  done
  touch src/ruby-3.1.7/.nx-patched
fi

if [ ! -f src/mkxp-z/.nx-patched ]; then
  say "mkxp-z patches (ORDEN.txt)"
  REPO_ROOT="$WS" MKXPZ_TREE="$WS/src/mkxp-z" python3 "$CI_DIR/apply_mkxpz_patches.py" || die "mkxp-z patching failed"
  touch src/mkxp-z/.nx-patched
fi
