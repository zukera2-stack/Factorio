-- Mock runtime lifecycle. Does NOT emulate native Factorio electrical solver.
package.path="./ElectrifiedMainline/?.lua;"..package.path
local M=require("scripts.power_bridge_058")
local tech=require("scripts.technical_network_046")
local PORT,INPUT,OUTPUT="em-25kv-bridge-port-058","em-25kv-bridge-input-058","em-25kv-bridge-output-058"
storage={};log=function() end
defines={wire_origin={script=2,player=1},wire_connector_id={pole_copper=5}}
local entities,serial={},1000
local force={name="player",set_surface_hidden=function()end}
local surface={index=1,name="nauvis",valid=true}
local lab
local function entity(name,s,pos,id,net)
 local e={name=name,valid=true,surface=s,force=force,position=pos,unit_number=id,electric_network_id=net,energy=0,electric_buffer_size=333334}
 local c={valid=true,owner=e,real_connections={}}
 local function remove(a,b,origin)for i=#a.real_connections,1,-1 do if a.real_connections[i].target==b and a.real_connections[i].origin==origin then table.remove(a.real_connections,i) end end end
 function c.is_connected_to(other,origin)for _,l in pairs(c.real_connections)do if l.target==other and l.origin==origin then return true end end return false end
 function c.connect_to(other,reach,origin)
   assert(reach==false and origin==2)
   c.real_connections[#c.real_connections+1]={target=other,origin=origin}
   other.real_connections[#other.real_connections+1]={target=c,origin=origin}
   e.electric_network_id=other.owner.electric_network_id
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
local t=tech.ensure_storage();t.helpers={[11]=101,[12]=102}
local graph={nodes={[1]={name=M.SUB},[2]={name=M.SUB}},edges={a={kind="feeder",a=1,b=11},b={kind="feeder",a=2,b=12}}}
M.rebuild(graph)
local messages={}
local player={force=force,selected=sub1,print=function(x)messages[#messages+1]=x end}
M.command(player,"import")
player.selected=sub2;M.command(player,"export")
M.on_tick(1,graph);M.on_tick(2,graph)
local s=storage.em.bridge058
local r1,r2=s.stations[1],s.stations[2]
assert(r1.status=="active" and r2.status=="active")
assert(r1.input.electric_network_id==10 and r1.output.electric_network_id==30)
assert(r2.input.electric_network_id==30 and r2.output.electric_network_id==20)
assert(t.bridge_ports[r1.port_id]==101 and t.bridge_ports[r2.port_id]==102)
r1.input.energy=M.LIMIT
M.on_tick(3,graph)
assert(r1.input.energy==0 and r1.output.energy==M.LIMIT and r2.output.energy==0)
-- Only simulated engine delivery plus actual transferred input can charge export.
r2.input.energy=100000
M.on_tick(4,graph);assert(r2.output.energy==100000 and r2.input.energy==0)
-- A change to the native network makes a loop; old output destroyed before any credit.
sub2.electric_network_id=10;r2.factory_port.electric_network_id=10
M.on_tick(5,graph);assert(r2.status=="cycle-or-same-network" and r2.output==nil and r1.status=="active")
-- Missing feeder means both terminals, interfaces, whitelist entry removed.
graph.edges.b=nil;M.mark_dirty();local pid=r2.port_id
M.on_tick(6,graph);assert(r2.status=="no-feeder-or-audit-failed" and r2.line_port==nil and t.bridge_ports[pid]==nil)
-- Off discards residual buffers, never creates energy. Role reversal allocates new zeroed interfaces.
player.selected=sub1;M.command(player,"off")
assert(r1.input==nil and r1.output==nil and r1.line_port==nil)
M.command(player,"export")
M.on_tick(7,graph);M.on_tick(8,graph)
assert(r1.status=="active" and r1.input.electric_network_id==30 and r1.output.electric_network_id==10)
assert(r1.input.energy==0 and r1.output.energy==0)
-- No hidden orphan after removing parent.
local p=r1.port_id
M.on_removed(sub1);sub1.destroy();graph.nodes[1]=nil
M.on_tick(9,graph)
assert(s.stations[1]==nil and t.bridge_ports[p]==nil)
assert(not next(lab.find_entities_filtered{}))
print("058 runtime mock PASS: real registration, modes, exact terminals, energy credit, cycle rejection, feeder loss and removal cleanup")
