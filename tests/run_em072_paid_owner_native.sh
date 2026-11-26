#!/usr/bin/env bash
# EM072 paid helper-owner safety: exact official 0.1.69 fullmod, real native 2.1.24.
# This is an external QA experiment, NOT a production mod patch or a release.
set -euo pipefail
cd "$(dirname "$0")/.."
: "${FACTORIO_BIN:?Provide Factorio 2.1.24 Linux headless executable}"
: "${EM072_FULL_GAME_ZIP:?Provide exact official ElectrifiedMainline_0.1.69.zip}"
expected=2915cf0a89670d12de9db4289aa7b9043467e8b9705b547bb4e21aa526edaa54
actual=$(sha256sum "$EM072_FULL_GAME_ZIP" | awk '{print $1}')
[[ "$actual" == "$expected" ]] || { echo "FULL-MOD provenance mismatch: $actual" >&2; exit 2; }
"$FACTORIO_BIN" --version | grep -F '2.1.24' >/dev/null
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/mods"
cp "$EM072_FULL_GAME_ZIP" "$work/mods/ElectrifiedMainline_0.1.69.zip"
cp -a tests/em072-paidowner-lifecycle "$work/mods/em072-paidowner-lifecycle_0.0.1"
cat > "$work/mods/mod-list.json" <<'JSON'
{"mods":[{"name":"base","enabled":true},{"name":"ElectrifiedMainline","enabled":true},{"name":"em072-paidowner-lifecycle","enabled":true}]}
JSON
positive=(owner_delete owner_split owner_second owner_isolated_sink owner_scarce owner_two owner_four)
for case_id in "${positive[@]}"; do
  if ! "$FACTORIO_BIN" --mod-directory "$work/mods" --test-scenario em072-paidowner-lifecycle/paid --test-arg "$case_id" --test-ticks 245 > "$work/$case_id.log" 2>&1; then
    echo "FAIL: $case_id" >&2; tail -75 "$work/$case_id.log" >&2; exit 1
  fi
  grep -F 'Test passed' "$work/$case_id.log" >/dev/null || { echo "No native pass: $case_id" >&2; exit 1; }
  grep -E '\[EM072 PAIDPROOF\]|\[EM072 OWNER SAFE GC\]' "$work/$case_id.log" | grep -E '(OWNER_RESULT|RESULT|OWNER SAFE GC)' | tail -2
  echo "NATIVE_PASS case=$case_id"
done
# Deliberate, unresolved third-party destruction must NEVER be reported as a pass.
if "$FACTORIO_BIN" --mod-directory "$work/mods" --test-scenario em072-paidowner-lifecycle/paid --test-arg owner_external_destroy --test-ticks 245 > "$work/owner_external_destroy.log" 2>&1; then
  echo 'FAIL: malicious external removal silently passed' >&2; exit 1
fi
grep -F '[EM072 OWNER UNRECOVERABLE]' "$work/owner_external_destroy.log" >/dev/null || { tail -75 "$work/owner_external_destroy.log" >&2; exit 1; }
echo 'EXPECTED_FEATURE_FAIL: unannounced third-party destroy of paid helper cannot reconstruct paid J'
echo 'EM072 RESEARCH RESULT: 7/7 native owner-safety positives, 1 explicitly unresolved negative, NO gameplay runtime modifications'