-- 0.1.34: One source for native C mast artwork and anchor alignment.
-- NORTH means entity north of rails: a shorter native mast faces SOUTH.
-- SOUTH means entity south of rails: a standard mast faces NORTH.
-- Preserve the actual entity floor position, footprints and Undo semantics.
local M={}
M.SOUTH_RISE=0.40  -- 0.1.34 native mast footprint shift, PRESERVED
-- User screenshot 1927px width, measured difference between southern and
-- northern contact levels: 27 rendered pixels (horizontal rows y586 vs 559).
-- Existing 512x384 source art is drawn at scale 0.5, 32 game pixels/tile.
-- Increase ONLY southern mast shaft above its unmodified foundation.
M.SOUTH_EXTEND_SOURCE_ROWS=54
M.SOUTH_EXTEND_TILES=M.SOUTH_EXTEND_SOURCE_ROWS*0.5/32
M.NORTH_DROP=2.20  -- existing 0.1.33 short native north prototype
M.BASE_SHIFT=-2.53125
M.STANDARD="em-35kv-catenary-pole"
M.SHORT_NORTH="em-35kv-catenary-pole-north"
function M.mast_shift(name)
  if name==M.SHORT_NORTH then return M.BASE_SHIFT+M.NORTH_DROP end
  return M.BASE_SHIFT-M.SOUTH_RISE
end
function M.cantilever_shift(name)
  local shift=M.mast_shift(name)
  if name==M.STANDARD then return shift-M.SOUTH_EXTEND_TILES end
  return shift
end
-- Native copper anchor for the STANDARD southern pole must return to its
-- proven pre-0.1.34 geometric coordinates. Art offsets are independent:
-- they move only the textured contact/messenger/dropper drawing.
function M.visual_delta(name,face)
  if name==M.STANDARD and face=="north" then
    return -M.SOUTH_RISE-M.SOUTH_EXTEND_TILES
  end
  return 0
end
function M.helper_delta(name,face)
  if name==M.SHORT_NORTH and face=="south" then return M.NORTH_DROP end
  return 0
end
return M
