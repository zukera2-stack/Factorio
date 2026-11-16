#!/usr/bin/env python3
"""0.1.36: repair the stretched 0.1.35 lattice using original C-mast pixels.

Screenshot 2026-11-16_21-51-56.png shows the southern standard C-arm
about 0.40 world tile ABOVE the northern hanger and lower copper contact;
its real placement marker sits ~0.40 tile BELOW the drawn foundation.
Move the standard shaft/arm picture down in mast_visual_034.lua, not
the real native connector. This script repairs a separate diagonal truss
seam by repeating original (unscaled) brace rows rather than interpolating
the source 0.1.35 truss's 141px vertical band.
"""
from pathlib import Path
from PIL import Image, ImageChops, ImageStat

ROOT=Path("ElectrifiedMainline/graphics/entity/35kv")
SRC=ROOT/"pole-native-mast-024.png"
DST=ROOT/"pole-south-lattice-036.png"
TOP_PAD,INSERT_ROWS,SPLICE_SOURCE_Y,BLEND_ROWS=10,54,221,10
im=Image.open(SRC).convert("RGBA")
assert im.size==(512,384) and im.getbbox()==(224,19,383,365)
out=Image.new("RGBA",(512,512))
out.paste(im.crop((0,0,512,SPLICE_SOURCE_Y)),(0,TOP_PAD))
# The middle web is duplicated from a real source segment at its original
# 1:1 pixel size, NOT bicubic-stretched. This preserves diagonal slopes,
# rivet positions, vertical guide widths, and consistent Factorio artwork.
out.paste(im.crop((0,SPLICE_SOURCE_Y-INSERT_ROWS,512,SPLICE_SOURCE_Y)),
          (0,TOP_PAD+SPLICE_SOURCE_Y))
out.paste(im.crop((0,SPLICE_SOURCE_Y,512,384)),
          (0,TOP_PAD+SPLICE_SOURCE_Y+INSERT_ROWS))
# A narrow seam transition (<10 original pixels) connects the repeated
# bay without ghosting or stretching the whole truss.
for i in range(BLEND_ROWS):
    continuing=im.crop((0,SPLICE_SOURCE_Y+i,512,SPLICE_SOURCE_Y+i+1))
    repeated=im.crop((0,SPLICE_SOURCE_Y-INSERT_ROWS+i,512,
                      SPLICE_SOURCE_Y-INSERT_ROWS+i+1))
    out.paste(Image.blend(continuing,repeated,(i+1)/BLEND_ROWS),
              (0,TOP_PAD+SPLICE_SOURCE_Y+i))
assert out.getbbox()==(224,29,383,429),out.getbbox()
# Original top riveted hardware and foundation must remain pixel-exact.
assert out.crop((0,TOP_PAD,512,TOP_PAD+SPLICE_SOURCE_Y)).tobytes()==(
    im.crop((0,0,512,SPLICE_SOURCE_Y)).tobytes())
assert out.crop((0,TOP_PAD+INSERT_ROWS+SPLICE_SOURCE_Y,512,
                 TOP_PAD+INSERT_ROWS+384)).tobytes()==(
    im.crop((0,SPLICE_SOURCE_Y,512,384)).tobytes())
for y in (TOP_PAD+SPLICE_SOURCE_Y,TOP_PAD+SPLICE_SOURCE_Y+INSERT_ROWS):
    above=out.crop((230,y-1,282,y))
    below=out.crop((230,y,282,y+1))
    delta=sum(ImageStat.Stat(ImageChops.difference(above,below)).mean)/4
    assert delta<14,(y,delta)
DST.parent.mkdir(parents=True,exist_ok=True)
out.save(DST,optimize=True)
print("0.1.36 south original-lattice module QA PASS: 54px, 512x512 RGBA, original foundation/top")
