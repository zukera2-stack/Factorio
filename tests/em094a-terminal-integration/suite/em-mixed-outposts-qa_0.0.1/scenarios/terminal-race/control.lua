local mode='isolation'
local N=mode=='large100' and 100 or 2
local J=100000
local function ck(x,m)if not x then error('[TERMINAL FAIL] '..mode..' '..m) end end
local function call(name,...)return remote.call('em094_terminal_QA_ONLY',name,...)end
local function make(s,n,x,y,o)
 local p={name=n,position={x=x,y=y},force='player',raise_built=true};for k,v in pairs(o or {})do p[k]=v end
 local e=s.create_entity(p);ck(e and e.valid,'create '..n);return e
end
script.on_init(function()
 local s=game.create_surface('terminal-qa',{width=256,height=N*32+128});s.generate_with_lab_tiles=true;s.always_day=true
 local st={s=s,lines={}}
 for i=1,N do local y=(i-1)*32-math.floor(N/2)*32+1;s.request_to_generate_chunks({0,y},2) end
 s.force_generate_chunk_requests()
 for i=1,N do local y=(i-1)*32-math.floor(N/2)*32+1;local l={};st.lines[i]=l
  for x=-43,43,2 do make(s,'em-high-speed-straight-rail',x,y,{direction=defines.direction.east})end
  for x=-41.5,38.5,20 do local m=make(s,'em-35kv-catenary-pole',x,y+1.5);l[#l+1]=m.unit_number end
 end
 storage.st=st
end)
local function snapshot(t)
 local q=call('snapshot');ck(math.abs(q.offered-q.accepted-q.remainder-q.uncertain-q.pending)<.05,'offer accounting')
 ck(math.abs(q.sink-q.accepted-q.uncertain)<.05 or q.pending>0,'native debit/receiver mismatch')
 log(string.format('[TERMINAL] t=%d mode=%s ports=%d valid=%d offered=%.3f accepted=%.3f remainder=%.3f uncertain=%.3f pending=%.3f source=%.3f sink=%.3f',t,mode,q.ports,q.valid,q.offered,q.accepted,q.remainder,q.uncertain,q.pending,q.source,q.sink))
 return q
end
script.on_event(defines.events.on_tick,function(ev)
 local t=ev.tick;local st=storage.st
 if t==120 then
  for i,l in ipairs(st.lines)do
   ck(call('ensure',l[1]),'source port '..i);ck(call('ensure',l[5]),'receiver port '..i)
   if mode=='multi' then ck(call('ensure',l[3]),'second source port '..i)end
  end
  local q=snapshot(t);local keys={}
  for i,l in ipairs(st.lines)do local a,b=q.rows[l[1]],q.rows[l[5]];ck(a.key and a.key==b.key,'same line '..i);ck(not keys[a.key],'isolated lines '..i);keys[a.key]=true
   if mode~='no-load' and (mode~='isolation' or i==2)then ck(call('demand',l[5],2*J),'native demand')end
  end
 elseif t==121 then
  for i,l in ipairs(st.lines)do
   if mode~='isolation' or i==1 then ck(call('offer',l[1],J),'offer '..i);ck(not call('offer',l[1],J),'double offer allowed')end
   if mode=='multi' then ck(call('offer',l[3],J),'second offer '..i)end
  end
  if mode=='cut' then
   local q=call('snapshot');local row=q.rows[st.lines[1][1]];local p=game.get_entity_by_unit_number(row.port);local a=game.get_entity_by_unit_number(row.anchor)
   local pc=p.get_wire_connector(defines.wire_connector_id.pole_copper,true);local ac=a.get_wire_connector(defines.wire_connector_id.pole_copper,true)
   ck(pc.disconnect_from(ac,defines.wire_origin.script),'disconnect pending source');ck(pc.real_connection_count==0,'port not disconnected')
  end
  local q=call('snapshot');local row=q.rows[st.lines[1][1]];local other=q.rows[st.lines[2][5]]
  local a=game.get_entity_by_unit_number(row.port);local b=game.get_entity_by_unit_number(other.port)
  ck(a.get_wire_connector(defines.wire_connector_id.pole_copper,true).connect_to(b.get_wire_connector(defines.wire_connector_id.pole_copper,true),false,defines.wire_origin.script),'late short refused')
  snapshot(t)
 elseif t==122 then call('settle');local q=snapshot(t)
  ck(q.accepted==0,'incorrect accepted credit after late short')
  ck(q.uncertain>0 and q.sink>0,'expected native cross-network delivery not reproduced')
  log('[TERMINAL RACE REPRODUCED] uncertain='..q.uncertain..' physical_wrong_sink='..q.sink)
  script.finish_test(true)
 end
end)
