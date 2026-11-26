local function ck(x,m) if not x then error('[EM087D WATCH FAIL] '..m) end end
script.on_init(function()
 local s=game.create_surface('em087d-watch',{width=128,height=128});s.generate_with_lab_tiles=true;s.request_to_generate_chunks({0,0},1);s.force_generate_chunk_requests()
 local e=s.create_entity{name='em-high-speed-straight-rail',position={0,1},force='player',direction=defines.direction.east,raise_built=true}
 ck(e and e.valid,'rail');local id=e.unit_number
 local r,u,k=script.register_on_object_destroyed(e);local r2=script.register_on_object_destroyed(e)
 ck(r==r2 and u==id,'duplicate registration or identity')
 storage.watch={entity=e,registration=r,unit=id,target=k,events=0,raised=0}
 log('[EM087D WATCH] registered unit='..id..' reg='..r)
end)
script.on_event(defines.events.script_raised_destroy,function(e)
 if storage.watch and e.entity.valid and e.entity.unit_number==storage.watch.unit then storage.watch.raised=storage.watch.raised+1 end
end)
script.on_event(defines.events.on_object_destroyed,function(e)
 local w=storage.watch
 if w and e.registration_number==w.registration then
  ck(e.useful_id==w.unit and e.type==w.target,'event identity')
  w.events=w.events+1;w.event_tick=e.tick
  log('[EM087D WATCH] detected tick='..e.tick..' destruction_tick='..w.cut..' unit='..e.useful_id)
 end
end)
script.on_event(defines.events.on_tick,function(e)
 local w=storage.watch
 if e.tick==5 then game.reload_script() end
 if e.tick==10 then w.cut=e.tick;ck(w.entity.destroy{raise_destroy=false},'silent destruction refused') end
 if e.tick==13 then
  ck(w.events==1 and w.raised==0 and w.event_tick>=w.cut and w.event_tick<=w.cut+1,'silent event contract')
  log('[EM087D WATCH PASS] silent rail cut detected with native registration after reload; latency_ticks='..(w.event_tick-w.cut));script.finish_test(true)
 end
end)
