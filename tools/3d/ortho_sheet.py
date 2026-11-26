"""Regenerate geometry-derived orthographic SVG sheets with Blender-axis grids.

The sheets embed the actual Blender QA PNG render, and the grid is SVG vector.
Not editable CAD dimensions / not a replacement for FreeCAD TechDraw.
"""
from __future__ import annotations
import argparse
import base64
import html
import json
import math
from pathlib import Path

# World axis projection: horizontal and vertical, with screen-positive signs.
AXES = {"front": ("X", 1, "Z", 1), "rear": ("X", -1, "Z", 1),
        "left": ("Y", -1, "Z", 1), "right": ("Y", 1, "Z", 1),
        "top": ("X", 1, "Y", 1)}
POS = {"X": 0, "Y": 1, "Z": 2}


def one_sheet(root, report, view, grid):
    src = root / ("view_" + view + ".png")
    if not src.is_file():
        return None
    img_data = base64.b64encode(src.read_bytes()).decode("ascii")
    render = report["renders"][view]
    w,h = render["pixels"]
    scale = render["pixel_per_blender_unit"]
    axis_h, sign_h, axis_v, sign_v = AXES[view]
    bounds = report["bounds"]
    center = [(a+b)/2 for a,b in zip(bounds["min"],bounds["max"])]
    cx,cy = w/2,h/2
    margin=48
    svg = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w+2*margin} {h+2*margin+48}" width="{w+2*margin}" height="{h+2*margin+48}">']
    svg.append('<rect width="100%" height="100%" fill="#f5f7fa"/>')
    svg.append(f'<image x="{margin}" y="{margin+32}" width="{w}" height="{h}" href="data:image/png;base64,{img_data}"/>')
    svg.append(f'<text x="{margin}" y="{margin-6}" font-size="18" fill="#223344" font-family="sans-serif">{html.escape(view.upper())} | {axis_h}/{axis_v} | model SHA256 {report["source"]["sha256"][:12]}</text>')
    # For grid lines anchor coordinates to Blender world grid, not image pixels.
    def screen_value(axis, sign, world):
        origin = center[POS[axis]]
        return sign * (world-origin) * scale
    def ticks(axis, sign, dim_px):
        extent = dim_px / (2*scale)
        origin = center[POS[axis]]
        lo = origin - extent
        hi = origin + extent
        first = math.ceil((lo-1e-9)/grid)
        last = math.floor((hi+1e-9)/grid)
        return [(k*grid, k) for k in range(first,last+1)]
    for value,k in ticks(axis_h,sign_h,w):
        x = margin + cx + screen_value(axis_h,sign_h,value)
        major=abs((value/0.5)-round(value/0.5))<1e-6
        svg.append(f'<line x1="{x:.2f}" y1="{margin+32}" x2="{x:.2f}" y2="{margin+32+h}" stroke="{ "#4a7898" if major else "#879baa" }" stroke-opacity="{0.65 if major else 0.25}" stroke-width="{1.2 if major else 0.5}"/>')
        if major:
            svg.append(f'<text x="{x:.2f}" y="{margin+32+h+15}" text-anchor="middle" font-family="monospace" font-size="10" fill="#35495b">{value:.1f}</text>')
    for value,k in ticks(axis_v,sign_v,h):
        y = margin + 32 + cy - screen_value(axis_v,sign_v,value)
        major=abs((value/0.5)-round(value/0.5))<1e-6
        svg.append(f'<line x1="{margin}" y1="{y:.2f}" x2="{margin+w}" y2="{y:.2f}" stroke="{ "#4a7898" if major else "#879baa" }" stroke-opacity="{0.65 if major else 0.25}" stroke-width="{1.2 if major else 0.5}"/>')
        if major:
            svg.append(f'<text x="{margin-8}" y="{y+4:.2f}" text-anchor="end" font-family="monospace" font-size="10" fill="#35495b">{value:.1f}</text>')
    svg.append(f'<text x="{margin+w/2}" y="{margin+h+32+31}" text-anchor="middle" font-family="sans-serif" font-size="13" fill="#223344">Horizontal {axis_h} | Vertical {axis_v} | grid {grid:g} Blender units | derived from 3D; regenerate when model changes</text>')
    svg.append('</svg>')
    out = root / ("sheet_" + view + ".svg")
    out.write_text("\n".join(svg)+"\n", encoding="utf8")
    return out.name


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--qa-dir",required=True,help="Directory produced by asset_cli.py")
    ap.add_argument("--grid",type=float,default=0.1,help="World Blender Unit grid step; positive")
    args=ap.parse_args()
    if not (0 < args.grid <= 1):
        ap.error("Grid step must be >0 and <=1 Blender Unit")
    root=Path(args.qa_dir).expanduser().resolve(strict=True)
    report=json.loads((root/"asset_report.json").read_text(encoding="utf8"))
    files=[one_sheet(root,report,view,args.grid) for view in AXES]
    files=[x for x in files if x]
    print("SVG orthographic sheets:", ", ".join(files))
    if not files:
        raise SystemExit("No orthographic previews to project")


if __name__=="__main__":
    main()
