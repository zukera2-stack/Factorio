#!/usr/bin/env bash
set -euo pipefail
: "${FACTORIO_BIN:?Set executable path to Factorio 2.1.24 Linux x64}"
: "${EM077_ZIP:?Set path to complete ElectrifiedMainline_0.1.77.zip}"
base="$(cd "$(dirname "$0")/.." && pwd)"
"$FACTORIO_BIN" --version | grep -Fq '2.1.24'
if [[ -n "${EM077_SHA256:-}" ]]; then printf '%s  %s\n' "$EM077_SHA256" "$EM077_ZIP" | sha256sum -c -; fi
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/mods" "${EM077_LOG_DIR:-$work/logs}"
logs="${EM077_LOG_DIR:-$work/logs}"
cp "$EM077_ZIP" "$work/mods/ElectrifiedMainline_0.1.77.zip"
cp -a "$base/tests/em077-block-qa" "$work/mods/em077-block-qa_0.0.1"
printf '%s\n' '{"mods":[{"name":"base","enabled":true},{"name":"ElectrifiedMainline","enabled":true},{"name":"em077-block-qa","enabled":true}]}' > "$work/mods/mod-list.json"
scenarios=(1 199 200 201 400 401 600 800 dual201 zero201 resize200 resize201 resize400 decrease201 loss201 auto201 power401)
for case_name in "${scenarios[@]}"; do
  ticks=55
  [[ "$case_name" == auto201 || "$case_name" == power401 ]] && ticks=310
  "$FACTORIO_BIN" --mod-directory "$work/mods" --test-scenario em077-block-qa/native --test-arg "$case_name" --test-ticks "$ticks" > "$logs/$case_name.log" 2>&1 || { tail -80 "$logs/$case_name.log"; exit 1; }
  grep -Fq "[EM077 QA] $case_name|PASS|" "$logs/$case_name.log" || { tail -80 "$logs/$case_name.log"; exit 1; }
  grep -Fq 'Test passed at tick' "$logs/$case_name.log" || { tail -80 "$logs/$case_name.log"; exit 1; }
  echo "PASS $case_name"
done
printf 'PASS: %s fullmod native block traction cases on Factorio 2.1.24\n' "${#scenarios[@]}"
