-- 0.1.28 / 35 kV. One P2 native-copper endpoint per actual C-arm PNG.
-- Pixel coordinates are within the unchanged 512x384 arm-only raster.
-- rendering.draw_sprite targets mast + (0,-2.53125), scale=0.5.
-- Hidden helper wire position is (0,-2.53125), so its world position is:
--   mast + ((px-256)/64,(py-192)/64).
-- SOUTH (368,141) is validated visually in the user's 0.1.27 game.
-- Other seven points were inspected on the actual PNGs, game QA pending.
local M={}
M.sprite_pixels={
  east={369,143}, southeast={344,185}, south={368,141},
  southwest={155,192}, west={140,149}, northwest={150,126},
  north={130,145}, northeast={374,123}
}
function M.tip(pos,face)
  local p=M.sprite_pixels[face]
  if not (pos and p) then return nil end
  return {x=pos.x+(p[1]-256)/64,y=pos.y+(p[2]-192)/64}
end
function M.key(a,b)
  if a>b then a,b=b,a end
  return tostring(a)..":"..tostring(b)
end
function M.eligible(a,b)
  return a and b and a.id~=b.id
    and a.name=="em-35kv-catenary-pole" and b.name==a.name
    and a.rail_adjacent and b.rail_adjacent
    and a.rail_id and b.rail_id
    and a.surface_index==b.surface_index and a.force_name==b.force_name
    and M.tip({x=a.x,y=a.y},a.face)~=nil
    and M.tip({x=b.x,y=b.y},b.face)~=nil
end
return M
