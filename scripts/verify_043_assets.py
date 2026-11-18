#!/usr/bin/env python3
"""Clean release sprite contract for 0.1.43. Uses only stdlib."""
import hashlib
import pathlib
import struct
import json
root=pathlib.Path('ElectrifiedMainline')
base=root/'graphics/entity/25kv'
expected={
  'contact-043.png':('95542e98e67b2529c2451353ceb938976a7b183caee37d7b38c073f736327782',(128,10)),
  'messenger-043.png':('a575cd0c7579077768cc9be1113eabf257dbc1c6edf8c6f3658bc22c7409a20e',(128,10)),
  'dropper-043.png':('841fcb9e3dcd09a5087e46194219b912fe398066490d1bef463d7179d4884fab',(10,32)),
}
assert json.loads((root/'info.json').read_text())['version']=='0.1.43'
assert {f.name for f in base.glob('*.png')}==set(expected),'no legacy 030 PNG in release'
for name,(sha,size) in expected.items():
 data=(base/name).read_bytes()
 assert data[:8]==b'\x89PNG\r\n\x1a\n',name
 w,h=struct.unpack('>II',data[16:24])
 assert (w,h)==size,(name,w,h,size)
 assert data[25]==6,(name,'must be RGBA')
 assert hashlib.sha256(data).hexdigest()==sha,(name,'unapproved PNG change')
proto=(root/'prototypes/catenary_art_030.lua').read_text()
wire=(root/'prototypes/native_wire_auto_028.lua').read_text()
ctrl=(root/'scripts/control.lua').read_text()
art=(root/'scripts/catenary_art_030.lua').read_text()
path=(root/'scripts/power_019.lua').read_text()
for n in expected:
 assert n in proto
for n in ('contact','messenger','dropper'):
 assert 'em-25kv-'+n+'-043' in art
assert 'a.draw_copper_wires=false' in wire
assert 'native_curve_graph' in ctrl and 'art030.on_tick' in ctrl
assert 'M.curve_geometry' in art and 'route=route' in path and 'cur.trace' in path
assert 'NORTH_DROP=2.02' in (root/'scripts/mast_visual_034.lua').read_text()
print('PASS 0.1.43 3 PNG RGBA exact sizes + SHA256 + hidden curved native wire + curve render path')
