#!/usr/bin/env python3
"""Static SHA/alpha validation of 0.1.24 artwork. No external Python deps."""
import hashlib
import json
import struct
import zlib
from pathlib import Path

ROOT = Path('ElectrifiedMainline/graphics/entity/35kv')
MANIFEST = Path('docs/builds/024-art-manifest.json')
NAMES = ('east','southeast','south','southwest','west','northwest','north','northeast')

def alpha_data(path):
    data=path.read_bytes()
    assert data.startswith(b'\x89PNG\r\n\x1a\n'), f'{path} invalid PNG'
    offset=8
    w=h=None
    compressed=[]
    while offset<len(data):
        n=struct.unpack('>I',data[offset:offset+4])[0]
        typ=data[offset+4:offset+8]
        chunk=data[offset+8:offset+8+n]
        offset+=12+n
        if typ==b'IHDR':
            w,h,depth,color=struct.unpack('>IIBB',chunk[:10])
            assert (w,h,depth,color)==(512,384,8,6) and not chunk[12]
        elif typ==b'IDAT':compressed.append(chunk)
        elif typ==b'IEND':break
    raw=zlib.decompress(b''.join(compressed))
    assert len(raw)==h*(w*4+1)
    alpha=[]
    prev=bytearray(w*4)
    index=0
    for _ in range(h):
        f=raw[index];index+=1
        row=bytearray(raw[index:index+w*4]);index+=w*4
        for x in range(w*4):
            L=row[x-4] if x>=4 else 0
            U=prev[x]
            UL=prev[x-4] if x>=4 else 0
            if f==0:p=0
            elif f==1:p=L
            elif f==2:p=U
            elif f==3:p=(L+U)//2
            elif f==4:
                z=L+U-UL
                dl,du,dc=abs(z-L),abs(z-U),abs(z-UL)
                p=L if dl<=du and dl<=dc else (U if du<=dc else UL)
            else:raise ValueError('invalid PNG filter')
            row[x]=(row[x]+p)&255
        alpha.append(row[3::4])
        prev=row
    return alpha

def main():
    m=json.loads(MANIFEST.read_text())
    desired={'pole-native-mast-024.png'}|{'pole-arm-'+f+'-024.png' for f in NAMES}
    assert set(m)==desired
    for name in sorted(desired):
        contents=(ROOT/name).read_bytes()
        assert hashlib.sha256(contents).hexdigest()==m[name]['sha256'],name
        a=alpha_data(ROOT/name)
        nonempty=sum(val>0 for row in a for val in row)
        assert nonempty>800,(name,nonempty)
        if name.startswith('pole-arm-'):
            assert all(v==0 for row in a[225:] for v in row),name+' has double native shaft/foot'
            assert any(v>0 for row in a[65:155] for v in row),name+' arm absent'
        else:
            assert any(v>50 for row in a[335:365] for v in row),'native footing missing'
            assert any(v>50 for row in a[20:50] for v in row),'native cap missing'
            assert all(v==0 for row in a[70:155] for v in row[290:]),'native mast still has arm'
        print(name, 'alpha pixels',nonempty,'PASS')
    for f in NAMES:
        assert (ROOT/('pole-'+f+'-012.png')).is_file(),'source sprite removed: '+f
    print('0.1.24 split mast PNG structure/sha PASS; Factorio 2.1.20 NOT TESTED')
if __name__=='__main__':main()
