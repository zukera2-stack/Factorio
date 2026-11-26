local W=1000000/60
local function ck(x,m)if not x then error('[SAME TERMINAL FAIL] '..m) end end
local function make(s,n,x,y,o)
 local p={name=n,position={x=x,y=y},force='player',raise_built=true};for k,v in pairs(o or {})do p[k]=v end
 local e=s.create_entity(p);ck(e and e.valid,'create '..n);return e
end
local function term(name,...)return remote.call('em094_terminal_QA_ONLY',name,...)end
local function schedule(loco)
 local tr=loco.train;tr.schedule={current=1,records={{station='LINE',wait_conditions={{type='time',compare_type='and',ticks=2000}}}}};tr.manual_mode=false
end
script.on_init(function()
 local s=game.create_surface('same-terminal',{width=1024,height=256});s.generate_with_lab_tiles=true;s.always_day=true
 for x=-160,352,64 do s.request_to_generate_chunks({x,0},2)end;s.force_generate_chunk_requests()
 local st={s=s,senders={},receivers={},starts={}}
 for x=-143,343,2 do make(s,'em-high-speed-straight-rail',x,1,{direction=defines.direction.east})end
 for x=-141.5,339,20 do local a=make(s,'em-35kv-catenary-pole',x,2.5);if x==-21.5 then st.mast=a.unit_number end end
 for i,x in ipairs({41,201})do st.senders[i]=make(s,'em-electric-locomotive',x,1,{direction=defines.direction.west})end
 for _,dy in ipairs({-2,2,0})do for _,d in ipairs({defines.direction.west,defines.direction.east})do if not st.stop then local q=s.create_entity{name='train-stop',position={x=-120,y=1+dy},direction=d,force='player',raise_built=true};if q and q.valid and q.connected_rail then q.backer_name='LINE';st.stop=q elseif q and q.valid then q.destroy()end end end end
 ck(st.stop,'station');storage.st=st
end)
script.on_event(defines.events.on_tick,function(ev)
 local t=ev.tick;local st=storage.st
 if t==120 then
  ck(term('ensure',st.mast),'terminal');local r=term('snapshot').rows[st.mast];local p=game.get_entity_by_unit_number(r.port)
  local e=p.surface.create_entity{name='em-25kv-bridge-output-058',position=p.position,force=p.force,raise_built=false};ck(e and e.valid,'seed');e.electric_interface_mode=defines.electric_interface_mode.secondary_output;e.electric_buffer_size=4000000;e.power_usage=0;e.power_production=0;e.input_flow_limit=0;e.output_flow_limit=4*W;e.energy=4000000;st.source=e
 elseif t==200 then ck(st.source.energy<.05,'seed not exhausted');for _,l in ipairs(st.senders)do schedule(l)end
 elseif t==230 then for i,x in ipairs({121,281})do local e=make(st.s,'em-electric-locomotive',x,1,{direction=defines.direction.west});st.receivers[i]=e;st.starts[i]=e.position.x;schedule(e)end
 elseif t==235 then for _,l in ipairs(st.senders)do ck(math.abs(l.train.speed)>.1,'sender not moving');l.train.manual_mode=true end end
 if t>=120 then
  local h=0;for _,e in ipairs(game.surfaces['em094-terminal-lab'].find_entities_filtered{type='electric-energy-interface'})do h=h+e.energy end
  local p=remote.call('em072_native_qa_071','snapshot').paid_J;local z=remote.call('em089_onboard_storage','snapshot');local q=remote.call('em091_brake_recovery','snapshot');local sum=h+p+z.stored_J+z.discharged_J+z.lost_J-q.recovered_J-q.qa_pending_J
  ck(math.abs(sum-4000000)<1,'closed J '..sum);ck(math.abs(q.estimated_J-q.recovered_J-q.rejected_J-q.qa_pending_J)<.05,'offer accounting');ck(q.qa_uncertain_J==0,'uncertain debit')
  if t%30==0 or t==540 then
   local rx=0;local count=0;for i,e in ipairs(st.receivers)do local b=remote.call('em088_train_energy','snapshot',e.unit_number);local j=b.owners[1] and b.owners[1].loco_J or 0;rx=rx+j;if e.position.x<st.starts[i]-.01 then count=count+1 end;if t==540 then ck(j>1000,'receiver debit '..i)end end
   log(string.format('[SAME TERMINAL] t=%d paid=%.6f receiver=%.6f moved=%d grid=%.6f pending=%.6f total=%.6f',t,p,rx,count,q.qa_grid_J,q.qa_pending_J,sum))
   if t==540 then ck(count==2 and q.qa_grid_J>1000 and q.qa_pending_J<.05,'final');log('[SAME TERMINAL PASS] grid='..q.qa_grid_J..' receiver='..rx);script.finish_test(true)end
  end
 end
end)
