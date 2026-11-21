package.path="./ElectrifiedMainline/?.lua;"..package.path
local D=require("scripts.bridge_dispatch_059")
local S=require("scripts.bridge_devices_060")
local L=20000000/60
defines={electric_interface_mode={solar_output=1,primary_output=2,secondary_output=3,tertiary_output=4,primary_input=5,secondary_input=6,tertiary_input=7,tertiary_input_output=8,accumulator=9}}
local function network(id)local n={valid=true,id=id};n.parent_network={valid=true,sub_networks={n}};return n end
local n1,n2=network(27),network(61)
local source={valid=true,active=true,type="electric-energy-interface",name="electric-energy-interface",electric_network=n1,electric_interface_mode=2,power_production=L,power_usage=0,energy=0,output_flow_limit=L}
local sink={valid=true,active=true,type="electric-energy-interface",name="electric-energy-interface",electric_network=n2,electric_interface_mode=6,power_usage=L,power_production=5*L,energy=0,electric_buffer_size=10*L,input_flow_limit=L}
local battery={valid=true,type="accumulator",name="accumulator",electric_network=n2,quality="normal",energy=5000,electric_buffer_size=50000,get_electric_input_flow_limit=function()return 5000 end,get_electric_output_flow_limit=function()return 5000 end}
local hidden={valid=true,type="electric-energy-interface",name="em-25kv-bridge-output-058",electric_network=n1,electric_interface_mode=2,power_production=100*L,energy=0,output_flow_limit=100*L}
local a=S.aggregate({source,sink,battery,hidden})
assert(a[27].production==L and a[27].interfaces==1)
assert(a[61].demand==L and a[61].production==0 and a[61].charge==5000 and a[61].discharge==5000)
local f={primary_output=0,secondary_output=0,solar_output=0,primary_demand=0,secondary_demand=0,tertiary_output=0,tertiary_demand=0,accumulator_energy=0,accumulator_capacity=0}
local p=D.plan({[27]=D.balance(f,nil,a[27]),[61]=D.balance(f,nil,a[61]),[44]=D.balance(f)},{{id=637,a=27,b=44},{id=761,a=61,b=44}},L)
assert(p[637]==L and p[761]==-L)
local same={primary_output=L,secondary_output=L,primary_demand=0,secondary_demand=L,maximum_production=2*L,maximum_consumption=L}
assert(D.balance(same,{offer=L,demand=L},a[27]).gen==L)
source.active=false;sink.active=false
a=S.aggregate({source,sink,battery,hidden});assert(a[27]==nil and a[61].discharge==5000)
p=D.plan({[27]={load=5000},[61]=D.balance(f,nil,a[61]),[44]=D.balance(f)},{{id=637,a=27,b=44},{id=761,a=61,b=44}},L)
assert(p[637]==-5000 and p[761]==5000)
battery.energy=50000;a=S.aggregate({battery});assert(a[61].charge==0)
battery.energy=0;a=S.aggregate({battery});assert(a[61].discharge==0)
assert(not next(S.aggregate({battery}, {[27]=true})))
local calls=0
local surf={valid=true,find_entities_filtered=function(arg)calls=calls+1;if arg.type then return {battery} else return {source,sink} end end}
local st={};S.sample(st,1,{[1]=surf},{[27]=true,[61]=true});S.sample(st,2,{[1]=surf},{[27]=true,[61]=true})
assert(calls==2)
S.sample(st,61,{[1]=surf},{[27]=true,[61]=true});assert(calls==4)
print("060 PASS: explicit editor modes, zero counters, same-network grouping, no duplicate power, actual battery limits, ignored bridge interfaces and bounded scanning")
