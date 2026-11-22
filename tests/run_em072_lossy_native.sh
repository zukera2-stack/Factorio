#!/usr/bin/env bash
# Isolated actual Factorio 2.1.24 QA, NEVER an installation or release script.
set -euo pipefail
cd "$(dirname "$0")/.."
: "${FACTORIO_BIN:?Point to official Factorio 2.1.24 headless executable}"
: "${EM072_GAME_ZIP:?Point to experimental full ElectrifiedMainline_0.1.70.zip}"
"$FACTORIO_BIN" --version | grep -F '2.1.24' >/dev/null
python3 - "$EM072_GAME_ZIP" <<'PY'
import zipfile,json,sys
with zipfile.ZipFile(sys.argv[1]) as z:
 info=json.loads(z.read('ElectrifiedMainline/info.json'))
 assert info['version']=='0.1.70',info['version']
 files=[n for n in z.namelist() if n.startswith('ElectrifiedMainline/') and not n.endswith('/')]
 assert len(files)==139,len(files)
 assert sum(n.endswith('.png') for n in files)==83
PY
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/mods"
cp "$EM072_GAME_ZIP" "$work/mods/ElectrifiedMainline_0.1.70.zip"
cp -a tests/em072-lossy-qa "$work/mods/em072-lossy-qa_0.0.1"
printf '%s\n' '{"mods":[{"name":"base","enabled":true},{"name":"ElectrifiedMainline","enabled":true},{"name":"em072-lossy-qa","enabled":true}]}' > "$work/mods/mod-list.json"
for scenario in loss_delete loss_split loss_second loss_foreign loss_two loss_four loss_scarce loss_external loss_keep loss_offgrid; do
  if ! "$FACTORIO_BIN" --mod-directory "$work/mods" --test-scenario em072-lossy-qa/paid --test-arg "$scenario" --test-ticks 245 > "$work/$scenario.log" 2>&1; then
    echo "FAIL: $scenario" >&2
    tail -70 "$work/$scenario.log" >&2
    exit 1
  fi
  grep -F 'Test passed' "$work/$scenario.log" >/dev/null || { tail -70 "$work/$scenario.log" >&2;exit 1; }
  echo "NATIVE PASS $scenario"
done
echo 'EM072 0.1.70 10/10 real full-mod native positive scenarios PASS; not a release gate'