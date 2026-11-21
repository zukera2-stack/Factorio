-- EM071: cosmetic-only 3rd mast connection at a *real* HSR turnout.
package.path="./ElectrifiedMainline/?.lua;"..package.path
local M=require("scripts.catenary_axis_056")
local rows={}
local function rail(id,length)
 rows[id]={length=length,ends={[-1]={},[1]={}}}
 rows[id].links=function(sign) return rows[id].ends[sign] end
end
local function link(a,sa,b,sb)
 rows[a].ends[sa][#rows[a].ends[sa]+1]={id=b,sign=-sb}
 rows[b].ends[sb][#rows[b].ends[sb]+1]={id=a,sign=-sa}
end
local function pole(rail_id,station,x,y) return {rail=rail_id,s=station,x=x,y=y} end
for i=1,5 do rail(i,10) end
link(1,1,2,-1) -- straight approach
link(2,1,3,-1) -- first outgoing switch blade
link(2,1,4,-1) -- second outgoing switch blade
local nodes={
 [1]=pole(1,3,3,0), [2]=pole(2,5,15,0),
 [3]=pole(3,5,25,-6), [4]=pole(4,5,25,6),
 [5]=pole(5,5,17,1), -- deliberately nearby but disconnected parallel rail
}
local function plan() return M.select(nodes,function(id)return rows[id]end)end
local function degree(edges,id)
 local n=0
 for _,e in pairs(edges) do
  if e.a==id or e.b==id then n=n+1 end
 end
 return n
end
local edges=plan()
assert(edges["1:2"] and edges["2:3"] and edges["2:4"],"actual 3-way switch must show three cosmetic spans")
assert(degree(edges,2)==3,"central switch mast should have degree=3")
assert(not edges["3:4"],"cannot shortcut through a closer intermediate switch mast")
for _,e in pairs(edges) do
 assert(e.a~=5 and e.b~=5,"unconnected parallel track leaked into cosmetic graph")
 assert(degree(edges,e.a)<=3 and degree(edges,e.b)<=3)
 assert(e.kind=="contact" and e.axis and e.axis_length>0)
end
local a=plan()
for key in pairs(edges) do assert(a[key],"turnout result must be deterministic")end
for key in pairs(a) do assert(edges[key],"turnout added unstable edges")end
-- Removing a real branch removes exactly its cosmetic connection.
rows[2].ends[1][2]=nil
rows[4].ends[-1]={}
edges=plan()
assert(edges["1:2"] and edges["2:3"],"remaining real route must stay connected")
assert(not edges["2:4"] and degree(edges,2)==2,"rail split must remove third cosmetic span")
assert(not edges["3:4"],"no detour through unrelated rails")
print("071 turnout PASS: actual branched RailEnd yields exactly three cosmetic spans; split, no shortcuts, deterministic")
