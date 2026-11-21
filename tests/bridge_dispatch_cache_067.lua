package.path='./ElectrifiedMainline/?.lua;'..package.path
local legacy=assert(loadfile('tests/reference_bridge_dispatch_062.lua'))()
local enhanced=require('scripts.bridge_dispatch_059')
local seed=20261121
math.randomseed(seed)
local cases=0
local function deepcopy_edges(edges)
 local r={}; for i,e in ipairs(edges) do r[i]={id=e.id,a=e.a,b=e.b} end;return r
end
local function assert_same(input,edges,limit,tag)
 local a=legacy.plan(input,deepcopy_edges(edges),limit)
 local b=enhanced.plan(input,deepcopy_edges(edges),limit)
 for id,x in pairs(a) do local y=b[id];assert(type(y)=='number' and math.abs(x-y)<1e-8,'MISMATCH '..tag..' id='..id..' baseline='..x..' optimized='..tostring(y)) end
 for id,x in pairs(b) do local y=a[id];assert(type(y)=='number' and math.abs(x-y)<1e-8,'EXTRA '..tag..' id='..id) end
 cases=cases+1
end
local function ran(n,shape)
 local nodes,edges={},{}
 for i=1,n do
  nodes[i]={gen=math.random(0,8)*100000,load=math.random(0,6)*100000,battery=math.random(0,4)*100000,charge=math.random(0,3)*100000}
 end
 if shape==1 then
  for i=2,n do edges[#edges+1]={id=i,a=1,b=i} end
 elseif shape==2 then
  for i=2,n do edges[#edges+1]={id=i,a=i-1,b=i} end
 elseif shape==3 then
  for i=2,n do edges[#edges+1]={id=i,a=math.random(1,i-1),b=i} end
 elseif shape==4 then
  for i=1,n-1 do edges[#edges+1]={id=i,a=i,b=i+1} end
  for i=1,n*2 do local a,b=math.random(1,n),math.random(1,n);if a~=b then edges[#edges+1]={id=#edges+1,a=a,b=b} end end
 end
 -- Randomly permute the edge order to catch cache ordering differences.
 for i=#edges,2,-1 do local j=math.random(1,i);edges[i],edges[j]=edges[j],edges[i] end
 return nodes,edges
end
for i=1,1100 do
 local n=math.random(2,16);local nodes,edges=ran(n,math.random(1,4))
 assert_same(nodes,edges,20000000/60,'random:'..i)
 -- Cache same shape twice, change only one numerical input, then restore.
 if i%4==0 then
  assert_same(nodes,edges,20000000/60,'cache-repeat:'..i)
  local id=math.random(1,n)
  nodes[id].charge=nodes[id].charge+166667
  assert_same(nodes,edges,20000000/60,'numeric-change:'..i)
 end
end
for _,n in ipairs({48,100,200}) do
 local nodes,edges=ran(n,1)
 assert_same(nodes,edges,20000000/60,'large:'..n)
 assert_same(nodes,edges,20000000/60,'large-repeat:'..n)
 for i=1,5 do nodes[math.random(1,n)].gen=math.random(0,500000);assert_same(nodes,edges,20000000/60,'large-change:'..n..':'..i) end
end
local stats=enhanced.cache_stats()
assert(stats.hits>0 and stats.misses>0,'expected hit and miss')
-- Caller mutation must not poison any future hit or the previous miss.
local i,e=ran(10,1)
local cached=enhanced.plan(i,deepcopy_edges(e),20000000/60)
for k in pairs(cached) do cached[k]=1000000000 end
assert_same(i,e,20000000/60,'caller-mutation-isolated')
-- Need correct cache invalidation even if only the edge order or endpoints change.
local before=enhanced.cache_stats()
local i2,e2=ran(12,4)
assert_same(i2,e2,20000000/60,'topology-before')
e2[1].a=12;e2[1].b=5
assert_same(i2,e2,20000000/60,'topology-after')
assert_same(i2,e2,20000000/60,'topology-hit')
local after=enhanced.cache_stats()
assert(after.hits>before.hits and after.misses>before.misses)
print('EM067 differential PASS cases='..cases..' seed='..seed..' cache_hits='..stats.hits..' cache_misses='..stats.misses)

