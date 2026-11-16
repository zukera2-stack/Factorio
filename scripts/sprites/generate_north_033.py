#!/usr/bin/env python3
"""Deterministically shorten the north-side C mast without changing source."""
from pathlib import Path
from PIL import Image
src=Path("ElectrifiedMainline/graphics/entity/35kv/pole-native-mast-024.png")
dst=Path("ElectrifiedMainline/graphics/entity/35kv/pole-north-short-033.png")
im=Image.open(src).convert("RGBA")
assert im.size==(512,384),im.size
result=Image.new("RGBA",im.size)
# Preserve full cantilever and foundation; remove 70 px of lattice middle.
result.paste(im.crop((0,0,512,210)),(0,0))
result.paste(im.crop((0,280,512,384)),(0,210))
assert result.getbbox()==(224,19,383,295),result.getbbox()
assert im.crop((0,0,512,210)).tobytes()==result.crop((0,0,512,210)).tobytes()
dst.parent.mkdir(parents=True,exist_ok=True)
result.save(dst,optimize=True)
print("0.1.33 native north shortened mast generated",dst)
