#!/usr/bin/env python3
"""Offline Factorio sprite staging and self-QA; never modifies mod prototypes."""
import argparse
import hashlib
import json
import shutil
import sys
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
SPEC = ROOT / "art/sprites/manifest.json"
MOD_ASSETS = ROOT / "ElectrifiedMainline/graphics/entity/35kv"
PNG = b"\x89PNG\r\n\x1a\n"

class QAError(ValueError):
    pass

def spec_read():
    spec = json.loads(SPEC.read_text(encoding="utf-8"))
    if spec.get("schema") != 1 or spec.get("target_mod") != "ElectrifiedMainline":
        raise QAError("wrong schema/mod")
    assets = spec["assets"]
    if [a["id"] for a in assets] != ["pole", "shadow", "wire"]:
        raise QAError("expected pole, shadow and wire")
    for a in assets:
        w,h = a["size"]
        if not (0 < w <= 8192 and 0 < h <= 8192):
            raise QAError("dimensions outside conservative atlas limits")
        if not (0 < a["scale"] <= 1):
            raise QAError("invalid scale")
        for key in ("source","output"):
            if Path(a[key]).name != a[key] or not a[key].endswith(".png"):
                raise QAError("unsafe asset name")
    return spec

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def striped(im):
    """Catch exact periodic vertical stripe corruption, not artistic similarity."""
    w,h = im.size
    if w < 64 or h < 64:
        return False
    p=im.load()
    ys=list(range(0,h,max(1,h//24)))
    # Uniform images are not periodic stripe corruption. They fail alpha/colour QA separately.
    signatures={tuple(p[x,y] for y in ys) for x in range(0,w,max(1,w//100))}
    if len(signatures)<2:
        return False
    if sum(any(p[x,y][3] > 32 for x in range(0,w,max(1,w//32))) for y in ys) < 0.8*len(ys):
        return False
    for period in (2,4,8,16):
        same=total=0
        for y in ys:
            for x in range(0,w-period,max(1,w//100)):
                total+=1
                same+=p[x,y]==p[x+period,y]
        if same/total > 0.985:
            return True
    return False

def inspect(path,asset):
    if not path.is_file():
        raise QAError("missing source: "+str(path))
    if path.stat().st_size > 16*1024*1024 or path.read_bytes()[:8] != PNG:
        raise QAError(asset["id"]+": invalid PNG or >16 MiB")
    with Image.open(path) as src:
        src.verify()
    with Image.open(path) as src:
        if src.mode != "RGBA" or list(src.size) != asset["size"]:
            raise QAError(asset["id"]+": expected RGBA "+str(asset["size"]))
        im=src.copy()
    if striped(im):
        raise QAError(asset["id"]+": repeating vertical stripes")
    p=im.load()
    for y in range(im.height):
        for x in range(im.width):
            r,g,b,a=p[x,y]
            if a==0 and (r or g or b):
                p[x,y]=(0,0,0,0)
    bbox=im.getchannel("A").getbbox()
    if not bbox:
        raise QAError(asset["id"]+": empty alpha")
    x1,y1,x2,y2=bbox
    margin=min(x1,y1,im.width-x2,im.height-y2)
    if margin < asset["min_margin"]:
        raise QAError(asset["id"]+": clipped margin "+str(margin))
    px=list(im.getdata())
    fraction=sum(a>=32 for r,g,b,a in px)/len(px)
    if not asset["coverage"][0] <= fraction <= asset["coverage"][1]:
        raise QAError(asset["id"]+": opaque background or empty art")
    soft=sum(0<a<255 for r,g,b,a in px)
    if soft < asset["min_soft_pixels"]:
        raise QAError(asset["id"]+": missing smooth edges")
    colors=len({(r,g,b) for r,g,b,a in px if a>=32})
    if colors < asset["min_colors"]:
        raise QAError(asset["id"]+": flat colours")
    if "anchor" in asset:
        ax,ay=asset["anchor"]
        radius=asset["anchor_radius"]
        if not any(im.getchannel("A").getpixel((x,y))>=96
                   for x in range(max(0,ax-radius),min(im.width,ax+radius+1))
                   for y in range(max(0,ay-radius),min(im.height,ay+radius+1))):
            raise QAError(asset["id"]+": anchor misses sprite")
    return im,dict(id=asset["id"],bbox=list(bbox),margin=margin,
                   coverage=round(fraction,5),soft_edge_pixels=soft,
                   opaque_colors=colors,source_sha256=digest(path))

def shift(a):
    w,h=a["size"]
    ax,ay=a["anchor"]
    return ((w/2-ax)*a["scale"]/32,(h/2-ay)*a["scale"]/32)

def snippet(spec):
    a={x["id"]:x for x in spec["assets"]}
    def layer(x,shadow=False):
        sx,sy=shift(x)
        return ('    {filename = "__ElectrifiedMainline__/graphics/entity/35kv/' +
                x["output"]+'", width = '+str(x["size"][0])+
                ', height = '+str(x["size"][1])+
                ', direction_count = 1, scale = '+str(x["scale"])+
                ', shift = {'+f"{sx:.6f}, {sy:.6f}"+'}'+
                (', draw_as_shadow = true' if shadow else '')+'},')
    w=a["wire"]
    return ('-- REVIEW ONLY: do not load before Factorio 2.1.20 game test.\n'
            'local pole_pictures = {layers = {\n'+layer(a["pole"])+'\n'+
            layer(a["shadow"],True)+'\n}}\n'
            'local wire_sprite = {type = "sprite", name = "em-35kv-contact-wire-texture",\n'
            '  filename = "__ElectrifiedMainline__/graphics/entity/35kv/'+w["output"]+
            '", width = '+str(w["size"][0])+', height = '+str(w["size"][1])+
            ', scale = '+str(w["scale"])+'}\n'
            'return {pole_pictures = pole_pictures, wire_sprite = wire_sprite}\n')

def demo_sources(spec,folder):
    """Synthetic vector-like fixture for CI, not production art."""
    folder.mkdir(parents=True,exist_ok=True)
    S=3
    def setup(w,h):
        im=Image.new("RGBA",(w*S,h*S))
        return im,ImageDraw.Draw(im)
    def points(seq):
        return [(round(x*S),round(y*S)) for x,y in seq]
    def ln(d,seq,color,width):
        d.line(points(seq),fill=color,width=round(width*S),joint="curve")
    im,d=setup(256,384)
    d.polygon(points([(113,350),(118,42),(138,42),(143,350)]),fill=(53,65,74,255))
    d.polygon(points([(120,345),(124,47),(130,47),(134,345)]),fill=(155,163,167,255))
    for y in range(60,330,25):
        ln(d,[(116,y),(140,y+22)],(26,34,40,255),3)
        ln(d,[(139,y),(117,y+22)],(183,189,193,255),2)
        ln(d,[(114,y),(141,y)],(38,49,55,255),3)
    d.polygon(points([(49,85),(207,85),(207,100),(49,100)]),fill=(61,72,81,255))
    ln(d,[(50,89),(205,89)],(187,191,190,255),3)
    ln(d,[(64,99),(125,142),(192,99)],(52,58,64,255),5)
    for x in (64,100,151,189):
        d.rectangle((x*S,72*S,(x+8)*S,87*S),fill=(102,73,44,255))
        for j in range(3):
            ln(d,[(x-3,74+j*4),(x+11,74+j*4)],(191,140+j*8,72,255),2)
    for y in range(110,345,23):
        d.ellipse((125*S,y*S,130*S,(y+5)*S),fill=(210,208,190,255))
    d.polygon(points([(101,349),(155,349),(149,363),(107,363)]),fill=(79,81,77,255))
    for x in range(105,148,12):
        ln(d,[(x,352),(x+8,360)],(225,176,45,255),4)
    im.resize((256,384),Image.Resampling.LANCZOS).save(folder/"pole.png")
    im,d=setup(256,384)
    d.ellipse((75*S,344*S,214*S,370*S),fill=(5,7,11,85))
    d.polygon(points([(126,350),(212,354),(205,363),(128,359)]),fill=(4,5,9,98))
    im.resize((256,384),Image.Resampling.LANCZOS).save(folder/"shadow.png")
    im,d=setup(512,48)
    ln(d,[(16,24),(496,24)],(24,30,35,255),5)
    ln(d,[(16,22),(496,22)],(159,164,169,255),2)
    ln(d,[(16,26),(496,26)],(85,91,94,255),1)
    for x in range(36,485,36):
        ln(d,[(x,19),(x+4,29)],(89+x%30,98,102,255),2)
    im.resize((512,48),Image.Resampling.LANCZOS).save(folder/"wire.png")

def preview(assets,images,path):
    cw,ch=550,420
    out=Image.new("RGB",(cw*3,ch*len(assets)),(25,30,35))
    d=ImageDraw.Draw(out)
    for row,a in enumerate(assets):
        for col in range(3):
            ox,oy=col*cw,row*ch
            if col<2:
                d.rectangle((ox,oy,ox+cw-1,oy+ch-1),
                            fill=(28,33,39) if col==0 else (215,213,203))
            else:
                for y in range(oy,oy+ch,20):
                    for x in range(ox,ox+cw,20):
                        c=(100,104,110) if ((x-ox)//20+(y-oy)//20)%2 else (175,179,181)
                        d.rectangle((x,y,x+19,y+19),fill=c)
            im=images[a["id"]]
            out.paste(im,(ox+(cw-im.width)//2,oy+(ch-im.height)//2),im)
            d.text((ox+12,oy+10),a["id"]+" / "+("dark","light","checker")[col],
                   fill=(241,200,80) if col==0 else (17,20,23))
    out.save(path)

def run(mode,source,out,install=False,approved=False):
    spec=spec_read()
    if install and (mode!="production" or not approved):
        raise QAError("install requires production AND --human-approved")
    if mode=="demo":
        if source is not None:
            raise QAError("demo does not accept external source")
        source=out/"source"
        demo_sources(spec,source)
    else:
        source=source or ROOT/"art/sprites/source"
        if not source.is_dir():
            raise QAError("production source missing; no demo fallback")
    # Validate ALL inputs before writing any installable sprites.
    images,results={},[]
    for a in spec["assets"]:
        im,stats=inspect(source/a["source"],a)
        images[a["id"]]=im
        stats["output"]=a["output"]
        stats["factorio_scale"]=a["scale"]
        if "anchor" in a:
            stats["factorio_shift_tiles"]=[round(x,6) for x in shift(a)]
        results.append(stats)
    ready=out/"ready"
    ready.mkdir(parents=True,exist_ok=True)
    for a,stats in zip(spec["assets"],results):
        path=ready/a["output"]
        images[a["id"]].save(path,optimize=True)
        stats["output_sha256"]=digest(path)
    preview(spec["assets"],images,out/"preview.png")
    (out/"prototype-snippet.lua").write_text(snippet(spec),encoding="utf-8")
    report={"status":"static_qa_passed_gameplay_unverified","mode":mode,
            "target_game":spec["target_game"],
            "official_docs_reviewed":"2.1.24 (2.1.20 not available)",
            "human_art_review":"not_performed","game_test":False,"assets":results}
    if install:
        MOD_ASSETS.mkdir(parents=True,exist_ok=True)
        for a in spec["assets"]:
            shutil.copy2(ready/a["output"],MOD_ASSETS/a["output"])
        report["installed"]=True
    (out/"report.json").write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n",
                                   encoding="utf-8")
    return report

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("mode",choices=("demo","production"))
    p.add_argument("--source",type=Path)
    p.add_argument("--out",type=Path,default=ROOT/"build/sprites/qa")
    p.add_argument("--install",action="store_true")
    p.add_argument("--human-approved",action="store_true")
    a=p.parse_args()
    try:
        result=run(a.mode,a.source,a.out,a.install,a.human_approved)
    except (QAError,OSError,ValueError) as exc:
        print("SPRITE QA FAIL:",exc,file=sys.stderr)
        return 1
    print("SPRITE QA PASS:",len(result["assets"]),"assets; game loading NOT tested")
    print("Preview:",a.out/"preview.png")
    return 0

if __name__=="__main__":
    sys.exit(main())
