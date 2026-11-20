"""Validate actual 1280 RGBA cells, every reference page and icon; no native game claim."""
from pathlib import Path
from hashlib import sha256
import json,math
import numpy as np
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[1]
MOD=ROOT/'ElectrifiedMainline'
D=MOD/'graphics/entity/locomotive-052'
QA=ROOT/'build/qa'
IN=ROOT/'build/052-rendered/qa'
layers=('body','mask','shadow','pantograph-up','pantograph-down')
assert json.loads((MOD/'info.json').read_text())['version'] in ('0.1.52','0.1.53','0.1.54','0.1.55','0.1.56','0.1.57')
names={f'{s}-{j:02}.png' for s in layers for j in range(8)}
assert {p.name for p in D.glob('*.png')}==names|{'icon.png'}
assert len(list((MOD/'graphics').rglob('*.png')))==57
report={}
for chunk in range(8):
    expected=json.loads((IN/f'chunk-{chunk:02}.json').read_text())
    alphas={}
    for layer in layers:
        name=f'{layer}-{chunk:02}.png';p=D/name
        im=Image.open(p);im.load()
        digest=sha256(p.read_bytes()).hexdigest()
        assert im.size==(4096,2048) and im.mode=='RGBA'
        assert expected[name]['sha256']==digest and expected[name]['first_frame']==chunk*32 and expected[name]['frames']==32
        alphas[layer]=np.array(im.getchannel('A'))
        if layer=='mask':
            rgb=np.array(im);sel=rgb[:,:,3]>200;v=rgb[sel]
            assert len(v)>0 and np.all(v[:,0]==v[:,1]) and np.all(v[:,1]==v[:,2])
            assert v[:,0].min()>=96 and v[:,0].max()<=222 and len(np.unique(v[:,0]))>=2
        for j in range(32):
            x=j%8*512;y=j//8*512;a=alphas[layer][y:y+512,x:x+512]
            assert a.max()>64 and not(a[0].any() or a[-1].any() or a[:,0].any() or a[:,-1].any()),(name,j,'empty/clipped')
            if layer=='pantograph-up':
                t=(chunk*32+j)*2*math.pi/256
                az=math.atan2(math.sin(t)/math.sqrt(2),math.cos(t))
                h=-.93*1.055
                px=round(256+64*h*math.sin(az))
                py=round(320+64*(-h*math.cos(az)/math.sqrt(2)-2.8728125))
                assert a[py-8:py+9,px-8:px+9].max()>64,(name,j,'head projection mismatch')
        report[name]=expected[name]
    assert np.all(alphas['mask']<=alphas['body'])
    assert np.count_nonzero(alphas['pantograph-up']!=alphas['pantograph-down'])>1000
icon=Image.open(D/'icon.png');assert icon.mode=='RGBA' and icon.size==(64,64) and icon.getchannel('A').getbbox()
report['icon.png']={'sha256':sha256((D/'icon.png').read_bytes()).hexdigest(),'size':[64,64]}
QA.mkdir(parents=True,exist_ok=True)
sheet=Image.new('RGB',(4*256,4*256+84),(219,225,229))
d=ImageDraw.Draw(sheet);d.text((14,10),'0.1.52 | original 3D model | 256 directions | weathered paint',fill='#273746')
sheet.paste(icon,(944,8),icon)
for k,state in enumerate(('up','down')):
    for j in range(8):
        frame=Image.open(IN/f'view-{j*32:03}-{state}.png').resize((240,240),Image.Resampling.LANCZOS)
        x=j%4*256;y=84+(k*2+j//4)*256
        sheet.paste(frame,(x+8,y+8),frame);d.text((x+8,y+5),f'{state} {j*45} deg',fill='#273746')
sheet.save(QA/'locomotive-052-preview.png')
(QA/'locomotive-052-assets.json').write_text(json.dumps(report,indent=2)+'\n')
print('052 ASSET PASS: 1280 nonempty unclipped cells, 40 sheets, exact manifest and mask coverage, projected head coordinates, 64px icon, 16 original contact PNGs')
