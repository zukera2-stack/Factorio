"""Check an artwork edit against an exact source. No drawing or mod installs.

A screenshot study can never be certified as a runtime atlas here. For a
repaint, source and candidate *RGBA alpha planes* must be pixel-identical.
Use explicit frame geometry for actual multi-cell atlas verification.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageChops


class AssetCheckError(ValueError):
    """A candidate does not meet the declared editing contract."""


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def alpha_bbox(im: Image.Image):
    return im.getchannel("A").getbbox()


def check(
    source: Path,
    candidate: Path,
    mode: str = "repaint",
    frame_width: int | None = None,
    frame_height: int | None = None,
    frames: int | None = None,
) -> dict:
    if mode not in {"repaint", "component", "study"}:
        raise AssetCheckError("mode must be repaint, component, or study")
    if not source.is_file() or not candidate.is_file():
        raise AssetCheckError("source and candidate must be real files")
    if source.suffix.lower() != ".png" or candidate.suffix.lower() != ".png":
        raise AssetCheckError("both inputs must be actual PNG files")
    with Image.open(source) as src_raw, Image.open(candidate) as dst_raw:
        if src_raw.format != "PNG" or dst_raw.format != "PNG":
            raise AssetCheckError("inputs must decode as PNG")
        if mode in {"repaint", "component"} and dst_raw.mode != "RGBA":
            raise AssetCheckError("runtime sprite candidates must use explicit RGBA")
        if mode == "repaint" and src_raw.mode != "RGBA":
            raise AssetCheckError("a repaint reference must be an RGBA source image")
        src = src_raw.convert("RGBA")
        dst = dst_raw.convert("RGBA")
        if src.size != dst.size and mode != "component":
            raise AssetCheckError("canvas size changed; same view/geometry required")
        if mode != "study" and not alpha_bbox(dst):
            raise AssetCheckError("candidate has zero visible sprite pixels")
        if frame_width is not None or frame_height is not None or frames is not None:
            if not (frame_width and frame_height and frames):
                raise AssetCheckError("frame width, height and count must be supplied together")
            if frame_width <= 0 or frame_height <= 0 or frames <= 0:
                raise AssetCheckError("frame dimensions/count must be positive")
            cols, rows = dst.width // frame_width, dst.height // frame_height
            if dst.width % frame_width or dst.height % frame_height or cols * rows != frames:
                raise AssetCheckError("canvas does not have the expected frame grid")
        elif mode != "study":
            raise AssetCheckError("actual sprite QA requires known frame width/height/count")
        source_alpha = src.getchannel("A")
        target_alpha = dst.getchannel("A")
        alpha_diff = ImageChops.difference(source_alpha, target_alpha) if src.size == dst.size else None
        if mode == "repaint" and alpha_diff and alpha_diff.getbbox():
            raise AssetCheckError("repaint alpha changed: silhouette/padding no longer exact")
        frame_boxes = []
        if frame_width and frame_height:
            for y in range(0, dst.height, frame_height):
                for x in range(0, dst.width, frame_width):
                    sub = dst.crop((x, y, x + frame_width, y + frame_height))
                    frame_boxes.append(sub.getchannel("A").getbbox())
            if mode != "study" and any(b is None for b in frame_boxes):
                raise AssetCheckError("one or more declared runtime frames are fully transparent")
        delta = ImageChops.difference(src.convert("RGB"), dst.convert("RGB")) if src.size == dst.size else None
        # RGBA ImageChops.getbbox() checks all four bands, so unchanged alpha
        # would mask RGB-only changes. Keep RGB and alpha deltas separate.
        return {
            "schema": "factorio-asset-review/v1",
            "mode": mode,
            "classification": "REFERENCE_STUDY_NOT_GAME_ASSET" if mode == "study" else "QA_CANDIDATE_NOT_GAME_ACCEPTANCE",
            "source": str(source),
            "source_sha256": digest(source),
            "candidate": str(candidate),
            "candidate_sha256": digest(candidate),
            "source_size": list(src.size),
            "candidate_size": list(dst.size),
            "source_alpha_bbox": alpha_bbox(src),
            "candidate_alpha_bbox": alpha_bbox(dst),
            "alpha_identical": None if mode == "study" else bool(alpha_diff is not None and not alpha_diff.getbbox()),
            "changed_bbox": delta.getbbox() if delta is not None else None,
            "frame_grid": {"width": frame_width, "height": frame_height, "count": frames},
            "frame_alpha_bounds": frame_boxes,
            "qa_pass": True,
            "windows_game_acceptance": "NOT_TESTED",
            "note": "This checks PNG structure, not pivots, permissions, Factorio API, visuals, or runtime behaviour.",
        }


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--source", required=True, type=Path)
    p.add_argument("--candidate", required=True, type=Path)
    p.add_argument("--mode", choices=["repaint", "component", "study"], default="repaint")
    p.add_argument("--frame-width", type=int)
    p.add_argument("--frame-height", type=int)
    p.add_argument("--frames", type=int)
    p.add_argument("--report", type=Path)
    a = p.parse_args()
    try:
        result = check(a.source, a.candidate, a.mode, a.frame_width, a.frame_height, a.frames)
    except (AssetCheckError, OSError) as e:
        p.exit(2, f"ASSET QA FAIL: {e}\n")
    text = json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True) + "\n"
    if a.report:
        a.report.parent.mkdir(parents=True, exist_ok=True)
        a.report.write_text(text, encoding="utf-8")
    print(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
