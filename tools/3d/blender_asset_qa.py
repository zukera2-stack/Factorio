"""Blender 5.x inspection-only QA. Call using Blender --background ... --python this.py -- ...

Never edits the input GLB/.blend; output only JSON + optional orthographic PNG renders.
All checks are evidence, not proof of correctness against the reference sketch or in Factorio.
"""
from __future__ import annotations

import argparse
import datetime
import hashlib
import json
import math
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector

VIEWS = ("hero", "front", "rear", "left", "right", "top")


def parse_args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser(description="Read-only Blender 3D asset QA")
    parser.add_argument("--input", required=True, help="GLB/glTF or Blender .blend")
    parser.add_argument("--out", required=True, help="Fresh output directory")
    parser.add_argument("--views", default="front,left,top,hero", help="Comma-separated: " + ",".join(VIEWS) + "; or none")
    parser.add_argument("--image-size", type=int, default=960)
    parser.add_argument("--require-closed", action="store_true", help="Mark open mesh topology as FAIL (solid-only models)")
    parser.add_argument("--require-uv", action="store_true", help="Mark missing UV on mesh as FAIL")
    return parser.parse_args(argv)


def sha256_file(path: Path):
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def load_source(src: Path):
    suffix = src.suffix.lower()
    if suffix in (".glb", ".gltf"):
        bpy.ops.wm.read_factory_settings(use_empty=True)
        result = bpy.ops.import_scene.gltf(filepath=str(src))
        if "FINISHED" not in result:
            raise RuntimeError("GLB importer did not return FINISHED")
    elif suffix == ".blend":
        bpy.ops.wm.open_mainfile(filepath=str(src))
    else:
        raise ValueError("Supported inputs: .blend, .glb, .gltf")


def audit_mesh(obj, depsgraph, require_closed, require_uv):
    ev = obj.evaluated_get(depsgraph)
    mesh = ev.to_mesh(preserve_all_data_layers=True, depsgraph=depsgraph)
    if mesh is None:
        raise RuntimeError("Unable to evaluate " + obj.name)
    try:
        mesh.calc_loop_triangles()
        bm = bmesh.new()
        bm.from_mesh(mesh)
        # evaluated mesh: 2-manifold only required for collision / watertight assets
        nonmanifold = sum(1 for e in bm.edges if not e.is_manifold)
        boundary = sum(1 for e in bm.edges if e.is_boundary)
        loose = sum(1 for e in bm.edges if e.is_wire)
        degenerate = sum(1 for f in bm.faces if f.calc_area() < 1e-12)
        bm.free()
        locs = [obj.matrix_world @ v.co for v in mesh.vertices]
        xs = [v.x for v in locs]
        ys = [v.y for v in locs]
        zs = [v.z for v in locs]
        uv_count = len(mesh.uv_layers)
        material_names = [slot.material.name if slot.material else None for slot in obj.material_slots]
        image_names = []
        for slot in obj.material_slots:
            mat = slot.material
            if mat and mat.use_nodes:
                for node in mat.node_tree.nodes:
                    if node.type == "TEX_IMAGE" and node.image:
                        image_names.append(node.image.name)
        rec = {
            "object": obj.name,
            "vertex_count": len(mesh.vertices),
            "polygon_count": len(mesh.polygons),
            "triangle_count": len(mesh.loop_triangles),
            "nonmanifold_edges": nonmanifold,
            "boundary_edges": boundary,
            "loose_edges": loose,
            "degenerate_faces": degenerate,
            "uv_layer_count": uv_count,
            "materials": material_names,
            "textures_seen": sorted(set(image_names)),
            "bounds": {
                "min": [min(xs), min(ys), min(zs)] if locs else None,
                "max": [max(xs), max(ys), max(zs)] if locs else None,
            },
            "checks": {
                "no_degenerate_faces": "PASS" if degenerate == 0 else "FAIL",
                "closed_surface": ("PASS" if nonmanifold == 0 else ("FAIL" if require_closed else "WARN_open_surface_allowed")),
                "has_uv": ("PASS" if uv_count else ("FAIL" if require_uv else "WARN_no_uv")),
            },
        }
        return rec
    finally:
        ev.to_mesh_clear()


def set_camera(scene, view, mins, maxs, target, ortho_scale):
    if view == "hero":
        direction, up = Vector((-1.1, -1.4, 1.0)), Vector((0, 0, 1))
    elif view == "front":
        direction, up = Vector((0, -1, 0)), Vector((0, 0, 1))
    elif view == "rear":
        direction, up = Vector((0, 1, 0)), Vector((0, 0, 1))
    elif view == "left":
        direction, up = Vector((-1, 0, 0)), Vector((0, 0, 1))
    elif view == "right":
        direction, up = Vector((1, 0, 0)), Vector((0, 0, 1))
    elif view == "top":
        direction, up = Vector((0, 0, 1)), Vector((0, 1, 0))
    else:
        raise ValueError(view)
    bpy.ops.object.camera_add()
    camera = bpy.context.object
    camera.name = "__QA_CAMERA_" + view
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = ortho_scale
    distance = max(maxs[i] - mins[i] for i in range(3)) * 3 + 3
    camera.location = target + direction.normalized() * distance
    camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()
    scene.camera = camera
    return camera


def render_views(output: Path, views, bounds, image_size):
    scene = bpy.context.scene
    # Use workbench to be reproducible on CPU even without GPU; these are QA previews, not final art.
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.light = "STUDIO"
    scene.display.shading.color_type = "MATERIAL"
    scene.display.shading.show_shadows = True
    scene.display.shading.show_cavity = True
    scene.render.resolution_x = image_size
    scene.render.resolution_y = round(image_size * 0.75)
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    # Leave no reference image planes or inherited cameras in the render; nonmesh is excluded.
    original = {o.name: o.hide_render for o in bpy.data.objects}
    for o in bpy.data.objects:
        if o.type not in {"MESH", "CURVE", "SURFACE", "FONT"}:
            o.hide_render = True
    mins, maxs = [Vector(v) for v in (bounds["min"], bounds["max"])]
    target = (mins + maxs) / 2
    dims = maxs - mins
    settings = {}
    for view in views:
        # Camera side views: width along Y; top width along X and Y.
        if view in {"front", "rear"}:
            width, height = dims.x, dims.z
        elif view in {"left", "right"}:
            width, height = dims.y, dims.z
        elif view == "top":
            width, height = dims.x, dims.y
        else:
            width = max(dims.x, dims.y) * 1.15
            height = dims.z + max(dims.x, dims.y) * 0.25
        aspect = scene.render.resolution_x / scene.render.resolution_y
        scale = max(width, height * aspect) * 1.25
        camera = set_camera(scene, view, mins, maxs, target, scale)
        out = output / ("view_" + view + ".png")
        scene.render.filepath = str(out)
        bpy.ops.render.render(write_still=True)
        settings[view] = {
            "file": out.name,
            "projection": "orthographic",
            "ortho_scale_horizontal": scale,
            "pixels": [scene.render.resolution_x, scene.render.resolution_y],
            "pixel_per_blender_unit": scene.render.resolution_x / scale,
            "camera_location": list(camera.location),
            "camera_view_up": list(camera.matrix_world.to_quaternion() @ Vector((0, 1, 0))),
        }
        bpy.data.objects.remove(camera, do_unlink=True)
    for name, hidden in original.items():
        obj = bpy.data.objects.get(name)
        if obj:
            obj.hide_render = hidden
    return settings


def main():
    args = parse_args()
    source = Path(args.input).expanduser().resolve(strict=True)
    output = Path(args.out).expanduser().resolve()
    if output.exists() and any(p.name != "blender.log" for p in output.iterdir()):
        raise FileExistsError("Output must be empty: " + str(output))
    output.mkdir(parents=True, exist_ok=True)
    requested = [] if args.views.lower() == "none" else [x.strip().lower() for x in args.views.split(",") if x.strip()]
    for view in requested:
        if view not in VIEWS:
            raise ValueError("Invalid camera: " + view)
    load_source(source)
    scene = bpy.context.scene
    depsgraph = bpy.context.evaluated_depsgraph_get()
    meshes = [o for o in scene.objects if o.type == "MESH" and not o.hide_render]
    if not meshes:
        raise RuntimeError("No visible mesh objects found; inspect source")
    data = [audit_mesh(o, depsgraph, args.require_closed, args.require_uv) for o in meshes]
    bounds = [x["bounds"] for x in data if x["bounds"]["min"] is not None]
    world_min = [min(a["min"][i] for a in bounds) for i in range(3)]
    world_max = [max(a["max"][i] for a in bounds) for i in range(3)]
    total_triangles = sum(x["triangle_count"] for x in data)
    issue_count = sum(v == "FAIL" for x in data for v in x["checks"].values())
    report = {
        "tool": "factorio-3d-asset-qa/1.0",
        "checked_at_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "source": {"file": source.name, "sha256": sha256_file(source), "input_type": source.suffix.lower()},
        "blender": {"version": bpy.app.version_string, "background": bpy.app.background},
        "convention": {"x": "width", "y": "nose-to-tail", "z": "height", "unit": "Blender Unit, not automatically a metre"},
        "bounds": {"min": world_min, "max": world_max, "dimensions": [world_max[i] - world_min[i] for i in range(3)]},
        "counts": {"meshes": len(data), "triangles": total_triangles, "materials_by_slot": sum(len(x["materials"]) for x in data)},
        "check_options": {"require_closed": args.require_closed, "require_uv": args.require_uv},
        "mesh_checks": data,
        "limitations": {
            "self_intersection": "NOT_RUN; no full triangle-pair intersection analysis",
            "uv_overlap": "NOT_RUN; UV existence only",
            "material_pbr_correctness": "NOT_RUN; material slots and image-node presence only",
            "reference_image_similarity": "NOT_RUN; requires calibrated matching sketch projection",
            "game_integration": "NOT_RUN; render or GLB import does not prove Factorio gameplay",
        },
        "status": "PASS" if issue_count == 0 else "FAIL",
    }
    report["renders"] = render_views(output, requested, report["bounds"], args.image_size) if requested else {}
    (output / "asset_report.json").write_text(json.dumps(report, ensure_ascii=False, indent=2, default=float) + "\n", encoding="utf8")
    print("ASSET_QA_REPORT " + str(output / "asset_report.json"))
    print("ASSET_QA_STATUS " + report["status"] + " | meshes=" + str(len(data)) + " triangles=" + str(total_triangles))
    if issue_count:
        raise RuntimeError("Asset strict checks failed: " + str(issue_count))


if __name__ == "__main__":
    main()
