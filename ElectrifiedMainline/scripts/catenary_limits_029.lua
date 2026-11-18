-- Electrified Mainline 0.1.29. Shared between prototype and runtime.
-- Limits describe mast spacing in WORLD TILES, not copper sprite length.
local M = {
  STRAIGHT = 32,
  CURVE = 16,
  WIRE_REACH = 40,
}
function M.allowed(a,b,path)
  if not (a and b and path and type(path.length)=="number") then return false end
  local dx,dy=b.x-a.x,b.y-a.y
  local dist=math.sqrt(dx*dx+dy*dy)
  local maximum=path.curved and M.CURVE or M.STRAIGHT
  if dist<0.1 or dist>maximum+1e-6 then return false end
  -- A true HSR path must not be a long detour through a junction, loop
  -- or a nearby but unrelated railway. path.length is an approximation
  -- based on connected custom rail entity centres.
  if path.length>maximum*1.5+4 then return false end
  if path.length>dist*1.6+4 then return false end
  return true
end
return M
