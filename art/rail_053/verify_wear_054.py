"""Compare regenerated 053 baseline to 054. No runtime claims."""
from pathlib import Path
import hashlib
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
old=ROOT/'build/rail053-baseline'
new=ROOT/'ElectrifiedMainline/graphics/entity/hsr-053'
assert len(list(old.glob('*.png')))==len(list(new.glob('*.png')))==48
cells=0
for p in sorted(old.glob('*-ties.png')):
    q=new/p.name
    a=np.asarray(Image.open(p))
    b=np.asarray(Image.open(q))
    assert a.shape==b.shape and a.shape[2]==4
    s=a.shape[0];assert a.shape[1]%s==0
    assert np.all(b[:,:,3]>=a[:,:,3])
    for x in range(0,a.shape[1],s):
        t=a[:,x:x+s];u=b[:,x:x+s];m=t[:,:,3]>200
        assert m.any()
        assert np.mean(np.abs(t[:,:,:3].astype(float)-u[:,:,:3].astype(float))[m])>1
        assert np.count_nonzero((u[:,:,3]>127)&(t[:,:,3]<=127))>15
        cells+=1
    pad=p.name.replace('-ties.png','-pads.png')
    assert (old/pad).read_bytes()==(new/pad).read_bytes(),pad
assert cells==98
assert len(list((ROOT/'ElectrifiedMainline/graphics').rglob('*.png')))==105
print('054 PASS: 98 modified slabs with visible face and dirt, 24 pad strips byte-identical to regenerated 053, 105 total PNGs')
