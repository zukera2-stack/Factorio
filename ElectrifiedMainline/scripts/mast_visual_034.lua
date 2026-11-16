-- 0.1.34: One source for native C mast artwork and anchor alignment.
-- NORTH means entity north of rails: a shorter native mast faces SOUTH.
-- SOUTH means entity south of rails: a standard mast faces NORTH.
-- Preserve the actual entity floor position, footprints and Undo semantics.
local M={}
M.SOUTH_RISE=0.40  -- screenshot-derived: raise standard south-of-track art ~13px
M.NORTH_DROP=2.20  -- existing 0.1.33 short native north prototype
M.BASE_SHIFT=-2.53125
M.STANDARD="em-35kv-catenary-pole"
M.SHORT_NORTH="em-35kv-catenary-pole-north"
function M.mast_shift(name)
  if name==M.SHORT_NORTH then return M.BASE_SHIFT+M.NORTH_DROP end
  return M.BASE_SHIFT-M.SOUTH_RISE
end
function M.cantilever_shift(name) return M.mast_shift(name) end
function M.helper_delta(name,face)
  if name==M.SHORT_NORTH and face=="south" then return M.NORTH_DROP end
  if name==M.STANDARD and face=="north" then return -M.SOUTH_RISE end
  return 0
end
return M
