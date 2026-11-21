-- 0.1.61 pure read-only priority diagnostic regression, no engine-simulation claim.
package.path="./ElectrifiedMainline/?.lua;"..package.path
defines={electric_interface_mode={solar_output=1,primary_output=2,secondary_output=3,tertiary_output=4,primary_input=5,secondary_input=6,tertiary_input=7,tertiary_input_output=8,accumulator=9}}
local M=require("scripts.priority_diagnostics_061")
local readonly={}
local e=setmetatable({valid=true,name="electric-energy-interface",type="electric-energy-interface",
 electric_network_id=27,electric_interface_mode=2,energy=300,electric_buffer_size=10000,
 input_flow_limit=0,output_flow_limit=10000000/60,power_production=10000000/60,power_usage=0},{
 __newindex=function()error("diagnostics must never write entity")end})
local a=M.describe(e)
assert(a:find("priority=primary_output",1,true) and a:find("net=27",1,true))
assert(a:find("output_limit=10.000MW",1,true) and a:find("production_setting=10.000MW",1,true))
e.electric_interface_mode=6
local b=M.describe(e)
assert(b:find("priority=secondary_input",1,true))
local acc={valid=true,name="accumulator",type="accumulator",electric_network_id=61,energy=5000,
 electric_buffer_size=10000,quality="normal",
 get_electric_input_flow_limit=function()return 1000 end,
 get_electric_output_flow_limit=function()return 2000 end}
local c=M.describe(acc)
assert(c:find("native_storage_priority=tertiary",1,true) and c:find("stored=5000J",1,true))
assert(M.describe(nil):find("Select",1,true))
local station={valid=true,name="em-35kv-traction-substation",type="electric-pole",electric_network_id=44}
assert(M.describe(station):find("fixed secondary%-input") and M.describe(station):find("secondary%-output"))
assert(e.energy==300 and acc.energy==5000)
print("061 PASS: read-only native EEI priority/limits, accumulator status, substation status, no energy edits")
