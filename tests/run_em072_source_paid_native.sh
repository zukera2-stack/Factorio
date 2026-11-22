#!/usr/bin/env bash
# Reproducible FULL-mod real Factorio 2.1.24 local research-only matrix.
# Does not download the engine, build the mod, touch save files, or alter user setup.
set -euo pipefail
cd "$(dirname "$0")/.."
: "${FACTORIO_BIN:?Set FACTORIO_BIN to exact official Factorio 2.1.24 executable}"
: "${EM072_FULL_GAME_ZIP:?Set EM072_FULL_GAME_ZIP to original full GHA 0.1.69 ZIP}"
EXPECTED=2915cf0a89670d12de9db4289aa7b9043467e8b9705b547bb4e21aa526edaa54
actual=$(sha256sum "$EM072_FULL_GAME_ZIP" | cut -d' ' -f1)
if [[ "$actual" != "$EXPECTED" ]]; then
 echo "PROVENANCE FAIL: wrong real fullmod ZIP SHA256 $actual, expected $EXPECTED" >&2; exit 2
fi
"$FACTORIO_BIN" --version | grep -F '2.1.24' >/dev/null
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/mods"
cp "$EM072_FULL_GAME_ZIP" "$work/mods/ElectrifiedMainline_0.1.69.zip"
cp -a tests/em072-source-paid-wagon-probe "$work/mods/em072-paidproof_0.0.1"
cat > "$work/mods/mod-list.json" <<'JSON'
{"mods":[{"name":"base","enabled":true},{"name":"ElectrifiedMainline","enabled":true},{"name":"em072-paidproof","enabled":true}]}
JSON
pass_cases=(base zero paid paid_fluid paid_both base4 paid4 paid_cut paid_offgrid paid_scarce paid_delete_fixed)
for case_id in "${pass_cases[@]}";do
 logpath="$work/$case_id.log"
 if ! "$FACTORIO_BIN" --mod-directory "$work/mods" --test-scenario em072-paidproof/paid --test-arg "$case_id" --test-ticks 240 > "$logpath" 2>&1;then
  echo "FAIL native case=$case_id"; tail -55 "$logpath"; exit 1
 fi
 grep -F 'Test passed' "$logpath" >/dev/null || { echo "Missing native PASS case=$case_id"; exit 1; }
 grep -E '\[EM072 PAIDPROOF\].* RESULT ' "$logpath" | tail -1
done
# This is an expected known defect, not a successful feature gate.
if "$FACTORIO_BIN" --mod-directory "$work/mods" --test-scenario em072-paidproof/paid --test-arg paid_delete --test-ticks 180 > "$work/paid_delete.log" 2>&1;then
 echo 'FAIL: owner-deletion defect unexpectedly stopped reproducing; re-audit before signoff'; exit 1
fi
grep -F 'ORPHAN: paid helper still exists' "$work/paid_delete.log" >/dev/null || { tail -50 "$work/paid_delete.log";exit 1; }
echo 'EXPECTED_FEATURE_FAIL: orphan charged helper after owner destroyed, NOT a production PASS'
echo 'RESEARCH_QA_PASS: 11 native positive scenarios + 1 explicitly expected feature failure; real fullmod unchanged'