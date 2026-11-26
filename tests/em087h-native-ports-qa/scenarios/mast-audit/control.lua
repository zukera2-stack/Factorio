local S=defines.wire_origin.script
local P=defines.wire_origin.player
local C=defines.wire_connector_id.pole_copper
local function ck(ok,m) if not ok then error('[EM087I MAST FAIL] '..m) end end
local function conn(e) local c=e.get_wire_connector(C,true);ck(c and c.valid,'connector absent');return c end
local function mk(s,n,x,y,raised,dir)
 local e=s.create_entity{name=n,position={x,y},force='player',direction=dir or defines.direction.east,raise_built=raised,auto_connect=false};ck(e and e.valid,'create '..n);return e
end
local function good(st)
 local a,b=conn(st.m),conn(st.a)
 ck(a.real_connection_count==1 and a.is_connected_to(b,S),'expected sole script link')
 ck(st.m.electric_network_id==st.a.electric_network_id,'native network mismatch')
 ck(not a.is_connected_to(conn(st.f),S) and not a.is_connected_to(conn(st.f),P),'foreign connection retained')
end
script.on_init(function()
 local s=game.create_surface('em087i-mast',{width=256,height=128});s.generate_with_lab_tiles=true;s.request_to_generate_chunks({0,0},2);s.force_generate_chunk_requests()
 for x=-43,43,2 do mk(s,'em-high-speed-straight-rail',x,1,true) end
 local m=mk(s,'em-35kv-catenary-pole',-21.5,2.5,true)
 local n=mk(s,'em-35kv-catenary-pole',-1.5,2.5,true)
 local f=mk(s,'small-electric-pole',-21.5,8.5,false,defines.direction.north)
 storage.qa={s=s,m=m,n=n,f=f}
end)
script.on_event(defines.events.on_tick,function(ev)
 local st=storage.qa;local t=ev.tick
 if t==125 then
  local a=st.s.find_entities_filtered{name='em-25kv-technical-anchor-046',position=st.m.position,radius=.1};ck(#a==1,'missing anchor');st.a=a[1];good(st)
  ck(conn(st.m).connect_to(conn(st.f),false,P),'foreign wire refused');log('[EM087I MAST] injected player foreign link')
 elseif t==126 then ck(conn(st.m).real_connection_count==2,'foreign link not actually present')
 elseif t==185 then good(st);log('[EM087I MAST] extra wire removed');ck(conn(st.m).disconnect_from(conn(st.a),S),'cut refused')
 elseif t==186 then ck(conn(st.m).real_connection_count==0,'cut did not occur')
 elseif t==245 then good(st);log('[EM087I MAST] missing link restored');ck(conn(st.m).disconnect_from(conn(st.a),S),'cut refused');ck(conn(st.m).connect_to(conn(st.a),false,P),'wrong origin refused')
 elseif t==246 then ck(conn(st.m).is_connected_to(conn(st.a),P) and not conn(st.m).is_connected_to(conn(st.a),S),'wrong origin not actually present')
 elseif t==305 then good(st);ck(not conn(st.m).is_connected_to(conn(st.a),P),'wrong origin retained');log('[EM087I MAST PASS] foreign, missing and wrong-origin connections recovered');script.finish_test(true) end
end)
