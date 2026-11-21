#!/usr/bin/env python3
"""Fast, offline Factorio mod QA; no GitHub Actions required.

Lua modules execute under a local Lua interpreter (or liblua 5.4 fallback),
NOT under Factorio's native electric-network solver. Never report an engine PASS.
"""
import argparse
import ctypes
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
import zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
TESTS = ['dispatch.lua', 'devices.lua', 'priority.lua', 'topology.lua']


def announce(message):
    print(message, flush=True)


def liblua():
    for name in ('liblua5.4.so.0', 'liblua5.4.dylib', 'lua54.dll'):
        try:
            lib = ctypes.CDLL(name)
            break
        except OSError:
            continue
    else:
        return None
    state_type = ctypes.c_void_p
    lib.luaL_newstate.restype = state_type
    lib.luaL_openlibs.argtypes = [state_type]
    lib.luaL_loadfilex.argtypes = [state_type, ctypes.c_char_p, ctypes.c_char_p]
    lib.luaL_loadfilex.restype = ctypes.c_int
    lib.lua_pcallk.argtypes = [state_type, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_longlong, ctypes.c_void_p]
    lib.lua_pcallk.restype = ctypes.c_int
    lib.lua_tolstring.argtypes = [state_type, ctypes.c_int, ctypes.c_void_p]
    lib.lua_tolstring.restype = ctypes.c_char_p
    lib.lua_settop.argtypes = [state_type, ctypes.c_int]
    lib.lua_close.argtypes = [state_type]
    return lib


def lua_execute(file, root, syntax_only=False):
    interpreter = next((shutil.which(x) for x in ('lua5.2', 'lua5.4', 'lua')), None)
    if interpreter and not syntax_only:
        proc = subprocess.run([interpreter, str(file)], cwd=root, text=True, capture_output=True, timeout=30)
        return proc.returncode == 0, (proc.stdout + proc.stderr).strip(), f'{Path(interpreter).name} script'
    if syntax_only:
        luac = next((shutil.which(x) for x in ('luac5.2', 'luac5.4', 'luac')), None)
        if luac:
            proc = subprocess.run([luac, '-p', str(file)], cwd=root, capture_output=True, text=True, timeout=15)
            return proc.returncode == 0, (proc.stdout + proc.stderr).strip(), f'{Path(luac).name} compile'
    lib = liblua()
    if not lib:
        return None, 'Neither Lua command nor compatible Lua library is available', 'unavailable'
    original_cwd = os.getcwd()
    os.chdir(root)
    state = lib.luaL_newstate()
    if not state:
        os.chdir(original_cwd)
        return False, 'Lua VM allocation failed', 'liblua5.4'
    try:
        lib.luaL_openlibs(state)
        ret = lib.luaL_loadfilex(state, str(file).encode('utf-8'), None)
        if ret == 0 and not syntax_only:
            ret = lib.lua_pcallk(state, 0, -1, 0, 0, None)
        msg = '' if ret == 0 else (lib.lua_tolstring(state, -1, None) or b'unknown Lua error').decode('utf-8', errors='replace')
        return ret == 0, msg, 'liblua5.4 (compatibility only)'
    finally:
        lib.lua_close(state)
        os.chdir(original_cwd)


def source_from_arg(value, dest):
    p = Path(value).resolve()
    if p.is_dir():
        if (p / 'info.json').exists():
            return p
        if (p / 'ElectrifiedMainline' / 'info.json').exists():
            return p / 'ElectrifiedMainline'
        raise ValueError(f'Cannot find Factorio info.json under {p}')
    if not p.exists():
        raise FileNotFoundError(p)
    with zipfile.ZipFile(p) as z:
        names = z.namelist()
        for item in names:
            parts = Path(item).parts
            if item.startswith('/') or '..' in parts or '\\' in item:
                raise ValueError(f'Unsafe ZIP entry: {item}')
        if len(names) == 1 and names[0].endswith('.zip'):
            child = dest / names[0]
            child.write_bytes(z.read(names[0]))
            return source_from_arg(child, dest)
        z.extractall(dest)
    root = dest / 'ElectrifiedMainline'
    if not (root / 'info.json').exists():
        raise ValueError('Installed ZIP has no ElectrifiedMainline/info.json')
    return root


def inspect_log(path):
    if not path:
        return None
    s = Path(path).read_text(encoding='utf-8-sig', errors='replace')
    lines = s.splitlines()
    stations,flow,problems,auth = [],0,[],None
    for l in lines:
        v = re.search(r'Loading mod ElectrifiedMainline\s+(\d+\.\d+\.\d+)', l)
        if v:
            auth = v.group(1)
        if '[EM060 flow]' in l:
            flow += 1
        if '[EM060] station=' in l:
            m = re.search(r'station=(\d+).*?measured=([\d.]+)MW.*?planned=([+-]?[\d.]+)MW', l)
            if m:
                stations.append((m.group(1), float(m.group(2)),float(m.group(3))))
        if 'Error ' in l or 'LuaError' in l or 'Error while' in l:
            problems.append(l[:230])
    return {
        'loaded_mod_version': auth,
        'bridge_status_entries': len(stations),
        'flow_debug_entries': flow,
        'stations_observed': sorted({x[0] for x in stations}),
        'max_measured_mw': max((x[1] for x in stations),default=None),
        'planned_reverse_seen': any(x[2] < 0 for x in stations) and any(x[2] > 0 for x in stations),
        'logged_error_lines': problems[:15],
        'warnings_present': sum('Warning ' in l for l in lines),
        'native_log_is_prior_game_evidence_not_a_fresh_engine_run': True,
    }


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--mod',required=True,help='Installed game ZIP, GitHub artifact ZIP, or extracted ElectrifiedMainline directory')
    parser.add_argument('--log',help='Optional Factorio game log (analysed, not replayed)')
    parser.add_argument('--expected-version',default='0.1.61')
    parser.add_argument('--expected-sha256',help='Optional SHA256 of inner game ZIP')
    parser.add_argument('--report',default=None,help='JSON report destination')
    args=parser.parse_args()
    started=time.monotonic()
    results=[]
    def report(name,result,details):
        results.append({'check':name,'status':'PASS' if result is True else 'SKIP' if result is None else 'FAIL','details':details})
        announce(f"[{results[-1]['status']}] {name} — {details}")
    with tempfile.TemporaryDirectory(prefix='em-qa-') as temp:
        root=source_from_arg(args.mod,Path(temp))
        info=json.loads((root/'info.json').read_text(encoding='utf-8'))
        report('mod identity', info.get('name')=='ElectrifiedMainline' and info.get('version')==args.expected_version,
               f"name={info.get('name')} version={info.get('version')}")
        lua=list(root.rglob('*.lua')); png=list(root.rglob('*.png'))
        report('runtime inventory',len(lua)>0 and len(png)>=83, f'{len(lua)} Lua, {len(png)} PNG')
        internalzip = root.parent/'ElectrifiedMainline_0.1.61.zip'
        if internalzip.exists():
            digest=hashlib.sha256(internalzip.read_bytes()).hexdigest()
            report('artifact SHA256',not args.expected_sha256 or digest.lower()==args.expected_sha256.lower(),digest)
            with zipfile.ZipFile(internalzip) as z:
                report('ZIP content/CRC', z.testzip() is None and len(z.namelist())==130,f"{len(z.namelist())} entries")
        else:
            report('artifact SHA256',None,'Unpacked source; no ZIP to hash')
        failed=[];backends=set()
        for lua_file in lua:
            passed,error,backend=lua_execute(lua_file,root,True)
            backends.add(backend)
            if not passed:
                failed.append(f'{lua_file.relative_to(root)}: {error}')
        report('Lua syntax',not failed, f'{len(lua)} files; {", ".join(sorted(backends))}; '+ ('; '.join(failed[:3]) if failed else 'all compiled'))
        (Path(temp)/'ElectrifiedMainline').mkdir(exist_ok=True)
        # The source root from a ZIP already resides in temp/ElectrifiedMainline.
        # For directory input create a symlink-free copy so Lua uses expected relative path.
        target=Path(temp)/'ElectrifiedMainline'
        if root.resolve()!=target.resolve():
            shutil.copytree(root,target,dirs_exist_ok=True)
        for test in TESTS:
            ok,detail,backend=lua_execute(HERE/'checks'/test,Path(temp),False)
            report(f'Lua {test}',ok,f'{backend}'+(f'; {detail}' if detail else ''))
    if args.log:
        log=inspect_log(args.log)
        report('Factorio log version',log['loaded_mod_version']==args.expected_version,
               f"engine log reports {log['loaded_mod_version']}")
        report('Factorio log runtime',bool(log['bridge_status_entries']) and not log['logged_error_lines'],
               f"{log['bridge_status_entries']} bridge entries; max {log['max_measured_mw']} MW; {log['flow_debug_entries']} flow diagnostics; error lines {len(log['logged_error_lines'])}")
    else:
        log=None
        report('native engine run',None,'Factorio executable unavailable; no native 2.1.24 test was run locally')
    elapsed=round(time.monotonic()-started,3)
    status='FAIL' if any(x['status']=='FAIL' for x in results) else 'PASS'
    obj={'status':status,'checks':results,'elapsed_seconds':elapsed,
         'test_layer':'local Lua + ZIP + optional prior actual engine log',
         'native_solver_executed_now':False,'log_summary':log}
    if args.report:
        target=Path(args.report);target.parent.mkdir(parents=True,exist_ok=True)
        target.write_text(json.dumps(obj,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
    announce(f'LOCAL QA RESULT {status}; {len(results)} checks; {elapsed}s; native game engine NOT executed')
    return status!='PASS'


if __name__=='__main__':
    sys.exit(main())