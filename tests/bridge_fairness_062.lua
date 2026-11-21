-- 062 pure Lua regression: even sharing of a constrained source, no joule creation.
-- Test the actual installed bridge_dispatch_059 module. 1 MW = 1e6/60 J/tick.
package.path='./ElectrifiedMainline/?.lua;'..package.path
local d=require('scripts.bridge_dispatch_059')
local L=20000000/60
local edge={{id=1,a=1,b=2},{id=2,a=2,b=3},{id=3,a=2,b=4}}
local function approx(actual,wanted,context)
  assert(math.abs((actual or 0)-wanted)<0.05,(context or '')..' expected '..wanted..', got '..tostring(actual))
end
local function net(g,l,b,c) return {gen=g or 0,load=l or 0,battery=b or 0,charge=c or 0} end
local f=d.plan({[1]=net(L),[2]=net(),[3]=net(0,L),[4]=net(0,L)},edge,L)
approx(f[1],L,'source cap')
approx(f[2],L/2,'sink 3 equal fair share')
approx(f[3],L/2,'sink 4 equal fair share')
approx((f[2] or 0)+(f[3] or 0),L,'global conservation')
local nextf=d.plan({[1]=net(L),[2]=net(),[3]=net(),[4]=net(0,L)},edge,L)
approx(nextf[2],0,'disconnected load')
approx(nextf[3],L,'remaining load receives whole 20 MW')
local reverse=d.plan({[1]=net(0,L),[2]=net(),[3]=net(L),[4]=net()},edge,L)
approx(reverse[1],-L,'reverse source through trunk')
approx(reverse[2],-L,'reverse customer through feeder')
local three=d.plan({[1]=net(L),[2]=net(),[3]=net(0,L),[4]=net(0,L),[5]=net(0,L)},
  {{id=1,a=1,b=2},{id=2,a=2,b=3},{id=3,a=2,b=4},{id=4,a=2,b=5}},L)
for i=2,4 do approx(three[i],L/3,'three equally hungry customers') end
local battery=d.plan({[1]=net(0,0,L),[2]=net(),[3]=net(0,L),[4]=net(0,L)},edge,L)
approx(battery[2],L/2,'battery-backed feeder B')
approx(battery[3],L/2,'battery-backed feeder C')
local none=d.plan({[1]=net(),[2]=net(),[3]=net(0,L),[4]=net(0,L)},edge,L)
for i=1,3 do approx(none[i],0,'empty source creates no electricity') end
print('[EM062 FAIRNESS PASS] 20MW split 10/10, reallocation 0/20, reverse, 3 sinks, stored supply, zero-energy')