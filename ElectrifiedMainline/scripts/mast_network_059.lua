-- 059 expose the actual 25kV electric network through the visible zero-reach mast.
local tech=require("scripts.technical_network_046")
local M={}
local POLE,NORTH="em-35kv-catenary-pole","em-35kv-catenary-pole-north"
local function mast(e) return e and e.valid and (e.name==POLE or e.name==NORTH) end
local function get(id) if id then local e=game.get_entity_by_unit_number(id);if e and e.valid then return e end end end
local function connector(e)
 if not e then return nil end
 local ok,c=pcall(function() return e.get_wire_connector(defines.wire_connector_id.pole_copper,true) end)
 if ok and c and c.valid then return c end
end
function M.sync(graph)
 local t=tech.ensure_storage()
 t.mast_connected={}
 local failed,removed=0,0
 for id,n in pairs(graph.nodes or {}) do
   if n.name==POLE or n.name==NORTH then
     local p,a=get(id),get(t.helpers[id])
     if mast(p) then
       local pc,ac=connector(p),connector(a)
       local origin=defines.wire_origin.script
       if not pc then failed=failed+1
       else
         local bad={}
         -- Exact native singleton proof; any other shape retains the full audit.
         if not (ac and pc.real_connection_count==1 and pc.is_connected_to(ac,origin)) then
           for _,l in pairs(pc.real_connections) do
             if l.target and l.target.valid and not(ac and l.target.owner==a and l.origin==origin) then bad[#bad+1]=l end
           end
         end
         local safe=true
         for _,l in ipairs(bad) do
           local ok,res=pcall(function()return pc.disconnect_from(l.target,l.origin)end)
           if not ok or not res then failed=failed+1;safe=false else removed=removed+1 end
         end
         if safe and ac and a.surface.index==p.surface.index and a.force.name==p.force.name then
           local ok,res=pcall(function()return pc.is_connected_to(ac,origin) or pc.connect_to(ac,false,origin)end)
           if ok and res then t.mast_connected[id]=true else failed=failed+1 end
         end
       end
     end
   end
 end
 t.stats.mast_audit_failed=failed;t.stats.mast_links_removed=removed
end
function M.on_tick(tick,graph)
 local t=tech.ensure_storage()
 if tick%60==0 or t.mast_connected==nil or t.mast_generation~=t.sync_generation then
   M.sync(graph);t.mast_generation=t.sync_generation
 end
end
function M.status(player)
 local e=player.selected
 if not mast(e) then return end
 local t=tech.ensure_storage();local a=get(t.helpers[e.unit_number])
 local pc,ac=connector(e),connector(a)
 local linked=pc and ac and pc.is_connected_to(ac,defines.wire_origin.script)
 local msg="[EM059] mast="..e.unit_number.." visible_net="..tostring(e.electric_network_id).." anchor="..tostring(a and a.unit_number).." hidden_net="..tostring(a and a.electric_network_id).." script_link="..tostring(linked).." component="..tostring(t.components[e.unit_number])
 player.print(msg);log(msg)
 if a and ac then for _,l in pairs(ac.real_connections) do local owner=l.target and l.target.valid and l.target.owner;if owner and owner.valid then log("[EM059] anchor-neighbour="..owner.name.."#"..owner.unit_number.." origin="..tostring(l.origin)) end end end
end
return M
