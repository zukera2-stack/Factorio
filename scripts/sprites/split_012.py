#!/usr/bin/env python3
"""Split the 0.1.11 catenary atlas into static mast and runtime-rotated arm.
Uses independent masking, not third-party code or art. No Factorio game test.
"""
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image

INPUT="pole-4dir-hr.png"
SHADOW="pole-shadow-4dir-hr.png"
OUT=("pole-mast-hr.png","pole-arm-hr.png","pole-shadow-static-hr.png")

def make(folder: Path) -> dict:
    src=folder/INPUT
    with Image.open(src) as im:
        if im.mode!="RGBA" or im.size!=(1024,768):
            raise ValueError("Invalid pole atlas: expected 1024x768 RGBA")
        pole=im.crop((0,0,512,384))
    with Image.open(folder/SHADOW) as im:
        if im.mode!="RGBA" or im.size!=(1024,768):
            raise ValueError("Invalid shadow atlas")
        shadow=im.crop((0,0,512,384))
    mast=pole.copy()
    arm=Image.new("RGBA",(512,512))
    pm=mast.load(); pa=arm.load(); original=pole.load()
    for y in range(174):
        for x in range(272,512):
            a=original[x,y]
            if x>278:
                pm[x,y]=(0,0,0,0)
            if a[3] and y+176<512:
                pa[x,y+176]=a
    assert mast.getchannel("A").getpixel((256,250))>=32, "mast anchor lost"
    assert arm.getchannel("A").getbbox(), "arm silhouette lost"
    assert shadow.getchannel("A").getbbox(), "shadow lost"
    a=pole.getchannel("A")
    if any(a.getpixel((x,y))>=32 for y in range(70,140) for x in range(0,130)):
        raise ValueError("Source is not a one-sided Г cantilever")
    report={"input_sha256":hashlib.sha256(src.read_bytes()).hexdigest(),
        "mode":"masked_mast_plus_rotatable_arm",
        "orientation_source":"nearest HSR rail",
        "signal_prototypes_created":False,"game_tested":False,"outputs":{}}
    for name,image in zip(OUT,(mast,arm,shadow)):
        image.save(folder/name,optimize=True)
        report["outputs"][name]={
            "size":list(image.size),
            "sha256":hashlib.sha256((folder/name).read_bytes()).hexdigest(),
            "alpha_bbox":list(image.getchannel("A").getbbox())}
    return report

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("--graphics-dir",type=Path,required=True)
    p.add_argument("--report",type=Path)
    args=p.parse_args()
    report=make(args.graphics_dir)
    if args.report:
        args.report.parent.mkdir(parents=True,exist_ok=True)
        args.report.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print("0.1.12 mast/arm art split PASS; engine game test UNVERIFIED")

if __name__=="__main__":
    main()
