#!/usr/bin/env bash
set -euo pipefail
: "${FACTORIO_BIN:?Set path to Factorio 2.1.24 Linux x64}"
: "${EM078_ZIP:?Set path to complete ElectrifiedMainline_0.1.78.zip}"
root="$(cd "$(dirname "$0")/.." && pwd)"
"$FACTORIO_BIN" --version | grep -Fq '2.1.24'
if [[ -n "${EM078_SHA256:-}" ]]; then
 printf '%s  %s\n' "$EM078_SHA256" "$EM078_ZIP" | sha256sum -c -
fi
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
logs="${EM078_LOG_DIR:-$work/logs}"
mkdir -p "$work/mods" "$logs"
cp "$EM078_ZIP" "$work/mods/ElectrifiedMainline_0.1.78.zip"
cp -a "$root/tests/em078-alert-qa" "$work/mods/em078-alert-qa_0.0.1"
cp -a "$root/tests/em077-block-qa" "$work/mods/em077-block-qa_0.0.1"
printf '%s\n' '{"mods":[{"name":"base","enabled":true},{"name":"ElectrifiedMainline","enabled":true},{"name":"em078-alert-qa","enabled":true},{"name":"em077-block-qa","enabled":true}]}' >"$work/mods/mod-list.json"
for c in 201 401 dual201 800 zero201; do
 "$FACTORIO_BIN" --mod-directory "$work/mods" --test-scenario em078-alert-qa/native --test-arg "$c" --test-ticks 55 > "$logs/no_path_$c.log" 2>&1 || { tail -70 "$logs/no_path_$c.log";exit 1; }
 grep -Fq "[EM078 QA DATA PASS]" "$logs/no_path_$c.log"
 grep -Fq "NATIVE_NO_PATH|state=no_path|" "$logs/no_path_$c.log"
 grep -Fq 'Test passed at tick' "$logs/no_path_$c.log"
 echo "PASS native no_path $c"
done
for c in 1 199 200 201 400 401 600 800 dual201 zero201 resize200 resize201 resize400 decrease201 loss201 auto201 power401; do
 ticks=55
 [[ "$c" == auto201 || "$c" == power401 ]] && ticks=310
 "$FACTORIO_BIN" --mod-directory "$work/mods" --test-scenario em077-block-qa/native --test-arg "$c" --test-ticks "$ticks" > "$logs/reg_$c.log" 2>&1 || { tail -70 "$logs/reg_$c.log";exit 1; }
 grep -Fq "[EM077 QA] $c|PASS|" "$logs/reg_$c.log"
 grep -Fq 'Test passed at tick' "$logs/reg_$c.log"
 echo "PASS native block traction $c"
done
echo '22/22 native scenarios PASS on exact EM078 ZIP'
