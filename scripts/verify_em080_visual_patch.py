"""EM080 exact local asset transfer; no rendering, fail closed."""
import hashlib
import json
import struct
import zipfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
archive = root / "art/sprites/locomotive-v3/EM080_visual_patch.zip"
expected_zip = "afb31e5a10449a024137a2f53798745338eab0afca785d9587884af1092bb060"
assert archive.is_file(), "BLOCKED: exact local EM080 archive missing"
assert hashlib.sha256(archive.read_bytes()).hexdigest() == expected_zip
manifest = json.loads((root / "docs/builds/runtime-artwork.json").read_text())
prefix = "graphics/entity/locomotive-052/"
expected = {k:v for k,v in manifest["files"].items() if k.startswith(prefix)}
layers = ("body","mask","shadow","pantograph-up","pantograph-down","bogie","bogie-shadow")
assert set(expected) == {prefix + f"{k}-{j:02}.png" for k in layers for j in range(8)} | {prefix + "icon.png"}
with zipfile.ZipFile(archive) as z:
    assert len(z.namelist()) == len(expected) == 57 and set(z.namelist()) == set(expected)
    assert z.testzip() is None
    data = {name:z.read(name) for name in expected}
    for name,payload in data.items():
        assert hashlib.sha256(payload).hexdigest() == expected[name], name
        assert payload[:8] == b"\x89PNG\r\n\x1a\n" and payload[12:16] == b"IHDR", name
        assert struct.unpack(">II",payload[16:24]) == ((64,64) if name.endswith("/icon.png") else (4096,2048)), name
        assert payload[24:26] == bytes((8,6)), name
    for name,payload in data.items():
        target = root / "ElectrifiedMainline" / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(payload)
print("EM080 exact local render: 57 PNGs verified and staged, no re-render")
