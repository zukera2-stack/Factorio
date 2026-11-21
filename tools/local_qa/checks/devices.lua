package.path='./ElectrifiedMainline/?.lua;'..package.path
local D=require('scripts.bridge_devices_060')
defines={electric_interface_mode={solar_output=1,primary_output=2,secondary_output=3,tertiary_output=4,primary_input=5,secondary_input=6,tertiary_input=7,tertiary_input_output=8,accumulator=9}}
local parent={valid=true,flow_last_tick={},sub_networks={{valid=true,id=113}}}
local en={valid=true,id=113,parent_network=parent}
local acc={valid=true,name='bob-fast-accumulator',type='accumulator',energy=2000000,electric_buffer_size=4000000,quality='normal',electric_network=en,
 get_electric_input_flow_limit=function() return 240000/60 end,
 get_electric_output_flow_limit=function() return 960000/60 end}
local key,obs=D.device(acc)
assert(key==113 and obs.stored==2000000 and obs.capacity==4000000)
assert(obs.charge==4000 and obs.discharge==16000)
acc.energy=4000000
local _,full=D.device(acc);assert(full.charge==0 and full.discharge==16000)
acc.energy=0
local _,empty=D.device(acc);assert(empty.discharge==0 and empty.charge==4000)
local eei={valid=true,name='electric-energy-interface',type='electric-energy-interface',active=true,electric_network=en,electric_interface_mode=2,
 power_production=400000/60,power_usage=0,output_flow_limit=200000/60,energy=0,electric_buffer_size=1000000}
local _,producer=D.device(eei)
assert(math.abs(producer.production-200000/60)<0.01)
eei.electric_interface_mode=6;eei.input_flow_limit=100000/60;eei.power_usage=200000/60
local _,consumer=D.device(eei)
assert(math.abs(consumer.demand-100000/60)<0.01)
local agg=D.aggregate({acc,eei},{[113]=true})
assert(agg[113] and agg[113].interfaces==1 and agg[113].accumulators==1)
assert(not D.aggregate({acc,eei},{[114]=true})[113])
local calls=0
local surface={valid=true,find_entities_filtered=function(f)
 calls=calls+1
 if f.type=='accumulator' then return {acc} end
 if f.name=='electric-energy-interface' then return {eei} end
 return {}
end}
local cache={}
local a=D.sample(cache,120,{[1]=surface},{[113]=true})
assert(a[113] and calls==2)
local b=D.sample(cache,149,{[1]=surface},{[113]=true})
assert(b==a and calls==2,'device sampling cache broken')
D.sample(cache,181,{[1]=surface},{[113]=true})
assert(calls==4,'device refresh after 60 ticks missing')
print('[LOCAL QA PASS] devices: Bob accumulator 240/960kW, EEI priority/limit, sampling cache')