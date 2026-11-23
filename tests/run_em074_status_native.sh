#!/usr/bin/env bash
set -euo pipefail
: "${FACTORIO_BIN:?Path to Factorio 2.1.24 executable}"
: "${EM074_ZIP:?Path to ElectrifiedMainline_0.1.74.zip}"
base="$(cd "$(dirname "$0")/.." && pwd)"
"$FACTORIO_BIN" --version | grep -Fq '2.1.24'
if [[ -n "${EM074_SHA256:-}" ]]; then echo "$EM074_SHA256  $EM074_ZIP" | sha256sum -c -; fi
work=$(mktemp -d);trap 'rm -rf "$work"' EXIT
mkdir -p "$work/mods" "${EM074_LOG_DIR:-$work/logs}"
logs=${EM074_LOG_DIR:-$work/logs}
cp "$EM074_ZIP" "$work/mods/ElectrifiedMainline_0.1.74.zip"
cp -a "$base/tests/em074-status-qa" "$work/mods/em074-status-qa_0.0.1"
cp -a "$base/tests/em072-bidir-qa" "$work/mods/em072-bidir-qa_0.0.1"
printf '%s\n' '{"mods":[{"name":"base","enabled":true},{"name":"ElectrifiedMainline","enabled":true},{"name":"em074-status-qa","enabled":true},{"name":"em072-bidir-qa","enabled":true}]}' > "$work/mods/mod-list.json"
"$FACTORIO_BIN" --mod-directory "$work/mods" --test-scenario em074-status-qa/native --test-ticks 5 > "$logs/status.log" 2>&1
for marker in '[EM074 STATUS QA DATA] PASS' '[EM074 STATUS QA RUNTIME] PASS'; do grep -Fq "$marker" "$logs/status.log" || { tail -60 "$logs/status.log";exit 1; };done
printf '%s\n' 'PASS: EM074 prototype status (native)'
scenarios=(single double_opposite bidir_zero bidir_offgrid bidir_auto bidir_reverse bidir_ownerloss)
if [[ "${EM074_EXTENDED:-0}" == 1 ]]; then scenarios+=(bidir_reversepassive standalone200 long200highopp long200highopp_rev long200highsame); fi
for c in "${scenarios[@]}"; do
 ticks=306;[[ "$c" == bidir_auto ]] && ticks=1710
 "$FACTORIO_BIN" --mod-directory "$work/mods" --test-scenario em072-bidir-qa/native --test-arg "$c" --test-ticks "$ticks" >"$logs/$c.log" 2>&1 || { tail -60 "$logs/$c.log";exit 1; }
 grep -Fq "[EM073 BIDIR QA] $c|PASS|" "$logs/$c.log" || { tail -60 "$logs/$c.log";exit 1; }
 echo "PASS: $c"
done
printf 'PASS: %s actual fullmod native scenarios plus exact status prototype test\n' "${#scenarios[@]}"