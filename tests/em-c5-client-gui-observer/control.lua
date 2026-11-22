-- EM072-C5 COMPACT HUMAN GUI fixture, not the 13-lane C4 robot benchmark.
-- Separate C5 companion enabled => C4 automatically suppresses its large setup.
-- Disposable map only. No real EM070 Joules, no production electric traction.
local X=12
local function is_rolling(e)
  return e and e.valid and (e.type=="locomotive" or e.type=="cargo-wagon" or e.type=="fluid-wagon")
end
local function snapshot(e)
  if not is_rolling(e) then return "entity=none|train_id=none" end
  local t=e.train
  if not (t and t.valid) then return "entity="..e.name.."|train_id=none" end
  local helpers,locos,motors,real,stock=0,0,0,0,{}
  for _,v in ipairs(t.carriages) do
    local hidden=v.name:find("^em%-c4%-technical%-booster%-")~=nil
    if hidden then helpers=helpers+1 end
    if v.type=="locomotive" and not hidden then real=real+1 end
    if v.name=="em-c4-motor-cargo" or v.name=="em-c4-motor-fluid" then motors=motors+1 end
    stock[#stock+1]=v.name
  end
  locos=#t.locomotives.front_movers+#t.locomotives.back_movers
  return "entity="..e.name..
    "|unit="..tostring(e.unit_number)..
    "|case=compact"..
    "|train_id="..t.id..
    "|native_carriages="..#t.carriages..
    "|real_locomotives="..real..
    "|native_locomotives="..locos..
    "|technical_helpers="..helpers..
    "|motor_wagons="..motors..
    "|native_stock="..table.concat(stock,",")
end
local function observe(kind,player,entity,gui)
  log("EMC5|"..kind.."|tick="..game.tick..
      "|player="..player.index..
      "|gui_type="..tostring(gui).."|"..snapshot(entity))
end
script.on_event(defines.events.on_gui_opened,function(ev)
  local p=game.get_player(ev.player_index)
  if p then observe("gui_open",p,ev.entity,ev.gui_type) end
end)
script.on_event(defines.events.on_gui_closed,function(ev)
  local p=game.get_player(ev.player_index)
  if p then observe("gui_close",p,ev.entity,ev.gui_type) end
end)
commands.add_command("em-c5-inspect","Log selected C5 train composition",function(cmd)
  if not cmd.player_index then return end
  local p=game.get_player(cmd.player_index)
  if not p then return end
  if not is_rolling(p.selected) then
    p.print("C5: choose a real visible locomotive or wagon first.")
    return
  end
  observe("manual_inspect",p,p.selected,"selected")
  p.print("C5: train composition recorded in factorio-current.log; screenshot of GUI still needed.")
end)
local function make_scene()
  local surface=game.surfaces[1]
  surface.request_to_generate_chunks({X,0},2)
  surface.force_generate_chunk_requests()
  local n=0
  -- Just 29 straight rail pieces, one train and zero automatic drive.
  for y=-24,32,2 do
    local rail=surface.create_entity{
      name="straight-rail",position={x=X,y=y},
      force="player",direction=defines.direction.north}
    assert(rail and rail.valid,"C5 failed to build short rail at y="..y)
    n=n+1
  end
  local loco=surface.create_entity{name="em-c4-real-electric",position={x=X,y=0},force="player",direction=defines.direction.north}
  local cargo=surface.create_entity{name="em-c4-motor-cargo",position={x=X,y=7},force="player",direction=defines.direction.north}
  local fluid=surface.create_entity{name="em-c4-motor-fluid",position={x=X,y=14},force="player",direction=defines.direction.north}
  assert(loco and cargo and fluid,"C5 compact visible train creation failed")
  storage.c5_compact={loco=loco,cargo=cargo,fluid=fluid}
  log("EMC5|compact_created|rails="..n.."|x="..X.."|visible=3|span=14|train_id="..loco.train.id)
end
local function mount()
  local s=storage.c5_compact
  assert(s and s.loco and s.loco.valid and s.cargo and s.fluid,"C5 visible train missing")
  local t=s.loco.train
  assert(t and t.valid and t.speed==0,"C5 must mount only at full stop")
  local detached=s.loco.disconnect_rolling_stock(defines.rail_direction.back)
  assert(detached,"C5 could not temporarily decouple the stopped loco")
  local helper=s.loco.surface.create_entity{
    name="em-c4-technical-booster-1000",
    position={x=X,y=3.5},force="player",direction=defines.direction.north}
  assert(helper and helper.valid,"C5 technical module placement failed")
  helper.minable_flag=false
  helper.destructible=false
  -- Deliberately ZERO J. This tests native GUI composition, NOT electric traction.
  -- C4 lab's artificial 10 MJ fuel is never seeded in this human UI case.
  local same=helper.train and s.loco.train and helper.train.id==s.loco.train.id
  assert(same,"C5 native helper did not join visible train")
  local full=s.loco.train
  local helpers,real,motors=0,0,0
  for _,e in ipairs(full.carriages) do
    if e.name=="em-c4-technical-booster-1000" then helpers=helpers+1 end
    if e.name=="em-c4-real-electric" then real=real+1 end
    if e.name=="em-c4-motor-cargo" or e.name=="em-c4-motor-fluid" then motors=motors+1 end
  end
  assert(#full.carriages==4 and helpers==1 and real==1 and motors==2,"C5 compact train composition mismatch")
  log("EMC5|compact_ready|tick="..game.tick.."|"..snapshot(s.loco)..
      "|helper_remaining_J="..tostring(helper.burner.remaining_burning_fuel))
  for _,p in pairs(game.connected_players) do
    if p.character and p.character.valid then
      local pos=p.surface.find_non_colliding_position("character",{X+5,0},10,0.5)
      if pos then p.teleport(pos,s.loco.surface) end
    end
    p.print("C5: one train is just next to you. Click the REAL locomotive, open its normal train GUI, take a screenshot. No commands required.")
  end
end
script.on_event(defines.events.on_tick,function(ev)
  if ev.tick==2 then make_scene() end
  if ev.tick==3 then mount() end
end)
