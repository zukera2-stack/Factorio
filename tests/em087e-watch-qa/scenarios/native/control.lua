local H='em-high-speed-straight-rail';local M='em-35kv-catenary-pole';local A='em-25kv-technical-anchor-046'
local function ck(v,m) if not v then error('[EM087E CORRIDOR FAIL] '..m) end end
local function mk(s,name,x,y,raised,dir)
 local r=s.create_entity{name=name,position={x,y},force='player',direction=dir or defines.direction.east,auto_connect=false,raise_built=raised}
 ck(r and r.valid,'create '..name..' at '..x..','..y);return r
end
local function conn(e) return e.get_wire_connector(defines.wire_connector_id.pole_copper,true) end
local O=defines.wire_origin.script
local function anchor(s,m)
 local a=s.find_entities_filtered{name=A,position=m.position,radius=0.1}
 ck(#a==1,'missing anchor');return a[1]
end
local function ids(st,same,label)
 local a,b=st.masts[1].electric_network_id,st.masts[2].electric_network_id
 ck(a and b and ((a==b)==same),label..' actual electric networks '..tostring(a)..' '..tostring(b))
 log('[EM087E CORRIDOR] tick='..game.tick..' '..label..' native='..a..'/'..b)
end
script.on_init(function()
 local s=game.create_surface('em087c-corridor',{width=256,height=128});s.generate_with_lab_tiles=true;s.request_to_generate_chunks({0,0},2);s.force_generate_chunk_requests()
 local st={s=s,rails={},masts={}}
 for x=-43,43,2 do st.rails[x]=mk(s,H,x,1,true) end
 for _,x in ipairs({-21.5,-1.5,18.5}) do st.masts[#st.masts+1]=mk(s,M,x,2.5,true) end
 storage.qa=st
end)
script.on_event(defines.events.on_tick,function(e)
 local st=storage.qa;local t=e.tick
 if t==120 then
  ids(st,true,'initial connected');st.a=anchor(st.s,st.masts[1]);st.b=anchor(st.s,st.masts[2]);ck(conn(st.a).is_connected_to(conn(st.b),O),'no selected native copper');ck(conn(st.a).disconnect_from(conn(st.b),O),'wire cut refused')
 elseif t==121 then ids(st,false,'native copper cut without Lua rebuild');ck(conn(st.a).connect_to(conn(st.b),false,O),'native wire reconnect refused')
 elseif t==122 then ids(st,true,'native copper restored without Lua rebuild')
 elseif t==130 then st.rails[-11].destroy{raise_destroy=true}
 elseif t==134 then ids(st,false,'raised rail cut separated real copper');st.rails[-11]=mk(st.s,H,-11,1,true)
 elseif t==138 then ids(st,true,'raised rail restore rejoined native network')
 elseif t==190 then game.reload_script()
 elseif t==200 then ck(st.rails[-11].destroy{raise_destroy=false},'silent cut refused')
 elseif t==203 then ids(st,false,'silent rail cut caught BEFORE periodic audit');st.rails[-11]=mk(st.s,H,-11,1,false)
 elseif t==601 then ids(st,true,'silent middle rail creation caught by full audit')
 elseif t==610 then ids(st,true,'restored path stable');st.foreign=mk(st.s,'small-electric-pole',-21.5,8.5,false,defines.direction.north);ck(conn(st.a).connect_to(conn(st.foreign),false,defines.wire_origin.player),'foreign link refused by engine')
 elseif t==661 then ck(not conn(st.a).is_connected_to(conn(st.foreign),defines.wire_origin.player),'foreign connection retained after audit');ids(st,true,'foreign wire rejected, lawful native network kept');log('[EM087E CORRIDOR PASS]');script.finish_test(true) end
end)
