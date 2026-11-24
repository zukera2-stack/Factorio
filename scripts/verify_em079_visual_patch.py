"""EM079: exact local V3 PNG overlay; never regenerate or package missing inputs."""
import hashlib
import json
import zipfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
archive = root / "art/sprites/locomotive-v3/Locomotive_V3_visual_patch.zip"
expected_zip = "97fa7fe4d8195d5ae6944ec62aa6bfc06e8437eea92e537e7ddccdbf4ffba7ac"
assert archive.is_file(), "BLOCKED: upload exact local V3 graphics patch"
assert hashlib.sha256(archive.read_bytes()).hexdigest() == expected_zip
manifest = json.loads((root / "docs/builds/runtime-artwork.json").read_text())
expected = {k: v for k, v in manifest["files"].items() if k.startswith("graphics/entity/locomotive-052/")}
assert len(expected) == 41
with zipfile.ZipFile(archive) as z:
    assert len(z.namelist()) == len(expected) and set(z.namelist()) == set(expected)
    assert z.testzip() is None
    data = {name: z.read(name) for name in expected}
    for name, payload in data.items():
        assert hashlib.sha256(payload).hexdigest() == expected[name], name
    for name, payload in data.items():
        (root / "ElectrifiedMainline" / name).write_bytes(payload)
print("EM079 exact local render: 41 PNGs verified and staged; no re-render")
