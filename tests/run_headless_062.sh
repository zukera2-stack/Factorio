#!/usr/bin/env bash
# 062 native regression: official Factorio 2.1.24, no user maps or saves changed.
set -euo pipefail
cd "$(dirname "$0")/.."
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/engine" "$work/package"
if [[ -n "${FACTORIO_BIN:-}" ]]; then
  engine="$FACTORIO_BIN"
else
  echo '[EM062] Downloading official Factorio headless 2.1.24 for CI'
  curl -fL --retry 2 --max-time 150 \
    'https://factorio.com/get-download/2.1.24/headless/linux64' -o "$work/engine.tar.xz"
  tar -xJf "$work/engine.tar.xz" -C "$work/engine"
  engine="$work/engine/factorio/bin/x64/factorio"
fi
"$engine" --version | tee "$work/version.txt"
grep -F '2.1.24' "$work/version.txt"
python3 scripts/package_mod.py --output "$work/package"
mod_version=$(python3 -c 'import json; print(json.load(open("ElectrifiedMainline/info.json"))["version"])')
case "$mod_version" in 0.1.62|0.1.63|0.1.64|0.1.65|0.1.66|0.1.67|0.1.68|0.1.69|0.1.70|0.1.71|0.1.72) ;; *) echo "Unsupported EM062 native regression mod version: $mod_version"; exit 1 ;; esac
test -f "$work/package/ElectrifiedMainline_${mod_version}.zip"
sha256sum "$work/package/ElectrifiedMainline_${mod_version}.zip"
for spec in \
 'em062-power-probe:1050:[EM061 NATIVE PASS]' \
 'em062-priority-probe:300:[EM061 MATRIX PASS]' \
 'em062-fairness-probe:680:[EM062 NATIVE PASS]'; do
  IFS=: read -r name ticks marker <<< "$spec"
  mkdir -p "$work/$name/mods"
  cp "$work/package/ElectrifiedMainline_${mod_version}.zip" "$work/$name/mods/"
  cp -a "tests/$name" "$work/$name/mods/${name}_0.0.1"
  printf '%s\n' "{\"mods\":[{\"name\":\"base\",\"enabled\":true},{\"name\":\"ElectrifiedMainline\",\"enabled\":true},{\"name\":\"$name\",\"enabled\":true}]}" > "$work/$name/mods/mod-list.json"
  echo "[EM062] $name: create map"
  "$engine" --mod-directory "$work/$name/mods" --create "$work/$name/save.zip" > "$work/$name/create.log" 2>&1 || { tail -40 "$work/$name/create.log"; exit 1; }
  echo "[EM062] $name: $ticks real Factorio ticks"
  "$engine" --mod-directory "$work/$name/mods" --benchmark "$work/$name/save.zip" --benchmark-ticks "$ticks" --benchmark-runs 1 > "$work/$name/bench.log" 2>&1 || { tail -70 "$work/$name/bench.log"; exit 1; }
  grep -F "$marker" "$work/$name/bench.log" || { tail -70 "$work/$name/bench.log"; exit 1; }
done
echo '[EM062 ENGINE QA PASS] 3/3 real native Factorio scenarios, 2030 ticks'