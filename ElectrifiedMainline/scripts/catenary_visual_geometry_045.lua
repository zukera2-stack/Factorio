-- Measured pixel landmarks on immutable 512x384 arm PNG, scale .5.
-- Each row: mount, insulator lower stem, contact crossbar, steel upper clamp.
-- The existing art has no dedicated steel lug; upper clamp is the convention.
local layout=require("scripts.mast_visual_034")
local M={WIDTH=512,HEIGHT=384,SCALE=0.5,PIXELS_PER_TILE=32}
M.PIXELS={
  east      ={252,170,360,184,360,203,360,139},
  northeast ={276,174,384,188,384,207,384,143},
  southeast ={246,153,354,167,354,186,354,122},
  south     ={261,104,369,118,369,137,369,73},
  southwest ={288,159,180,173,180,192,180,128},
  west      ={252,168,144,182,144,201,144,137},
  northwest ={269,158,161,172,161,191,161,127},
  north     ={243,95,135,109,135,128,135,64},
}
function M.pixel_to_world(pos,name,px,py)
  local k=M.SCALE/M.PIXELS_PER_TILE
  return {x=pos.x+(px-M.WIDTH/2)*k,y=pos.y+layout.cantilever_shift(name)+(py-M.HEIGHT/2)*k}
end
function M.points(pos,name,face)
  local p=M.PIXELS[face]
  if not p or (name~=layout.STANDARD and name~=layout.SHORT_NORTH) then return nil end
  return {mount=M.pixel_to_world(pos,name,p[1],p[2]),
          insulator=M.pixel_to_world(pos,name,p[3],p[4]),
          contact=M.pixel_to_world(pos,name,p[5],p[6]),
          messenger=M.pixel_to_world(pos,name,p[7],p[8])}
end
return M
