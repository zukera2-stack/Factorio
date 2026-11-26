local mode=script.test_arg or 'join'
local J=100000
local function ck(x,m)if not x then error('[TOPOLOGY FAIL] '..mode..' '..m) end end
local function call(n,...)return remote.call('em094_terminal_QA_ONLY',n,...)end
local function make(s,n,x,y,o)
 local p={name=n,position={x=x,y=y},force='player',raise_built=true};for k,v in pairs(o or {})do p[k]=v end
 local e=s.create_entity(p);ck(e and e.valid,'create '..n);return e
end
local function middle(st) return make(st.s,'em-35kv-catenary-pole',-11.5,2.5) end
script.on_init(function()
 local s=game.create_surface('topology-qa',{width=256,height=128});s.generate_with_lab_tiles=true;s.always_day=true
 s.request_to_generate_chunks({0,1},2);s.force_generate_chunk_requests()
 for x=-63,63,2 do make(s,'em-high-speed-straight-rail',x,1,{direction=defines.direction.east})end
 local st={s=s,a=make(s,'em-35kv-catenary-pole',-41.5,2.5),b=make(s,'em-35kv-catenary-pole',18.5,2.5)}
 if mode=='split' or mode=='same' then st.mid=middle(st)end
 storage.st=st
end)
local function snapshot(st,t)
 local q=call('snapshot');local a,b=q.rows[st.a.unit_number],q.rows[st.b.unit_number]
 ck(math.abs(q.offered-q.accepted-q.remainder-q.uncertain-q.pending)<.05,'offer accounting')
 ck(math.abs(q.sink-q.accepted-q.uncertain)<.05 or q.pending>0,'native debit/receiver mismatch')
 log(string.format('[TOPOLOGY] mode=%s t=%d keyA=%s keyB=%s valid=%d accepted=%.3f remainder=%.3f uncertain=%.3f pending=%.3f source=%.3f sink=%.3f',mode,t,tostring(a.key),tostring(b.key),q.valid,q.accepted,q.remainder,q.uncertain,q.pending,q.source,q.sink))
 return q,a,b
end
script.on_event(defines.events.on_tick,function(ev)
 local t=ev.tick;local st=storage.st
 if t==120 then
  ck(call('ensure',st.a.unit_number),'source terminal');ck(call('ensure',st.b.unit_number),'sink terminal')
  local q,a,b=snapshot(st,t);ck(q.valid==2,'initial terminal auth');ck((a.key==b.key)==(mode=='split' or mode=='same'),'initial topology')
  ck(call('demand',st.b.unit_number,J),'demand')
 elseif t==121 then
  ck(call('offer',st.a.unit_number,J),'offer')
  if mode=='join' or mode=='normal-join' then st.mid=middle(st);if mode=='join' then call('sync')end
  elseif mode=='split' then st.mid.destroy{raise_destroy=true};call('sync')
  elseif mode=='foreign' then
   local q,a,b=snapshot(st,t)
   local pa=game.get_entity_by_unit_number(a.port);local pb=game.get_entity_by_unit_number(b.port)
   ck(pa.get_wire_connector(defines.wire_connector_id.pole_copper,true).connect_to(pb.get_wire_connector(defines.wire_connector_id.pole_copper,true),false,defines.wire_origin.script),'foreign link')
  end
  local q,a,b=snapshot(st,t)
  if mode=='join' then ck(a.key and a.key==b.key,'legal immediate join')end
  if mode=='split' then ck(a.key and b.key and a.key~=b.key,'legal split')end
 elseif t==122 then
  call('settle');local q,a,b=snapshot(st,t)
  local want=(mode=='join' or mode=='same') and J or 0
  ck(math.abs(q.accepted-want)<.05,'expected accepted '..want)
  ck(q.pending==0 and q.source==0,'pending remains')
  if mode=='foreign' then ck(q.uncertain==J and q.sink==J,'foreign must be distinguished')
  else ck(q.uncertain==0 and q.remainder==J-want and q.sink==want,'balance result')end
  if mode=='normal-join' then ck(a.key and a.key==b.key,'normal event joins by next callback')end
 elseif t==123 and mode=='normal-join' then
  ck(call('offer',st.a.unit_number,J),'next offer after join')
 elseif t==124 and mode=='normal-join' then
  call('settle');local q=snapshot(st,t);ck(q.accepted==J and q.remainder==J and q.uncertain==0,'next offer delivered')
 elseif t==130 then log('[TOPOLOGY PASS] '..mode);script.finish_test(true)
 end
end)
