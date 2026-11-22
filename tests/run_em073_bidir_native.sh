#!/usr/bin/env bash
# Real FULL Factorio test, not a mock and not a source-only green check.
set -euo pipefail
repo="$(cd "$(dirname "$0")/.." && pwd)"
: "${FACTORIO_BIN:?Path to official Factorio 2.1.24 headless executable required}"
: "${EM073_OFFICIAL_ZIP:?Path to official full mod ElectrifiedMainline_0.1.73.zip required}"
"$FACTORIO_BIN" --version | grep -Fq '2.1.24'
if [[ -n "${EM073_ZIP_SHA256:-}" ]]; then
 echo "$EM073_ZIP_SHA256  $EM073_OFFICIAL_ZIP" | sha256sum -c -
fi
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/mods"
cp "$EM073_OFFICIAL_ZIP" "$work/mods/ElectrifiedMainline_0.1.73.zip"
cp -a "$repo/tests/em072-bidir-qa" "$work/mods/em072-bidir-qa_0.0.1"
cat > "$work/mods/mod-list.json" <<'JSON'
{"mods":[{"name":"base","enabled":true},{"name":"ElectrifiedMainline","enabled":true},{"name":"em072-bidir-qa","enabled":true}]}
JSON
logs=${EM073_LOG_DIR:-$work/logs}
mkdir -p "$logs"
for scenario in single double_opposite bidir_reverse bidir_reversepassive bidir_auto bidir_zero bidir_offgrid bidir_ownerloss standalone200 long200highopp long200highopp_rev long200highsame; do
 ticks=306
 [[ "$scenario" != bidir_auto ]] || ticks=1710
 echo "[EM073 NATIVE] START:$scenario"
 "$FACTORIO_BIN" --mod-directory "$work/mods" --test-scenario em072-bidir-qa/native --test-arg "$scenario" --test-ticks "$ticks" > "$logs/$scenario.log" 2>&1 || { tail -45 "$logs/$scenario.log"; exit 1; }
 grep -Fq "[EM073 BIDIR QA] $scenario|PASS|" "$logs/$scenario.log" || { tail -45 "$logs/$scenario.log"; exit 1; }
 if [[ $scenario == bidir_auto ]]; then
   grep -Fq 'station=EM072_NATIVE_AUTO_TARGET' "$logs/$scenario.log" || exit 1
   grep -Fq 'station=EM073_NATIVE_RETURN_TARGET' "$logs/$scenario.log" || exit 1
 fi
 grep -F "[EM073 BIDIR QA] $scenario|SNAP|tick=300" "$logs/$scenario.log" | tail -1
 echo "[EM073 NATIVE] PASS:$scenario"
done
echo '[EM073 NATIVE] 12/12 PASS (includes 200 wagon no-loco and both AUTO stations)'