#!/usr/bin/env python3
"""Prepare transparent artist/AI RGBA PNG for the strict Factorio sprite manifest.

Does NOT remove opaque backgrounds, invent missing art, or silently crop a subject.
"""
import argparse
import sys
import tempfile
from pathlib import Path
from PIL import Image
from pipeline import QAError, inspect, spec_read, striped

def prepare_image(src: Path, asset: dict) -> Image.Image:
    if not src.is_file():
        raise QAError("missing raw artwork: "+str(src))
    with Image.open(src) as raw:
        if raw.format!="PNG" or raw.mode!="RGBA":
            raise QAError("raw art must be a transparent RGBA PNG")
        image=raw.copy()
    if striped(image):
        raise QAError("raw art contains repeating vertical stripes")
    alpha=image.getchannel("A")
    bbox=alpha.getbbox()
    if not bbox:
        raise QAError("raw art is empty")
    if sum(alpha.histogram()[32:]) / (image.width*image.height) > 0.85:
        raise QAError("raw art is mostly opaque: remove background before preparing")
    if bbox[0]==0 or bbox[1]==0 or bbox[2]==image.width or bbox[3]==image.height:
        raise QAError("raw subject touches image edge; cannot prove it is complete")
    cut=image.crop(bbox)
    w,h=asset["size"]
    margin=asset["min_margin"]+3
    if "source_anchor_fraction" in asset:
        # Asymmetric Г mast: align its base, NOT the bounding-box centre.
        ax,ay=asset["anchor"]
        fx,fy=asset["source_anchor_fraction"]
        source_x=cut.width*fx
        source_y=cut.height*fy
        sides=((ax-margin,source_x),(w-margin-ax,cut.width-source_x),
               (ay-margin,source_y),(h-margin-ay,cut.height-source_y))
        factor=min(space/distance for space,distance in sides if distance>0)
    else:
        factor=min((w-2*margin)/cut.width,(h-2*margin)/cut.height)
    if factor<=0:
        raise QAError("invalid manifest canvas/anchor")
    neww=max(1,int(cut.width*factor))
    newh=max(1,int(cut.height*factor))
    scaled=cut.resize((neww,newh),Image.Resampling.LANCZOS)
    out=Image.new("RGBA",(w,h))
    if "source_anchor_fraction" in asset:
        ax,ay=asset["anchor"]
        fx,fy=asset["source_anchor_fraction"]
        x=round(ax-neww*fx)
        y=round(ay-newh*fy)
    else:
        x=(w-neww)//2
        y=(h-newh)//2
    if x<margin or y<margin or x+neww>w-margin or y+newh>h-margin:
        raise QAError("art cannot fit without clipping")
    out.paste(scaled,(x,y))
    return out

def prepare_file(src: Path, asset_id: str, dst: Path):
    assets={a["id"]:a for a in spec_read()["assets"]}
    if asset_id not in assets:
        raise QAError("unknown asset "+asset_id)
    a=assets[asset_id]
    image=prepare_image(src,a)
    # Validate a temporary file first: no invalid output is installed on failure.
    with tempfile.TemporaryDirectory() as tmp:
        temp=Path(tmp)/"prepared.png"
        image.save(temp)
        _,metrics=inspect(temp,a)
    dst.parent.mkdir(parents=True,exist_ok=True)
    image.save(dst,optimize=True)
    return metrics

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("--input",type=Path,required=True)
    p.add_argument("--asset",choices=("pole","shadow","wire"),required=True)
    p.add_argument("--output",type=Path,required=True)
    args=p.parse_args()
    try:
        stats=prepare_file(args.input,args.asset,args.output)
    except (QAError,OSError,ValueError) as exc:
        print("SPRITE PREP FAIL:",exc,file=sys.stderr)
        return 1
    print("SPRITE PREP PASS:",args.asset,"bbox",stats["bbox"])
    return 0

if __name__=="__main__":
    sys.exit(main())
