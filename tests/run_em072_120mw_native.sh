#!/usr/bin/env bash
# Run exact experimental full ZIP on native Factorio 2.1.24; no helper/J injection.
set -euo pipefail
cd "$(dirname "$0")/.."
: "${FACTORIO_BIN:?Factorio 2.1.24 binary required}"
: "${EM072_072_ZIP:?Original full ElectrifiedMainline_0.1.72.zip required}"
"$FACTORIO_BIN" --version | grep -F '2.1.24' >/dev/null
if [[ -n "${EM072_072_SHA256:-}" ]]; then
  echo "$EM072_072_SHA256  $EM072_072_ZIP" | sha256sum -c -
fi
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/mods" "$work/logs"
cp "$EM072_072_ZIP" "$work/mods/ElectrifiedMainline_0.1.72.zip"
cp -a tests/em072-integration-qa "$work/mods/em072-integration-qa_0.0.1"
cat >"$work/mods/mod-list.json" <<'JSON'
{"mods":[{"name":"base","enabled":true},{"name":"ElectrifiedMainline","enabled":true},{"name":"em072-integration-qa","enabled":true}]}
JSON
for c in zero offgrid single long200high20 long200high; do
 echo "EM072_HIGH_SOURCE_CASE:$c"
 "$FACTORIO_BIN" --mod-directory "$work/mods" --test-scenario em072-integration-qa/native --test-arg "$c" --test-ticks 306 >"$work/logs/$c.log" 2>&1 || { tail -45 "$work/logs/$c.log"; exit 1; }
 grep -qF "[EM072 INT QA] $c|PASS|" "$work/logs/$c.log" || { tail -45 "$work/logs/$c.log"; exit 1; }
 grep -F "[EM072 INT QA] $c|SNAP|tick=300" "$work/logs/$c.log" | tail -1
 done
 echo "EM072_HIGH_SOURCE_NATIVE_PASS:5"