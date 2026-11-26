"""No Blender required. Standalone axis and SVG-generator smoke test."""
from pathlib import Path
import importlib.util
import tempfile
import json
import base64
import xml.etree.ElementTree as ET

source=Path(__file__).resolve().parents[1]/'tools'/'3d'/'ortho_sheet.py'
spec=importlib.util.spec_from_file_location('ortho_sheet',source)
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
assert m.AXES['front'] == ('X',1,'Z',1)
assert m.AXES['left'] == ('Y',-1,'Z',1)
assert m.AXES['top'] == ('X',1,'Y',1)
# Minimal valid 1×1 PNG embedded in SVG. Does not test Blender render semantics.
P=base64.b64decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jM4kAAAAASUVORK5CYII=')
with tempfile.TemporaryDirectory() as t:
    root=Path(t)
    (root/'view_front.png').write_bytes(P)
    report={'source':{'sha256':'a'*64},'renders':{'front':{'pixels':[64,48],'pixel_per_blender_unit':64}},'bounds':{'min':[-0.5,-1.0,0],'max':[0.5,1.0,1]}}
    out=m.one_sheet(root,report,'front',0.1)
    assert out=='sheet_front.svg'
    ET.parse(root/out)
print('PASS: axes, SVG grid and standalone embedded raster')
