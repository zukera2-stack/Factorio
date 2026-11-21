-- EM067 real Factorio 2.1.24, 48-substation 6x20MW / 42 sinks native regression.
local RATE=20000000/60
local substations,sinks,sources,lines={},{},{},{}
local start_tick
local function make(surface,name,x,y,extra)
 local args={name=name,position={x,y},force='player',raise_built=true}
 for k,v in pairs(extra or {}) do args[k]=v end
 local e=surface.create_entity(args)
 assert(e and e.valid,'cannot create '..name..' at '..x..','..y)
 return e
end
local function eei(s,x,mode)
 local e=make(s,'electric-energy-interface',x,13)
 e.electric_interface_mode=defines.electric_interface_mode[mode]
 e.electric_buffer_size=1000000000
 e.power_usage=0;e.power_production=mode=='primary_output' and RATE or 0
 e.input_flow_limit=mode=='secondary_input' and RATE or 0
 e.output_flow_limit=mode=='primary_output' and RATE or 0;e.energy=0
 return e
end
local function setup()
 local s=game.create_surface('em067-long-mainline',{width=2048,height=128})
 s.generate_with_lab_tiles=true
 for x=-992,992,96 do s.request_to_generate_chunks({x,0},2) end
 s.force_generate_chunk_requests()
 for x=-943,943,2 do make(s,'em-high-speed-straight-rail',x,1,{direction=defines.direction.east}) end
 for x=-941.5,938.5,20 do lines[#lines+1]=make(s,'em-35kv-catenary-pole',x,2.5) end
 for i=1,48 do
   local x=-940+(i-1)*40
   substations[i]=make(s,'em-35kv-traction-substation',x,9)
   if (i-1)%8==0 then sources[i]=eei(s,x,'primary_output')
   else sinks[i]=eei(s,x,'secondary_input') end
 end
 log('[EM067 48] setup six 20MW sources, 42 sinks, 48 substations')
end
local function sum()
 local total,lo,hi,count=0,math.huge,0,0
 for i=1,48 do
  local e=sinks[i]
  if e and e.input_flow_limit>0 then
    count=count+1;total=total+e.energy
    lo=math.min(lo,e.energy);hi=math.max(hi,e.energy)
  end
 end
 return total,lo,hi,count
end
local function connectivity()
 local factory={}
 for i,s in ipairs(substations) do
  local id=s.electric_network_id
  assert(id,'factory net missing '..i)
  assert(not factory[id],'factory grids shorted '..i)
  factory[id]=true
 end
 local line=lines[1].electric_network_id
 for i=2,#lines do assert(lines[i].electric_network_id==line,'catenary split '..i) end
 assert(not factory[line],'factory/catenary short')
end
script.on_event(defines.events.on_tick,function(ev)
 if not start_tick then start_tick=ev.tick;setup() end
 local t=ev.tick-start_tick
 if t==90 then connectivity() end
 if t==240 then
   connectivity()
   local total,lo,hi,n=sum()
   assert(n==42 and lo>500000 and hi/lo<2.2 and total>340000000 and total<490000000,
          string.format('unfair 48: n=%d total=%.0f lo=%.0f hi=%.0f',n,total,lo,hi))
   log(string.format('[EM067 48 STAGE1 PASS] total=%.0f lo=%.0f hi=%.0f',total,lo,hi))
   storage.before={}
   for i=1,48 do if sinks[i] then storage.before[i]=sinks[i].energy end end
   for i=1,48 do if sinks[i] and i%2==0 then sinks[i].input_flow_limit=0 end end
 end
 if t==600 then
   connectivity()
   local added,lo,hi,n=0,math.huge,0,0
   for i=1,48 do
     local e=sinks[i]
     if e then
       local d=e.energy-storage.before[i]
       if i%2==1 then n=n+1;added=added+d;lo=math.min(lo,d);hi=math.max(hi,d)
       else assert(d<600000,'disabled sink still charges '..i..': '..d) end
     end
   end
   assert(n==18 and lo>200000 and hi/lo<2.3 and added>590000000 and added<750000000,
          string.format('reroute fail n=%d added=%.0f lo=%.0f hi=%.0f',n,added,lo,hi))
   log(string.format('[EM067 48 REROUTE PASS] recipients=%d added=%.0f lo=%.0f hi=%.0f',n,added,lo,hi))
   for _,e in pairs(sources) do
     e.electric_interface_mode=defines.electric_interface_mode.secondary_input
     e.power_production=0;e.power_usage=0;e.input_flow_limit=RATE;e.output_flow_limit=0
   end
   storage.outage_total=0
   for _,e in pairs(sinks) do storage.outage_total=storage.outage_total+e.energy end
 end
 if t==900 then
   connectivity()
   local post=0;for _,e in pairs(sinks) do post=post+e.energy end
   assert(post<=storage.outage_total+27000000,'unaccounted energy after outage: '..(post-storage.outage_total))
   log(string.format('[EM067 48 PASS] complete 900 ticks, post-outage added=%.0f J',post-storage.outage_total))
 end
end)
