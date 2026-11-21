#!/usr/bin/env python3
"""Run Base-only native finite locomotive proof, plus genuine disk SAVE/LOAD.
Run from a checkout with --factorio /path/to/factorio --output disposable-dir.
Never used for distributing or installing the mod.
"""
import argparse
import hashlib
import json
import re
import shutil
import socket
import subprocess
import time
from pathlib import Path

def run(command, output, timeout=40):
    with output.open("w",encoding="utf8") as f:
        subprocess.run(command,check=True,timeout=timeout,stdout=f,stderr=subprocess.STDOUT)
    return output.read_text(encoding="utf8")

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--factorio",type=Path,required=True)
    p.add_argument("--output",type=Path,required=True)
    args=p.parse_args()
    engine=args.factorio.resolve()
    source=Path(__file__).resolve().parent/"em072-native-traction-probe"
    out=args.output.resolve()
    if not engine.is_file() or not (source/"control.lua").is_file():
        raise FileNotFoundError("Factorio engine or EM072 probe missing")
    (out/"mods").mkdir(parents=True,exist_ok=True)
    (out/"private/saves").mkdir(parents=True,exist_ok=True)
    mod=out/"mods/em072-native-traction-probe_0.0.1"
    if mod.exists(): shutil.rmtree(mod)
    mod.mkdir()
    for filename in ("info.json","data.lua","control.lua"):
        shutil.copy2(source/filename,mod/filename)
    mods=[("base",True),("space-age",False),("elevated-rails",False),("quality",False),("recycler",False),("em072-native-traction-probe",True)]
    (out/"mods/mod-list.json").write_text(json.dumps({"mods":[{"name":n,"enabled":v} for n,v in mods]}),encoding="utf8")
    (out/"config.ini").write_text(f'[path]\nread-data={engine.parents[2]/"data"}\nwrite-data={out/"private"}\n',encoding="utf8")
    cmd=[str(engine),"--config",str(out/"config.ini"),"--mod-directory",str(out/"mods")]
    run(cmd+["--create",str(out/"start.zip")],out/"create.log")
    native=run(cmd+["--benchmark",str(out/"start.zip"),"--benchmark-ticks","620","--benchmark-runs","1"],out/"native.log")
    match=re.search(r'\[EM072 NATIVE PASS\].*?burner_distance=(\d+\.\d+).*?physical_distance=(\d+\.\d+).*?void_distance=(\d+\.\d+)',native)
    assert match and "tick=240" in match.group(0),"Base-only native power controls FAIL"
    assert "[EM072 SNAP] tick=3 kind=burner" in native and "[EM072 SNAP] tick=5 kind=burner" in native
    # Inject a save hook into the disposable copy ONLY; the tracked control is unchanged.
    program=(mod/"control.lua").read_text(encoding="utf8")
    marker="-- EM072_SERVER_SAVE_HOOK"
    assert program.count(marker)==1
    hook="""if t==3 then
  local ok,err=pcall(function() game.server_save('em072-checkpoint') end)
  log('[EM072 SERVER SAVE] at=3 requested='..tostring(ok)..' err='..tostring(err))
 end"""
    (mod/"control.lua").write_text(program.replace(marker,hook),encoding="utf8")
    run(cmd+["--create",str(out/"server-start.zip")],out/"server-create.log")
    server={"name":"EM072 isolated native traction QA","description":"Disposable local test","max_players":1,
            "visibility":{"public":False,"lan":False},"require_user_verification":False,
            "auto_pause":False,"autosave_interval":100}
    (out/"server-settings.json").write_text(json.dumps(server),encoding="utf8")
    with socket.socket() as sock:
        sock.bind(("127.0.0.1",0));port=sock.getsockname()[1]
    logfile=out/"save-server.log"
    with logfile.open("w",encoding="utf8") as output:
        proc=subprocess.Popen(cmd+["--start-server",str(out/"server-start.zip"),
                         "--server-settings",str(out/"server-settings.json"),"--port",str(port)],
                         stdout=output,stderr=subprocess.STDOUT)
        checkpoint=out/"private/saves/em072-checkpoint.zip"
        try:
            for _ in range(120):
                time.sleep(0.25)
                log=logfile.read_text(encoding="utf8",errors="replace")
                if proc.poll() is not None: raise RuntimeError("Server exited: "+log[-1500:])
                if checkpoint.is_file() and "[EM072 SERVER SAVE] at=3 requested=true" in log and "Saving finished" in log:break
                if "Error " in log:raise RuntimeError("Game error: "+log[-1500:])
            else:raise TimeoutError("Native Factorio disk checkpoint was not saved")
        finally:
            proc.terminate()
            try:proc.wait(timeout=5)
            except subprocess.TimeoutExpired:proc.kill();proc.wait()
    loaded=run(cmd+["--test-save",str(checkpoint),"--test-ticks","240"],out/"native-reload.log")
    assert "[EM072 NATIVE PASS] tick=240" in loaded,"Disk reload traction verification failed"
    assert "[EM072 SNAP] tick=10 kind=burner" in loaded
    report={"status":"PASS","engine":"Factorio 2.1.24 build 87808","base_only":True,
            "injected_burner_initial_j":120000,"physical_fuel_item_j":120000,
            "no_fuel_train_moved":False,"benchmark_ticks":620,"disk_reload_ticks":240,
            "burner_distance_tiles":float(match[1]),"physical_distance_tiles":float(match[2]),
            "void_distance_tiles":float(match[3]),"disk_save_bytes":checkpoint.stat().st_size,
            "no_train_speed_writes":True,
            "native_log_sha256":hashlib.sha256((out/"native.log").read_bytes()).hexdigest(),
            "reload_log_sha256":hashlib.sha256((out/"native-reload.log").read_bytes()).hexdigest(),
            "unverified":["No EM070 source debit","No 500 kW wagon gain","No regen/battery","No automatic schedule"]}
    (out/"report.json").write_text(json.dumps(report,indent=2,ensure_ascii=False)+"\n",encoding="utf8")
    print("[EM072 NATIVE DISK PASS] "+json.dumps(report,ensure_ascii=False))

if __name__=="__main__":main()
