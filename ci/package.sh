#!/bin/bash
# Assemble release/rgss-switch-<VERSION>.zip with the layout Empaquetar.ps1 expects
# (same as construir.sh step 4). The Windows helper tools (nacptool.exe etc.) cannot be built
# on Linux, so tools/ is left empty: that only disables the optional installable .nsp.
. "$(dirname "$0")/env.sh"
cd "$WS"
VERSION="$(cat VERSION)"; ENT="release/rgss-switch-$VERSION"
rm -rf "$ENT"; mkdir -p "$ENT/motor" "$ENT/lib/io" "$ENT/tools" "$ENT/shims" "$ENT/diagnostico"

cp mkxp-z-nx/rgss-switch.nro "$ENT/motor/"
elf2nso mkxp-z-nx/rgss-switch.elf "$ENT/motor/main"
cp nsp/icono.jpg nsp/npdm.json "$ENT/motor/"

cp runtime/lib/*.rb "$ENT/lib/"; cp runtime/lib/io/*.rb "$ENT/lib/io/"
n=0
while read -r f; do
  case "$f" in ''|'#'*) continue ;; esac
  mkdir -p "$ENT/lib/$(dirname "$f")"; cp "src/ruby-3.1.7/lib/$f" "$ENT/lib/$f"; n=$((n+1))
done < runtime/lib-stdlib.txt
echo "lib/: stdlib files copied: $n"

cp runtime/mkxp.base.json "$ENT/mkxp.base.json"
cp -r juegos "$ENT/juegos"
cp runtime/shims/* "$ENT/shims/"
cp runtime/mkxp.diagnostico.json "$ENT/"; cp runtime/diagnostico/*.rb "$ENT/diagnostico/"

# Profile for Pokemon GS Vitro (see ci/extra)
if [ -f "$CI_DIR/extra/perfil-gs-vitro.json" ]; then
  mkdir -p "$ENT/juegos/pokemon-gs-vitro"; cp "$CI_DIR/extra/perfil-gs-vitro.json" "$ENT/juegos/pokemon-gs-vitro/perfil.json"
fi

echo "Windows helper tools are not built by this Linux workflow; .nsp creation is disabled, the .nro works." > "$ENT/tools/LEEME.txt"
cp Empaquetar.ps1 Empaquetar.cmd GUIA.md LICENSE LICENCIAS.md "$ENT/"
echo "$VERSION $(date -u '+%Y-%m-%d') (linux-ci)" > "$ENT/VERSION.txt"
( cd release && rm -f "rgss-switch-$VERSION.zip" && zip -qr "rgss-switch-$VERSION.zip" "rgss-switch-$VERSION" )
ls -la "release/rgss-switch-$VERSION.zip"
