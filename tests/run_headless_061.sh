#!/usr/bin/env bash
# CI-only; tests a disposable packaged SOURCE tree in exact Factorio 2.1.24.
# Does not modify test/updater-approved, the owner's game or any saves.
set -euo pipefail
test "${GITHUB_ACTIONS:-}" = "true" || { echo 'Native QA is CI-only unless manually invoked with GITHUB_ACTIONS=true'; exit 2; }
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/engine" "$work/mods"
echo '[EM061 NATIVE] Fetching official Factorio 2.1.24 headless for exact-source smoke and power regression'
curl --fail --location --retry 2 --max-time 150 "https://factorio.com/get-download/2.1.24/headless/linux64" --output "$work/engine.tar.xz"
tar -xJf "$work/engine.tar.xz" -C "$work/engine"
bin="$work/engine/factorio/bin/x64/factorio"
test -x "$bin"
"$bin" --version | tee "$work/version.txt"
grep -F '2.1.24' "$work/version.txt"
cp -a ElectrifiedMainline "$work/mods/ElectrifiedMainline_0.1.61"
cp -a tests/em061-power-probe "$work/mods/em061-power-probe_0.0.1"
printf '%s\n' '{"mods":[{"name":"base","enabled":true},{"name":"ElectrifiedMainline","enabled":true},{"name":"em061-power-probe","enabled":true}]}' > "$work/mods/mod-list.json"
"$bin" --mod-directory "$work/mods" --create "$work/native-save.zip" 2>&1 | tee "$work/create.log"
"$bin" --mod-directory "$work/mods" --benchmark "$work/native-save.zip" --benchmark-ticks 1050 --benchmark-runs 1 2>&1 | tee "$work/benchmark.log"
grep -F '[EM061 NATIVE PASS]' "$work/benchmark.log"
grep -F '[EM061 NATIVE] priority-mode API' "$work/benchmark.log"
echo '[EM061 NATIVE CI] PASS: exact source loaded, inherited 060 20MW/reverse regression, native EEI priority fields'
