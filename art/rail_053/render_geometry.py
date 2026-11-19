"""Reconstruct derivative geometry from owner-supplied atlas contours.
No original game image is required or packaged. One contour set per direction,
with deterministic material fluctuations for the native variation count.
"""
import json
from pathlib import Path
import numpy as np
from scipy import ndimage as nd
from PIL import Image, ImageDraw
ROOT=Path(__file__).resolve().parents[2]
D=ROOT/'ElectrifiedMainline/graphics/entity/hsr-053'
D.mkdir(parents=True,exist_ok=True)
G=json.loads((Path(__file__).with_name('geometry.json')).read_text())
dirs=('north','northeast','east','southeast','south','southwest','west','northwest')
keys=[('straight', (256,384,256,384), (8,3,8,3)),('half-diagonal',(384,)*4,(3,)*4),('curved-a',(512,)*8,(4,)*8),('curved-b',(512,)*8,(4,)*8)]
def mask(polys,s,lines=False):
    im=Image.new('L',(s*2,s*2))
    d=ImageDraw.Draw(im)
    for p in polys:
        assert len(p)%2==0 and len(p)>=4
        coords=[(2*x,2*y) for x,y in zip(p[::2],p[1::2])]
        if lines: d.line(coords,fill=255,width=4)
        else: d.polygon(coords,fill=255)
    return np.array(im.resize((s,s),Image.Resampling.LANCZOS))
count=0;idx=0
for kind,sides,counts in keys:
    for direction,s,n in zip(dirs,sides,counts):
        side,slabs,joints,fasteners=G[idx];idx+=1
        assert side==s
        a=mask(slabs,s);b=mask(fasteners,s);j=mask(joints,s,True)/255
        assert a.max()==255 and b.max()==255
        strips=[Image.new('RGBA',(s*n,s)) for _ in range(2)]
        for i in range(n):
            rng=np.random.default_rng(53000+count)
            for k,alpha in enumerate((a,b)):
                edge=np.clip(nd.distance_transform_edt(alpha>127)/(5 if k==0 else 2),0,1)
                grain=rng.normal(0,2.0,(s,s))
                v=np.clip(181+grain-35*(1-edge)-42*j,80,205) if k==0 else np.clip(24+25*edge+grain,20,65)
                rgb=np.stack((v+2,v,v-2),axis=-1) if k==0 else np.stack((v,v,v),axis=-1)
                rgb=np.where(alpha[:,:,None]>0,rgb,0)
                frame=Image.fromarray(np.dstack((rgb.astype('uint8'),alpha)))
                strips[k].paste(frame,(i*s,0))
            count+=1
        for suffix,im in zip(('ties','pads'),strips):
            assert im.size==(s*n,s) and im.mode=='RGBA'
            p=D/f'{kind}-{direction}-{suffix}.png';im.save(p)
            assert Image.open(p).size==(s*n,s)
assert idx==24 and count==98 and len(list(D.glob('*.png')))==48
print('053: 48 strips, 196 reconstructed nonempty cells, original native variation counts; no game test')
