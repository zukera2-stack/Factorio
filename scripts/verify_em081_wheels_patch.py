"""Verify both complete EM080 input and wheel-only EM081 delta before staging."""
import hashlib,json,struct,zipfile
from pathlib import Path
root=Path(__file__).resolve().parents[1]
folder=root/"art/sprites/locomotive-v3"
prefix="graphics/entity/locomotive-052/"
base=json.loads((root/"docs/builds/em081-base-locomotive.json").read_text())
final=json.loads((root/"docs/builds/runtime-artwork.json").read_text())["files"]
expected={k:v for k,v in final.items() if k.startswith(prefix)}
patch={prefix+f"{kind}-{i:02}.png" for kind in ("bogie","bogie-shadow") for i in range(8)}|{prefix+"icon.png"}
assert len(base)==len(expected)==57 and set(base)==set(expected)
assert {k for k in expected if base[k]!=expected[k]}==patch
def load(name,sha,manifest,small=False):
    p=folder/name
    assert p.is_file(), f"BLOCKED: {name} missing"
    assert hashlib.sha256(p.read_bytes()).hexdigest()==sha, name
    with zipfile.ZipFile(p) as z:
        assert len(z.namelist())==len(manifest) and set(z.namelist())==set(manifest) and z.testzip() is None
        data={k:z.read(k) for k in manifest}
        for k,b in data.items():
            assert hashlib.sha256(b).hexdigest()==manifest[k],k
            assert b[:8]==b"\x89PNG\r\n\x1a\n" and b[12:16]==b"IHDR" and b[24:26]==bytes((8,6)),k
            size=(64,64) if k.endswith("/icon.png") else (2048,1024) if small else (4096,2048)
            assert struct.unpack(">II",b[16:24])==size,k
        return data
data=load("EM080_visual_patch.zip","afb31e5a10449a024137a2f53798745338eab0afca785d9587884af1092bb060",base)
data.update(load("EM081_wheels_patch.zip","f3fb61cb21915e6d9e8ef8bf01aa8218b92de169f36927180bbbb5322d55d818",{k:expected[k] for k in patch},True))
for k,b in data.items():assert hashlib.sha256(b).hexdigest()==expected[k],k
for k,b in data.items():
    p=root/"ElectrifiedMainline"/k
    p.parent.mkdir(parents=True,exist_ok=True)
    p.write_bytes(b)
print("EM081 exact base + 17 PNG wheel delta verified, no re-render")
