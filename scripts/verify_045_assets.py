#!/usr/bin/env python3
"""0.1.45 static and pixel contract (for GitHub Actions; no Factorio GUI)."""
from pathlib import Path
from hashlib import sha256
import sys, struct, json
import verify_042_assets as accepted042

ROOT=Path(__file__).resolve().parents[1]
MOD=ROOT/'ElectrifiedMainline'
assert json.loads((MOD/'info.json').read_text())['version']=='0.1.45'
WIRE=MOD/'graphics/entity/25kv'
EXPECTED={
  'contact-043.png':('95542e98e67b2529c2451353ceb938976a7b183caee37d7b38c073f736327782',(128,10)),
  'messenger-043.png':('a575cd0c7579077768cc9be1113eabf257dbc1c6edf8c6f3658bc22c7409a20e',(128,10)),
  'dropper-043.png':('841fcb9e3dcd09a5087e46194219b912fe398066490d1bef463d7179d4884fab',(10,32)),
}
assert {f.name for f in WIRE.glob('*.png')}==set(EXPECTED), 'old/unapproved contact wire PNGs in install'
for name,(digest,dimensions) in EXPECTED.items():
    buf=(WIRE/name).read_bytes()
    assert buf[:8]==b'\x89PNG\r\n\x1a\n' and buf[25]==6,(name,'not PNG RGBA')
    assert struct.unpack('>II',buf[16:24])==dimensions,(name,'wrong dimensions')
    assert sha256(buf).hexdigest()==digest,(name,'modified 043 PNG')
for name,digest in accepted042.SHAS.items():
    accepted042.check_png(name,digest)
# The working rail-topology code is the exact accepted 0.1.42 version;
# visual correction cannot change what rail links are eligible for wire.
power=(MOD/'scripts/power_019.lua').read_bytes()
assert sha256(power).hexdigest()=='b3940d1921c990bcca7ea19ac7f73b386ae017bd3c99f1f3911f3bcdb00f1094', 'rail graph changed from stable 042'
art=(MOD/'scripts/catenary_art_030.lua').read_text()
proto=(MOD/'prototypes/catenary_art_030.lua').read_text()
assert all(f'em-25kv-{n}-043' in art for n in ('contact','messenger','dropper'))
assert all(f'{n}-043.png' in proto for n in ('contact','messenger','dropper'))
assert 'local function catmull' not in art and 'route_points' not in art, 'old unanchored curve spline survived'
assert 'return span_geometry(a,b,ma,mb,true)' in art,'curve not drawn as chord'
assert 'visible.points(pa.position' in art and 'local HEIGHT=2.53125' not in art
assert 'arg.y_scale=0.40' in art and 'arg.y_scale=0.48' in art,'wire thickness regression'
assert 'arg.x_scale=1.14' in art,'riveted dropper visibility regression'
assert 'NORTH_DROP=2.02' in (MOD/'scripts/mast_visual_034.lua').read_text()
assert 'a.draw_copper_wires=false' in (MOD/'prototypes/native_wire_auto_028.lua').read_text()
assert 'native_curve_graph' in (MOD/'scripts/control.lua').read_text()
assert len(list((MOD/'graphics/entity/35kv').glob('*.png')))==11,'missing or obsolete 35kv graphics'
assert len(list((MOD/'graphics/icons').glob('*.png')))==2
assert len(list(WIRE.glob('*.png')))==3
print('0.1.45 PASS: 12 approved mast PNG + 3 approved contact PNG SHA256; 16 total; restored stable 042 rail graph; chord on curves; slim steel/copper; visible rivets; unchanged NORTH_DROP')
