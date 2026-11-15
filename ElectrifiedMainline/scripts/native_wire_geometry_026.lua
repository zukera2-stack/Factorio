-- Pure Lua / Factorio-independent rail-facing C-mast tip projection.
local M={}
local offsets={
  east={1.5,0}, southeast={1.06,1.06}, south={0,1.5},
  southwest={-1.06,1.06}, west={-1.5,0},
  northwest={-1.06,-1.06}, north={0,-1.5},
  northeast={1.06,-1.06}
}
function M.tip(pos,face)
  local o=offsets[face]
  if not o then return nil end
  return {x=pos.x+o[1],y=pos.y+o[2]}
end
local function distance2(a,b)
  local x,y=a.x-b.x,a.y-b.y
  return x*x+y*y
end
-- Find the two closest C-masts to the command player, then validate span.
-- No entity selection/proximity mutation, signals, rail or power-network edits.
function M.pick_pair(masts,origin,max_radius,max_span)
  local candidates={}
  for _,e in pairs(masts or {}) do
    if e.valid and e.position and e.unit_number then
      local d=distance2(e.position,origin)
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
  if distance2(a.position,b.position)>max_span*max_span then
    return nil,nil,"nearest two C-masts farther than allowed 16 tiles"
  end
  return a,b,nil
end
return M
