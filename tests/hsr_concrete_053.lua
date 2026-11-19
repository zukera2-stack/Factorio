local M=dofile("ElectrifiedMainline/prototypes/hsr_concrete_053.lua")
local function copy(t)
 if type(t)~="table" then return t end
 local r={} for k,v in pairs(t) do r[k]=copy(v) end return r
end
local dirs={"north","northeast","east","southeast","south","southwest","west","northwest"}
local raw={}
for _,r in ipairs({
 {"straight-rail","em-high-speed-straight-rail",4,{8,3,8,3},256},
 {"half-diagonal-rail","em-half-diagonal-high-speed-rail",4,{3,3,3,3},384},
 {"curved-rail-a","em-curved-high-speed-rail",8,{4,4,4,4,4,4,4,4},512},
 {"curved-rail-b","em-curved-high-speed-rail-b",8,{4,4,4,4,4,4,4,4},512}}) do
 local pictures={rail_endings={filename="native-end"}}
 for i=1,r[3] do
  local s=r[5];if r[1]=="straight-rail" and i%2==0 then s=384 end
  local spr={filename="native",width=s,height=s,x=42,y=64,scale=.5,variation_count=r[4][i],flags={"low-object"}}
  pictures[dirs[i]]={ties=copy(spr),backplates=copy(spr),metals=copy(spr),stone_path=copy(spr),stone_path_background=copy(spr)}
 end
 raw[r[1]]={[r[2]]={pictures=pictures},native={pictures=pictures}}
end
assert(M.apply(raw,copy)==48)
for _,group in pairs(raw) do
 for name,rail in pairs(group) do
  if name~="native" then
   assert(rail.pictures.rail_endings.filename=="native-end")
   for _,d in ipairs(dirs) do
    local p=rail.pictures[d]
    if p then
     for _,k in ipairs({"ties","backplates"}) do
      assert(p[k].filename:find("hsr-053",1,true) and p[k].x==0 and p[k].y==0 and p[k].scale==.5)
      assert(p[k].width==group.native.pictures[d][k].width and p[k].variation_count==group.native.pictures[d][k].variation_count)
     end
     for _,k in ipairs({"metals","stone_path","stone_path_background"}) do assert(p[k].filename=="native" and p[k].x==42 and p[k].y==64) end
     assert(group.native.pictures[d].ties.filename=="native")
    end
   end
  end
 end
end
print("053 HSR replacement contract PASS")
