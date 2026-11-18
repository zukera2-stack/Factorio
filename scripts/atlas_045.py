#!/usr/bin/env python3
"""Offline atlas using actual PNGs and Lua pixel register."""
from pathlib import Path
from PIL import Image, ImageDraw
import re
ROOT=Path(__file__).resolve().parents[1]
MOD=ROOT/'ElectrifiedMainline'
gfx=MOD/'graphics/entity/35kv'
lua=(MOD/'scripts/catenary_visual_geometry_045.lua').read_text()
faces={k:[int(x) for x in v.split(',')] for k,v in re.findall(r'^\s+(\w+)\s*=\{([\d,]+)\},',lua,re.M)}
assert len(faces)==8
canvas=Image.new('RGB',(1760,2080),'#374332')
d=ImageDraw.Draw(canvas)
for i,(name,shift,shaft,shaft_shift) in enumerate([('long',-3.375,'south',-2.53125),('short',-0.51125,'north',-0.51125)]):
 for j,face in enumerate(('north','northeast','east','southeast','south','southwest','west','northwest')):
  p=faces[face]
  arm=Image.open(gfx/f'pole-arm-{face}-039.png').convert('RGBA')
  box=arm.getbbox()
  assert arm.size==(512,384) and box[2]-box[0]==132 and box[3]-box[1]==83
  assert p[5]==box[3]-5 and p[7]==box[1]+14
  assert p[4]==p[6] and p[5]-p[7]==64
  for x,y in zip(p[::2],p[1::2]): assert arm.getpixel((x,y))[3]>=180,(face,x,y)
  col=j%4;row=i*2+j//4;ox=col*440;oy=row*520
  d.text((ox+12,oy+8),f'{name.upper()} / {face.upper()}',fill='white')
  s=Image.open(gfx/f'pole-{shaft}-039.png').convert('RGBA')
  tile=Image.new('RGBA',(440,480))
  tile.alpha_composite(s,(220-s.width//2,round(415+shaft_shift*64-s.height/2)))
  top=(220-256,round(415+shift*64-192))
  tile.alpha_composite(arm,top)
  canvas.paste(tile,(ox,oy+22),tile)
  for k,color in ((4,'#ffb24d'),(6,'#9bdcff')):
   x=ox+top[0]+p[k];y=oy+22+top[1]+p[k+1]
   direction=1 if p[k]<256 else -1
   d.line((x+direction*62,y+12,x,y),fill=color,width=3)
   d.ellipse((x-4,y-4,x+4,y+4),outline=color,width=2)
  d.text((ox+12,oy+485),f'Cu {p[4]},{p[5]}  Steel {p[6]},{p[7]}',fill='white')
out=ROOT/'dist/geometry-045-atlas.png';out.parent.mkdir(exist_ok=True);canvas.save(out)
print('045 PASS: actual PNG landmarks, 16 composite atlas panels')
