local function ck(x,m)if not x then error('[BUS FAIL] '..m) end end
local function make(s,n,x,y,o)
 local p={name=n,position={x=x,y=y},force='player',raise_built=true};for k,v in pairs(o or {})do p[k]=v end
 local e=s.create_entity(p);ck(e and e.valid,'create '..n);return e
end
local function snap(e)
 local b=remote.call('em088_train_energy','snapshot',e and e.unit_number)
 ck(math.abs(b.paid_J-b.original_paid_J)<.05,'ledger total');ck(not b.battery_enabled and not b.regen_enabled,'battery/regen disabled');return b
end
local function owner(b,id)for _,r in ipairs(b.owners)do if r.unit==id then return r end end;error('missing owner '..id)end
script.on_init(function()
 local s=game.create_surface('bus',{width=512,height=256});s.generate_with_lab_tiles=true;s.always_day=true
 for x=-100,100,64 do s.request_to_generate_chunks({x=x,y=0},2)end;s.force_generate_chunk_requests()
 for x=-100,100,2 do make(s,'em-high-speed-straight-rail',x,1,{direction=defines.direction.east})end
 for x=-81.5,79,20 do make(s,'em-35kv-catenary-pole',x,2.5)end
 make(s,'em-35kv-traction-substation',-20,9)
 local g=make(s,'electric-energy-interface',-20,13);g.electric_interface_mode=defines.electric_interface_mode.primary_output;g.electric_buffer_size=20000000;g.energy=20000000;g.power_usage=0;g.power_production=0;g.output_flow_limit=20000000/60;g.input_flow_limit=0
 local a=make(s,'em-electric-locomotive',0,1,{direction=defines.direction.west});local b=make(s,'em-electric-locomotive',7,1,{direction=defines.direction.west})
 ck(a.train.id==b.train.id,'initial join');storage.qa={a=a,b=b,g=g,aid=a.unit_number,bid=b.unit_number}
end)
script.on_event(defines.events.on_tick,function(ev)
 local t=ev.tick;local st=storage.qa;local a,b=st.a,st.b
 if t==120 then
  local z=snap(a);ck(#z.owners==2 and z.train_id==b.train.id,'joint membership');st.aj=owner(z,st.aid).loco_J;st.bj=owner(z,st.bid).loco_J;ck(st.aj>0 and st.bj>0,'both paid');st.old=z.train_id
  for _,side in ipairs({defines.rail_direction.front,defines.rail_direction.back})do local n=a.get_connected_rolling_stock(side);if n and n.unit_number==st.bid then st.side=side end end
  ck(st.side~=nil and a.disconnect_rolling_stock(st.side),'split refused');log('[BUS] pre-split '..st.aj..' '..st.bj)
 elseif t==180 then
  local x,y=snap(a),snap(b);ck(x.train_id~=y.train_id and #x.owners==1 and #y.owners==1,'split membership');ck(owner(x,st.aid).loco_J>=st.aj and owner(y,st.bid).loco_J>=st.bj,'history lost');ck(a.connect_rolling_stock(st.side),'rejoin refused');log('[BUS] split IDs '..x.train_id..' '..y.train_id)
 elseif t==240 then
  local z=snap(a);ck(#z.owners==2 and z.train_id==b.train.id,'rejoin membership');st.before=z.paid_J;st.removed=owner(z,st.bid).loco_J;log('[BUS] rejoined paid '..z.paid_J)
 elseif t==241 then game.server_save('bus-checkpoint')
 elseif t==300 then
  local z=snap(a);ck(#z.owners==2 and z.paid_J>=st.before,'checkpoint membership');st.removed=owner(z,st.bid).loco_J;ck(b.destroy{raise_destroy=true},'destroy');log('[BUS] remove credited history '..st.removed)
 elseif t==361 then
  local z=snap(a);ck(#z.owners==1 and z.retired_loco_J>=st.removed,'retire attribution');ck(z.legacy_paid_J==0,'unexpected legacy');local lab=game.surfaces['em-25kv-isolated-bridge-058'];local h=0;for _,e in ipairs(lab.find_entities_filtered{type='electric-energy-interface'})do h=h+e.energy end
  ck(math.abs(st.g.energy+h+z.paid_J-20000000)<100,'closed source conservation');log(string.format('[BUS] PASS paid=%.3f retired=%.3f remaining_source=%.3f hidden=%.3f',z.paid_J,z.retired_loco_J,st.g.energy,h));script.finish_test(true)
 end
end)
