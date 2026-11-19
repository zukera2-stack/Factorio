#!/usr/bin/env python3
"""0.1.48 static and pixel contract (for GitHub Actions; no Factorio GUI)."""
from pathlib import Path
from hashlib import sha256
import sys, struct, json
import verify_042_assets as accepted042

ROOT=Path(__file__).resolve().parents[1]
MOD=ROOT/'ElectrifiedMainline'
assert json.loads((MOD/'info.json').read_text())['version'] in ('0.1.48','0.1.49','0.1.50','0.1.51','0.1.52','0.1.53','0.1.54','0.1.55')
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
# 046 changes only a dry-run adapter in the visual graph; legacy compatibility tests remain.
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
ctrl=(MOD/'scripts/control.lua').read_text()
tech=(MOD/'scripts/technical_network_046.lua').read_text()
assert 'native_curve_graph' not in ctrl and 'technical046.on_tick' in ctrl
assert 'ca.connect_to(cb,false,origin())' in tech and 'defines.wire_origin.script' in tech
assert 't.maximum_wire_distance=0' in proto and 't.auto_connect_up_to_n_wires=0' in proto
assert 'connect_to(' not in art and 'create_entity' not in art
assert 'preview_at' in (MOD/'scripts/power_019.lua').read_text()
assert 'local limit=lim.STRAIGHT+4' in art
assert 'path_check(valid[e.a],valid[e.b])' in tech
assert 'technical046.mark_dirty()' in ctrl
assert 'visual047.plan(s.nodes)' in (MOD/'scripts/power_019.lua').read_text()
assert 'technical.span_state(na,nb)=="connected"' in art
assert 'ca.is_connected_to(cb,origin())' in tech and 'M.refresh_components()' in tech
assert 'technical046.on_tick(event.tick,graph) then' in ctrl
assert 'preview_span' in (MOD/'scripts/ghost_mast_023.lua').read_text()
assert len(list((MOD/'graphics/entity/35kv').glob('*.png')))==11,'missing or obsolete 35kv graphics'
assert len(list((MOD/'graphics/icons').glob('*.png')))==2
assert len(list(WIRE.glob('*.png')))==3
print('0.1.48 PASS: 12 approved mast PNG + 3 approved contact PNG SHA256; 16 total; isolated technical and visual graphs; chord on curves; slim steel/copper; visible rivets; unchanged NORTH_DROP')
