-- Run from repository root: lua5.2 tests/35kv_topology.lua
package.path="./ElectrifiedMainline/?.lua;./ElectrifiedMainline/?/init.lua;"..package.path
local t=require("scripts.power_topology")
local function n(id,x,y,tx,ty,side)
    return {id=id,x=x,y=y,tx=tx,ty=ty,side=side,rail_adjacent=true}
end
local function eq(node,id)
    assert((node and node.id or nil)==id,
        "expected "..tostring(id).." got "..tostring(node and node.id))
end
local line={}
for i=1,5 do line[i]=n(i,(i-1)*10,-2,1,0,-1) end
for i,a in ipairs(line) do
    local f,b=t.choose(a,line,16)
    eq(f,i<5 and i+1 or nil)
    eq(b,i>1 and i-1 or nil)
end
assert(not t.compatible(line[1],n(6,7,5,1,0,1),16))
assert(not t.compatible(line[1],n(7,7,2.1,1,0,-1),16))
assert(not t.compatible(line[1],n(8,17,-2,1,0,-1),16))
assert(not t.compatible(line[1],n(9,10,-2,0,1,-1),16))
local f,b=t.choose(line[1],{n(10,4,-2,1,0,-1),n(11,6,-2,1,0,-1),
    n(12,-3,-2,1,0,-1),n(13,-6,-2,1,0,-1)},16)
eq(f,10);eq(b,12)
eq(select(1,t.choose(line[1],{n(15,5,-2,1,0,-1),
    n(14,5,-2,1,0,-1)},16)),14)
eq(select(1,t.choose(line[1],{line[2]},16,function()return false end)),nil)
local invalid=n(16,6,-2,1,0,-1);invalid.rail_adjacent=false
assert(not t.compatible(line[1],invalid,16))
print("35 kV topology: all pure Lua assertions passed")
