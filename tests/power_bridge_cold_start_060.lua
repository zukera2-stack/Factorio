-- Mock runtime lifecycle. Does NOT emulate native Factorio electrical solver.
package.path="./ElectrifiedMainline/?.lua;"..package.path
local M=require("scripts.power_bridge_058")
local tech=require("scripts.technical_network_046")
local mast=require("scripts.mast_network_059")
local PORT,INPUT,OUTPUT="em-25kv-bridge-port-058","em-25kv-bridge-input-058","em-25kv-bridge-output-058"
storage={};log=function() end
defines={wire_origin={script=2,player=1},wire_connector_id={pole_copper=5},electric_interface_mode={solar_output=1,primary_output=2,secondary_output=3,tertiary_output=4,primary_input=5,secondary_input=6,tertiary_input=7,tertiary_input_output=8,accumulator=9}}
local entities,serial={},1000
local networks={}
local function net(id)
 if not id then return nil end
 if not networks[id] then local sub={id=id,valid=true};sub.parent_network={valid=true,sub_networks={sub},flow_last_tick={primary_output=0,secondary_output=0,solar_output=0,primary_demand=0,secondary_demand=0,tertiary_output=0,tertiary_demand=0,accumulator_energy=0,accumulator_capacity=0}};networks[id]=sub end
 return networks[id]
end
local force={name="player",set_surface_hidden=function()end}
local surface={index=1,name="nauvis",valid=true}
local physical_eei,physical_acc={},{}
function surface.find_entities_filtered(arg) if arg.name then return physical_eei else local out={} for _,e in ipairs(physical_acc)do out[#out+1]=e end return out end end
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
local source=entity("electric-energy-interface",surface,{x=0,y=2},200,10)
local sink=entity("electric-energy-interface",surface,{x=10,y=2},201,20)
for _,e in ipairs({source,sink}) do e.type="electric-energy-interface";e.active=true;e.electric_buffer_size=10*L;e.input_flow_limit=L;e.output_flow_limit=L end
source.electric_interface_mode=2;source.power_production=L;source.power_usage=0
sink.electric_interface_mode=6;sink.power_usage=L;sink.power_production=0
physical_eei={source,sink}
M.rebuild(graph)
-- All native last-tick fields zero. Model real engine fill and consumption explicitly.
M.on_tick(1,graph);M.on_tick(2,graph)
local s=storage.em.bridge058;local a,b=s.stations[1],s.stations[2]
assert(a.status=="active" and b.status=="active" and a.direction=="import" and b.direction=="export")
assert(a.input.input_flow_limit==L and a.output.output_flow_limit==L)
local delivered=0
for tick=3,120 do
 a.input.energy=L
 b.input.energy=a.output.energy
 a.output.energy=0
 delivered=delivered+b.output.energy
 b.output.energy=0
 M.on_tick(tick,graph)
 assert(a.status=="active" and b.status=="active")
 assert(a.input.energy==0 and a.output.energy<=L and b.output.energy<=L)
end
assert(delivered>110*L and delivered<=118*L)
source.electric_interface_mode=6;source.power_usage=L;source.power_production=0
local battery=entity("accumulator",surface,{x=10,y=4},202,20)
battery.type="accumulator";battery.energy=10*L;battery.electric_buffer_size=10*L
local small=20000
battery.get_electric_input_flow_limit=function()return small end;battery.get_electric_output_flow_limit=function()return small end
physical_acc={battery};sink.active=false
M.on_tick(121,graph)
assert(a.direction=="export" and b.direction=="import")
assert(a.input.electric_buffer_size==small and b.input.electric_buffer_size==small)
-- Measured in real 2.1.24 trace dt=602: newly created EEIs report old
-- prototype request L despite programmed small flow cap. Model that tick.
assert(s.last_auto[20].demand==L and s.last_auto[30].demand==L)
flow(20,0,0,small,small,10*L,10*L)
net(20).parent_network.flow_last_tick.secondary_demand=L
net(30).parent_network.flow_last_tick.secondary_demand=L
b.input.energy=small
M.on_tick(122,graph)
assert(a.status=="active" and b.status=="active" and b.output.energy==small and battery.energy==10*L)
-- Subsequent tick advertises the smaller request; no artificial load or cycle.
net(20).parent_network.flow_last_tick.secondary_demand=small
net(30).parent_network.flow_last_tick.secondary_demand=small
net(30).parent_network.flow_last_tick.secondary_output=small
b.output.energy=0;b.input.energy=small;a.input.energy=small
M.on_tick(123,graph)
assert(a.status=="active" and b.status=="active" and a.output.energy==small)
flow(20,0,0);flow(30,0,0)
source.active=false;M.on_tick(181,graph)
-- Unlike 060, the 063 contract keeps already buffered native joules until
-- the outgoing EEI has discharged; the mock must advance the native state.
assert(a.status=="draining-buffer" and b.status=="draining-buffer")
assert(a.output.energy==small and b.output.energy==small)
assert(a.input.input_flow_limit==0 and b.input.input_flow_limit==0)
a.output.energy=0;b.output.energy=0
M.on_tick(182,graph)
assert(a.status=="auto-idle" and b.status=="auto-idle" and not a.output and not b.output)
print("060/063 cold-start runtime mock PASS: zero counters, sustained buffered transfer, battery reverse, drained idle cleanup")
