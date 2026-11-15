#!/usr/bin/env python3
"""Verify the exact user-supplied ElectrifiedMainline 0.1.13 payload.

This is an immutable archive-provenance check, not a Factorio runtime test.
For intentional art changes, bump the mod version before updating artwork.
"""
from __future__ import annotations

import hashlib
import json
import struct
import sys
import zipfile
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "docs" / "builds" / "013-payload.json"
MOD = ROOT / "ElectrifiedMainline"


def png_dimensions(blob: bytes) -> tuple[int, int]:
    if not blob.startswith(b"\x89PNG\r\n\x1a\n"):
        raise ValueError("not PNG")
    pos, dimensions = 8, None
    while pos < len(blob):
        if pos + 12 > len(blob):
            raise ValueError("truncated PNG chunk")
        size = struct.unpack_from(">I", blob, pos)[0]
        kind = blob[pos + 4:pos + 8]
        end = pos + 12 + size
        if end > len(blob):
            raise ValueError("truncated PNG data")
        if zlib.crc32(blob[pos + 4:pos + 8 + size]) & 0xFFFFFFFF != struct.unpack_from(">I", blob, pos + 8 + size)[0]:
            raise ValueError("PNG CRC mismatch")
        if kind == b"IHDR":
            if size != 13 or blob[pos + 17] != 6:
                raise ValueError("expected RGBA PNG")
            dimensions = struct.unpack_from(">II", blob, pos + 8)
        if kind == b"IEND":
            if end != len(blob):
                raise ValueError("PNG trailing bytes")
            if dimensions is None:
                raise ValueError("missing IHDR")
            return dimensions
        pos = end
    raise ValueError("missing IEND")


def main() -> None:
    data = json.loads(MANIFEST.read_text(encoding="utf-8"))
    expected = data["files"]
    actual = {p.relative_to(ROOT).as_posix() for p in MOD.rglob("*") if p.is_file()}
    if actual != set(expected):
        raise AssertionError(f"Payload mismatch; missing={sorted(set(expected)-actual)}, extra={sorted(actual-set(expected))}")
    for path, details in expected.items():
        blob = (ROOT / path).read_bytes()
        digest = hashlib.sha256(blob).hexdigest()
        if digest != details["sha256"] or len(blob) != details["bytes"]:
            raise AssertionError(f"Changed archive payload: {path}")
        if path.endswith(".png"):
            w, h = png_dimensions(blob)
            if [w, h] != details["dimensions"]:
                raise AssertionError(f"Wrong PNG size: {path}")
    info = json.loads((MOD / "info.json").read_text(encoding="utf-8"))
    if info["version"] != "0.1.13":
        raise AssertionError("Only valid for the immutable 0.1.13 baseline")
    proto = (MOD / "prototypes" / "power_019.lua").read_text(encoding="utf-8")
    for marker in ("catenary.connection_points = {table.deepcopy(catenary.connection_points[1])}",
                   "catenary.maximum_wire_distance = 0", "catenary.supply_area_distance = 0"):
        if marker not in proto:
            raise AssertionError("Missing 0.1.13 pole prototype invariant: " + marker)
    archive = ROOT / "dist" / "ElectrifiedMainline_0.1.13.zip"
    if archive.is_file():
        with zipfile.ZipFile(archive) as z:
            if set(z.namelist()) != set(expected):
                raise AssertionError("Built ZIP does not match archived 0.1.13 file set")
            if z.testzip() is not None:
                raise AssertionError("Built ZIP CRC failure")
            for name, details in expected.items():
                if hashlib.sha256(z.read(name)).hexdigest() != details["sha256"]:
                    raise AssertionError("Built ZIP differs from user archive: " + name)
    print(f"PASS: {len(expected)} original 0.1.13 files, 12 RGBA PNGs, prototype invariants"
          + (", built ZIP byte-identical payload" if archive.is_file() else ", no built ZIP yet"))
    print("Factorio 2.1.20 data-stage and gameplay: NOT TESTED by this script")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print("FAIL:", exc, file=sys.stderr)
        raise SystemExit(1)