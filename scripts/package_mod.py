#!/usr/bin/env python3
"""Build the game-only ZIP. Fail on misplaced files rather than silently ship them.

Runtime source files are copied byte for byte; no code or image generation.
Historical payloads must be built from their own source revisions.
"""
from __future__ import annotations

import argparse
import json
import re
import zipfile
from pathlib import Path, PurePosixPath

ROOT = Path(__file__).resolve().parents[1]
MOD_ROOT = ROOT / "ElectrifiedMainline"
OUTPUT = ROOT / "build" / "package"
REQUIRED = {"info.json", "control.lua", "data.lua", "data-updates.lua", "data-final-fixes.lua"}
OPTIONAL_ROOT = {"settings.lua", "settings-updates.lua", "settings-final-fixes.lua", "thumbnail.png", "changelog.txt"}
DIRECTORY_SUFFIX = {
    "scripts": {".lua"},
    "prototypes": {".lua"},
    "compatibility": {".lua"},
    "migrations": {".lua", ".json"},
    "graphics": {".png"},
    "locale": {".cfg"},
}


def allowed(rel: str) -> bool:
    p = PurePosixPath(rel)
    if p.is_absolute() or any(part.startswith(".") or part == "__pycache__" for part in p.parts):
        return False
    if len(p.parts) == 1:
        return rel in REQUIRED or rel in OPTIONAL_ROOT
    return p.suffix in DIRECTORY_SUFFIX.get(p.parts[0], set())


def inventory(mod: Path) -> dict[str, Path]:
    files = {}
    for p in sorted(mod.rglob("*")):
        if p.is_symlink():
            raise ValueError(f"Symlink not allowed: {p}")
        if not p.is_file():
            continue
        rel = p.relative_to(mod).as_posix()
        if not allowed(rel):
            raise ValueError(f"Non-runtime file in mod: {rel}; move development material to docs/ or build/")
        files[rel] = p
    absent = REQUIRED - files.keys()
    if absent:
        raise ValueError(f"Missing Factorio entrypoints: {sorted(absent)}")
    return files


def package(mod: Path, output: Path) -> Path:
    files = inventory(mod)
    info = json.loads(files["info.json"].read_text(encoding="utf-8"))
    for field in ("name", "version", "title", "author", "factorio_version"):
        if not isinstance(info.get(field), str) or not info[field].strip():
            raise ValueError(f"Invalid metadata field: {field}")
    if info["name"] != "ElectrifiedMainline" or mod.name != info["name"]:
        raise ValueError("Unexpected mod name/folder")
    if info["factorio_version"] != "2.1" or not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", info["version"]):
        raise ValueError("Expected Factorio 2.1 and numeric mod version")
    output.mkdir(parents=True, exist_ok=True)
    archive = output / f'{info["name"]}_{info["version"]}.zip'
    prefix = info["name"] + "/"
    # Stable ordering and ZIP metadata; file payloads are byte-identical.
    with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for rel, path in files.items():
            item = zipfile.ZipInfo(prefix + rel, (1980, 1, 1, 0, 0, 0))
            item.external_attr = 0o100644 << 16
            z.writestr(item, path.read_bytes(), compress_type=zipfile.ZIP_DEFLATED, compresslevel=9)
    with zipfile.ZipFile(archive) as z:
        expected = {prefix + rel for rel in files}
        if len(z.namelist()) != len(expected) or set(z.namelist()) != expected or z.testzip() is not None:
            raise ValueError("ZIP entry/CRC validation failed")
        for rel, path in files.items():
            if z.read(prefix + rel) != path.read_bytes():
                raise ValueError(f"ZIP payload differs: {rel}")
    print(f"PACKAGE PASS: {len(files)} game files, {sum(p.suffix == '.png' for p in files.values())} PNGs, no development material")
    print(f"Built and validated {archive}")
    return archive


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=OUTPUT)
    args = parser.parse_args()
    package(MOD_ROOT, args.output)
