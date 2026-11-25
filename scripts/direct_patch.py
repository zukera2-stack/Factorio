#!/usr/bin/env python3
"""Build and validate *manual* Factorio Direct Patch ZIPs; never edit the user's mod.

Usage:
    python scripts/direct_patch.py build --base /path/to/0.1.84/ElectrifiedMainline \
        --target /path/to/0.1.85/ElectrifiedMainline --out build/direct-patch/EM085.zip \
        --manifest build/direct-patch/EM085.manifest.json --record-deletions
    python scripts/direct_patch.py verify --base /path/to/0.1.84/ElectrifiedMainline \
        --patch build/direct-patch/EM085.zip --manifest build/direct-patch/EM085.manifest.json

The ZIP uses paths relative to the mod directory, without an outer directory.
The external manifest is deliberately not included in the ZIP. Verification runs
in memory (hash maps), not by extracting over the actual installation.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import stat
import sys
import zipfile
from pathlib import Path, PurePosixPath

SCHEMA = "factorio-direct-patch/v1"
ROOT_FILES = {"info.json", "control.lua", "data.lua", "data-updates.lua", "data-final-fixes.lua", "settings.lua", "settings-updates.lua", "settings-final-fixes.lua", "changelog.txt"}
ROOT_DIRS = {"prototypes", "scripts", "graphics", "locale", "migrations", "compatibility", "sound", "sounds", "models"}
VERSION = re.compile(r"^\d+\.\d+\.\d+$")
CHUNK = 1024 * 1024


class PatchError(ValueError):
    pass


def digest_bytes(blob: bytes) -> str:
    return hashlib.sha256(blob).hexdigest()


def safe_path(name: str) -> str:
    if not isinstance(name, str) or not name or "\\" in name or "\x00" in name or ":" in name:
        raise PatchError(f"Unsafe member name: {name!r}")
    if name.startswith("/") or name.endswith("/") or "//" in name:
        raise PatchError(f"Unsafe path separators: {name!r}")
    p = PurePosixPath(name)
    if any(part in ("", ".", "..") for part in name.split("/")) or str(p) != name:
        raise PatchError(f"Traversal / unnormalized path: {name!r}")
    parts = name.split("/")
    if (len(parts) == 1 and name not in ROOT_FILES) or (len(parts) > 1 and parts[0] not in ROOT_DIRS):
        raise PatchError(f"Not a mod runtime file: {name!r}")
    if any(part.startswith(".") for part in parts):
        raise PatchError(f"Hidden file not allowed in a patch: {name!r}")
    return name


def case_unique(paths: list[str]) -> None:
    seen = {}
    for path in paths:
        safe_path(path)
        key = path.casefold()
        if key in seen:
            raise PatchError(f"Windows case collision / duplicate: {seen[key]!r} and {path!r}")
        seen[key] = path


def scan_directory(root: Path) -> dict[str, bytes]:
    root = Path(root)
    if not root.is_dir() or root.is_symlink():
        raise PatchError(f"Expected a real extracted mod directory: {root}")
    out = {}
    for current, dirs, files in os.walk(root, followlinks=False):
        current = Path(current)
        for directory in dirs:
            if (current / directory).is_symlink():
                raise PatchError(f"Symlink directory not allowed: {current / directory}")
        for file in files:
            p = current / file
            if p.is_symlink() or not p.is_file():
                raise PatchError(f"Symlink / non-file not allowed: {p}")
            rel = p.relative_to(root).as_posix()
            safe_path(rel)
            out[rel] = p.read_bytes()
    case_unique(list(out))
    if "info.json" not in out:
        raise PatchError(f"Missing info.json in {root}")
    return out


def metadata(tree: dict[str, bytes]) -> tuple[str, str]:
    try:
        info = json.loads(tree["info.json"].decode("utf-8"))
        mod, ver = info["name"], info["version"]
    except (KeyError, ValueError, UnicodeDecodeError, TypeError) as err:
        raise PatchError("Invalid info.json") from err
    if not isinstance(mod, str) or not mod or not isinstance(ver, str) or not VERSION.fullmatch(ver):
        raise PatchError("Invalid Factorio name/version")
    return mod, ver


def tree_hash(tree: dict[str, bytes]) -> str:
    h = hashlib.sha256()
    for path in sorted(tree):
        h.update(path.encode("utf-8"))
        h.update(b"\0")
        h.update(bytes.fromhex(digest_bytes(tree[path])))
    return h.hexdigest()


def check_versions(base: dict[str, bytes], target: dict[str, bytes]) -> tuple[str, str, str]:
    mod, a = metadata(base)
    nextmod, b = metadata(target)
    if nextmod != mod:
        raise PatchError(f"Mod identity changed: {mod} -> {nextmod}")
    old = tuple(map(int, a.split(".")))
    new = tuple(map(int, b.split(".")))
    if new[:2] != old[:2] or new[2] != old[2] + 1:
        raise PatchError(f"Direct Patch requires adjacent patch versions, got {a} -> {b}")
    return mod, a, b


def build(base: Path, target: Path, output: Path, manifest_path: Path, *, record_deletions: bool = False) -> dict:
    old, new = scan_directory(base), scan_directory(target)
    mod, before, after = check_versions(old, new)
    removed = sorted(set(old) - set(new))
    if removed and not record_deletions:
        raise PatchError(f"Removed paths cannot be deleted by ZIP: {removed}; use --record-deletions to require manual deletion")
    changes = sorted(path for path in new if path not in old or new[path] != old[path])
    if "info.json" not in changes:
        raise PatchError("info.json must change with every Direct Patch")
    if output.resolve() == manifest_path.resolve():
        raise PatchError("ZIP and external manifest paths must differ")
    if output.exists() or manifest_path.exists():
        raise PatchError("Outputs exist; refuse to overwrite evidence")
    output.parent.mkdir(parents=True, exist_ok=True)
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    try:
        with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as z:
            for name in changes:
                info = zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
                info.compress_type = zipfile.ZIP_DEFLATED
                info.external_attr = (0o100644 << 16)
                z.writestr(info, new[name], compress_type=zipfile.ZIP_DEFLATED, compresslevel=6)
        patch_hash = digest_bytes(output.read_bytes())
        manifest = {
            "schema": SCHEMA,
            "mod": mod,
            "base_version": before,
            "target_version": after,
            "base_tree_sha256": tree_hash(old),
            "target_tree_sha256": tree_hash(new),
            "zip_sha256": patch_hash,
            "files": [
                {"path": p, "old_sha256": digest_bytes(old[p]) if p in old else None,
                 "new_sha256": digest_bytes(new[p]), "bytes": len(new[p])}
                for p in changes
            ],
            "delete_after_extract": [
                {"path": p, "old_sha256": digest_bytes(old[p])} for p in removed
            ],
        }
        manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        verify(base, output, manifest_path, expected_target=target)
    except Exception:
        output.unlink(missing_ok=True)
        manifest_path.unlink(missing_ok=True)
        raise
    return manifest


def verify(base: Path, patch: Path, manifest_path: Path, *, expected_target: Path | None = None) -> dict:
    old = scan_directory(base)
    manifest = json.loads(Path(manifest_path).read_text(encoding="utf-8"))
    if manifest.get("schema") != SCHEMA:
        raise PatchError("Unknown patch manifest schema")
    if manifest.get("base_tree_sha256") != tree_hash(old):
        raise PatchError("Base folder does not match patch manifest; DO NOT APPLY")
    if metadata(old) != (manifest.get("mod"), manifest.get("base_version")):
        raise PatchError("Base version/mod mismatch")
    if digest_bytes(Path(patch).read_bytes()) != manifest.get("zip_sha256"):
        raise PatchError("Patch ZIP SHA256 mismatch")
    entries = manifest.get("files")
    deletion_entries = manifest.get("delete_after_extract")
    if not isinstance(entries, list) or not isinstance(deletion_entries, list):
        raise PatchError("Invalid file lists in manifest")
    files = [e.get("path") for e in entries]
    deletions = [e.get("path") for e in deletion_entries]
    case_unique(files + deletions)
    if "info.json" not in files:
        raise PatchError("Missing info.json update")
    patched = dict(old)
    with zipfile.ZipFile(patch) as z:
        actual = [i.filename for i in z.infolist()]
        case_unique(actual)
        if actual != files:
            raise PatchError("ZIP files/order do not match external manifest")
        if z.testzip() is not None:
            raise PatchError("ZIP CRC failed")
        for entry, member in zip(entries, z.infolist()):
            # Symlink entries are not runtime files; prevent extraction surprises.
            mode = member.external_attr >> 16
            if mode and stat.S_IFMT(mode) not in (0, stat.S_IFREG):
                raise PatchError(f"Not a regular file: {member.filename}")
            path = entry["path"]
            if (digest_bytes(old[path]) if path in old else None) != entry.get("old_sha256"):
                raise PatchError(f"Old file SHA mismatch: {path}")
            data = z.read(member)
            if digest_bytes(data) != entry.get("new_sha256") or len(data) != entry.get("bytes"):
                raise PatchError(f"New file SHA or size mismatch: {path}")
            patched[path] = data
    for entry in deletion_entries:
        path = entry["path"]
        if path not in patched or digest_bytes(patched[path]) != entry.get("old_sha256"):
            raise PatchError(f"Cannot safely remove mismatched file: {path}")
        del patched[path]
    if metadata(patched) != (manifest["mod"], manifest["target_version"]):
        raise PatchError("Updated info.json wrong version")
    check_versions(old, patched)
    if tree_hash(patched) != manifest.get("target_tree_sha256"):
        raise PatchError("Virtual overlay did not produce target file tree")
    if expected_target is not None:
        if tree_hash(scan_directory(expected_target)) != tree_hash(patched):
            raise PatchError("Virtual overlay does not equal expected target")
    return manifest


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    cmd = parser.add_subparsers(dest="command", required=True)
    build_parser = cmd.add_parser("build", help="Build and verify an update ZIP from two extracted mod folders")
    verify_parser = cmd.add_parser("verify", help="Verify patch against a specific extracted base; NEVER installs")
    for p in (build_parser, verify_parser):
        p.add_argument("--base", type=Path, required=True)
        p.add_argument("--manifest", type=Path, required=True)
    build_parser.add_argument("--target", type=Path, required=True)
    build_parser.add_argument("--out", type=Path, required=True)
    build_parser.add_argument("--record-deletions", action="store_true")
    verify_parser.add_argument("--patch", type=Path, required=True)
    verify_parser.add_argument("--target", type=Path, default=None)
    args = parser.parse_args(argv)
    try:
        if args.command == "build":
            result = build(args.base, args.target, args.out, args.manifest, record_deletions=args.record_deletions)
        else:
            result = verify(args.base, args.patch, args.manifest, expected_target=args.target)
        print(json.dumps({"result": "PASS", "mod": result["mod"],
                          "versions": [result["base_version"], result["target_version"]],
                          "changed": len(result["files"]),
                          "manual_deletions": [e["path"] for e in result["delete_after_extract"]],
                          "zip_sha256": result["zip_sha256"]}, ensure_ascii=False, indent=2))
    except (PatchError, OSError, KeyError, ValueError, zipfile.BadZipFile) as err:
        parser.exit(2, f"Direct Patch BLOCKED: {err}\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
