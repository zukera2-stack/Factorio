-- 0.1.27 screenshot-calibrated native wire helper positions in world tiles.
-- SOUTH: screenshot 2026-11-16 shows 0.1.26 wire left 1.75 and below 2.30 tiles.
-- Other face offsets are initial mirrored estimates, NOT yet verified in game.
local M={}
local offsets={
  east={1.75,-0.80},southeast={1.68,-0.84},south={1.75,-0.80},
  southwest={-1.68,-0.84},west={-1.75,-0.80},
  northwest={-1.68,-0.84},north={-1.75,-0.80},
  northeast={1.68,-0.84}
}
function M.tip(pos,face,dx,dy)
  local o=offsets[face]
  if not o then return nil end
  return {x=pos.x+o[1]+(dx or 0),y=pos.y+o[2]+(dy or 0)}
end
local function dist2(a,b)
  local x,y=a.x-b.x,a.y-b.y
  return x*x+y*y
end
function M.pick_pair(masts,origin,max_radius,max_span)
  local candidates={}
  for _,e in pairs(masts or {}) do
    if e.valid and e.position and e.unit_number then
      local d=dist2(e.position,origin)
      if d<=max_radius*max_radius then
        candidates[#candidates+1]={entity=e,d=d}
      end
    end
  end
  table.sort(candidates,function(a,b)
    if a.d~=b.d then return a.d<b.d end
    return a.entity.unit_number<b.entity.unit_number
  end)
  if #candidates<2 then return nil,nil,"need two nearby 0.1.24 C-masts" end
  local a,b=candidates[1].entity,candidates[2].entity
  if dist2(a.position,b.position)>max_span*max_span then
    return nil,nil,"nearest two C-masts farther than allowed 16 tiles"
  end
  return a,b,nil
end
return M
