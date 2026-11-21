#!/usr/bin/env python3
"""Run real Factorio 2.1.24 headless electrical QA locally, with no GitHub Actions.

Only launches a user-supplied headless executable/archive. The binary is never
committed or included in the developer toolkit. The game uses disposable saves.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import platform
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile
import time
import zipfile
from pathlib import Path

TOOL_DIR = Path(__file__).resolve().parent
FIXTURES = TOOL_DIR / "native_fixtures"
FIXTURE_SPECS = (
    ("em061-power-probe", 1050, "[EM061 NATIVE PASS]"),
    ("em061-priority-probe", 300, "[EM061 MATRIX PASS]"),
)
SHA061 = "3771b7241848ae98e74019659baeb03616ab9aa4fa5dfcb9e7acf02efbef754c"


def status(s):
    print(s, flush=True)


def digest(p):
    h = hashlib.sha256()
    with p.open("rb") as fd:
        for part in iter(lambda: fd.read(1024 * 1024), b""):
            h.update(part)
    return h.hexdigest()


def checked_run(cmd, *, logfile=None, timeout=80):
    start = time.perf_counter()
    ret = subprocess.run([str(x) for x in cmd], text=True, stdout=subprocess.PIPE,
                         stderr=subprocess.STDOUT, errors="replace", timeout=timeout)
    elapsed = round(time.perf_counter() - start, 3)
    if logfile:
        Path(logfile).write_text(ret.stdout, encoding="utf-8")
    if ret.returncode:
        excerpt = "\n".join(ret.stdout.splitlines()[-24:])
        raise RuntimeError(f"Command failed (exit={ret.returncode}, {elapsed}s): {cmd}\n{excerpt}")
    return ret.stdout, elapsed


def valid_tar_members(archive):
    with tarfile.open(archive, "r:xz") as fd:
        for entry in fd.getmembers():
            if not entry.name.startswith("factorio/") or ".." in Path(entry.name).parts:
                raise ValueError(f"Unexpected tar path: {entry.name}")
            if entry.issym() or entry.islnk() or entry.isdev():
                raise ValueError(f"Refusing tar link/device entry: {entry.name}")
        return True


def engine_binary(args, temp):
    if args.engine:
        binary = Path(args.engine).resolve()
        if not binary.is_file():
            raise ValueError(f"Engine executable not found: {binary}")
        return binary
    if not args.headless_archive:
        raise ValueError("Specify --engine (already extracted) or --headless-archive (user-supplied tar.xz)")
    archive = Path(args.headless_archive).resolve()
    if not archive.is_file():
        raise ValueError(f"Archive not found: {archive}")
    valid_tar_members(archive)
    status(f"[NATIVE] Extracting user-provided headless archive {archive.name}")
    with tarfile.open(archive, "r:xz") as fd:
        fd.extractall(temp, filter="data")
    binary = temp / "factorio" / "bin" / "x64" / "factorio"
    if not binary.is_file():
        raise ValueError("This archive does not contain Linux x64 Factorio. Match archive architecture to the host (" + platform.machine() + ")")
    binary.chmod(binary.stat().st_mode | 0o111)
    return binary


def resolve_game_mod(given, expected_version, folder):
    given = Path(given).resolve()
    if not given.exists():
        raise FileNotFoundError(given)
    if given.is_file():
        with zipfile.ZipFile(given) as z:
            members = [x for x in z.infolist() if not x.is_dir()]
            if len(members) == 1 and members[0].filename.endswith(".zip"):
                tmp = folder / Path(members[0].filename).name
                tmp.write_bytes(z.read(members[0]))
                return resolve_game_mod(tmp, expected_version, folder)
            info_path = "ElectrifiedMainline/info.json"
            if info_path not in z.namelist():
                raise ValueError("Expected installable ElectrifiedMainline ZIP with root ElectrifiedMainline/")
            if z.testzip():
                raise ValueError("Invalid game ZIP CRC")
            info = json.loads(z.read(info_path))
        mod_zip = given
    else:
        moddir = given / "ElectrifiedMainline" if (given / "ElectrifiedMainline").is_dir() else given
        info = json.loads((moddir / "info.json").read_text(encoding="utf-8"))
        mod_zip = folder / f"ElectrifiedMainline_{info['version']}.zip"
        with zipfile.ZipFile(mod_zip, "w", zipfile.ZIP_DEFLATED) as z:
            for f in sorted(moddir.rglob("*")):
                if f.is_file():
                    z.write(f, "ElectrifiedMainline/" + str(f.relative_to(moddir)).replace(os.sep, "/"))
    if info.get("name") != "ElectrifiedMainline" or info.get("version") != expected_version:
        raise ValueError(f"Wrong game mod {info.get('name')} {info.get('version')}; expected {expected_version}")
    if info.get("factorio_version") != "2.1":
        raise ValueError(f"Unexpected supported game series: {info.get('factorio_version')}")
    return mod_zip, info


def make_mod_list(folder, fixture):
    folder.mkdir(parents=True, exist_ok=True)
    payload = {"mods": [
        {"name": "base", "enabled": True},
        {"name": "ElectrifiedMainline", "enabled": True},
        {"name": fixture, "enabled": True},
    ]}
    (folder / "mod-list.json").write_text(json.dumps(payload), encoding="utf-8")


def evidence(log, kind):
    if kind == "em061-power-probe":
        keys = ("[EM061 NATIVE] priority-mode API", "[EM060 NATIVE] delivery sink_J=",
                "[EM060 NATIVE] battery charge J=", "[EM060 NATIVE] reverse sink_J=",
                "[EM061 NATIVE PASS]")
    else:
        keys = ("[EM061 MATRIX] t=240", "[EM061 MATRIX PASS]")
    return [line.split(": ", 1)[-1] for line in log.splitlines() if any(x in line for x in keys)]


def test_case(binary, mod_zip, fixture, ticks, marker, scratch, out):
    name = fixture
    case_dir = scratch / name
    mods = case_dir / "mods"
    make_mod_list(mods, fixture)
    shutil.copy2(mod_zip, mods / f"ElectrifiedMainline_0.1.61.zip")
    shutil.copytree(FIXTURES / name, mods / (name + "_0.0.1"))
    save = case_dir / (name + ".zip")
    out.mkdir(parents=True, exist_ok=True)
    status(f"[NATIVE] {name}: creating disposable map")
    _, create_s = checked_run([binary, "--mod-directory", mods, "--create", save],
                              logfile=out / (name + "-create.log"), timeout=70)
    status(f"[NATIVE] {name}: running {ticks} actual Factorio ticks")
    full, run_s = checked_run([binary, "--mod-directory", mods, "--benchmark", save,
                                "--benchmark-ticks", ticks, "--benchmark-runs", "1"],
                               logfile=out / (name + "-benchmark.log"), timeout=100)
    if marker not in full:
        raise AssertionError(f"No {marker} marker in native benchmark log; see {name}-benchmark.log")
    if "Error while running event" in full or "LuaError" in full:
        raise AssertionError(f"Lua error in native benchmark log of {name}")
    markers = evidence(full, name)
    for item in markers:
        if "TRACE" not in item:
            status("  " + item[:260])
    status(f"[PASS] {name}: engine tick test completed (map {create_s}s + tick {run_s}s)")
    return {"name": name, "status": "PASS", "game_ticks": ticks,
            "create_wall_seconds": create_s, "benchmark_wall_seconds": run_s,
            "evidence": markers, "logs": [name + "-create.log", name + "-benchmark.log"]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--engine", help="Unpacked factorio/bin/x64/factorio executable")
    parser.add_argument("--headless-archive", help="Owner-supplied factorio-headless_linux_2.1.24.tar.xz")
    parser.add_argument("--mod", required=True, help="Exact installed ZIP, outer GitHub artifact ZIP or source dir")
    parser.add_argument("--expected-version", default="0.1.61")
    parser.add_argument("--expected-sha256", help="Optional SHA256 for exact installed mod ZIP")
    parser.add_argument("--output", default="build/native-local-qa", help="Where compact logs and JSON are saved")
    args = parser.parse_args()
    if bool(args.engine) == bool(args.headless_archive):
        parser.error("Provide exactly one of --engine or --headless-archive")
    out = Path(args.output).resolve()
    out.mkdir(parents=True, exist_ok=True)
    summary = {"tool": "Electrified Mainline local native engine QA", "native_engine_used": True,
               "tests": [], "status": "FAIL", "target_mod_version": args.expected_version}
    begin = time.perf_counter()
    try:
        with tempfile.TemporaryDirectory(prefix="em061-native-qa-") as directory:
            temp = Path(directory)
            binary = engine_binary(args, temp)
            version, _ = checked_run([binary, "--version"], timeout=30)
            head = version.splitlines()[0]
            if "2.1.24" not in head or "build 87808" not in head:
                raise ValueError(f"Wrong engine; expected 2.1.24 build 87808, got: {head}")
            summary["native_engine_version"] = head
            status("[NATIVE] " + head)
            mod_zip, info = resolve_game_mod(args.mod, args.expected_version, temp)
            sha = digest(mod_zip)
            summary["mod_sha256"] = sha
            required = args.expected_sha256
            if required and sha.lower() != required.lower():
                raise ValueError("Exact mod ZIP SHA256 mismatch (refusing game test)")
            status(f"[NATIVE] Mod {info['name']} {info['version']} SHA256={sha}")
            for name, ticks, marker in FIXTURE_SPECS:
                result = test_case(binary, mod_zip, name, ticks, marker, temp, out)
                summary["tests"].append(result)
            summary["status"] = "PASS"
    except Exception as e:
        summary["error"] = str(e)
        status("[FAIL] " + str(e))
    summary["total_wall_seconds"] = round(time.perf_counter() - begin, 3)
    (out / "native-report.json").write_text(json.dumps(summary, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    status(f"NATIVE QA {summary['status']}: {len(summary['tests'])}/{len(FIXTURE_SPECS)} game scenarios, {summary['total_wall_seconds']}s; report={out/'native-report.json'}")
    return 0 if summary["status"] == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())