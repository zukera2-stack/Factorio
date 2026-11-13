#!/usr/bin/env python3
"""Conservative offline Factorio sprite contract guard, NOT an engine/data-stage test.

API fields manually reviewed against Factorio official docs 2.1.24.
User's installed game is 2.1.20: a real game load remains mandatory.
"""
import hashlib
import json
import sys
from pathlib import Path
from PIL import Image
from pipeline import ROOT, QAError, spec_read, snippet

ROTATED_FIELDS = ("filename", "width", "height", "direction_count",
                  "scale", "shift", "draw_as_shadow")
SPRITE_FIELDS = ("type", "name", "filename", "width", "height", "scale")
ISOLATION = (
    "catenary.maximum_wire_distance = 0",
    "catenary.supply_area_distance = 0",
    "catenary.auto_connect_up_to_n_wires = 0",
    "catenary.draw_copper_wires = false",
    "catenary.draw_circuit_wires = false",
)

def verify(out: Path, root: Path = ROOT) -> dict:
    spec=spec_read()
    report=json.loads((out/"report.json").read_text(encoding="utf-8"))
    if report.get("status")!="static_qa_passed_gameplay_unverified" or report.get("game_test") is not False:
        raise QAError("report incorrectly claims game test or is not QA-passed")
    if report.get("target_game")!=spec["target_game"]:
        raise QAError("target Factorio version mismatch")
    text=(out/"prototype-snippet.lua").read_text(encoding="utf-8")
    if text != snippet(spec):
        raise QAError("generated Lua does not match approved sprite schema")
    if text.count("direction_count = 1") != 2 or text.count("draw_as_shadow = true") != 1:
        raise QAError("RotatedSprite layers/rotation/shadow invalid")
    if text.count('type = "sprite"') != 1 or text.count('name = "em-35kv-contact-wire-texture"') != 1:
        raise QAError("wire SpritePrototype registration invalid")
    if len(report.get("assets",[])) != len(spec["assets"]):
        raise QAError("asset count mismatch")
    checks=[]
    for a,entry in zip(spec["assets"],report["assets"]):
        path=out/"ready"/a["output"]
        if not path.is_file() or entry["id"]!=a["id"] or entry["output"]!=a["output"]:
            raise QAError("missing/mismatched output sprite")
        if hashlib.sha256(path.read_bytes()).hexdigest()!=entry["output_sha256"]:
            raise QAError("output PNG hash mismatch")
        with Image.open(path) as im:
            if im.mode!="RGBA" or list(im.size)!=a["size"]:
                raise QAError("output PNG size/alpha mismatch")
        expected="__ElectrifiedMainline__/graphics/entity/35kv/"+a["output"]
        if expected not in text:
            raise QAError("sprite path missing from Lua snippet")
        checks.append(dict(id=a["id"],png_path=expected,dimensions=a["size"],sha256_ok=True))
    info=json.loads((root/"ElectrifiedMainline/info.json").read_text(encoding="utf-8"))
    if info["name"]!="ElectrifiedMainline" or info["factorio_version"]!="2.1":
        raise QAError("mod identity/factorio_version mismatch")
    pole=(root/"ElectrifiedMainline/prototypes/power_019.lua").read_text(encoding="utf-8")
    for field in ISOLATION:
        if field not in pole:
            raise QAError("electric isolation invariant changed: "+field)
    runtime=(root/"ElectrifiedMainline/scripts/power_019.lua").read_text(encoding="utf-8")
    if "rendering.draw_line" not in runtime:
        raise QAError("existing visual line renderer unexpectedly replaced")
    return {
        "result":"offline_api_contract_passed_not_game_verified",
        "target_factorio":"2.1.20",
        "official_api_reference":"2.1.24",
        "docs_version_matches_target":False,
        "rotated_sprite_allowed_fields":list(ROTATED_FIELDS),
        "sprite_prototype_allowed_fields":list(SPRITE_FIELDS),
        "prototype_source_isolation_preserved":True,
        "existing_line_renderer_preserved":True,
        "lua_syntax_verified_by_separate_ci_step":True,
        "factorio_data_stage_loaded":False,
        "factorio_game_tested":False,
        "assets":checks,
    }

def main():
    if len(sys.argv)!=2:
        print("Usage: python scripts/sprites/api_contract.py <QA-output-folder>",file=sys.stderr)
        return 2
    out=Path(sys.argv[1])
    try:
        result=verify(out)
    except (QAError,ValueError,OSError,KeyError) as exc:
        print("FACTORIO API CONTRACT FAIL:",exc,file=sys.stderr)
        return 1
    (out/"api-contract-report.json").write_text(
        json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print("FACTORIO API CONTRACT PASS (offline 2.1.24 docs; 2.1.20 game unverified)")
    return 0

if __name__=="__main__":
    sys.exit(main())
