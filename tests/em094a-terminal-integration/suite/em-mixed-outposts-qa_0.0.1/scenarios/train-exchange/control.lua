local mode=script.test_arg or 'pair'
local N=mode=='large100' and 50 or mode=='multi' and 3 or 1
local W=1000000/60
local function ck(x,m)if not x then error('[TRAIN EXCHANGE FAIL] '..mode..' '..m) end end
local function make(s,n,x,y,o)
 local p={name=n,position={x=x,y=y},force='player',raise_built=true};for k,v in pairs(o or {})do p[k]=v end
 local e=s.create_entity(p);ck(e and e.valid,'create '..n);return e
end
local function term(name,...)return remote.call('em094_terminal_QA_ONLY',name,...)end
local function key(e)
 local n=e.electric_network;local p=n and n.parent_network;ck(p and p.valid,'no parent '..e.name);local id=n.id;for _,a in pairs(p.sub_networks)do if a.valid and a.id<id then id=a.id end end;return id
end
local function seed(port)
 local e=port.surface.create_entity{name='em-25kv-bridge-output-058',position=port.position,force=port.force,raise_built=false};ck(e and e.valid,'seed EEI');e.electric_interface_mode=defines.electric_interface_mode.secondary_output;e.electric_buffer_size=2000000;e.power_usage=0;e.power_production=0;e.input_flow_limit=0;e.output_flow_limit=2*W;e.energy=2000000;return e
end
local function schedule(loco,name)
 local tr=loco.train;tr.schedule={current=1,records={{station=name,wait_conditions={{type='time',compare_type='and',ticks=2000}}}}};tr.manual_mode=false
end
script.on_init(function()
 local s=game.create_surface('train-exchange',{width=512,height=(N+1)*40+128});s.generate_with_lab_tiles=true;s.always_day=true
 local st={s=s,lines={}}
 for i=1,N+1 do local y=(i-1)*40-math.floor((N+1)/2)*40+1;for x=-160,160,64 do s.request_to_generate_chunks({x,y},1)end end;s.force_generate_chunk_requests()
 for i=1,N+1 do local y=(i-1)*40-math.floor((N+1)/2)*40+1;local l={y=y,name='LINE-'..i};st.lines[i]=l
  for x=-143,143,2 do make(s,'em-high-speed-straight-rail',x,y,{direction=defines.direction.east})end
  for x=-141.5,139,20 do local a=make(s,'em-35kv-catenary-pole',x,y+1.5);if x==-21.5 then l.mast=a.unit_number end end
  if i<=N then
   l.loco=make(s,'em-electric-locomotive',41,y,{direction=defines.direction.west})
   for _,dy in ipairs({-2,2,0})do for _,d in ipairs({defines.direction.west,defines.direction.east})do if not l.stop then local q=s.create_entity{name='train-stop',position={x=-120,y=y+dy},direction=d,force='player',raise_built=true};if q and q.valid and q.connected_rail then q.backer_name=l.name;l.stop=q elseif q and q.valid then q.destroy()end end end end
   ck(l.stop,'station '..i)
  end
 end
 storage.st=st
end)
local function snapshot(st,t,final)
 local h=0;local lab=game.surfaces['em094-terminal-lab'];for _,e in ipairs(lab.find_entities_filtered{type='electric-energy-interface'})do h=h+e.energy end
 local p=remote.call('em072_native_qa_071','snapshot').paid_J
 local z=remote.call('em089_onboard_storage','snapshot');local q=remote.call('em091_brake_recovery','snapshot');local terminals=term('snapshot')
 local sum=h+p+z.stored_J+z.discharged_J+z.lost_J-q.recovered_J-q.qa_pending_J
 ck(math.abs(sum-N*2000000)<math.max(1,N*.1),'closed J '..sum);ck(math.abs(q.estimated_J-q.recovered_J-q.rejected_J-q.qa_pending_J)<.05,'offer accounting');ck(terminals.rows[st.lines[N+1].mast].sink_J==0,'other corridor leak');ck(q.qa_uncertain_J==0,'uncertain debit');ck(q.qa_grid_J+z.regen_J<=q.recovered_J+.05,'double claim')
 if t%30==0 or final then
  local rx,moved=0,0
  for i=1,N do local l=st.lines[i];if l.receiver then local bus=remote.call('em088_train_energy','snapshot',l.receiver.unit_number);local j=bus.owners[1] and bus.owners[1].loco_J or 0;rx=rx+j;if l.receiver.position.x<l.receiver_start-.01 then moved=moved+1 end;if final then ck(j>1000,'receiver debit '..i);ck(l.receiver.position.x<l.receiver_start-.01,'receiver did not move '..i)end end end
  log(string.format('[TRAIN EXCHANGE] t=%d lines=%d paid=%.6f receiver_paid=%.6f moved=%d hidden=%.6f recovered=%.6f grid=%.6f fallback=%.6f pending=%.6f battery=%.6f total=%.6f',t,N,p,rx,moved,h,q.recovered_J,q.qa_grid_J,q.qa_fallback_J,q.qa_pending_J,z.stored_J,sum))
  if final then ck(q.qa_pending_J<.05 and q.qa_grid_J>1000*N and moved==N,'final grant/motion');log('[TRAIN EXCHANGE PASS] '..mode..' grid='..q.qa_grid_J..' receiver='..rx..' moved='..moved)end
 end
end
script.on_event(defines.events.on_tick,function(ev)
 local t=ev.tick;local st=storage.st
 if t==120 then
  for i,l in ipairs(st.lines)do ck(term('ensure',l.mast),'terminal '..i)end
  local q=term('snapshot');local keys={}
  for i,l in ipairs(st.lines)do local r=q.rows[l.mast];ck(r and r.key and not keys[r.key],'isolated terminal '..i);keys[r.key]=true;if i<=N then l.source=seed(game.get_entity_by_unit_number(r.port))end end
 elseif t==200 then
  for i=1,N do local l=st.lines[i];ck(l.source.energy<.05,'seed not exhausted '..i);schedule(l.loco,l.name)end
 elseif t==230 then
  for i=1,N do local l=st.lines[i];l.receiver=make(st.s,'em-electric-locomotive',121,l.y,{direction=defines.direction.west});l.receiver_start=l.receiver.position.x;schedule(l.receiver,l.name)end
 elseif t==235 then
  for i=1,N do local l=st.lines[i];ck(math.abs(l.loco.train.speed)>.1,'sender not moving '..i);l.loco.train.manual_mode=true end
 end
 if t>=120 then snapshot(st,t,t==540);if t==540 then script.finish_test(true)end end
end)
