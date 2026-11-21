-- Optional, machine-dependent Lua-only benchmark. Run from repo root:
-- lua5.2 tests/benchmark_dispatch_067.lua
-- Baseline reference is the unmodified 0.1.62 dispatcher captured by EM067.
package.path='./ElectrifiedMainline/?.lua;'..package.path
local baseline=assert(loadfile('tests/reference_bridge_dispatch_062.lua'))()
local optimized=require('scripts.bridge_dispatch_059')
local LIMIT=20000000/60
local function build(n)
 local nodes,edges,hub={}, {},n+1
 nodes[hub]={gen=0,load=0,battery=0,charge=0}
 for i=1,n do
   edges[i]={id=i,a=i,b=hub}
   if (i-1)%8==0 then nodes[i]={gen=LIMIT,load=0,battery=0,charge=0}
   else nodes[i]={gen=0,load=10000000/60,battery=0,charge=0} end
 end
 return nodes,edges
end
local function measure(dispatch,n,iterations,changing)
 local nodes,edges=build(n)
 local t=os.clock();local chk=0
 for run=1,iterations do
   if changing then nodes[1].gen=LIMIT-run*3 end
   local flows=dispatch.plan(nodes,edges,LIMIT)
   for i=1,n do chk=chk+(flows[i] or 0) end
 end
 return (os.clock()-t)*1000/iterations,chk
end
for _,n in ipairs({10,48,100,200}) do
 local repeats=n<50 and 60 or 12
 for _,changing in ipairs({false,true}) do
   local base,h1=measure(baseline,n,repeats,changing)
   local opt,h2=measure(optimized,n,repeats,changing)
   assert(math.abs(h1-h2)<0.01,'benchmark unexpectedly changed dispatch allocation')
   print(string.format('EM067 BENCH nodes=%d changing=%s rounds=%d baseline_ms=%.4f optimized_ms=%.4f',n,tostring(changing),repeats,base,opt))
 end
end