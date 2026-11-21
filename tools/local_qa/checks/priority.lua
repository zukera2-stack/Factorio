package.path='./ElectrifiedMainline/?.lua;'..package.path
defines={electric_interface_mode={solar_output=1,primary_output=2,secondary_output=3,tertiary_output=4,primary_input=5,secondary_input=6,tertiary_input=7,tertiary_input_output=8,accumulator=9}}
local M=require('scripts.priority_diagnostics_061')
local obj={valid=true,name='electric-energy-interface',type='electric-energy-interface',electric_network_id=11,electric_interface_mode=6,
 input_flow_limit=20000000/60,output_flow_limit=0,energy=4000,electric_buffer_size=10000,power_usage=20000000/60,power_production=0}
local before=obj.energy
local output=M.describe(obj)
assert(output:find('priority=secondary_input',1,true))
assert(output:find('input_limit=20.000MW',1,true))
assert(obj.energy==before,'read-only command edited a buffer')
local acc={valid=true,name='bob-fast-accumulator',type='accumulator',electric_network_id=113,energy=3000000,electric_buffer_size=4000000,quality='normal',
 get_electric_input_flow_limit=function() return 4000 end,
 get_electric_output_flow_limit=function() return 16000 end}
local report=M.describe(acc)
assert(report:find('input_limit=0.240MW',1,true))
assert(report:find('output_limit=0.960MW',1,true))
assert(report:find('stored=3000000J',1,true))
assert(report:find('native_storage_priority=tertiary',1,true))
assert(M.describe(nil):find('Select',1,true))
assert(M.describe({valid=true,name='em-35kv-traction-substation',type='electric-pole'}):find('secondary%-output'))
print('[LOCAL QA PASS] diagnostic: native EEI priority and Bob accumulator limits, read-only')