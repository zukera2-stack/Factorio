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
assert json.loads((MOD/'info.json').read_text())['version'] in ('0.1.49','0.1.50','0.1.51')
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
# 050 correction: actual pixels, not just a Lua flag or synthetic example.
mask=np.array(Image.open(DIR/'mask.png'))
visible=mask[:,:,3]>200
assert visible.any() and np.all(mask[visible,0]==mask[visible,1]) and np.all(mask[visible,1]==mask[visible,2])
assert 96<=mask[visible,0].min()<=mask[visible,0].max()<=222
assert len(np.unique(mask[visible,0]))>=2, 'flat/tint-insensitive mask'
colors=np.array([[220,35,35],[115,35,220],[20,180,55],[25,90,220],[0,0,0],[255,255,255]],dtype=np.float32)
paint=[np.rint(mask[visible,:3]*c/255).astype(np.uint8) for c in colors]
assert all(np.any(paint[i]!=paint[j]) for i in range(len(paint)) for j in range(i))
# Exact 049 non-mask atlas hashes: no incidental geometric or shading changes.
expected={
 'body':'c7b26bf39f7c1e2350e5e0da461df1b33145e02d2063dc06207909c089c56927',
 'shadow':'821bf8cdac0060f9b197ad272266851e0efaaf4b959acec9ba97079c71234213',
 'pantograph-up':'7211e75b290284188101d0b9898d5486308ec7f1004248f67db297099041c935',
 'pantograph-down':'557e1f0b69381e643635fbd5ed2f6e02c0cc357e5411e71f3a581c5fb6c73e7e',
}
for n,digest in expected.items():
    assert sha256((DIR/(n+'.png')).read_bytes()).hexdigest()==digest,(n,'049 image drift')
assert sha256((DIR/'mask.png').read_bytes()).hexdigest()=='2ddb10f397c0de76ca94d73ef83267e9278217e5879051c7cd95453153fe1de2'
print('050 PASS: actual grayscale mask with six distinguishable multiply colors, four approved 049 sheets byte-identical')
assert np.count_nonzero(imgs['pantograph-up']!=imgs['pantograph-down'])>1000
assert len(list((MOD/'graphics').rglob('*.png')))==21
for p in sorted(DIR.iterdir()):print(p.name,sha256(p.read_bytes()).hexdigest())
print('049 ASSET PASS: 160 RGBA cells / five sprite sheets, aligned mask, distinct poses, 16 original contact PNG + 5 new train PNG')
