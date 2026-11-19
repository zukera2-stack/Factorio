"""Verify generated game sprites and exact geometry-independent alpha contract."""
from pathlib import Path
from hashlib import sha256
import json
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
MOD=ROOT/'ElectrifiedMainline'
DIR=MOD/'graphics/entity/locomotive-049'
names=('body','mask','shadow','pantograph-up','pantograph-down')
assert json.loads((MOD/'info.json').read_text())['version']=='0.1.49'
assert {p.name for p in DIR.iterdir()}=={n+'.png' for n in names}
imgs={}
for name in names:
    im=Image.open(DIR/(name+'.png'));im.load()
    assert im.mode=='RGBA' and im.size==(4096,2048),(name,im.mode,im.size)
    imgs[name]=np.array(im.getchannel('A'))
    for i in range(32):
        x=(i%8)*512;y=(i//8)*512
        a=imgs[name][y:y+512,x:x+512]
        assert a.max()>64 and (a==0).any(),(name,i)
        assert not (a[0].any() or a[-1].any() or a[:,0].any() or a[:,-1].any()),(name,i,'clipped')
assert np.all(imgs['mask']<=imgs['body'])
assert np.count_nonzero(imgs['pantograph-up']!=imgs['pantograph-down'])>1000
assert len(list((MOD/'graphics').rglob('*.png')))==21
for p in sorted(DIR.iterdir()):print(p.name,sha256(p.read_bytes()).hexdigest())
print('049 ASSET PASS: 160 RGBA cells / five sprite sheets, aligned mask, distinct poses, 16 original contact PNG + 5 new train PNG')
