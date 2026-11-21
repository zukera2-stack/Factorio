from pathlib import Path
import json
from PIL import Image
root=Path(__file__).resolve().parents[1]/'ElectrifiedMainline'
for name in ('hsr-057.png','hsr-replacement-057.png'):
 im=Image.open(root/'graphics/icons'/name)
 assert im.size==(64,64) and im.mode=='RGBA' and im.getchannel('A').getbbox()
a=root/'graphics/icons/hsr-057.png'
b=root/'graphics/icons/hsr-replacement-057.png'
assert a.read_bytes()!=b.read_bytes()
migration=json.loads((root/'migrations/0.1.57.json').read_text())
expected=[['em-high-speed-cargo-wagon','cargo-wagon'],['em-high-speed-fluid-wagon','fluid-wagon']]
assert migration=={'item':expected,'entity':expected}
for p in (root/'prototypes').glob('*.lua'):
 assert all(n[0] not in p.read_text() for n in expected),p
for p in (root/'locale').rglob('*.cfg'):
 assert all(n[0] not in p.read_text() for n in expected),p
assert len(list((root/'graphics').rglob('*.png')))==83
print('057 PASS: 83 PNGs, distinct 64px icons, exact native item/entity migrations and no stale wagon prototype references')
