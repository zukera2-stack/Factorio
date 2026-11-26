from pathlib import Path
import shutil,json,subprocess
p=Path(__file__).parent;eng=Path('/mnt/data/em087c/factorio');w=p/'fault';m=w/'mods';m.mkdir(parents=True,exist_ok=True)
q=m/'em-idle-fault-qa_0.0.1';shutil.copytree('/mnt/data/em087j/idle/mods/em-idle-fault-qa_0.0.1',q,dirs_exist_ok=True)
f=q/'scenarios/native/control.lua';s=f.read_text();s=s.replace("local C='idle-fault'","local C='idle-fault'\nlocal variant=script.test_arg or 'direct'\nlocal function parent_key(e)\n local sub=e.electric_network;local parent=sub and sub.parent_network\n if not (parent and parent.valid) then return nil end\n local id=sub.id;for _,n in pairs(parent.sub_networks) do if n.valid and n.id<id then id=n.id end end;return id\nend")
s=s.replace(" storage.qa=st;say('SETUP",''' st.fault_mast=st.masts[3]
 if variant=='cross' or variant=='cross-switch' then
  for x=-43,43,2 do make(s,'em-high-speed-straight-rail',x,-19,{direction=defines.direction.east}) end
  local a=make(s,'em-35kv-catenary-pole',-21.5,-17.5)
  local b=make(s,'em-35kv-catenary-pole',-1.5,-17.5)
  local c=make(s,'em-35kv-catenary-pole',18.5,-17.5)
  st.fault_mast=b;st.other_masts={a,b,c}
 end
 if variant=='switch' or variant=='cross-switch' then
  st.sw=make(s,'power-switch',10,24,{auto_connect=false,raise_built=false});st.sw.power_switch_state=false
 end
 storage.qa=st;say('SETUP''')
s=s.replace("  ck(connector(st.subs[2]).connect_to(connector(st.masts[3]),false,defines.wire_origin.player),'fault wire creation failed')",'''  if st.sw then
   local C=defines.wire_connector_id
   ck(connector(st.subs[2]).connect_to(st.sw.get_wire_connector(C.power_switch_left_copper,true),false,defines.wire_origin.player),'switch factory')
   ck(connector(st.fault_mast).connect_to(st.sw.get_wire_connector(C.power_switch_right_copper,true),false,defines.wire_origin.player),'switch corridor')
   st.sw.power_switch_state=true
  else
   ck(connector(st.subs[2]).connect_to(connector(st.fault_mast),false,defines.wire_origin.player),'fault wire creation failed')
  end''')
s=s.replace("  ck(st.subs[2].electric_network_id==st.masts[3].electric_network_id,'fault not physically shorted')",'''  ck(parent_key(st.subs[2])==parent_key(st.fault_mast),'fault not physically shorted')
  if st.sw then ck(st.subs[2].electric_network_id~=st.fault_mast.electric_network_id,'switch raw subnet unexpectedly merged') end
  if st.other_masts then ck(parent_key(st.fault_mast)~=parent_key(st.masts[3]),'cross corridor not independent') end
  say('variant='..variant..' parent_short=true raw_factory='..tostring(st.subs[2].electric_network_id)..' raw_fault='..tostring(st.fault_mast.electric_network_id))''')
s=s.replace('st.subs[2].electric_network_id==st.masts[3].electric_network_id','parent_key(st.subs[2])==parent_key(st.fault_mast)')
s=s.replace("st.subs[2].electric_network_id~=st.masts[3].electric_network_id,'isolation not repaired by mast audit'","parent_key(st.subs[2])~=parent_key(st.fault_mast),'isolation not repaired by mast audit'")
f.write_text(s)
shutil.copy2(p/'candidate/mods/ElectrifiedMainline_0.1.97.zip',m/'ElectrifiedMainline_0.1.97.zip');shutil.copy2('/mnt/data/em087j/idle/mods/mod-list.json',m/'mod-list.json');cfg=w/'config.ini';cfg.write_text(f'[path]\nread-data={eng}/data\nwrite-data={w}\n')
for tag in ['direct','cross','switch','cross-switch']:
 with (p/f'fault-{tag}.log').open('w') as out:
  rc=subprocess.run([str(eng/'bin/x64/factorio'),'--config',str(cfg),'--mod-directory',str(m),'--test-scenario','em-idle-fault-qa/native','--test-arg',tag,'--test-ticks','380'],stdout=out,stderr=subprocess.STDOUT,timeout=120).returncode
 t=(p/f'fault-{tag}.log').read_text();print(tag,rc,'PASS' if rc==0 and 'Test passed at tick' in t else 'FAIL',flush=True)
