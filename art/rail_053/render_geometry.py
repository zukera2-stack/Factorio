"""Reconstruct derivative geometry from owner-supplied atlas contours.
No original game image is required or packaged. One contour set per direction,
with deterministic material fluctuations for the native variation count.
"""
import json, argparse, hashlib
from pathlib import Path
import numpy as np
from scipy import ndimage as nd
from PIL import Image, ImageDraw
ROOT=Path(__file__).resolve().parents[2]
parser=argparse.ArgumentParser()
parser.add_argument('--wear',action='store_true',help='054 slab depth and grime')
args=parser.parse_args()
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
# Geometry, registration and pad random stream stay identical to 053.
def down(a, n):
    r=np.zeros_like(a)
    r[n:]=a[:-n]
    return r

def wear(top, a, b, j, s, seed):
    rng=np.random.default_rng(seed)
    solid=a>127
    depth=3 if s==256 else 4
    dist=nd.distance_transform_edt(solid)
    # Two independent spatial scales + fine concrete pores.
    def field(sigma):
        x=nd.gaussian_filter(rng.normal(0,1,(s,s)),sigma)
        return (x-x.mean())/max(x.std(),1e-8)
    clouds=.65*field(11)+.35*field(3)
    patch=np.clip(.87+.35*clouds,.2,1.6)
    edge_dirt=np.exp(-dist/3.8)*patch
    joint_dirt=nd.gaussian_filter(j,2.2)*patch
    fastener_dirt=nd.gaussian_filter((b>100).astype(float),3.0)*patch
    noise_dirt=np.clip(clouds+.35,0,2)
    grime=7*edge_dirt+13*joint_dirt+10*fastener_dirt+7*noise_dirt
    # Slight warm dust near edges, not a global tint.
    px=np.array(top).astype(float)
    rgb=px[:,:,:3]
    rgb-=grime[:,:,None]*np.array([.88,1,1.10])
    # Thin upper lit bevel; keep joints and footprint from 053 unchanged.
    up=np.zeros_like(a);up[:-1]=a[1:]
    bevel=np.clip(a.astype(float)-up,0,255)/255
    # Light upper edge faces toward top-left of screen.
    upper=np.clip(a.astype(float)-down(a,1),0,255)/255
    rgb+=upper[:,:,None]*7
    px[:,:,:3]=np.clip(rgb,0,255)
    px[:,:,:3]=np.where(a[:,:,None]>0,px[:,:,:3],0)
    px=px.astype('uint8')
    # Draw vertical front face BEHIND the original top; no rotation of lighting.
    # Use actual shifted native contour, not a one-pixel dilation.
    assert not np.any(a[-depth:]>0), ('face would clip',s,seed)
    face=Image.new('RGBA',(s,s))
    for d in range(depth,0,-1):
        fa=down(a,d)
        v=134-4*d+np.clip(down(clouds,d),-2,2)*3-11*down(j,d)
        rgba=np.dstack((np.clip(v+2,0,255),np.clip(v,0,255),np.clip(v-2,0,255),fa)).astype('uint8')
        rgba[fa==0,:3]=0
        face=Image.alpha_composite(face,Image.fromarray(rgba))
    final=Image.alpha_composite(face,Image.fromarray(px))
    out=np.asarray(final)
    assert np.all(out[:,:,3]>=a)
    assert np.count_nonzero((out[:,:,3]>127)&~solid)>depth*5
    assert not np.any(out[-1,:,3]), ('face clipped',s,seed)
    assert not np.any((a>200)&(out[:,:,3]<200))
    return final

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
                if args.wear and k==0:
                    frame=wear(frame,a,b,j,s,54000+count)
                strips[k].paste(frame,(i*s,0))
            count+=1
        for suffix,im in zip(('ties','pads'),strips):
            assert im.size==(s*n,s) and im.mode=='RGBA'
            p=D/f'{kind}-{direction}-{suffix}.png';im.save(p)
            assert Image.open(p).size==(s*n,s)
assert idx==24 and count==98 and len(list(D.glob('*.png')))==48
print(('054 slab wear' if args.wear else '053')+': 48 strips, 196 cells, original native variation counts; no game test')
