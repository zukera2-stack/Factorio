"""Rebuild the eight approved EM083 raised-pantograph atlases from EM079+EM080.

This deliberately does not rerender the locomotive or change the folded ghost,
traction, spark logic or other artwork. Deterministic SHA256 gate is mandatory.
"""
from __future__ import annotations

import argparse
import hashlib
import io
import json
import zipfile
from pathlib import Path

import numpy as np
from PIL import Image

ART = "graphics/entity/locomotive-052/"
SOURCE_SHA = "97fa7fe4d8195d5ae6944ec62aa6bfc06e8437eea92e537e7ddccdbf4ffba7ac"
EXPECTED = [
    "6e8040a4e521c3f593096f53def510f8de04f02b2db1aa4c0952efcc8aac5f9c",
    "8a08a250ec1c67a908b060729979517a07006e87e6a54967018f53d39da372d4",
    "9351ce3a8501481737ed87d041be828dc43db14ae427d5f956e19fda816a4915",
    "5908cf02617f0665001116467584083722c77a6d38bd0bcf1f147d6697c4db3e",
    "4c4f178824099bfb481f884d6be89a89ad7003d53e3f9eb40b2de5d583ca7db3",
    "eebd72d52669fb3b12baa2753d7fd20e36ff5610c8b6198f8dbf5a01e6ea89b0",
    "c9c07e0d017fbcf3e1bfa2bdd3d2c21cf1ada6d63cf9a2aba11df008d6edd2a3",
    "2d573640e0b0c7dc4d64a474d7d1eedaeceec64376656196e284a5f84f5491e6",
]


def crop_frame(img: Image.Image, k: int) -> Image.Image:
    x, y = (k % 8) * 512, (k // 8) * 512
    return img.crop((x, y, x + 512, y + 512))


def replacement(base: Image.Image, target: Image.Image) -> Image.Image:
    # Preserve exact inverse-compositing arithmetic from EM083 source QA.
    b = np.asarray(base).astype(np.float32) / 255
    t = np.asarray(target).astype(np.float32) / 255
    A = b[:, :, 3]
    U = t[:, :, 3]
    diff = np.max(np.abs(t - b), axis=2) > 1 / 255 / 2
    pa = np.zeros_like(A)
    opaque = A >= (254.5 / 255)
    pa[opaque & diff] = 1
    partial = (~opaque) & diff
    pa[partial] = np.clip((U[partial] - A[partial]) / np.maximum(1 - A[partial], 1e-8), 0, 1)
    rgb = (t[:, :, :3] * U[:, :, None] - b[:, :, :3] * A[:, :, None] * (1 - pa[:, :, None])) / np.maximum(pa[:, :, None], 1e-10)
    rgb = np.clip(rgb, 0, 1)
    v = np.uint8(np.rint(np.concatenate((rgb, pa[:, :, None]), axis=2) * 255))
    v[v[:, :, 3] == 0] = 0
    return Image.fromarray(v, "RGBA")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", type=Path, default=Path.cwd())
    args = parser.parse_args()
    root = args.repo.resolve()
    source = root / "art/sprites/locomotive-v3/Locomotive_V3_visual_patch.zip"
    actual_source = hashlib.sha256(source.read_bytes()).hexdigest()
    assert actual_source == SOURCE_SHA, ("EM079 source ZIP hash mismatch", actual_source)
    dest = root / "ElectrifiedMainline" / ART
    assert dest.is_dir(), dest
    verified = []
    with zipfile.ZipFile(source) as old:
        assert old.testzip() is None
        for j in range(8):
            def get_old(layer: str) -> Image.Image:
                return Image.open(io.BytesIO(old.read(ART + f"{layer}-{j:02d}.png"))).convert("RGBA")
            old_body, old_up = get_old("body"), get_old("pantograph-up")
            with Image.open(dest / f"body-{j:02d}.png") as body:
                new_body = body.convert("RGBA")
            assert all(i.size == (4096, 2048) for i in (old_body, old_up, new_body))
            sheet = Image.new("RGBA", (4096, 2048))
            for k in range(32):
                xyz = ((k % 8) * 512, (k // 8) * 512)
                target = Image.alpha_composite(crop_frame(old_body, k), crop_frame(old_up, k))
                base = crop_frame(new_body, k)
                over = np.maximum(
                    np.asarray(base)[:, :, 3].astype("int16") - np.asarray(target)[:, :, 3].astype("int16"),
                    0,
                )
                assert int(over.max()) == 0, (j, k, "base alpha exceeds restored pose")
                patch = replacement(base, target)
                sheet.paste(patch, xyz)
            output = dest / f"pantograph-up-{j:02d}.png"
            sheet.save(output, compress_level=6)
            digest = hashlib.sha256(output.read_bytes()).hexdigest()
            assert digest == EXPECTED[j], (output.name, digest, EXPECTED[j])
            verified.append(output.name)
            print("VERIFIED", output.name, digest)
    assert len(verified) == 8
    print("PASS: exactly eight original EM083 panto atlases reconstructed")

    # The historical EM081 manifest is preserved unmodified. Compare all
    # other 91 PNGs to it and the restored raised collector to EXPECTED.
    baseline = json.loads((root / "docs/builds/runtime-artwork.json").read_text())["files"]
    assert len(baseline) == 99, len(baseline)
    for relative, expected in baseline.items():
        if relative.startswith(ART + "pantograph-up-"):
            idx = int(relative.rsplit("-", 1)[1].split(".", 1)[0])
            expected = EXPECTED[idx]
        actual = hashlib.sha256((root / "ElectrifiedMainline" / relative).read_bytes()).hexdigest()
        assert actual == expected, (relative, actual, expected)
    all_png = [p for p in (root / "ElectrifiedMainline").rglob("*.png") if p.is_file()]
    assert len(all_png) == 99, len(all_png)
    print("PASS: 99 PNG match EM085 owner-tested graphics (91 old + 8 restored)")


if __name__ == "__main__":
    main()
