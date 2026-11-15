-- 0.1.26 ONLY: on-demand, reversible native copper-wire visual experiment.
-- Does NOT enable real 25kV energy, automatic poles, Undo joins or train changes.
local M={}
local geo=require("scripts.native_wire_geometry_026")
local MAST="em-35kv-catenary-pole"
local ANCHOR="em-25kv-wire-probe-anchor"
local MAX_RADIUS,SPAN=24,16
local function state()
  storage.em=storage.em or {}
  storage.em.native_wire_probe_026=storage.em.native_wire_probe_026 or {runs={}}
  return storage.em.native_wire_probe_026
end
function M.ensure_storage() return state() end
local function get_anchor(id)
  if not id then return nil end
  local e=game.get_entity_by_unit_number(id)
  if e and e.valid and e.name==ANCHOR then return e end
end
local function destroy_anchors(run)
  for _,id in ipairs(run.anchor_ids or {}) do
    local entity=get_anchor(id)
    if entity then entity.destroy() end
  end
end
function M.clear(player)
  local s=state()
  local run=s.runs[player.index]
  if not run then
    player.print("[EM 25kV probe] no active test for this player")
    return
  end
  destroy_anchors(run)
  s.runs[player.index]=nil
  player.print("[EM 25kV probe] cleared both test anchors and their wire")
end
local function connector(e,create)
  return e.get_wire_connector(defines.wire_connector_id.pole_copper,create)
end
function M.start(player,power019)
  local s=state()
  if s.runs[player.index] then M.clear(player) end
  local masts=player.surface.find_entities_filtered{
    position=player.position,radius=MAX_RADIUS,name=MAST,force=player.force}
  local a,b,err=geo.pick_pair(masts,player.position,MAX_RADIUS,SPAN)
  if err then player.print("[EM 25kV probe] "..err);return end
  local created={}
  for _,mast in ipairs({a,b}) do
    local face=power019.facing_at(mast)
    local tip=geo.tip(mast.position,face)
    if not tip then
      for _,ent in ipairs(created) do if ent.valid then ent.destroy() end end
      player.print("[EM 25kV probe] cannot project mast face "..tostring(face))
      return
    end
    -- Hidden electric poles are placed only on command, no native Undo join.
    local anchor=mast.surface.create_entity{
      name=ANCHOR,position=tip,force=mast.force,
      create_build_effect_smoke=false,raise_built=false,snap_to_grid=false}
    if not (anchor and anchor.valid and anchor.unit_number) then
      for _,ent in ipairs(created) do if ent.valid then ent.destroy() end end
      player.print("[EM 25kV probe] anchor creation failed; no test wire built")
      return
    end
    anchor.destructible=false
    created[#created+1]=anchor
  end
  local ca,cb=connector(created[1],true),connector(created[2],true)
  if not (ca and cb) then
    for _,ent in ipairs(created) do if ent.valid then ent.destroy() end end
    player.print("[EM 25kV probe] copper connector missing")
    return
  end
  if not ca.can_wire_reach(cb) then
    for _,ent in ipairs(created) do if ent.valid then ent.destroy() end end
    player.print("[EM 25kV probe] connector endpoints are out of reach")
    return
  end
  local linked=ca.connect_to(cb,true,defines.wire_origin.player)
  if not linked or not ca.is_connected_to(cb,defines.wire_origin.player) then
    for _,ent in ipairs(created) do if ent.valid then ent.destroy() end end
    player.print("[EM 25kV probe] game refused visible copper connection")
    return
  end
  s.runs[player.index]={
    surface_index=player.surface.index,force_name=player.force.name,
    mast_ids={a.unit_number,b.unit_number},
    anchor_ids={created[1].unit_number,created[2].unit_number}
  }
  local msg=string.format(
    "[EM 25kV probe] NATIVE player-origin copper linked. endpoints=(%.2f,%.2f) -> (%.2f,%.2f); net=%s/%s; contacts=%d/%d. Screenshot wire; /em-25kv-probe clear to undo test.",
    created[1].position.x,created[1].position.y,
    created[2].position.x,created[2].position.y,
    tostring(ca.network_id),tostring(cb.network_id),
    ca.connection_count,cb.connection_count)
  player.print(msg);log(msg)
end
function M.status(player)
  local run=state().runs[player.index]
  if not run then player.print("[EM 25kV probe] no active test");return end
  local a,b=get_anchor(run.anchor_ids[1]),get_anchor(run.anchor_ids[2])
  if not (a and b) then
    player.print("[EM 25kV probe] anchor missing; run /em-25kv-probe clear")
    return
  end
  local ca,cb=connector(a,false),connector(b,false)
  local ok=ca and cb and ca.is_connected_to(cb,defines.wire_origin.player)
  local msg=string.format(
    "[EM 25kV probe] visible-connection=%s, endpoints=%s/%s, network=%s/%s, wire-count=%s/%s; AC voltage NOT simulated",
    tostring(not not ok),tostring(a.unit_number),tostring(b.unit_number),
    tostring(ca and ca.network_id),tostring(cb and cb.network_id),
    tostring(ca and ca.connection_count),tostring(cb and cb.connection_count))
  player.print(msg);log(msg)
end
function M.on_mast_removed(mast)
  if not (mast and mast.valid and mast.name==MAST and mast.unit_number) then return end
  local s=state()
  for player_index,run in pairs(s.runs) do
    if run.mast_ids[1]==mast.unit_number or run.mast_ids[2]==mast.unit_number then
      destroy_anchors(run)
      s.runs[player_index]=nil
      log("[EM 25kV probe] cleared native-wire test after mast removal")
    end
  end
end
function M.command(event,power019)
  local player=event.player_index and game.get_player(event.player_index)
  if not (player and player.valid) then
    log("[EM 25kV probe] run command in-game as a player")
    return
  end
  local action=string.match(event.parameter or "start","^%s*(%S+)") or "start"
  if action=="start" then M.start(player,power019)
  elseif action=="status" then M.status(player)
  elseif action=="clear" then M.clear(player)
  else player.print("[EM 25kV probe] /em-25kv-probe start | status | clear")
  end
end
return M
