-- EM072-C5 research companion to em-c4-loco-mounted-probe.
-- Only observes native GUI openings / train composition. Not a production mod.
-- Does not modify rolling stock, schedule, energy, or engine state.
local lanes={solo=0,vanilla=40,em0=80,em1=120,em2=160,em4=200,remove=240,change=280,multi=320,zero=360,em2drive=400,multi_owner_removed=440,late=480}
local function rolling(e)
  if not (e and e.valid) then return false end
  return e.type=="locomotive" or e.type=="cargo-wagon" or e.type=="fluid-wagon"
end
local function case_at(x)
  for label,lane_x in pairs(lanes) do
    if math.abs(x-lane_x)<3 then return label end
  end
  return "unknown"
end
local function snapshot(entity)
  if not rolling(entity) then return "entity=none|train_id=none" end
  local t=entity.train
  if not (t and t.valid) then return "entity="..entity.name.."|train_id=none" end
  local helpers,locos,motors,real,stock=0,0,0,0,{}
  for _,e in ipairs(t.carriages) do
    local is_helper=e.name:find("^em%-c4%-technical%-booster%-")~=nil
    if is_helper then helpers=helpers+1 end
    if e.type=="locomotive" and not is_helper then real=real+1 end
    if e.name=="em-c4-motor-cargo" or e.name=="em-c4-motor-fluid" then motors=motors+1 end
    stock[#stock+1]=e.name
  end
  locos=#t.locomotives.front_movers+#t.locomotives.back_movers
  return "entity="..entity.name..
    "|unit="..tostring(entity.unit_number)..
    "|case="..case_at(entity.position.x)..
    "|train_id="..t.id..
    "|native_carriages="..#t.carriages..
    "|real_locomotives="..real..
    "|native_locomotives="..locos..
    "|technical_helpers="..helpers..
    "|motor_wagons="..motors..
    "|native_stock="..table.concat(stock,",")
end
local function observe(kind,player,entity,gui_type)
  log("EMC5|"..kind.."|tick="..game.tick..
      "|player="..player.index..
      "|gui_type="..tostring(gui_type).."|"..snapshot(entity))
end
script.on_event(defines.events.on_gui_opened,function(event)
  local p=game.get_player(event.player_index)
  if p then observe("gui_open",p,event.entity,event.gui_type) end
end)
script.on_event(defines.events.on_gui_closed,function(event)
  local p=game.get_player(event.player_index)
  if p then observe("gui_close",p,event.entity,event.gui_type) end
end)
commands.add_command("em-c5-inspect","Log selected rolling stock without changing the train",function(cmd)
  if not cmd.player_index then return end
  local p=game.get_player(cmd.player_index)
  if not p then return end
  local e=p.selected
  if not rolling(e) then
    p.print("EMC5: select a visible locomotive or wagon first.")
    return
  end
  observe("manual_inspect",p,e,"selected")
  p.print("EMC5: train composition logged to factorio-current.log. This does NOT prove native GUI invisibility.")
end)
commands.add_command("em-c5-case","Teleport the player to a C4 test lane: em2, change, vanilla, solo, etc.",function(cmd)
  if not cmd.player_index then return end
  local p=game.get_player(cmd.player_index)
  if not p then return end
  local x=lanes[cmd.parameter or ""]
  if not x then
    p.print("EMC5: unknown lane. Choose em2, change, vanilla, solo, multi, late, etc.")
    return
  end
  -- Teleport affects the player only; never changes rolling stock or trains.
  local list=p.surface.find_entities_filtered{
    area={{x-2,-360},{x+2,360}},
    name={"em-c4-real-electric","em-c4-motor-cargo","em-c4-motor-fluid","locomotive"}
  }
  table.sort(list,function(a,b)
    if a.name=="em-c4-real-electric" and b.name~="em-c4-real-electric" then return true end
    if b.name=="em-c4-real-electric" and a.name~="em-c4-real-electric" then return false end
    return a.position.y<b.position.y
  end)
  local found=list[1]
  if not found then
    p.print("EMC5: no test stock in lane; open a fresh disposable C4 save and allow setup to finish.")
    return
  end
  local pos=p.surface.find_non_colliding_position("character",{x=found.position.x+4,y=found.position.y},10,0.5)
  if pos and p.teleport(pos,found.surface) then
    p.print("EMC5: at "..(cmd.parameter or "").."; select visible train, open native GUI, capture screenshot.")
    observe("case_jump",p,found,"teleport")
  else
    p.print("EMC5: safe player teleport was not possible; no train changed.")
  end
end)
