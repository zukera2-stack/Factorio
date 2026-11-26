#!/usr/bin/env bash
# Known functional blocker (should fail on 0.1.71): real opposite-cab reverse traction
# Usage: FACTORIO_BIN=/path/to/factorio EM072_071_ZIP=/path/to/ElectrifiedMainline_0.1.71.zip bash tests/run_em072_reverse_boundary.sh
set -euo pipefail
cd "$(dirname "$0")/.."
: "${FACTORIO_BIN:?Official Factorio 2.1.24 headless binary required}"
: "${EM072_071_ZIP:?Exact full official ElectrifiedMainline_0.1.71 ZIP required}"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/mods"
cp "$EM072_071_ZIP" "$work/mods/ElectrifiedMainline_0.1.71.zip"
cp -a tests/em072-reverse-qa "$work/mods/em072-reverse-qa_0.0.1"
cat > "$work/mods/mod-list.json" <<'JSON'
{"mods":[{"name":"base","enabled":true},{"name":"ElectrifiedMainline","enabled":true},{"name":"em072-reverse-qa","enabled":true}]}
JSON
for C in reverse reversepassive;do
 "$FACTORIO_BIN" --mod-directory "$work/mods" --test-scenario em072-reverse-qa/native --test-arg "$C" --test-ticks 306 >"$work/$C.log" 2>&1 || { tail -35 "$work/$C.log";exit 1; }
 grep -q "\[EM072 INT QA\].*$C|PASS|" "$work/$C.log" || { tail -35 "$work/$C.log";exit 1; }
done
python - "$work/reverse.log" "$work/reversepassive.log" <<'PY'
import re,sys
from pathlib import Path
def measure(path,case):
 text=Path(path).read_text()
 rows=[x for x in text.splitlines() if f'[EM072 INT QA] {case}|SNAP|tick=300' in x]
 assert len(rows)==1,(case,'missing tick300',len(rows))
 m=re.search(r'\bdistance=([-\d.]+)\b.*\bspeed=([-\d.]+)',rows[0])
 assert m,(case,rows[0])
 return float(m.group(1)),float(m.group(2))
a=measure(sys.argv[1],'reverse');b=measure(sys.argv[2],'reversepassive')
print(f'native reverse from rear cab / exact official fullmod: MOTOR {a[0]} tiles speed {a[1]}; PASSIVE {b[0]} tiles speed {b[1]}')
if not (a[0]>b[0]+2 and a[1]<0 and b[1]<0):
 raise SystemExit('EM072 REVERSE FUNCTIONAL FAIL: paid motor helper does not increase native reverse traction. Gate NOT accepted.')
print('EM072 REVERSE PASS: accepted source-paid true reverse motor boost')
PY