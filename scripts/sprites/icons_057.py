"""Original 057 inventory icons: supersampled concrete rail and conversion tool."""
from pathlib import Path
from PIL import Image, ImageDraw
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'ElectrifiedMainline/graphics/icons'
S=4
def canvas():
    im=Image.new('RGBA',(64*S,64*S))
    return im,ImageDraw.Draw(im)
def poly(d,pts,c): d.polygon([(int(x*S),int(y*S)) for x,y in pts],fill=c)
def rect(d,box,c): d.rectangle(tuple(int(v*S) for v in box),fill=c)
def line(d,pts,c,w): d.line([(int(x*S),int(y*S)) for x,y in pts],fill=c,width=int(w*S),joint='curve')
def track(d,x,y,w,h,old=False):
    # Native-like horizontal length, two bright steel rails and concrete foundation.
    poly(d,[(x,y+5),(x+w,y+5),(x+w,y+h),(x+2,y+h+2),(x,y+h-1)],'#393b3d')
    if not old:
        rect(d,(x,y,x+w,y+h-4),'#a6abad')
        for k in range(1,4):
            xx=x+k*w/4
            line(d,[(xx,y+1),(xx,y+h-4)],'#646a6e',1)
            line(d,[(xx+1,y+1),(xx+1,y+h-4)],'#d6d9d8',1)
    else:
        rect(d,(x,y+3,x+w,y+h-4),'#725638')
        for k in range(5):
            xx=x+(k+.25)*w/5
            rect(d,(xx,y,xx+w/10,y+h-3),'#c5a35d')
    for yy in (y+3,y+h-9):
        rect(d,(x,yy-2,x+w,yy+3),'#272b30')
        rect(d,(x+1,yy-1,x+w-1,yy+1),'#c8d3d8')
        line(d,[(x+1,yy-1),(x+w-1,yy-1)],'#f2f6f4',1)
def save(im,name):
    im.resize((64,64),Image.Resampling.LANCZOS).save(OUT/name)
OUT.mkdir(parents=True,exist_ok=True)
im,d=canvas()
track(d,4,17,55,33)
# two short dark fastener pads beneath rails per slab; no text at inventory size
save(im,'hsr-057.png')
im,d=canvas()
poly(d,[(5,3),(57,3),(61,7),(61,57),(57,61),(5,61),(2,57),(2,7)],'#162b37')
line(d,[(6,5),(56,5),(59,8),(59,56),(56,59),(6,59),(4,56),(4,8),(6,5)],'#43cbdc',2)
track(d,8,8,36,17,True)
track(d,20,39,36,17)
poly(d,[(46,13),(54,13),(54,30),(60,30),(50,38),(40,30),(46,30)],'#0c1d24')
poly(d,[(47,14),(53,14),(53,31),(57,31),(50,36),(43,31),(47,31)],'#65e5ef')
save(im,'hsr-replacement-057.png')
