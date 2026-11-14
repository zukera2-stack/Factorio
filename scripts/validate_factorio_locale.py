#!/usr/bin/env python3
"""Guard Factorio locale property-tree syntax: section names MUST be unique.

Unlike ordinary INI, Factorio rejects repeated [item-name] sections.
Used by ElectrifiedMainline CI before packaging. Root properties (dotted)
are permitted because existing 0.1.8/0.1.18 locale uses them.
"""
from pathlib import Path
import sys

def validate(source: str, label: str) -> int:
    sections = {}
    keys = set()
    active = ""
    count = 0
    for number, raw in enumerate(source.splitlines(), 1):
        line = raw.strip()
        if not line or line.startswith(("#", ";")):
            continue
        if line.startswith("[") and line.endswith("]"):
            section = line[1:-1].strip()
            if not section:
                raise ValueError(f"{label}:{number}: empty locale section")
            if section in sections:
                raise ValueError(
                    f"{label}:{number}: duplicate [{section}], first at line {sections[section]}"
                )
            sections[section] = number
            active = section
            continue
        if "=" not in line:
            raise ValueError(f"{label}:{number}: expected key=value: {line!r}")
        key, _ = line.split("=", 1)
        key = key.strip()
        if not key:
            raise ValueError(f"{label}:{number}: empty key")
        identity = (active, key)
        if identity in keys:
            raise ValueError(f"{label}:{number}: duplicate [{active}].{key}")
        keys.add(identity)
        count += 1
    return count

def selftest():
    assert validate("item-name.a=X\n[item-name]\na=Y\n", "fixtures-good") == 2
    for bad in ("[item-name]\na=x\n[item-name]\nb=y\n",
                "[item-name]\na=x\na=y\n"):
        try:
            validate(bad, "fixtures-bad")
        except ValueError:
            continue
        raise AssertionError("locale validator failed to reject invalid fixture")

def main():
    selftest()
    locale_dir = Path("ElectrifiedMainline/locale")
    paths = sorted(locale_dir.rglob("*.cfg"))
    if not paths:
        raise SystemExit("ERROR no Factorio locale cfg files found")
    try:
        for path in paths:
            text = path.read_text(encoding="utf-8-sig")
            count = validate(text, str(path))
            print(f"Locale property tree: PASS {path} ({count} keys)")
    except ValueError as exc:
        raise SystemExit(f"Factorio locale QA FAILED: {exc}") from exc
    print(f"Factorio locale QA: PASS {len(paths)} files")

if __name__ == "__main__":
    main()
