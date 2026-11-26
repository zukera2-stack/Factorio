from pathlib import Path
import zipfile,shutil,json,argparse,hashlib
p=argparse.ArgumentParser();p.add_argument('--engine-root',type=Path,required=True);p.add_argument('--full-mod',type=Path,required=True);p.add_argument('--suite',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args();eng=a.engine_root.resolve();base=a.full_mod.resolve();suite=a.suite.resolve();w=a.output.resolve();m=w/'mods';m.mkdir(parents=True,exist_ok=False)
assert hashlib.sha256(base.read_bytes()).hexdigest()=='9c3ebef74c366aaeed530e48b53a1c1594acbe8e7347ad6aed07bba5733b2d9a'
q=m/'em-mixed-outposts-qa_0.0.1';shutil.copytree(suite/q.name,q,dirs_exist_ok=True);f=q/'scenarios/continuous/control.lua';s=f.read_text();s=s.replace('elseif t==1800 then',"elseif t==600 then\n  local q=snapshot(st,t);local moving=0;for _,r in ipairs(st.trains)do if math.abs(r.loco.train.speed)>0.001 then moving=moving+1 end end;ck(moving==N,'not all moving t600 '..moving);say('PROFILE WINDOW PASS '..N..' moving at t600');script.finish_test(true)\n elseif t==1800 then");f.write_text(s)
(m/'mod-list.json').write_text(json.dumps({'mods':[{'name':n,'enabled':True} for n in ('base','ElectrifiedMainline','em-mixed-outposts-qa')]}));(w/'config.ini').write_text(f'[path]\nread-data={eng}/data\nwrite-data={w}\n')
with zipfile.ZipFile(base) as z,zipfile.ZipFile(m/'ElectrifiedMainline_0.1.98.zip','w',zipfile.ZIP_DEFLATED) as out:
 for name in z.namelist():
  b=z.read(name)
  if name.endswith('/scripts/control.lua'):
   s=b.decode();s=s.replace('local function on_tick(event)','''local function em_profile_sample(tick) return tick>=240 and (tick%30==7 or tick%600==0) end
local function em_profile(label,fn,...)
    if not em_profile_sample(game.tick) then return fn(...) end
    local p=helpers.create_profiler();local a,b=fn(...);p.stop();log({"","[EM087O PROFILE] tick="..game.tick.." "..label.." ",p});return a,b
end
local function on_tick(event)''')
   for n in ['technical046','mast059','bridge058','art030','helper067','paidTraction065','power019']:
    a=n+'.on_tick(';assert s.count(a)==1;s=s.replace(a,'em_profile("'+n+'",'+n+'.on_tick,')
   s=s.replace('    pantograph049.sync(trains,','    local visual_profile=em_profile_sample(event.tick) and helpers.create_profiler() or nil\n    pantograph049.sync(trains,')
   a='    end\nend\n\n-- One registration per event.';assert s.count(a)==1;s=s.replace(a,'    end\n    if visual_profile then visual_profile.stop();log({"","[EM087O PROFILE] tick="..event.tick.." visual_diagnostics ",visual_profile}) end\nend\n\n-- One registration per event.');b=s.encode()
  if name.endswith('/scripts/power_bridge_058.lua'):
   s=b.decode();a='function M.on_tick(tick,graph)\n local s=state()';assert s.count(a)==1;s=s.replace(a,'''function M.on_tick(tick,graph)
 local prof=(tick>=240 and (tick%30==7 or tick%600==0)) and helpers.create_profiler() or nil
 local function mark(label) if prof then prof.stop();log({"","[EM087O BRIDGE] tick="..tick.." "..label.." ",prof});prof=helpers.create_profiler() end end
 local s=state()''')
   for a,label in [(' local previous=(s.sample_tick','allow_sample'),(' local traction_demand=','ports_observe'),(' local plan=dispatch.plan','traction_requests'),(' local connected_peers=','dispatch'),(' local accepted,rejected=M.select(safe)','idle_isolation'),(' -- Settled diagnostic:','settlement')]:
    assert s.count(a)==1;s=s.replace(a,' mark("'+label+'")\n'+a)
   a=' end\nend\nfunction M.command';assert s.count(a)==1;s=s.replace(a,' end\n mark("diagnostic")\nend\nfunction M.command');b=s.encode()
  out.writestr(name,b)
