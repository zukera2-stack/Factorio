"""Cross-platform runner for read-only Blender QA. Python stdlib only."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys


def main():
    parser = argparse.ArgumentParser(description="Factorio 3D source QA: safe report + model-derived orthographic renders")
    parser.add_argument("--input", required=True, help="Existing .glb, .gltf, or .blend")
    parser.add_argument("--output", required=True, help="NEW empty directory (will refuse overwrite)")
    parser.add_argument("--blender", default=os.environ.get("BLENDER_BIN") or shutil.which("blender"), help="Full Blender executable path")
    parser.add_argument("--views", default="front,left,top,hero")
    parser.add_argument("--image-size", type=int, default=960)
    parser.add_argument("--require-closed", action="store_true")
    parser.add_argument("--require-uv", action="store_true")
    args = parser.parse_args()
    if not args.blender or not Path(args.blender).is_file():
        parser.error("Blender executable not found: use --blender or BLENDER_BIN")
    source = Path(args.input).expanduser().resolve(strict=True)
    if source.suffix.lower() not in {".glb", ".gltf", ".blend"}:
        parser.error("Only .glb, .gltf, .blend")
    output = Path(args.output).expanduser().resolve()
    if output.exists() and any(output.iterdir()):
        parser.error("Output already contains files; refusal prevents overwrite: " + str(output))
    output.mkdir(parents=True, exist_ok=True)
    helper = Path(__file__).resolve().parent / "blender_asset_qa.py"
    argv = [str(Path(args.blender).resolve()), "--background", "--factory-startup", "--disable-autoexec", "--python-exit-code", "1", "--python", str(helper), "--", "--input", str(source), "--out", str(output), "--views", args.views, "--image-size", str(args.image_size)]
    if args.require_closed:
        argv.append("--require-closed")
    if args.require_uv:
        argv.append("--require-uv")
    print("Running read-only Blender QA. Input remains untouched.", flush=True)
    with (output / "blender.log").open("w", encoding="utf8") as log:
        result = subprocess.run(argv, stdout=log, stderr=subprocess.STDOUT, check=False)
    report_path = output / "asset_report.json"
    if report_path.exists():
        report = json.loads(report_path.read_text(encoding="utf8"))
        print("Status:", report["status"], "| triangle count:", report["counts"]["triangles"], "| meshes:", report["counts"]["meshes"])
        print("Report:", report_path)
    else:
        print("No report produced; read", output / "blender.log", file=sys.stderr)
    print("Blender exit code:", result.returncode)
    return result.returncode


if __name__ == "__main__":
    sys.exit(main())
