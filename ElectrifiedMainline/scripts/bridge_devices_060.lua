-- 060 independent native device sample, never edits player devices.
local D=require("scripts.bridge_dispatch_059")
local M={}
local function pos(x) return type(x)=="number" and x==x and math.max(0,x) or 0 end
local function rate(e,kind)
 local ok,v=pcall(function()
   if kind=="input" then return e.get_electric_input_flow_limit(e.quality)
   else return e.get_electric_output_flow_limit(e.quality) end
 end)
 return ok and pos(v) or 0
end
local function bounded(v,limit) if type(limit)=="number" then return math.min(v,pos(limit)) end;return v end
function M.device(e)
 if not (e and e.valid) then return nil end
 local ok,key,obs=pcall(function()
   local id=D.network_key(e)
   if not id then return nil end
   if e.type=="accumulator" then
     local stored,cap=pos(e.energy),pos(e.electric_buffer_size)
     return id,{stored=stored,capacity=cap,charge=math.min(pos(cap-stored),rate(e,"input")),discharge=math.min(stored,rate(e,"output")),accumulators=1}
   end
   if e.name~="electric-energy-interface" or e.type~="electric-energy-interface" or e.active==false then return nil end
   local modes=defines.electric_interface_mode
   if not modes then return nil end
   local mode=e.electric_interface_mode
   if mode==nil then return nil end
   local out=mode==modes.solar_output or mode==modes.primary_output or mode==modes.secondary_output or mode==modes.tertiary_output
   local inp=mode==modes.primary_input or mode==modes.secondary_input or mode==modes.tertiary_input
   local production,demand=0,0
   if out then production=bounded(math.max(pos(e.power_production),pos(e.energy)),e.output_flow_limit) end
   if inp then demand=bounded(math.max(pos(e.power_usage),pos(pos(e.electric_buffer_size)-pos(e.energy))),e.input_flow_limit) end
   return id,{production=production,demand=demand,interfaces=1}
 end)
 if ok then return key,obs end
end
function M.aggregate(entities,allowed)
 local result={}
 for _,e in pairs(entities) do
   local id,v=M.device(e)
   if id and v and (not allowed or allowed[id]) then
     local n=result[id] or {}
     for k,x in pairs(v) do n[k]=(n[k] or 0)+x end
     result[id]=n
   end
 end
 return result
end
-- Sample at most once/second for stable topology, only relevant physical
-- surfaces. Cache numeric values, not transient Lua network objects.
function M.sample(s,tick,surfaces,allowed)
 local ids,keys={},{}
 for id in pairs(surfaces) do ids[#ids+1]=id end;table.sort(ids)
 for id in pairs(allowed) do keys[#keys+1]=id end;table.sort(keys)
 local signature=table.concat(ids,":").."/"..table.concat(keys,":")
 if s.device_sample and s.device_sample.signature==signature and tick-s.device_sample.tick<60 then return s.device_sample.data end
 local data={}
 for _,id in ipairs(ids) do
   local surface=surfaces[id]
   if surface and surface.valid and surface.find_entities_filtered then
     local all=surface.find_entities_filtered{type="accumulator"}
     for _,e in pairs(surface.find_entities_filtered{name="electric-energy-interface"}) do all[#all+1]=e end
     for key,v in pairs(M.aggregate(all,allowed)) do
       local row=data[key] or {}
       for k,x in pairs(v) do row[k]=(row[k] or 0)+x end
       data[key]=row
     end
   end
 end
 s.device_sample={signature=signature,tick=tick,data=data}
 return data
end
return M
