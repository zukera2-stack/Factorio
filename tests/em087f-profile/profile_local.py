from pathlib import Path
import zipfile,shutil,json,subprocess,re,statistics
p=Path(__file__).parent;engine=Path('/mnt/data/em087c/factorio');binary=engine/'bin/x64/factorio'
fixture=p/'localqa/mods/em-watch-qa_0.0.1'
for tag in ['base','candidate']:
 w=p/('profile-'+tag);m=w/'mods';m.mkdir(parents=True,exist_ok=True)
 source=next((p/tag/'mods').glob('ElectrifiedMainline_*.zip'))
 with zipfile.ZipFile(source) as z,zipfile.ZipFile(m/source.name,'w',zipfile.ZIP_DEFLATED) as out:
  for n in z.namelist():
   data=z.read(n)
   if n.endswith('/scripts/technical_network_046.lua'):
    s=data.decode();a='  local s=M.ensure_storage()\n  local nodes,parents={},{}';b='  return M.refresh_components((rejected==0 and missed==0 and failures==0) and verified or nil)'
    assert s.count(a)==s.count(b)==1
    s=s.replace(a,'  local prof=(game.tick>=190 and game.tick<=430) and helpers.create_profiler() or nil\n'+a)
    s=s.replace(b,'''  local result=M.refresh_components((rejected==0 and missed==0 and failures==0) and verified or nil)
  if prof then prof.stop();log({"","[EM087F PROFILE] sync tick="..game.tick.." ",prof}) end
  return result''')
    data=s.encode()
   out.writestr(n,data)
 shutil.copytree(fixture,m/fixture.name,dirs_exist_ok=True)
 scenario=m/fixture.name/'scenarios/localstress';scenario.mkdir(parents=True,exist_ok=True)
 scenario.joinpath('control.lua').write_text('''local H='em-high-speed-straight-rail';local M='em-35kv-catenary-pole';local N=50
local function ck(v,m) if not v then error('[EM087F STRESS FAIL] '..m) end end
local function mk(s,name,x,y,raised)
 local r=s.create_entity{name=name,position={x,y},force='player',direction=defines.direction.east,auto_connect=false,raise_built=raised}
 ck(r and r.valid,'create '..name..' at '..x..','..y);return r
end
local function cknet(g,same,label)
 local a,b=g.masts[1].electric_network_id,g.masts[3].electric_network_id
 ck(a and b and ((a==b)==same),label..' '..tostring(a)..'/'..tostring(b))
 return a,b
end
script.on_init(function()
 local s=game.create_surface('em087f-stress',{width=256,height=8192});s.generate_with_lab_tiles=true
 local st={s=s,groups={},ids={}}
 for i=1,N do local y=(i-25)*160+1;s.request_to_generate_chunks({0,y},2) end
 s.force_generate_chunk_requests()
 for i=1,N do
  local y=(i-25)*160+1;local g={y=y,rails={},masts={}};st.groups[i]=g
  for x=-43,43,2 do g.rails[x]=mk(s,H,x,y,true) end
  for _,x in ipairs({-21.5,-1.5,18.5}) do g.masts[#g.masts+1]=mk(s,M,x,y+1.5,true) end
 end
 storage.qa=st
end)
script.on_event(defines.events.on_tick,function(e)
 local st=storage.qa;local g=st.groups[25];local t=e.tick
 if t==120 then
  local seen={}
  for i,v in ipairs(st.groups) do local id=cknet(v,true,'initial '..i);ck(not seen[id],'shorted corridors');seen[id]=true;st.ids[i]=id end
 end
 if t>=200 and t<440 then
  local phase=(t-200)%40
  if phase==0 then ck(g.rails[-11].destroy{raise_destroy=false},'silent cut refused')
  elseif phase==3 or phase==23 then
   cknet(g,phase==23,'changed corridor')
   for i,v in ipairs(st.groups) do if i~=25 then local id=cknet(v,true,'unaffected '..i);ck(id==st.ids[i],'unaffected ID changed '..i) end end
   log('[EM087F STRESS] tick='..t..' unaffected=49 state='..(phase==3 and 'split' or 'repaired'))
  elseif phase==20 then g.rails[-11]=mk(st.s,H,-11,g.y,true) end
 end
 if t==440 then log('[EM087F STRESS PASS] six cut/repair cycles, 49 independent corridors intact');script.finish_test(true) end
end)
''')
 shutil.copy2(p/'localqa/mods/mod-list.json',m/'mod-list.json');cfg=w/'config.ini';cfg.write_text(f'[path]\nread-data={engine}/data\nwrite-data={w}\n')
 for run in range(2):
  out=p/f'profile-{tag}-{run}.log';cmd=[str(binary),'--config',str(cfg),'--mod-directory',str(m),'--test-scenario','em-watch-qa/localstress','--test-ticks','450']
  with out.open('w') as f:rc=subprocess.run(cmd,stdout=f,stderr=subprocess.STDOUT,timeout=180).returncode
  t=out.read_text();print(tag,run,rc,'PASS' if 'Test passed at tick' in t else 'NO PASS',flush=True)
  if rc or 'Test passed at tick' not in t:raise RuntimeError(out)
