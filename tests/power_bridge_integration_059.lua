-- Mock runtime lifecycle. Does NOT emulate native Factorio electrical solver.
package.path="./ElectrifiedMainline/?.lua;"..package.path
local M=require("scripts.power_bridge_058")
local tech=require("scripts.technical_network_046")
local mast=require("scripts.mast_network_059")
local PORT,INPUT,OUTPUT="em-25kv-bridge-port-058","em-25kv-bridge-input-058","em-25kv-bridge-output-058"
storage={};log=function() end
defines={wire_origin={script=2,player=1},wire_connector_id={pole_copper=5},electric_interface_mode={secondary_input=1,secondary_output=2}}
local entities,serial={},1000
local networks={}
local function net(id)
 if not id then return nil end
 if not networks[id] then local sub={id=id,valid=true};sub.parent_network={valid=true,sub_networks={sub},flow_last_tick={primary_output=0,secondary_output=0,solar_output=0,primary_demand=0,secondary_demand=0,tertiary_output=0,tertiary_demand=0,accumulator_energy=0,accumulator_capacity=0}};networks[id]=sub end
 return networks[id]
end
local force={name="player",set_surface_hidden=function()end}
local surface={index=1,name="nauvis",valid=true}
local lab
local function entity(name,s,pos,id,netid)
 local e={name=name,valid=true,surface=s,force=force,position=pos,unit_number=id,electric_network_id=netid,energy=0,electric_buffer_size=333334}
 e.electric_network=net(netid)
 local c={valid=true,owner=e,real_connections={}}
 local function remove(a,b,origin)for i=#a.real_connections,1,-1 do if a.real_connections[i].target==b and a.real_connections[i].origin==origin then table.remove(a.real_connections,i) end end end
 function c.is_connected_to(other,origin)for _,l in pairs(c.real_connections)do if l.target==other and l.origin==origin then return true end end return false end
 function c.connect_to(other,reach,origin)
   assert(reach==false and origin==2)
   c.real_connections[#c.real_connections+1]={target=other,origin=origin}
   other.real_connections[#other.real_connections+1]={target=c,origin=origin}
   e.electric_network_id=other.owner.electric_network_id
   e.electric_network=other.owner.electric_network
   return true
 end
 function c.disconnect_from(other,origin)remove(c,other,origin);remove(other,c,origin);return true end
 function e.get_wire_connector()return c end
 function e.destroy()while #c.real_connections>0 do local l=c.real_connections[1];c.disconnect_from(l.target,l.origin)end;e.valid=false;c.valid=false;entities[id]=nil end
 e.c=c;entities[id]=e;return e
end
game={tick=0,surfaces={[1]=surface},forces={player=force},get_entity_by_unit_number=function(id)return entities[id]end}
function game.get_surface(name)return lab and lab.name==name and lab or nil end
function game.create_surface(name)
 lab={index=2,name=name,valid=true,request_to_generate_chunks=function()end,force_generate_chunk_requests=function()end}
 game.surfaces[2]=lab
 function lab.create_entity(arg)
   serial=serial+1
   local net
   if arg.name==INPUT or arg.name==OUTPUT then
     for _,e in pairs(entities)do if e.name==PORT and e.surface==lab and e.position.x==arg.position.x and e.position.y==arg.position.y then net=e.electric_network_id end end
   else assert(arg.name==PORT and arg.auto_connect==false) end
   return entity(arg.name,lab,arg.position,serial,net)
 end
 function lab.find_entities_filtered(f)local out={} for _,e in pairs(entities)do if e.surface==lab then out[#out+1]=e end end return out end
 return lab
end
local sub1=entity(M.SUB,surface,{x=0,y=0},1,10)
local sub2=entity(M.SUB,surface,{x=10,y=0},2,20)
local anchor1=entity("em-25kv-technical-anchor-046",surface,{x=1,y=0},101,30)
local anchor2=entity("em-25kv-technical-anchor-046",surface,{x=9,y=0},102,30)
local mast1=entity("em-35kv-catenary-pole",surface,{x=1,y=0},11,110)
local mast2=entity("em-35kv-catenary-pole-north",surface,{x=9,y=0},12,120)
local t=tech.ensure_storage();t.helpers={[11]=101,[12]=102}
local graph={nodes={[1]={name=M.SUB},[2]={name=M.SUB},[11]={name=mast1.name},[12]={name=mast2.name}},edges={a={kind="feeder",a=1,b=11},b={kind="feeder",a=2,b=12}}}
mast.sync(graph)
assert(t.mast_connected[11] and t.mast_connected[12] and mast1.electric_network_id==30 and mast2.electric_network_id==30)
assert(mast1.c.is_connected_to(anchor1.c,2) and mast2.c.is_connected_to(anchor2.c,2))
local foreign=entity("small-electric-pole",surface,{x=1,y=1},333,50)
foreign.c.connect_to(mast1.c,false,2)
mast.sync(graph)
assert(not foreign.c.is_connected_to(mast1.c,2) and t.stats.mast_links_removed==1)
local function flow(id,g,l,b,c,energy,capacity)
 local f=net(id).parent_network.flow_last_tick
 f.primary_output=g or 0;f.secondary_output=0;f.solar_output=0
 f.primary_demand=l or 0;f.secondary_demand=0
 f.tertiary_output=b or 0;f.tertiary_demand=c or 0
 f.accumulator_energy=energy or 0;f.accumulator_capacity=capacity or 0
end
local L=M.LIMIT
flow(10,L,0);flow(20,0,0,0,L,0,10*L)
M.rebuild(graph)
M.on_tick(1,graph);M.on_tick(2,graph)
local s=storage.em.bridge058;local a,b=s.stations[1],s.stations[2]
assert(a.mode=="auto" and b.mode=="auto")
assert(a.direction=="import" and b.direction=="export")
assert(a.status=="active" and b.status=="active")
assert(a.input.electric_network_id==10 and a.output.electric_network_id==30 and b.output.electric_network_id==20)
local olda,oldb=a.output,b.output
-- Simulate no native generation, load A, charged B. Reset previous mocked sample
-- because no actual engine step is simulated in this fixture.
flow(10,0,L);flow(20,0,0,L,0,10*L,10*L)
s.sample_tick=nil
M.on_tick(3,graph)
assert(a.direction=="export" and b.direction=="import")
assert(olda.valid and oldb.valid,"charged native EEIs must be re-used across reversal")
assert(a.input==olda and b.input==oldb,"reversal must swap the old EEI roles, not destroy and recreate")
assert(a.input.electric_network_id==30 and a.output.electric_network_id==10)
assert(b.input.electric_network_id==20 and b.output.electric_network_id==30)
assert(a.output.energy==0 and b.output.energy==0)
-- Native input actually received real energy; the bridge only credits that amount.
b.input.energy=100000;s.sample_tick=nil
M.on_tick(4,graph)
assert(b.input.energy==0 and b.output.energy==100000)
-- No demand, no generation: source A idles. On B, the prior 100kJ relay
-- output remains connected until native power usage empties it (063 behavior).
flow(10,0,0,0,L,0,10*L);s.sample_tick=nil
M.on_tick(5,graph)
assert(a.status=="auto-idle" and not a.output)
assert(b.status=="draining-buffer" and b.output and b.output.valid and b.output.energy==100000)
assert(b.input.input_flow_limit==0,"idle relay must stop requesting new input power")
-- The mock has no native EEI energy solver: simulate the next engine tick
-- that discharged the remaining 100kJ, then verify cleanup.
b.output.energy=0;s.sample_tick=nil
M.on_tick(6,graph)
assert(b.status=="auto-idle" and not b.output)
-- Rejected mast link blocks automatic transfer.
t.mast_connected[11]=nil;flow(10,L,0);flow(20,0,L);s.sample_tick=nil
M.on_tick(7,graph)
assert(a.status=="auto-network-or-mast-unverified")
print("059 runtime mock PASS: visible own-anchor link, foreign-wire audit, auto charge, reversed discharge, actual joules, idle and fail-closed")
