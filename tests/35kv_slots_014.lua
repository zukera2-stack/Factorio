-- Pure Lua 5.2 test; no Factorio executable or actual train signals.
package.path = './ElectrifiedMainline/?.lua;'..package.path
defines={rail_direction={front=0,back=1}}
local slot=require('scripts.rail_slot_debug_014')
local function loc(x,y,d) return {position={x=x,y=y},direction=d,rail_layer=0} end
local rail={name='em-high-speed-straight-rail',valid=true,position={x=1,y=2},direction=0,unit_number=4}
rail.get_rail_end=function(d)
 if d==0 then return {out_signal_location=loc(3,4,2),in_signal_location=loc(5,6,4)} end
 return {out_signal_location=loc(3,4,2),in_signal_location=loc(7,8,6),alternative_out_signal_location=loc(9,10,8)}
end
local marks,errors=slot.collect(rail)
assert(#marks==4,'shared rail end slots must be deduplicated')
assert(#errors==0)
local plain={name='straight-rail',valid=true}
local player={selected=plain,position={x=0,y=0},force='player',surface={find_entities_filtered=function(_) return {rail} end}}
assert(slot.nearest_rail(player)==rail)
player.selected=rail
assert(slot.nearest_rail(player)==rail)
local prints,draws={},0
player.print=function(x) prints[#prints+1]=x end
rail.surface=player.surface
rendering={draw_circle=function(_) draws=draws+1 end,draw_text=function(_) draws=draws+1 end}
log=function(_) end
slot.show(player)
assert(draws==8,'one circle and one label per unique slot')
assert(#prints==5,'one summary and one line per slot')
player.selected=plain
player.surface.find_entities_filtered=function(_) return {} end
slot.show(player)
assert(#prints==6,'no HSR must print a message, not create a signal')
print('0.1.14 slot diagnostic mocked geometry: PASS')
-- Regression: Factorio forbids require() in a command callback after script parsing.
-- The diagnostic module must be loaded once at control.lua top level.
local control_file = assert(io.open('ElectrifiedMainline/scripts/control.lua', 'r'))
local control_source = control_file:read('*a')
control_file:close()
assert(control_source:find('local rail_slot_debug014 = require("scripts.rail_slot_debug_014")', 1, true),
  'slot diagnostic must be required at control.lua parse time')
assert(not control_source:find('then require("scripts.rail_slot_debug_014")', 1, true),
  'slot diagnostic must not be required from the runtime command handler')
print('0.1.14 command callback require regression: PASS')
