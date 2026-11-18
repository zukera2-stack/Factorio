-- 0.1.28: eight C-arm hanger attachment offsets, derived from the 0.1.24
-- arm-only 512x384 sprites (scale=.5, 32 px/tile), calibrated on user's
-- 2026-11-16 SOUTH screenshot. x/y are hidden-pole FLOOR offsets in tiles;
-- the connector prototype adds the native -2.53125 tile image height.
-- Other seven orientations are sprite-relative estimates, pending game QA.
local M={}
local mast034=require("scripts.mast_visual_034")
M.OFFSETS={
  south={1.75,-0.80},
  east={1.61,-0.61},
  southeast={1.52,-0.88},
  southwest={-1.17,-0.78},
  west={-1.73,-0.64},
  northwest={-1.47,-0.80},
  north={-1.66,-1.43},
  northeast={1.98,-0.55}
}
function M.tip(pos,face,corrections)
  local o=M.OFFSETS[face]
  if not o then return nil end
  local c=corrections and corrections[face] or nil
  return {x=pos.x+o[1]+(c and c.x or 0),
          y=pos.y+o[2]+(c and c.y or 0)}
end
-- The north-of-track mast is a separately placeable native pole with a
-- vertical shaft shortened by 70 source pixels and shifted +2.20 tiles.
-- Its native copper helper follows the shifted hanger, NOT the footprint.
M.NORTH_SPRITE_DOWN=mast034.NORTH_DROP
function M.tip_for_pole(pos,face,corrections,prototype_name)
  local tip=M.tip(pos,face,corrections)
  if tip then
    tip.y=tip.y+mast034.helper_delta(prototype_name,face)
  end
  return tip
end
function M.same_pos(a,b)
  return a and b and math.abs(a.x-b.x)<0.0001 and
    math.abs(a.y-b.y)<0.0001
end
return M
