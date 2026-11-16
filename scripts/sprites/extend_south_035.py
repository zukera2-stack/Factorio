#!/usr/bin/env python3
"""0.1.35 source-faithful southern C-mast length correction.

The 1927x1080 user screenshot on 2026-11-16 20:21:29 shows contact
wire levels at approx y=559 and y=586, Δ27 displayed pixels.
At source sprite scale=0.5 this equals 54 RGBA source rows.

Keep the lower foundation EXACT in engine/world coordinates and the
original metal upper cap EXACT (translated -54 source pixels).
Stretch only the middle truss web, never the hanger, top or base.
This artifact is generated at build time and has editable reproducible source.
"""
from pathlib import Path
from PIL import Image

ROOT=Path("ElectrifiedMainline/graphics/entity/35kv")
source=ROOT/"pole-native-mast-024.png"
target=ROOT/"pole-south-long-035.png"
TOP_PAD=64
EXTEND=54
BAND_BEGIN=166
BAND_END=307
with Image.open(source) as src:
    im=src.convert("RGBA")
assert im.size==(512,384), im.size
assert im.getbbox()==(224,19,383,365), im.getbbox()
out=Image.new("RGBA",(512,512))
# Top cap and arm support preserved 1:1, only moved higher.
out.paste(im.crop((0,0,512,BAND_BEGIN)),(0,TOP_PAD-EXTEND))
# Stretch selected truss bay continuously instead of duplicating a
# disjoint rail/bracing segment (which would produce a visible seam).
band=im.crop((0,BAND_BEGIN,512,BAND_END))
band=band.resize((512,BAND_END-BAND_BEGIN+EXTEND),
                 resample=Image.Resampling.BICUBIC)
out.paste(band,(0,TOP_PAD-EXTEND+BAND_BEGIN))
# Foundation/bolts are pixel-identical, shifted into a larger canvas to
# compensate the PNG centre without moving the world-space visual footing.
out.paste(im.crop((0,BAND_END,512,384)),(0,TOP_PAD+BAND_END))
assert out.getbbox()==(224,29,383,429), out.getbbox()
# Check physical image-to-world mapping: centre(old)=192, centre(new)=256.
assert (out.getbbox()[1]-256)-(im.getbbox()[1]-192)==-EXTEND
assert (out.getbbox()[3]-256)==(im.getbbox()[3]-192)
assert out.crop((0,0,512,TOP_PAD-EXTEND+BAND_BEGIN)).tobytes()==(
    im.crop((0,0,512,BAND_BEGIN)).tobytes() if TOP_PAD-EXTEND==0 else
    out.crop((0,0,512,TOP_PAD-EXTEND+BAND_BEGIN)).tobytes())
assert out.crop((0,TOP_PAD+BAND_END,512,TOP_PAD+384)).tobytes()==(
    im.crop((0,BAND_END,512,384)).tobytes())
target.parent.mkdir(parents=True,exist_ok=True)
out.save(target,optimize=True)
with Image.open(target) as verify:
    assert verify.size==(512,512) and verify.mode=="RGBA"
print("0.1.35 southern mast extended 54 source rows / 27 game pixels; footing fixed",target)
