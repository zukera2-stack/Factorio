#!/usr/bin/env python3
"""Research-only Factorio 2.1.24 dynamic max_power rejection vs predeclared prototype A/B.
No gameplay source code is modified and no user saves are touched.
"""
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
from pathlib import Path


def run(args, logfile, env):
    with open(logfile, "wb") as fd:
        proc = subprocess.run(args, stdout=fd, stderr=subprocess.STDOUT, env=env, timeout=180)
    txt = Path(logfile).read_text(encoding="utf-8", errors="replace")
    if proc.returncode:
        raise RuntimeError(f"Factorio exited {proc.returncode}; tail:\n{txt[-3500:]}")
    return txt


def main():
    p = argparse.ArgumentParser(description="EM072-C2 native max_power API test")
    p.add_argument("--factorio", required=True, help="2.1.24 headless Factorio binary")
    p.add_argument("--output", required=True, help="fresh isolated evidence directory")
    ns = p.parse_args()
    exe = Path(ns.factorio).resolve()
    if not exe.exists():
        raise FileNotFoundError(exe)
    base = Path(__file__).resolve().parent / "em072-c2-power-api-probe"
    out = Path(ns.output).resolve()
    if out.exists() and list(out.iterdir()):
        raise RuntimeError("--output must be an empty or nonexistent directory")
    out.mkdir(parents=True, exist_ok=True)
    mods = out / "mods"
    mods.mkdir()
    shutil.copytree(base, mods / "em-power-api-probe_0.0.1")
    (mods / "mod-list.json").write_text(json.dumps({"mods": [
        {"name": "base", "enabled": True},
        {"name": "em-power-api-probe", "enabled": True},
    ]}), encoding="utf-8")
    env = os.environ.copy()
    home = out / "home"
    home.mkdir()
    env["HOME"] = str(home)
    version = subprocess.run([str(exe), "--version"], capture_output=True, text=True, timeout=15).stdout
    assert "2.1.24" in version and "87808" in version, version
    save = out / "power-test.zip"
    run([str(exe), "--create", str(save), "--mod-directory", str(mods)], out / "create.log", env)
    log = run([str(exe), "--benchmark", str(save), "--benchmark-ticks", "185", "--mod-directory", str(mods)], out / "benchmark.log", env)
    expected = [
        "runtime_prototype_field_read|ok=false|result=LuaEntityPrototype doesn't contain key max_power.",
        "runtime_prototype_field_set|ok=false|result=No modifications of LuaEntityPrototype are currently possible.",
        "live_entity_max_power_read|ok=false|result=LuaEntity doesn't contain key max_power.",
        "live_entity_max_power_set|ok=false|result=LuaEntity doesn't contain key max_power.",
        "live_entity_prototype_power_set|ok=false|result=No modifications of LuaEntityPrototype are currently possible.",
        "live_entity_prototype_replace|ok=false|result=LuaEntity::prototype is read only.",
        "entity_em-power-2mw_exists=true", "entity_em-power-3mw_exists=true",
        "set_acceleration_em-power-2mw|ok=true", "set_acceleration_em-power-3mw|ok=true",
    ]
    for marker in expected:
        if marker not in log:
            raise AssertionError(f"Missing native API proof: {marker}")
    samples = {}
    for tick, name, position, speed in re.findall(r"POWER_API_PROBE\|motion\|tick=(\d+)\|name=([\w-]+)\|y=([-\d.]+)\|speed=([\d.]+)", log):
        samples[(int(tick), name)] = {"distance_tiles": -float(position), "speed_tiles_per_tick": float(speed)}
    for tick in (60, 120, 180):
        low, high = samples[(tick, "em-power-2mw")], samples[(tick, "em-power-3mw")]
        assert high["distance_tiles"] > low["distance_tiles"] > 0, (tick, low, high)
    summary = {
        "engine": "Factorio 2.1.24 build 87808 Linux Headless",
        "result": "RUNTIME MAX_POWER MUTATION BLOCKED, PREDECLARED 2MW AND 3MW PROTOTYPES MOVE DIFFERENTLY",
        "entity_max_power_edit_supported": False,
        "prototype_power_edit_at_runtime_supported": False,
        "loco_prototype_swap_property_supported": False,
        "energy_source": "void (TEST ONLY, FREE ENERGY, NOT GAMEPLAY)",
        "wagons_tested": False,
        "samples": {str(t): {k.split("-")[-1]: samples[(t,k)] for k in ("em-power-2mw", "em-power-3mw")} for t in (60,120,180)},
        "benchmark_log_sha256": hashlib.sha256((out / "benchmark.log").read_bytes()).hexdigest(),
        "gameplay_accepted": False,
    }
    (out / "summary.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()