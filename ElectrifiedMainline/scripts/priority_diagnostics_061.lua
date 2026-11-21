-- 0.1.61 read-only introspection. Never writes to LuaEntity or energy buffers.
-- LuaEntity electric-interface limits are J/tick; multiply by 60 for MW.
local M={}
local function value(e,key)
 local ok,v=pcall(function()return e[key]end)
 if ok then return v end
end
local function number(v)
 return type(v)=="number" and v==v and v or nil
end
local function text(v)
 if v==nil then return "-" end
 return tostring(v)
end
local function mode_name(raw)
 local modes=defines and defines.electric_interface_mode or {}
 for name,id in pairs(modes) do if id==raw then return name end end
 return raw==nil and "-" or ("unknown-"..tostring(raw))
end
local function mw(v)
 v=number(v)
 return v and string.format("%.3f",v*60/1000000) or "-"
end
local function joules(v)
 v=number(v)
 return v and string.format("%.0f",v) or "-"
end
local function native_limit(e,kind)
 local field=kind=="input" and "input_flow_limit" or "output_flow_limit"
 if value(e,"type")=="electric-energy-interface" then return value(e,field) end
 local method=kind=="input" and "get_electric_input_flow_limit" or "get_electric_output_flow_limit"
 local fn=value(e,method)
 if type(fn)=="function" then
   local ok,lim=pcall(fn,value(e,"quality"))
   if ok then return lim end
 end
 return nil
end
function M.describe(entity)
 if not entity or value(entity,"valid")~=true then
   return "[EM061] Select an electric-energy-interface, accumulator or traction substation first."
 end
 local kind=value(entity,"type")
 local name=value(entity,"name")
 local net=value(entity,"electric_network_id")
 if kind=="electric-energy-interface" then
   return string.format("[EM061] EEI=%s net=%s priority=%s input_limit=%sMW output_limit=%sMW buffer=%sJ capacity=%sJ production_setting=%sMW consumption_setting=%sMW (read-only)",
     text(name),text(net),mode_name(value(entity,"electric_interface_mode")),
     mw(native_limit(entity,"input")),mw(native_limit(entity,"output")),
     joules(value(entity,"energy")),joules(value(entity,"electric_buffer_size")),
     mw(value(entity,"power_production")),mw(value(entity,"power_usage")))
 end
 if kind=="accumulator" then
   return string.format("[EM061] accumulator=%s net=%s native_storage_priority=tertiary input_limit=%sMW output_limit=%sMW stored=%sJ capacity=%sJ (read-only)",
     text(name),text(net),mw(native_limit(entity,"input")),mw(native_limit(entity,"output")),
     joules(value(entity,"energy")),joules(value(entity,"electric_buffer_size")))
 end
 if name=="em-35kv-traction-substation" then
   return "[EM061] substation net="..text(net)..
     " | hidden bridge source port: fixed secondary-input; destination port: fixed secondary-output; 20 MW/station; use /em-25kv-mode status for measured/planned MW. No priority switching in 061."
 end
 return "[EM061] selected="..text(name).." type="..text(kind).." net="..text(net)..
   " | select a native electric-energy-interface or accumulator for priority details."
end
M.report=M.describe
return M
