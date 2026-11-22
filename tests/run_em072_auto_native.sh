#!/usr/bin/env bash
# Exact full-zip, full runtime native engine integration QA. No gameplay fixture grants hidden J.
set -euo pipefail
cd "$(dirname "$0")/.."
: "${FACTORIO_BIN:?Set FACTORIO_BIN to official Factorio 2.1.24 headless executable}"
: "${EM072_071_ZIP:?Set EM072_071_ZIP to an ORIGINAL full ElectrifiedMainline_0.1.71.zip}"
"$FACTORIO_BIN" --version | grep -F '2.1.24' >/dev/null
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/mods" "$work/logs"
cp "$EM072_071_ZIP" "$work/mods/ElectrifiedMainline_0.1.71.zip"
cp -a tests/em072-integration-qa "$work/mods/em072-integration-qa_0.0.1"
cat > "$work/mods/mod-list.json" <<'JSON'
{"mods":[{"name":"base","enabled":true},{"name":"ElectrifiedMainline","enabled":true},{"name":"em072-integration-qa","enabled":true}]}
JSON
cases=(single double_same double_opposite brownout offgrid zero nonmotor vanilla split loss auto long64 long64passive long128 long200 long200dual long64pushpull long256)
for scenario in "${cases[@]}"; do
  ticks=306
  [[ $scenario == long* ]] && ticks=1206
  [[ $scenario == long200* || $scenario == long256 ]] && ticks=306
  [[ $scenario == auto ]] && ticks=506
  echo "Native fullmod $scenario ($ticks ticks)"
  "$FACTORIO_BIN" --mod-directory "$work/mods" --test-scenario em072-integration-qa/native --test-arg "$scenario" --test-ticks "$ticks" >"$work/logs/$scenario.log" 2>&1 || { tail -60 "$work/logs/$scenario.log";exit 1; }
  grep -q "\[EM072 INT QA\].*|PASS|" "$work/logs/$scenario.log" || { tail -60 "$work/logs/$scenario.log";exit 1; }
  grep "\[EM072 INT QA\].*|PASS|" "$work/logs/$scenario.log" | tail -1
 done