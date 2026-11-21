package.path='./ElectrifiedMainline/?.lua;'..package.path
local T=require('scripts.power_topology')
local function n(id,x,side)
 return {id=id,x=x,y=1,tx=1,ty=0,side=side or -1,rail_adjacent=true}
end
local a=n(1,0);local b=n(2,10);local c=n(3,-10)
assert(T.compatible(a,b,16))
assert(not T.compatible(a,n(4,20),16))
assert(not T.compatible(a,n(5,10,1),16))
assert(not T.compatible(a,n(6,4,1),16))
local f,r=T.choose(a,{b,c},16)
assert(f.id==2 and r.id==3)
local f2,r2=T.choose(a,{b,c},16,function()return false end)
assert(f2==nil and r2==nil)
print('[LOCAL QA PASS] topology: span, side, deterministic forward/backward choice')