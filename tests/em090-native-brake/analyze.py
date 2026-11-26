"""Read exact native trace logs; observations only, never award energy."""
import pathlib as P, json, collections, math
root=P.Path(__file__).parent
rows={}
for p in (root/'runs').glob('*/stdout.log'):
 a=[];cut=0
 for line in p.read_text().splitlines():
  if '[CUT] ' in line:cut=float(line.split('[CUT] ')[1]);continue
  if '[TRACE] ' not in line:continue
  t,v,j,r,s,w,x,h,loss,i=map(float,line.split('[TRACE] ')[1].split());a.append(dict(t=int(t),v=v,J=j,r=int(r),state=int(s),w=w,x=x,health=h,loss=loss,id=int(i),cons=20e6-j-cut,K=.5*w*3600*v*v))
 m=max(a,key=lambda x:x['v']);decel=[(o,n) for o,n in zip(a,a[1:]) if o['v']-n['v']>1e-8];counts=collections.Counter(n['r'] for o,n in decel)
 rows[p.parent.name]={'peak':m,'peak_ratio':m['K']/m['cons'],'decel':dict(counts),'max_decel':max((o['v']-n['v'],n['t'],n['r'],n['state']) for o,n in decel),'completion': 'Test passed at tick' in p.read_text()}
for p in (root/'fullruns').glob('*/stdout.log'):
 a=[]
 for l in p.read_text().splitlines():
  if '[FULLTRACE] ' not in l:continue
  t,v,r,s,w,paid,dis,fuel,h,i,x=map(float,l.split('[FULLTRACE] ')[1].split());a.append(dict(t=int(t),v=v,r=int(r),state=int(s),w=w,paid=paid,dis=dis,fuel=fuel,helpers=int(h),id=int(i),x=x,cons=paid+dis-fuel,K=.5*w*3600*v*v))
 m=max(a,key=lambda x:x['v']);decel=[(o,n) for o,n in zip(a,a[1:]) if o['v']-n['v']>1e-8];rows[p.parent.name]={'peak':m,'peak_ratio':m['K']/m['cons'],'decel':dict(collections.Counter(n['r'] for o,n in decel)),'max_decel':max((o['v']-n['v'],n['t'],n['r'],n['state']) for o,n in decel),'final':a[-1],'completion':'Test passed at tick' in p.read_text()}
assert len(rows)==10 and all(x['completion'] for x in rows.values())
assert rows['station2000']['peak_ratio']>2.5 and rows['onboard-move']['peak_ratio']>2.8
assert rows['coast2000']['decel'].get(2,0)==0
assert rows['collision2000']['max_decel'][2]==2 and rows['collision2000']['max_decel'][0]>1
assert rows['onboard-move']['final']['x']==-696 and rows['onboard-outage']['final']['x']==-696
(root/'observations.json').write_text(json.dumps(rows,indent=2));print(json.dumps(rows,indent=2))
