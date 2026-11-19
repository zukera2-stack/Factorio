package.path='./ElectrifiedMainline/?.lua;'..package.path
local M=require("prototypes.hsr_palette_051")
local function copy(t)
 if type(t)~="table" then return t end
 local r={};for k,v in pairs(t) do r[k]=copy(v) end;return r
end
local function eq(a,b)
 if type(a)~=type(b) then return false end
 if type(a)~="table" then return a==b end
 for k,v in pairs(a) do if not eq(v,b[k]) then return false end end
 for k in pairs(b) do if a[k]==nil then return false end end
 return true
end
local specs={{"straight-rail","em-high-speed-straight-rail",4},{"half-diagonal-rail","em-half-diagonal-high-speed-rail",4},{"curved-rail-a","em-curved-high-speed-rail",8},{"curved-rail-b","em-curved-high-speed-rail-b",8}}
local dirs={"north","northeast","east","southeast","south","southwest","west","northwest"}
local function art(i)
 return {filename="native.png",width=256,height=256,x=i*256,y=0,shift={0,0},scale=.5,variation_count=4,usage="rail"}
end
local raw={}
for _,spec in ipairs(specs) do
 local p={rail_endings={sheets={art(1)}},render_layers={tie="rail-tie"},segment_visualisation_endings=art(2)}
 for i=1,8 do
  p[dirs[i]]={}
  if i<=spec[3] then
   local x=p[dirs[i]]
   for _,l in ipairs({"metals","backplates","ties","stone_path","stone_path_background","segment_visualisation_middle"}) do x[l]=art(i) end
  end
 end
 raw[spec[1]]={[spec[1]]={pictures=p},[spec[2]]={pictures=p,collision_box={{-1,-1},{1,1}},next_upgrade="keep"}}
end
local before=copy(raw)
assert(M.apply(raw,copy)==72,"24 directions x 3 layers")
for _,spec in ipairs(specs) do
 local vanilla=raw[spec[1]][spec[1]]
 local custom=raw[spec[1]][spec[2]]
 assert(eq(vanilla,before[spec[1]][spec[1]]))
 for i=1,spec[3] do
  local p=custom.pictures[dirs[i]]
  assert(p.ties.tint.r==.55 and p.ties.tint.g==.82 and p.ties.tint.b==1)
  assert(p.stone_path.tint.r==.76 and p.stone_path_background.tint.r==.86)
  for _,l in ipairs({"ties","stone_path","stone_path_background"}) do p[l].tint=nil end
 end
 assert(eq(custom,before[spec[1]][spec[2]]),"non-tint difference")
end
local p=raw["straight-rail"]["em-high-speed-straight-rail"].pictures.north
p.ties={layers={{filename="a.png",tint={.5,.5,.5,.7}},{filename="shadow.png",draw_as_shadow=true}}}
p.stone_path={{filename="a.png"},{filename="b.png"}}
assert(M.apply(raw,copy)==73)
p=raw["straight-rail"]["em-high-speed-straight-rail"].pictures.north
assert(p.ties.layers[1].tint.r==.275 and p.ties.layers[1].tint.a==.7)
assert(p.ties.layers[2].tint==nil and p.stone_path[2].tint.r==.76)
print("051 PASS: 24 native rail directions, only 3 art tints, vanilla and geometry intact, layered/array variation handling")
