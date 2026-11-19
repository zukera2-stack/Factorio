-- 053: replace only native tie and backplate sprites.
local M={}
local rails={
 {"straight-rail","em-high-speed-straight-rail","straight",4,{8,3,8,3},256},
 {"half-diagonal-rail","em-half-diagonal-high-speed-rail","half-diagonal",4,{3,3,3,3},384},
 {"curved-rail-a","em-curved-high-speed-rail","curved-a",8,{4,4,4,4,4,4,4,4},512},
 {"curved-rail-b","em-curved-high-speed-rail-b","curved-b",8,{4,4,4,4,4,4,4,4},512},
}
local dirs={"north","northeast","east","southeast","south","southwest","west","northwest"}
function M.apply(raw,copy)
 local n=0
 for _,r in ipairs(rails) do
  local rail=assert(raw[r[1]][r[2]])
  rail.pictures=copy(assert(rail.pictures))
  for i=1,r[4] do
   local d=dirs[i]
   local piece=assert(rail.pictures[d])
   for layer,suffix in pairs({ties="ties",backplates="pads"}) do
    local s=assert(piece[layer])
    local side=r[6]
    if r[3]=="straight" and i%2==0 then side=384 end
    assert(s.width==side and s.height==side and s.variation_count==r[5][i], "EM053 unexpected native rail sprite "..r[3].." "..d.." "..layer)
    s.filename="__ElectrifiedMainline__/graphics/entity/hsr-053/"..r[3].."-"..d.."-"..suffix..".png"
    s.x=0; s.y=0; s.tint=nil
    n=n+1
   end
  end
 end
 assert(n==48)
 return n
end
if data then log("[EM053] replacement sprites="..M.apply(data.raw,table.deepcopy)) end
return M
