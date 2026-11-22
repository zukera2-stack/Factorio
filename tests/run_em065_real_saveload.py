#!/usr/bin/env python3
"""EM065 real private server SAVE -> independent Factorio 2.1.24 --test-save.

A --benchmark does NOT create the file even if Lua game.server_save succeeds.
Tests are disposable; never access user saves. Fails closed on all native errors.
"""
import argparse
import hashlib
import json
from pathlib import Path
import socket
import subprocess
import sys
import time

def run(command,output,timeout=180):
    with output.open("w",encoding="utf-8") as f:
        p=subprocess.run([str(v) for v in command],stdout=f,stderr=subprocess.STDOUT,
                         check=False,timeout=timeout)
    log=output.read_text(encoding="utf-8",errors="replace")
    if p.returncode:
        raise RuntimeError(f"Factorio exit={p.returncode} log={output}: {log[-3200:]}")
    return log

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--factorio",type=Path,required=True)
    ap.add_argument("--mods",type=Path,required=True)
    ap.add_argument("--initial",type=Path,required=True)
    ap.add_argument("--output",type=Path,required=True)
    args=ap.parse_args()
    exe=args.factorio.resolve()
    output=args.output.resolve()
    output.mkdir(parents=True,exist_ok=True)
    private=output/"private"
    (private/"saves").mkdir(parents=True,exist_ok=True)
    config=output/"config.ini"
    config.write_text("[path]\nread-data="+str(exe.parents[2]/"data")+
                      "\nwrite-data="+str(private)+"\n",encoding="utf-8")
    command=[str(exe),"--config",str(config),"--mod-directory",str(args.mods.resolve())]
    version=subprocess.run([str(exe),"--version"],capture_output=True,
                           text=True,check=True).stdout
    assert "2.1.24" in version and "87808" in version,version
    save=private/"saves"/"em065-paid-checkpoint.zip"
    settings=output/"server-settings.json"
    settings.write_text(json.dumps({
        "name":"EM065 private native traction paid-J checkpoint",
        "description":"Disposable source-paid Factorio 2.1.24 research ONLY",
        "visibility":{"public":False,"lan":False},
        "max_players":1,
        "require_user_verification":False,
        "auto_pause":False,
        "autosave_interval":100
    }),encoding="utf-8")
    with socket.socket() as sock:
        sock.bind(("127.0.0.1",0))
        port=sock.getsockname()[1]
    serverlog=output/"em065-real-save-load-server.log"
    with serverlog.open("w",encoding="utf-8") as f:
        server=subprocess.Popen(command+["--start-server",str(args.initial.resolve()),
                           "--server-settings",str(settings),"--port",str(port)],
                          stdout=f,stderr=subprocess.STDOUT)
        try:
            for _ in range(500):
                time.sleep(0.2)
                data=serverlog.read_text(encoding="utf-8",errors="replace")
                if server.poll() is not None:
                    raise RuntimeError("Private Factorio server died: "+data[-3500:])
                if (save.is_file() and save.stat().st_size>1000 and
                    "[EM065 DISK CHECKPOINT] tick=125" in data and
                    "Saving finished" in data):
                    break
            else:
                raise TimeoutError("No complete real disk SAVE: "+data[-3500:])
        finally:
            server.terminate()
            try: server.wait(timeout=9)
            except subprocess.TimeoutExpired:
                server.kill()
                server.wait(timeout=9)
    digest=hashlib.sha256(save.read_bytes()).hexdigest()
    (output/"em065-real-save-load-checkpoint.sha256").write_text(
        digest+"  em065-paid-checkpoint.zip\n",encoding="utf-8")
    print("TRUE FACTORIO DISK SAVE:",save.stat().st_size,"bytes",digest,flush=True)
    newprocess=run(command+["--test-save",str(save),"--test-ticks","365"],
                   output/"em065-real-save-load-reload.log",timeout=240)
    for marker in ["[EM065 NATIVE MOTION]","[EM065 NATIVE PAID PASS]",
                   "[EM065 NATIVE 0W CONTROL]","[EM065 REAL SAVELOAD PASS]"]:
        if marker not in newprocess:
            raise AssertionError("Separate-process LOAD missing "+marker+
                                 "\n"+newprocess[-3700:])
    print("NATIVE 2MW REAL SAVELOAD PASS",digest,flush=True)

if __name__=="__main__":
    main()
