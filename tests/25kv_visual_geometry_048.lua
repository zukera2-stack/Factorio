package.path='./ElectrifiedMainline/?.lua;'..package.path
local info_file=assert(io.open('ElectrifiedMainline/info.json'))
local version_text=info_file:read('*a')
local axis_version=version_text:find('"version": "0.1.56"',1,true)~=nil or version_text:find('"version": "0.1.57"',1,true)~=nil or version_text:find('"version": "0.1.58"',1,true)~=nil or version_text:find('"version": "0.1.59"',1,true)~=nil or version_text:find('"version": "0.1.60"',1,true)~=nil or version_text:find('"version": "0.1.61"',1,true)~=nil or version_text:find('"version": "0.1.62"',1,true)~=nil
info_file:close()
local geo=require('scripts.catenary_visual_geometry_045')
local art=require('scripts.catenary_art_030')
local technical=require('scripts.technical_network_046')
technical.span_state=function() return 'connected' end
local layout=require('scripts.mast_visual_034')
local function near(a,b) assert(math.abs(a-b)<1e-6,tostring(a)..' ~= '..tostring(b)) end
local function P(x,y) return {x=x,y=y} end
local function point(a,b) near(a.x,b.x);near(a.y,b.y) end
local expected={east={360,203,139},northeast={384,207,143},southeast={354,186,122},
 south={369,137,73},southwest={180,192,128},west={144,201,137},
 northwest={161,191,127},north={135,128,64}}
local names={layout.STANDARD,layout.SHORT_NORTH}
local function want(pos,name,face,k)
 local p=expected[face]
 local s=name==layout.STANDARD and -3.375 or -0.51125
 return P(pos.x+(p[1]-256)/64,pos.y+s+(p[k]-192)/64)
end
local n=0
for _,name in ipairs(names) do for face in pairs(expected) do
 local p=P(12.5,-37.5)
 local v=geo.points(p,name,face)
 point(v.contact,want(p,name,face,2));point(v.messenger,want(p,name,face,3))
 n=n+1
end end
assert(n==16)
for _,b in ipairs({P(12,0),P(0,12),P(-12,0),P(0,-12),P(8,8),P(-8,8)}) do
 for _,f in ipairs({art.geometry,art.curve_geometry}) do
  local a,ma,mb=P(0,0),P(0,-1),P(b.x,b.y-1)
  local g=assert(f(a,b,ma,mb))
  point(g.contact(0),a);point(g.contact(1),b)
  point(g.messenger(0),ma);point(g.messenger(1),mb)
  local c,m=g.contact(.5),g.messenger(.5)
  assert(m.y<c.y)
  if math.abs(b.x)/g.len>=.25 then near(c.x,m.x) else assert(m.x>c.x) end
 end
end
assert(art.curve_geometry(P(0,0),P(32,0),P(0,-1),P(32,-1)))
assert(not art.curve_geometry(P(0,0),P(37,0),P(0,-1),P(37,-1)))
assert(not art.geometry(P(0,0),P(37,0),P(0,-1),P(37,-1)))
storage={};defines={wire_connector_id={pole_copper=5},wire_origin={player=1}}
local eid=100;local entities={};local objects={};local order={};local surface={index=1};local force={name='player'}
local function connector()
 local c={real_connections={},connected={}}
 function c.can_wire_reach(other) return true end
 function c.is_connected_to(other,origin) return c.connected[other]==true end
 function c.connect_to(other,preserve,origin) c.connected[other]=true;return true end
 function c.disconnect_from(other,origin) c.connected[other]=nil;return true end
 return c
end
function surface.create_entity(args)
 eid=eid+1
 local e={unit_number=eid,name=args.name,position=args.position,surface=surface,force=force,valid=true,con=connector()}
 function e.get_wire_connector(id,create) return e.con end
 function e.destroy() e.valid=false;entities[e.unit_number]=nil end
 entities[eid]=e;return e
end
local function parent(id,name,pos) entities[id]={unit_number=id,name=name,position=pos,surface=surface,force=force,valid=true} end
rendering={}
function rendering.draw_sprite(args)
 if args.sprite and args.sprite:find("em-25kv-",1,true) then assert(args.render_layer=="wires","050 wire must draw above train") end
 local ob={id=#order+1,valid=true,args=args}
 function ob.destroy() ob.valid=false end
 objects[ob.id]=ob;order[#order+1]=ob;return ob
end
function rendering.get_object_by_id(id) return objects[id] end
game={get_entity_by_unit_number=function(id) return entities[id] end}
local function node(id,name,face,p)
 return {id=id,x=p.x,y=p.y,name=name,face=face,rail_adjacent=true,rail_id=id+10,surface_index=1,force_name='player'}
end
for _,name in ipairs(names) do for face in pairs(expected) do
 local other=name==names[1] and names[2] or names[1]
 local a,b=P(0,0),P(8,4)
 parent(1,name,a);parent(2,other,b)
 local g={nodes={[1]=node(1,name,face,a),[2]=node(2,other,'west',b)},edges={['1:2']={a=1,b=2,kind='contact',corner=true}}}
 -- 056 requires an explicit rail-axis route from its planner. Exercise both
 -- rejection of an unqualified edge and unchanged rendering of a qualified edge.
 if axis_version then
  art.sync(g);assert(art.ensure_storage().stats.drawn==0)
  assert(art.inspect_pair(g,1,2)=='no-axis-route')
  g.edges['1:2'].axis=true
  g.edges['1:2'].axis_length=math.sqrt(80)
 end
 local start=#order
 art.sync(g);assert(art.ensure_storage().stats.drawn==1 and next(art.ensure_storage().helpers)==nil)
 local groups={contact={},messenger={},dropper={}}
 for i=start+1,#order do
  local args=order[i].args;local kind=args.sprite:match('em%-25kv%-(%a+)%-043')
  table.insert(groups[kind],args)
 end
 local function ends(args)
  local t=args.orientation*2*math.pi; local r=args.x_scale*128/64
  return P(args.target.x-math.cos(t)*r,args.target.y-math.sin(t)*r),P(args.target.x+math.cos(t)*r,args.target.y+math.sin(t)*r)
 end
 for _,k in ipairs({'contact','messenger'}) do
  local f=groups[k];assert(#f>=2)
  local v=select(1,ends(f[1]));local w=select(2,ends(f[#f]))
  local j=k=='contact' and 2 or 3
  point(v,want(a,name,face,j));point(w,want(b,other,'west',j))
 end
 assert(#groups.dropper>=2 and art.inspect_pair(g,1,2)=='drawn')
 local row=art.ensure_storage().draws['1:2']
 local p=P((row.contact_a.x+row.contact_b.x)/2,(row.contact_a.y+row.contact_b.y)/2)
 assert(art.contact_at(1,'player',p).distance<1e-6)
 assert(not art.contact_at(2,'player',p) and not art.contact_at(1,'enemy',p))
 assert(not art.contact_at(1,'player',P(p.x+100,p.y+100)))
 local ci=math.min(row.contact_pieces,math.floor(.5*row.contact_pieces)+1)
 local ob=objects[row.ids[ci]]
 ob.visible=false;assert(not art.contact_at(1,'player',p));ob.visible=true
 ob.valid=false;assert(not art.contact_at(1,'player',p));ob.valid=true
 art.mark_dirty();assert(not art.contact_at(1,'player',p))
 local old=#order;art.sync(g);assert(#order==old)
 assert(art.contact_at(1,'player',p))
 -- The art renderer must not create an electric helper, even with no wires.
 assert(eid==100)
 g.edges={};art.sync(g)
 assert(art.inspect_pair(g,1,2)=='no-contact-edge' and not art.contact_at(1,'player',p))
 for i=start+1,#order do assert(not order[i].valid) end
end end
print('048 PASS: 16 independent pixel/render endpoint pairs; six directions, chord, limits, cleanup, calibration independence')
