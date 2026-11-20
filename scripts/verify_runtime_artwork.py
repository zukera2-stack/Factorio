"""Fail closed on missing, extra, corrupt or mismatched frozen runtime artwork."""
import hashlib,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def verify():
    mod=ROOT/"ElectrifiedMainline"
    manifest=json.loads((ROOT/"docs/builds/runtime-artwork.json").read_text())
    assert manifest["schema"]==1
    expected=manifest["files"]
    assert expected and all(p.startswith("graphics/") and p.endswith(".png") for p in expected)
    actual={p.relative_to(mod).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in (mod/"graphics").rglob("*.png")}
    missing=set(expected)-set(actual)
    extra=set(actual)-set(expected)
    changed={p for p in set(actual)&set(expected) if actual[p]!=expected[p]}
    if missing or extra or changed:
        raise SystemExit(f"Artwork manifest mismatch: missing={sorted(missing)} extra={sorted(extra)} changed={sorted(changed)}")
    print(f"FROZEN ARTWORK PASS: {len(actual)} PNG SHA256 checks; no regeneration")
if __name__=="__main__": verify()
