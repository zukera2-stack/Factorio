#!/usr/bin/env python3
"""Assemble 4-direction test atlases from QA sprites; NO final art approval implied.

The four frames test whether Factorio electric poles honor entity.direction.
Frames N,E have a rightward Г cantilever; S,W are horizontally mirrored.
This is deliberately a game TEST, not a production art pipeline.
"""
import argparse
import hashlib
import json
import sys
import tempfile
from pathlib import Path
from PIL import Image, ImageOps
from pipeline import QAError, ROOT, demo_sources, inspect, spec_read

FRAME=(512,384)
FRAMES=4
LINE_LENGTH=2
ASSETS=("pole","shadow","wire")
ATLAS_FILES={"pole":"pole-4dir-hr.png","shadow":"pole-shadow-4dir-hr.png",
             "wire":"contact-wire-hr.png"}
ORDER=("right","right","left","left")
FOOT=(256,354)

def atlas(image: Image.Image, anchor: tuple[int,int]) -> Image.Image:
    """One frame has mast foot at (256,354), independent of arm handedness."""
    if image.size!=(256,384):
        raise QAError("unexpected source canvas")
    x=FOOT[0]-anchor[0]
    y=FOOT[1]-anchor[1]
    if x<0 or y<0 or x+image.width>FRAME[0] or y+image.height>FRAME[1]:
        raise QAError("cannot preserve whole subject and mast anchor")
    frame=Image.new("RGBA",FRAME)
    frame.alpha_composite(image,(x,y))
    sheet=Image.new("RGBA",(FRAME[0]*LINE_LENGTH,FRAME[1]*2))
    for i,side in enumerate(ORDER):
        tile=frame if side=="right" else ImageOps.mirror(frame)
        sheet.alpha_composite(tile,((i%LINE_LENGTH)*FRAME[0],
                                     (i//LINE_LENGTH)*FRAME[1]))
    return sheet

def verify_atlas(image: Image.Image, label: str):
    if image.mode!="RGBA" or image.size!=(1024,768):
        raise QAError(label+": bad atlas size or alpha")
    # Pixel-for-pixel mirror is required; no cropping or shifted base.
    tiles=[image.crop(((i%2)*512,(i//2)*384,(i%2+1)*512,(i//2+1)*384))
           for i in range(4)]
    if tiles[0].tobytes()!=tiles[1].tobytes():
        raise QAError(label+": first two frames differ")
    if ImageOps.mirror(tiles[0]).tobytes()!=tiles[2].tobytes():
        raise QAError(label+": left variant is not a true mirror")
    if tiles[2].tobytes()!=tiles[3].tobytes():
        raise QAError(label+": last two frames differ")
    if label=="pole":
        a=tiles[0].getchannel("A")
        if a.getpixel((256,250))<32:
            raise QAError("pole: mast is not on entity origin")
        right=sum(a.getpixel((x,y))>=32 for y in range(70,160)
                  for x in range(340,450))
        left=sum(a.getpixel((x,y))>=32 for y in range(70,160)
                 for x in range(60,170))
        if right<100 or left>25:
            raise QAError("pole: Г arm is not on the correct side")
    return True

def build(mod: Path, mode: str, source: Path | None=None, output: Path | None=None):
    spec=spec_read()
    if mode=="demo":
        if source is not None:
            raise QAError("demo mode cannot use external artwork")
        temp=tempfile.TemporaryDirectory()
        try:
            source=Path(temp.name)
            demo_sources(spec,source)
            return _build(mod,source,mode,output,spec)
        finally:
            temp.cleanup()
    if mode!="experimental":
        raise QAError("mode must be demo or experimental")
    if source is None:
        raise QAError("experimental mode requires a source directory")
    return _build(mod,source,mode,output,spec)

def _build(mod,source,mode,output,spec):
    images={}
    for asset in spec["assets"]:
        image,_=inspect(source/asset["source"],asset)
        images[asset["id"]]=image
    pole=atlas(images["pole"],tuple(spec["assets"][0]["anchor"]))
    shadow=atlas(images["shadow"],tuple(spec["assets"][1]["anchor"]))
    verify_atlas(pole,"pole")
    verify_atlas(shadow,"shadow")
    sprites={"pole":pole,"shadow":shadow,"wire":images["wire"]}
    folder=mod/"graphics/entity/35kv"
    folder.mkdir(parents=True,exist_ok=True)
    report={"version":"0.1.11","art_mode":mode,
            "source_approval":"not_approved",
            "factorio_2_1_20_game_test":False,
            "direction_count":4,"line_length":2,
            "frame_size":list(FRAME),"frame_order":list(ORDER),
            "foot_anchor_in_each_frame":list(FOOT),
            "rendering":"prototype pole only; overhead spans remain rendering.draw_line",
            "files":{}}
    for label,image in sprites.items():
        path=folder/ATLAS_FILES[label]
        image.save(path,optimize=True)
        report["files"][ATLAS_FILES[label]]={
            "size":list(image.size),
            "sha256":hashlib.sha256(path.read_bytes()).hexdigest()}
    if output is not None:
        output.mkdir(parents=True,exist_ok=True)
        (output/"atlas-report.json").write_text(
            json.dumps(report,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
        for label,image in sprites.items():
            image.save(output/ATLAS_FILES[label],optimize=True)
    return report

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mod-dir",type=Path,default=ROOT/"ElectrifiedMainline")
    parser.add_argument("--mode",choices=("demo","experimental"),default="demo")
    parser.add_argument("--source-dir",type=Path)
    parser.add_argument("--out",type=Path,default=ROOT/"build/sprites/game-test")
    args=parser.parse_args()
    try:
        report=build(args.mod_dir,args.mode,args.source_dir,args.out)
    except (QAError,ValueError,OSError) as exc:
        print("SPRITE GAME-TEST ATLAS FAIL:",exc,file=sys.stderr)
        return 1
    print("SPRITE GAME-TEST ATLAS PASS:",len(report["files"]),"PNGs; Factorio load UNVERIFIED")
    return 0

if __name__=="__main__":
    sys.exit(main())
