package.path="./ElectrifiedMainline/?.lua;"..package.path
local D=require("scripts.bridge_dispatch_059")
local L=20000000/60
local function n(g,l,b,c)return {gen=g or 0,load=l or 0,battery=b or 0,charge=c or 0} end
local edges={{id=1,a=10,b=30},{id=2,a=20,b=30}}
local function plan(a,b,c)return D.plan({[10]=a,[20]=b,[30]=c},edges,L) end
local p=plan(n(2*L),n(0,2*L),n())
assert(p[1]==L and p[2]==-L)
p=plan(n(L),n(0,0,0,L),n());assert(p[1]==L and p[2]==-L)
p=plan(n(0,L),n(0,0,L,0),n());assert(p[1]==-L and p[2]==L)
p=plan(n(0,0,L,0),n(0,0,0,L),n());assert(not next(p))
p=plan(n(L),n(),n());assert(not next(p))
p=plan(n(L),n(0,L),n(0,L));assert((p[1] or 0)<=L and math.abs(p[2] or 0)<=L)
-- Same source allocated across two independent feeders; total must not exceed available source.
p=D.plan({[10]=n(L),[20]=n(0,L),[30]=n(0,L)},{{id=1,a=10,b=20},{id=2,a=10,b=30}},L)
assert((p[1] or 0)+(p[2] or 0)==L)
-- Local native load takes priority over storage; local deficit reserves battery.
p=plan(n(0,L,L,0),n(0,L),n());assert(not next(p))
p=plan(n(L),n(0,0,0,L),n(0,L));assert(p[1]==L and not p[2])
-- Exclude our own artificial demand and output offer.
local f={primary_output=0,secondary_output=L,solar_output=0,primary_demand=0,secondary_demand=L,tertiary_output=L,tertiary_demand=L,accumulator_energy=0,accumulator_capacity=L}
local b=D.balance(f,{offer=L,demand=L})
assert(b.gen==0 and b.load==0 and b.battery==0 and b.charge==L)
-- Actual whole-network API fields are read rather than trusting raw copper subnetwork IDs.
local s1={valid=true,id=8};local s2={valid=true,id=3}
local parent={valid=true,sub_networks={s1,s2},flow_last_tick=f};s1.parent_network=parent;s2.parent_network=parent
local id,flow=D.read_network({electric_network=s1});assert(id==3 and flow==f)
assert(D.read_network({})==nil)
-- Split corridor, no phantom transfer.
p=D.plan({[10]=n(L),[20]=n(0,L),[30]=n(),[31]=n()},{{id=1,a=10,b=30},{id=2,a=20,b=31}},L)
assert(not next(p))
-- Same ordinary and corridor network must not form a route.
p=D.plan({[10]=n(L)},{{id=1,a=10,b=10}},L);assert(not next(p))
print("059 PASS: automatic source/consumer allocation, shared 20 MW ceiling, charge, reverse discharge, no battery-to-battery, parent IDs and rail split")
