"""053 calibration: original concrete material derived from exact native rail registration.
Inputs are local game assets, never copied into Git or artifact. Output is derivative
art for the mod plus comparison of the assembled visual result. No packaging here.
"""
import argparse, hashlib, json, tarfile
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw
from scipy import ndimage as nd

FILES={'ties':'rail-ties.png','pads':'rail-backplates.png','metal':'rail-metals.png',
       'bed':'rail-stone-path.png','inside':'rail-stone-path-inside.png'}
DIRS=('north','northeast','east','southeast','south','southwest','west','northwest')
# Factorio Base 2.1.24 rail-pictures.lua, native x/y, side, variations.
KEYS={
 'straight':[(0,256,256,8),(0,2048,384,3),(0,0,256,8),(0,896,384,3)],
 'half-diagonal':[(0,1280,384,3),(0,1664,384,3),(0,2432,384,3),(0,512,384,3)],
 'curved-a':[(2048,i*512,512,4) for i in (3,12,7,0,11,4,15,8)],
 'curved-b':[(2048,i*512,512,4) for i in (2,13,6,1,10,5,14,9)]
}
def images_from_archive(path):
    names={v:k for k,v in FILES.items()}
    import io
    result={};meta=None
    with tarfile.open(path,'r:*') as t:
        for m in t:
            if not m.isfile():continue
            if m.name.endswith('/data/base/info.json'):
                meta=json.load(t.extractfile(m))
            if '/data/base/graphics/entity/rails/rail/' not in m.name:continue
            name=Path(m.name).name
            if name not in names:continue
            assert m.size<100_000_000
            buf=t.extractfile(m).read()
            im=Image.open(io.BytesIO(buf));im.load()
            result[names[name]]=(im.convert('RGBA'),hashlib.sha256(buf).hexdigest())
    assert meta and meta.get('version')=='2.1.24',('expected exact base version',meta)
    assert set(result)==set(FILES),('demo lacks required rail atlases',list(result))
    return result

def disk(r):
    y,x=np.ogrid[-r:r+1,-r:r+1]
    return x*x+y*y<=r*r

def slab(tie,seed):
    ar=np.array(tie)
    solid=ar[:,:,3]>=112
    lab,n=nd.label(solid)
    counts=np.bincount(lab.ravel())
    good=counts>=20;good[0]=False
    solid=good[lab]
    assert solid.any(),'native ties missing'
    # Bridge gaps of original sleepers, round corners, but never extend indefinitely.
    # Work on a padded cell so transparent margins never wrap between variants.
    p=24
    pad=np.pad(solid,p)
    closed=nd.binary_closing(nd.binary_dilation(pad,structure=disk(3)),structure=disk(17))
    closed=nd.binary_fill_holes(closed)|pad
    footprint=closed[p:-p,p:-p]
    # Voronoi joints at midpoints of disconnected original support blocks.
    # Only a narrow shadow seam, not a wide transparent gap or painted wooden texture.
    labels,n=nd.label(solid)
    _,idx=nd.distance_transform_edt(~solid,return_indices=True)
    near=labels[tuple(idx)]
    seam=np.zeros_like(solid)
    seam[1:,:]|=near[1:,:]!=near[:-1,:]
    seam[:,1:]|=near[:,1:]!=near[:,:-1]
    seam=nd.binary_dilation(seam,structure=disk(1)) & footprint & ~solid
    dist=nd.distance_transform_edt(footprint)
    edge=np.clip(dist/5,0,1)
    rng=np.random.default_rng(seed)
    grain=rng.normal(0,2.5,solid.shape)
    cloud=nd.gaussian_filter(rng.normal(0,1,solid.shape),5)*30
    # Neutral slightly warm concrete, beveled darker perimeter and modest pores.
    v=np.clip(181+grain+cloud-41*(1-edge)-53*seam,75,205)
    rgb=np.stack((v+2,v,v-2),axis=-1)
    alpha=np.rint(nd.gaussian_filter(footprint.astype(float),.55)*255).astype(np.uint8)
    rgb=np.where(alpha[:,:,None]>0,rgb,0)
    out=Image.fromarray(np.dstack((rgb.astype(np.uint8),alpha)),'RGBA')
    assert np.count_nonzero(alpha)>np.count_nonzero(solid)
    assert np.all((alpha[solid])>80)
    assert np.all(np.abs(np.asarray(out,dtype=np.int16)[:,:,0]-np.asarray(out,dtype=np.int16)[:,:,1])<=3)
    return out

def pads(pad):
    a=np.array(pad)
    assert a[:,:,3].max()>100
    lum=np.sum(a[:,:,:3]*np.array([.299,.587,.114]),axis=2)
    # Dark elastomer with readable upper facets, exact native fastening footprint.
    v=np.clip(21+lum*.22,21,77).astype(np.uint8)
    a[:,:,:3]=np.stack((v,v,v),axis=-1)
    a[a[:,:,3]==0,:3]=0
    return Image.fromarray(a,'RGBA')

def generate(inputs,out):
    out.mkdir(parents=True,exist_ok=True)
    sprites=out/'derived';sprites.mkdir(exist_ok=True)
    atlas={k:v[0] for k,v in inputs.items()}
    report={'source_version':'2.1.24','source_files':{k:{'sha256':v[1],'size':list(v[0].size)} for k,v in inputs.items()},'pieces':[]}
    sheet=Image.new('RGB',(6*240,8*246),(57,63,60))
    draw=ImageDraw.Draw(sheet)
    cells=0
    for kind,keys in KEYS.items():
        for d,(x,y,s,n) in enumerate(keys):
            assert all(im.width>=x+n*s and im.height>=y+s for im in atlas.values()),(kind,d,x,y,s,n)
            outputs={k:Image.new('RGBA',(s*n,s)) for k in ('ties','pads')}
            for i in range(n):
                native={k:im.crop((x+i*s,y,x+(i+1)*s,y+s)) for k,im in atlas.items()}
                assert native['metal'].getchannel('A').getbbox(),(kind,d,i,'metal')
                new={'ties':slab(native['ties'],cells+53),'pads':pads(native['pads'])}
                for k,v in new.items():outputs[k].paste(v,(i*s,0))
                assert np.array_equal(np.asarray(new['pads'])[:,:,3],np.asarray(native['pads'])[:,:,3])
                if i==0:
                    old=Image.alpha_composite(native['bed'],native['inside'])
                    cur=old.copy()
                    for k in ('ties','pads','metal'):
                        old=Image.alpha_composite(old,native[k])
                        cur=Image.alpha_composite(cur,new.get(k,native[k]))
                    entry=len(report['pieces'])
                    for j,img in enumerate((old,cur)):
                        slot=entry*2+j;px=(slot%6)*240;py=(slot//6)*246
                        img.thumbnail((226,218),Image.Resampling.LANCZOS)
                        sheet.paste(img,(px+(240-img.width)//2,py+24),img)
                        draw.text((px+5,py+4),f'{kind} {DIRS[d]} '+('native' if j==0 else '053'),fill='white')
                cells+=1
            item={'type':kind,'direction':DIRS[d],'size':s,'variations':n,'native_x':x,'native_y':y,'outputs':{}}
            for k,im in outputs.items():
                p=sprites/f'{kind}-{DIRS[d]}-{k}.png';im.save(p)
                item['outputs'][k]={'file':p.name,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
            report['pieces'].append(item)
    assert cells==98 and len(report['pieces'])==24
    report['cells_per_layer']=cells
    sheet.save(out/'concrete-053-comparison.png')
    (out/'geometry-053.json').write_text(json.dumps(report,indent=2)+'\n')
    print('053 CALIBRATION PASS: 24 directions, 98 native variation cells x 2 new material layers; no game test')

def selftest():
    a=Image.new('RGBA',(256,256));d=ImageDraw.Draw(a)
    for y in (72,105,138,171):d.rounded_rectangle((78,y,178,y+15),radius=3,fill=(80,53,24,255))
    out=slab(a,53)
    assert out.getpixel((128,96))[3]>220,'slab should bridge sleeper gap'
    b=pads(a)
    assert b.getpixel((128,80))[0]<77 and b.getpixel((128,80))[3]==255
    assert b.getpixel((0,0))[3]==0
    print('053 synthetic material/alpha test PASS (not native geometry)')

if __name__=='__main__':
    p=argparse.ArgumentParser()
    p.add_argument('--archive',type=Path)
    p.add_argument('--out',type=Path,default=Path('build/qa/rail053'))
    p.add_argument('--selftest',action='store_true')
    a=p.parse_args()
    selftest()
    if a.archive:generate(images_from_archive(a.archive),a.out)
    elif not a.selftest:p.error('provide official demo archive or --selftest')
