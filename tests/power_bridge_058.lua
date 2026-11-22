package.path="./ElectrifiedMainline/?.lua;"..package.path
local M=require("scripts.power_bridge_058")
local B=M.LIMIT
-- Native bridge buffers are 1 tick of the physical station rating (old 333334J; research 2MJ).
local CAP=math.ceil(B)
local FLOW=(B>1000000) and '120MW' or '20MW'
local BUFFER=(B>1000000) and '2MJ' or '333334J'
local a,b,q=M.transfer(B+100,0,CAP)
assert(math.abs(q-B)<1e-8 and math.abs(a+b-(B+100))<1e-8)
a,b,q=M.transfer(200,100,200);assert(a==100 and b==200 and q==100)
a,b,q=M.transfer(0,100,200);assert(a==0 and b==100 and q==0)
a,b,q=M.transfer(B,CAP,CAP);assert(q==0 and a==B)
local accepted,blocked=M.select({{id=1,source=1,target=2},{id=2,source=2,target=3},{id=3,source=3,target=1},{id=4,source=2,target=1},{id=5,source=5,target=5},{id=6,source=1,target=2},{id=7,source=3,target=4}})
assert(accepted[1] and accepted[2] and accepted[6] and accepted[7])
assert(not accepted[3] and blocked[3] and blocked[4] and blocked[5])
local ei,eo,total=0,0,0
for i=1,600 do
 ei=ei+math.min(B,CAP-ei)
 eo=eo-math.min(eo,100000)
 local before=ei+eo
 ei,eo,q=M.transfer(ei,eo,CAP);total=total+q
 assert(math.abs(ei+eo-before)<1e-7 and q<=B and ei>=0 and eo<=CAP)
end
assert(total<=600*B)
table.deepcopy=function(x)local function c(v)if type(v)~="table" then return v end;local t={} for k,a in pairs(v) do t[k]=c(a) end return t end return c(x) end
data={raw={["electric-pole"]={["em-25kv-technical-anchor-046"]={name="anchor",flags={"get-by-unit-number"}}}}}
function data:extend(v) self.result=v end
dofile("ElectrifiedMainline/prototypes/power_bridge_058.lua")
assert(#data.result==3 and data.result[1].maximum_wire_distance==0 and data.result[1].auto_connect_up_to_n_wires==0)
local i,o=data.result[2],data.result[3]
assert(i.energy_source.input_flow_limit==FLOW and i.energy_source.output_flow_limit=="0W")
assert(o.energy_source.input_flow_limit=="0W" and o.energy_source.output_flow_limit==FLOW)
for _,p in ipairs({i,o}) do assert(p.energy_source.buffer_capacity==BUFFER) end
for _,p in ipairs({i,o}) do assert(p.energy_production=="0W" and p.energy_usage=="0W" and p.energy_source.drain=="0W") end
print("058 PASS: joule conservation, rated "..FLOW.." cap, correct buffer, directed cycle rejection and real native interface limits")
