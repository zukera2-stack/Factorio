-- 0.1.34: One source for native C mast artwork and anchor alignment.
-- NORTH means entity north of rails: a shorter native mast faces SOUTH.
-- SOUTH means entity south of rails: a standard mast faces NORTH.
-- Preserve the actual entity floor position, footprints and Undo semantics.
local M={}
-- 0.1.36: the +0.40 lift of the whole southern native pole in 0.1.34
-- is REVOKED. Screenshot 21:51:56 shows the visible base ~32 px ABOVE
-- its yellow placement marker; the southern triangle hanger is ~32 px
-- ABOVE the northern triangle and existing contact line. Both errors
-- share the same cause: native shaft and arm are 0.40 tiles too high.
-- Preserve the 0.1.35 custom CONTACT DRAW position and hidden wire anchor.
M.SOUTH_RISE=0.40  -- historical offset in the art-to-hidden-wire transform only
-- User screenshot 1927px width, measured difference between southern and
-- northern contact levels: 27 rendered pixels (horizontal rows y586 vs 559).
-- Existing 512x384 source art is drawn at scale 0.5, 32 game pixels/tile.
-- Increase ONLY southern mast shaft above its unmodified foundation.
M.SOUTH_EXTEND_SOURCE_ROWS=54
M.SOUTH_EXTEND_TILES=M.SOUTH_EXTEND_SOURCE_ROWS*0.5/32
M.NORTH_DROP=2.02  -- 0.1.42 user-accepted fine adjustment for shortened north mast
M.BASE_SHIFT=-2.53125
M.STANDARD="em-35kv-catenary-pole"
M.SHORT_NORTH="em-35kv-catenary-pole-north"
function M.mast_shift(name)
  if name==M.SHORT_NORTH then return M.BASE_SHIFT+M.NORTH_DROP end
  -- Correct placement-marker vs footer and align BOTH triangular hangers.
  return M.BASE_SHIFT
end
function M.cantilever_shift(name)
  local shift=M.mast_shift(name)
  if name==M.STANDARD then return shift-M.SOUTH_EXTEND_TILES end
  return shift
end
-- Real native wire helper for the southern standard pole is already at
-- the pre-0.1.34 coordinate. Do NOT move it. Preserve 0.1.35 custom
-- contact/messenger/dropper draw level while the shaft+arm move DOWN
-- 0.40 world tiles, as measured on the latest user screenshot.
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
