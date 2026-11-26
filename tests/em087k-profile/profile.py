from pathlib import Path
import zipfile,shutil,subprocess,re,json
p=Path(__file__).parent;eng=Path('/mnt/data/em087c/factorio');qa=p/'base/mods'
for tag in ['base','codeonly']:
 w=p/f'profile-{tag}';m=w/'mods';m.mkdir(parents=True,exist_ok=True)
 shutil.copytree(qa/'em-audit-qa_0.0.1',m/'em-audit-qa_0.0.1',dirs_exist_ok=True);shutil.copy2(qa/'mod-list.json',m/'mod-list.json');cfg=w/'config.ini';cfg.write_text(f'[path]\nread-data={eng}/data\nwrite-data={w}\n')
 base=p/tag/'mods/ElectrifiedMainline_0.1.96.zip'
 with zipfile.ZipFile(base) as z,zipfile.ZipFile(m/base.name,'w',zipfile.ZIP_DEFLATED) as out:
  for f in z.namelist():
   b=z.read(f)
   if f.endswith('/scripts/control.lua'):
    s=b.decode();s=s.replace('local function on_tick(event)','''local function emk_profile(label,fn,...)
    if game.tick%15~=7 then return fn(...) end
    local p=helpers.create_profiler();local a,b=fn(...);p.stop();log({"","[EM087K PROFILE] tick="..game.tick.." "..label.." ",p});return a,b
end
local function on_tick(event)''')
    for name in ['technical046','mast059','bridge058','art030','helper067','paidTraction065','power019']:
     s=s.replace(name+'.on_tick(', 'emk_profile("'+name+'",'+name+'.on_tick,')
    s=s.replace('    pantograph049.sync(trains,','    local visual_profile=event.tick%15==7 and helpers.create_profiler() or nil\n    pantograph049.sync(trains,')
    target='''    end
end

-- One registration per event.''';assert s.count(target)==1
    s=s.replace(target,'''    end
    if visual_profile then visual_profile.stop();log({"","[EM087K PROFILE] tick="..event.tick.." visual_diagnostics ",visual_profile}) end
end

-- One registration per event.''');b=s.encode()
   if f.endswith('/scripts/power_bridge_058.lua'):
    s=b.decode();s=s.replace('function M.on_tick(tick,graph)\n local s=state()','''function M.on_tick(tick,graph)
 local prof=tick%15==7 and helpers.create_profiler() or nil
 local function mark(label) if prof then prof.stop();log({"","[EM087K BRIDGE] tick="..tick.." "..label.." ",prof});prof=helpers.create_profiler() end end
 local s=state()''')
    for before,label in [(' local previous=(s.sample_tick','allow_sample'),(' local traction_demand=','ports_observe'),(' local plan=dispatch.plan','traction_requests'),(' local connected_peers=','dispatch'),(' local accepted,rejected=M.select(safe)','idle_isolation'),(' -- Settled diagnostic:','settlement')]:
     assert s.count(before)==1,(label,s.count(before));s=s.replace(before,' mark("'+label+'")\n'+before)
    target=''' end
end
function M.command''';assert s.count(target)==1;s=s.replace(target,''' end
 mark("diagnostic")
end
function M.command''');b=s.encode()
   out.writestr(f,b)
 cmd=[str(eng/'bin/x64/factorio'),'--config',str(cfg),'--mod-directory',str(m),'--benchmark','/mnt/data/em087c/evidence/saves/100x2.zip','--benchmark-ticks','180','--benchmark-runs','1']
 with (p/f'profile-{tag}.log').open('w') as f:rc=subprocess.run(cmd,stdout=f,stderr=subprocess.STDOUT,timeout=180).returncode
 print(tag,rc,flush=True)
 if rc:raise RuntimeError(tag)
