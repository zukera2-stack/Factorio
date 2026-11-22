#!/usr/bin/env python3
"""Real dual-process Factorio 2.1.24 fault runner: benchmark is NOT disk SAVE.

Runs exact original FULL 0.1.63 ZIP + separate test probe in a private server,
waits for actual disk save, shuts down server, and --test-save in another process.
Exit nonzero on any violated native assertion. Original mod bytes are not changed.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import socket
import subprocess
import sys
import time

SHA = "2b150cdc506dafdde8fd10358e8f4e31d62c3215469db2027ba2a56b4d47c2b6"
CONFIG = {
    "rail_stock": {
        "probe": "em063-fault-rail-stock",
        "checkpoint": "em063-fault-rail_stock-checkpoint",
        "tick": 100,
        "benchmark": 115,
        "resume": 230,
        "pass": "[EM063 RAIL STOCK PASS]",
        "later": "event=destroy_owner|tick=160",
    },
    "electrical": {
        "probe": "em063-fault-electrical",
        "checkpoint": "em063-fault-electrical-checkpoint",
        "tick": 500,
        "benchmark": 525,
        "resume": 740,
        "pass": "[EM063 POWER FAULT PASS]",
        "later": "event=double_mast_break|tick=930",
    },
}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def run(cmd, log, timeout=180):
    with log.open("w", encoding="utf-8") as f:
        result = subprocess.run([str(x) for x in cmd], stdout=f,
                                stderr=subprocess.STDOUT, timeout=timeout,
                                check=False)
    data = log.read_text(encoding="utf-8", errors="replace")
    if result.returncode != 0:
        raise RuntimeError(f"Factorio exited {result.returncode}: {log}\n{data[-3500:]}")
    return data


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--factorio", required=True, type=Path)
    parser.add_argument("--mods", required=True, type=Path)
    parser.add_argument("--work-dir", required=True, type=Path)
    parser.add_argument("--lane", required=True, choices=sorted(CONFIG))
    args = parser.parse_args()

    lane = args.lane
    spec = CONFIG[lane]
    work = args.work_dir.resolve()
    logs = work / "logs"
    logs.mkdir(parents=True, exist_ok=True)
    private = work / "private"
    (private / "saves").mkdir(parents=True, exist_ok=True)
    binary = args.factorio.resolve()
    mods = args.mods.resolve()
    z = mods / "ElectrifiedMainline_0.1.63.zip"
    report = {
        "lane": lane,
        "fullmod_source_sha256_expected": SHA,
        "checkpoint": spec["checkpoint"],
        "expected_native_engine": "Factorio 2.1.24 build 87808",
        "separate_server_disk_save_and_test_save": True,
        "pass": False
    }
    try:
        report["fullmod_source_sha256_observed"] = sha(z)
        if report["fullmod_source_sha256_observed"] != SHA:
            raise ValueError("Not the exact owner full 0.1.63 ZIP; refusing test")
        if not (mods / (spec["probe"] + "_0.0.1") / "control.lua").is_file():
            raise ValueError("Missing separate test-only probe")
        versions = subprocess.run([str(binary), "--version"], capture_output=True,
                                  text=True, check=True).stdout
        if not ("2.1.24" in versions and "87808" in versions):
            raise ValueError("Wrong native Factorio engine: " + versions[:250])
        report["engine"] = versions.splitlines()[0]

        ini = work / "config.ini"
        ini.write_text("[path]\nread-data=" + str(binary.parents[2] / "data")
                       + "\nwrite-data=" + str(private) + "\n", encoding="utf-8")
        cmd = [str(binary), "--config", str(ini), "--mod-directory", str(mods)]
        initial = work / "initial.zip"
        run(cmd + ["--create", str(initial)], logs / "create.log")
        benchmark = run(
            cmd + ["--benchmark", str(initial), "--benchmark-ticks",
                   str(spec["benchmark"]), "--benchmark-runs", "1"],
            logs / "benchmark.log"
        )
        if "event=disk_checkpoint|tick=" + str(spec["tick"]) not in benchmark:
            raise AssertionError("Benchmark never reached native checkpoint tick")
        report["benchmark_reached_checkpoint_tick"] = True

        settings = work / "server-settings.json"
        settings.write_text(json.dumps({
            "name": "EM063 private full mod fault test " + lane,
            "description": "Local disposable CI only; not a user save.",
            "max_players": 1,
            "visibility": {"public": False, "lan": False},
            "require_user_verification": False,
            "auto_pause": False,
            "autosave_interval": 100
        }), encoding="utf-8")

        with socket.socket() as sock:
            sock.bind(("127.0.0.1", 0))
            port = sock.getsockname()[1]
        checkpoint = private / "saves" / (spec["checkpoint"] + ".zip")
        server_log = logs / "server.log"
        with server_log.open("w", encoding="utf-8") as file:
            server = subprocess.Popen(
                cmd + ["--start-server", str(initial), "--server-settings",
                       str(settings), "--port", str(port)],
                stdout=file, stderr=subprocess.STDOUT
            )
            try:
                for _ in range(440):
                    time.sleep(0.2)
                    message = server_log.read_text(encoding="utf-8", errors="replace")
                    success = ("event=disk_checkpoint|tick=" + str(spec["tick"])
                               in message and "Saving finished" in message
                               and checkpoint.is_file() and checkpoint.stat().st_size > 0)
                    if success:
                        report["server_checkpoint_present"] = True
                        break
                    if server.poll() is not None:
                        raise RuntimeError("Native server died before disk checkpoint:\n"
                                           + message[-4000:])
                else:
                    raise TimeoutError("No completed real disk save in server:\n"
                                       + message[-4000:])
            finally:
                server.terminate()
                try:
                    server.wait(timeout=9)
                except subprocess.TimeoutExpired:
                    server.kill()
                    server.wait(timeout=9)

        report["checkpoint_bytes"] = checkpoint.stat().st_size
        report["checkpoint_sha256"] = sha(checkpoint)
        (logs / "checkpoint-sha256.txt").write_text(
            report["checkpoint_sha256"] + "  " + checkpoint.name + "\n", encoding="utf-8")
        print("REAL DISK SAVE", lane, checkpoint, report["checkpoint_bytes"], flush=True)

        replay = run(cmd + ["--test-save", str(checkpoint), "--test-ticks",
                            str(spec["resume"])],
                     logs / "reload-separate-process.log", timeout=240)
        if spec["later"] not in replay:
            raise AssertionError("Independent SAVE/LOAD didn't reach after-fault phase "
                                 + spec["later"] + ":\n" + replay[-3000:])
        if spec["pass"] not in replay:
            raise AssertionError("REAL FAULT GATE FAILURE: no native PASS marker. "
                                 "Read reload-separate-process.log:\n" + replay[-4500:])
        report["pass"] = True
        print("PARALLEL NATIVE FAULT PASS", lane, report["checkpoint_sha256"],
              flush=True)
    except Exception as exc:
        report["failure"] = str(exc)[-5500:]
        print("PARALLEL NATIVE FAULT FAIL", lane, str(exc)[-3500:], file=sys.stderr,
              flush=True)
        raise
    finally:
        (logs / "result.json").write_text(json.dumps(report, ensure_ascii=False,
                                                      indent=2) + "\n",
                                         encoding="utf-8")


if __name__ == "__main__":
    main()
