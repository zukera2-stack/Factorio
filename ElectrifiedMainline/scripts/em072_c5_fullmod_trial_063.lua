-- EM072-C5 full-mod user GUI probe. Runs ONLY on explicit console command.
-- Existing on_tick/Undo/Redo/control.lua power event ownership is untouched.
local prefix="EMFULLC5|"
local function report(event,entity,player)
  if not (entity and entity.valid) then return "none" end
  local train=entity.train
  if not (train and train.valid) then return "entity="..entity.name.."|train=none" end
  local helpers,real,motors=0,0,0
  local names={}
  for _,e in ipairs(train.carriages) do
    names[#names+1]=e.name
    if string.find(e.name,"^em%-c5%-technical%-booster%-") then helpers=helpers+1 end
    if e.name=="em-electric-locomotive" then real=real+1 end
    if e.name=="em-motor-cargo-wagon" or e.name=="em-motor-fluid-wagon" then motors=motors+1 end
  end
  local locos=#train.locomotives.front_movers+#train.locomotives.back_movers
  return "entity="..entity.name.."|train_id="..train.id..
    "|native_carriages="..#train.carriages..
    "|real_EM_locomotives="..real..
    "|native_locomotives="..locos..
    "|helpers="..helpers..
    "|motor_wagons="..motors..
    "|names="..table.concat(names,",")
end

local function say(player,text)
  player.print("[EM 0.1.63 TEST] "..text)
  log(prefix..text)
end

commands.add_command("em-test-kit","Give REAL mod items for a temporary 0.1.63 test save.",function(e)
  local p=e.player_index and game.get_player(e.player_index)
  if not p or not p.valid then return end
  local kit={
    {"em-high-speed-rail",100},
    {"em-35kv-catenary-pole",12},
    {"em-35kv-catenary-pole-north",12},
    {"em-35kv-traction-substation",4},
    {"em-electric-locomotive",2},
    {"em-motor-cargo-wagon",2},
    {"em-motor-fluid-wagon",2},
    {"em-rail-replacement-planner",1}
  }
  local ok=0
  for _,rec in ipairs(kit) do
    if prototypes.item[rec[1]] then
      local got=p.insert{name=rec[1],count=rec[2]}
      ok=ok+1
      log(prefix.."kit|item="..rec[1].."|requested="..rec[2].."|inserted="..got)
    else
      say(p,"Missing actual mod item "..rec[1])
    end
  end
  say(p,"Actual HSR, masts, substation, locomotive, motor wagons and replacement planner granted ("..ok.."/"..#kit.." types). No technical helper item.")
end)

local function create_scene(player)
  if storage.em_c5_full_scene and storage.em_c5_full_scene.valid then
    return false,"Scene already exists in this test save; use it or create a new disposable world."
  end
  local s=player.surface
  local x=math.floor((player.position.x+14)/2)*2
  local y=math.floor(player.position.y/2)*2
  s.request_to_generate_chunks({x=x,y=y},3)
  s.force_generate_chunk_requests()
  local stock={}
  local created={}
  local function put(name,px,py,direction)
    local e=s.create_entity{
      name=name,position={x=px,y=py},
      direction=direction or defines.direction.north,force=player.force,
      raise_built=true
    }
    if e and e.valid then created[#created+1]=e end
    return e
  end
  -- 29 native FULL-MOD HSR segments, not vanilla rails and no giant benchmark.
  for delta=-24,32,2 do
    if not put("em-high-speed-straight-rail",x,y+delta) then
      -- Do not tear down the player's existing entities or other mod content.
      for i=#created,1,-1 do
        if created[i] and created[i].valid then created[i].destroy() end
      end
      return false,"HSR segment blocked at y-offset "..delta.."; new empty map / clear ground needed."
    end
  end
  local loco=put("em-electric-locomotive",x,y)
  local cargo=put("em-motor-cargo-wagon",x,y+7)
  local fluid=put("em-motor-fluid-wagon",x,y+14)
  if not (loco and cargo and fluid) then
    return false,"Actual EM locomotive or motor wagon blocked. Please send factorio-current.log."
  end
  stock={loco,cargo,fluid}
  -- Show actual placeable 25 kV entities on same new map, but do not
  -- imply locomotive receives or pays Joules from the bridge.
  local mast=put("em-35kv-catenary-pole",x+5,y-10)
  local mast_n=put("em-35kv-catenary-pole-north",x+5,y+10)
  local substation=put("em-35kv-traction-substation",x+12,y-2)
  local native=loco.train
  if not (native and native.valid and native.speed==0) then
    return false,"Real electric locomotive not stopped or no native train."
  end
  local detached=loco.disconnect_rolling_stock(defines.rail_direction.back)
  if not detached then
    return false,"Native rolling-stock decoupling failed; cannot test hidden helper."
  end
  local helper=put("em-c5-technical-booster-1000",x,y+3.5)
  if not (helper and helper.valid) then
    return false,"Native 1MW hidden locomotive creation failed."
  end
  helper.minable_flag=false
  helper.destructible=false
  -- No hidden energy seed, no fake 500 kW traction in this GUI test.
  local joined=helper.train and helper.train.valid and loco.train and loco.train.valid and helper.train.id==loco.train.id
  if not joined then
    return false,"Native 1MW helper was not physically coupled. Inspect log; GUI experiment FAIL."
  end
  storage.em_c5_full_scene={valid=true,loco=loco,cargo=cargo,fluid=fluid,helper=helper}
  local summary=report("compact_setup",loco,player)
  log(prefix.."compact_ready|"..summary.."|masts="..tostring(mast~=nil)..
    "|north_mast="..tostring(mast_n~=nil)..
    "|substation="..tostring(substation~=nil)..
    "|helper_J="..tostring(helper.burner.remaining_burning_fuel))
  local pos=s.find_non_colliding_position("character",{x=x+7,y=y},10,0.5)
  if pos and player.character and player.character.valid then player.teleport(pos,s) end
  say(player,"READY: short HSR line, real EM locomotive + 2 real motor wagons; hidden helper zero J. Masts and substation nearby. Open real locomotive GUI and screenshot.")
  return true
end

commands.add_command("em-test-scene","Build ONE full-mod HSR+25kV+EM train test next to player (new throwaway map ONLY).",function(e)
  local p=e.player_index and game.get_player(e.player_index)
  if not p then return end
  local ok,worked,message=pcall(create_scene,p)
  if not ok then
    say(p,"SCENE FAIL: "..tostring(worked))
  elseif not worked then
    say(p,"SCENE FAIL: "..tostring(message))
  end
end)

commands.add_command("em-test-train","Log true full-mod selected locomotive/wagon and native hidden helper counts.",function(e)
  local p=e.player_index and game.get_player(e.player_index)
  if not p then return end
  local stock=p.selected
  if not stock or not stock.valid then
    say(p,"Select a real train vehicle first.")
    return
  end
  local x=report("manual_inspect",stock,p)
  say(p,"manual_inspect|"..x)
end)

local M={}
function M.on_gui_opened(e)
  local p=e.player_index and game.get_player(e.player_index)
  if not p then return end
  local entity=e.entity
  if entity and entity.valid and (entity.type=="locomotive" or
       entity.type=="cargo-wagon" or entity.type=="fluid-wagon") then
    log(prefix.."gui_open|tick="..game.tick.."|gui_type="..
      tostring(e.gui_type).."|"..report("gui_open",entity,p))
  end
end
return M
