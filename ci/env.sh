# Common environment for the Linux/GitHub Actions build. Sourced by every ci/*.sh script.
set -euo pipefail

CI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export WS="${WS:-$(cd "$CI_DIR/.." && pwd)}"          # repo checkout root

export DEVKITPRO="${DEVKITPRO:-/opt/devkitpro}"
export DEVKITA64="$DEVKITPRO/devkitA64"
export PORTLIBS="$DEVKITPRO/portlibs/switch"
export PATH="$DEVKITA64/bin:$DEVKITPRO/tools/bin:$PORTLIBS/bin:$PATH"

# Same code-generation flags the original scripts used.
export ARCH="-march=armv8-a+crc+crypto -mtune=cortex-a57 -mtp=soft -fPIE"
export NPROC="$(nproc 2>/dev/null || echo 4)"

mkdir -p "$WS/logs" "$WS/out/lib" "$WS/out/nx/lib" "$WS/out/nx/include" "$WS/build" "$WS/src" "$WS/docs"

say() { printf '\n=== %s ===\n' "$*"; }
die() { printf '\nFATAL: %s\n' "$*" >&2; exit 1; }

# Run the original repo scripts (hard-coded for the author's Windows PC) on Linux
# by rewriting their paths: C:/devkitPro, /c/devkitPro -> $DEVKITPRO ; C:/anilswitch, /c/anilswitch -> $WS
linuxize() { sed -e "s#C:/devkitPro#$DEVKITPRO#g" -e "s#/c/devkitPro#$DEVKITPRO#g" \
                 -e "s#C:/anilswitch#$WS#g" -e "s#/c/anilswitch#$WS#g" "$1"; }
