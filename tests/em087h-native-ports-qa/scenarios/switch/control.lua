local C=defines.wire_connector_id
local S=defines.wire_origin.script
local function ck(v,m) if not v then error('[EM087H SWITCH FAIL] '..m) end end
local function network_key(e)
 local sub=e.electric_network
 ck(sub and sub.valid,'subnetwork absent')
 local parent=sub.parent_network
 ck(parent and parent.valid,'parent absent')
 local id=sub.id
 for _,n in pairs(parent.sub_networks) do if n.valid and n.id<id then id=n.id end end
 return id,#parent.sub_networks
end
local function check(st,on)
 local a,b=st.a.electric_network_id,st.b.electric_network_id
 local x,n=network_key(st.a);local y,m=network_key(st.b)
 log(string.format('[EM087H SWITCH] tick=%d closed=%s raw=%d,%d parent_keys=%d,%d subcounts=%d,%d',game.tick,tostring(on),a,b,x,y,n,m))
 ck(a~=b,'raw IDs unexpectedly merged');ck((x==y)==on,'parent grouping wrong');ck(n==(on and 2 or 1) and m==(on and 2 or 1),'subnetwork count')
end
script.on_init(function()
 local s=game.create_surface('em087h-switch',{width=128,height=128});s.generate_with_lab_tiles=true;s.request_to_generate_chunks({0,0},2);s.force_generate_chunk_requests()
 local function mk(name,x) local e=s.create_entity{name=name,position={x,0},force='player',auto_connect=false,raise_built=false};ck(e and e.valid,'create '..name);return e end
 local a,b,sw=mk('small-electric-pole',-6),mk('small-electric-pole',6),mk('power-switch',0)
 sw.power_switch_state=false
 ck(a.get_wire_connector(C.pole_copper,true).connect_to(sw.get_wire_connector(C.power_switch_left_copper,true),false,S),'left')
 ck(b.get_wire_connector(C.pole_copper,true).connect_to(sw.get_wire_connector(C.power_switch_right_copper,true),false,S),'right')
 storage.qa={a=a,b=b,sw=sw}
end)
script.on_event(defines.events.on_tick,function(e)
 local st=storage.qa
 if e.tick==10 then check(st,false);st.sw.power_switch_state=true
 elseif e.tick==20 then check(st,true);st.sw.power_switch_state=false
 elseif e.tick==30 then check(st,false);log('[EM087H SWITCH PASS] native parent network is not raw subnetwork ID');script.finish_test(true) end
end)
