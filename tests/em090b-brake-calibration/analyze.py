"""Verify native trace results. No game state writes; all regen amounts hypothetical."""
from pathlib import Path
import collections, json, math, re
R=Path(__file__).resolve().parent
C=450

def trace(p,tag='TRACE'):
    return [list(map(float,l.split(f'[{tag}] ')[1].split())) for l in p.read_text().splitlines() if f'[{tag}] ' in l]
def ratios(p,full=False):
    a=trace(p,'FULLTRACE' if full else 'TRACE'); out=[]
    for x,y in zip(a,a[1:]):
        if full:
            v,vn,m=x[1],y[1],x[4]; debit=(y[5]+y[6]-y[7])-(x[5]+x[6]-x[7]); r=x[2]; stable=x[4]==y[4] and x[9]==y[9]
        else:
            v,vn,m=x[1],y[1],x[5]; debit=x[2]-y[2]; r=x[3]; stable=x[5]==y[5] and x[9]==y[9]
            if 'coast' in str(p) and y[0]>=121:continue
        if stable and vn>v+1e-8 and r in (1,3) and debit>0:
            out.append((debit/(m*(vn*vn-v*v)/2),int(y[0])))
    return out
training={p.parent.name:min(ratios(p)) for p in (R/'matrix-runs').glob('*/stdout.log')}
holdout={p.parent.name:min(ratios(p,full)) for full in (False,True) for p in (R/'holdout'/('full' if full else 'base')).glob('*/stdout.log')}
assert len(training)==8 and len(holdout)==10
assert min(x[0] for x in training.values())>2*C and min(x[0] for x in holdout.values())>C

a=trace(R/'matrix-runs/coast/stdout.log')
coast_err=[abs(max(0,x[1]-1/3000)*(1-.0075/3)-y[1]) for x,y in zip(a,a[1:]) if 123<=y[0]<=500 and y[1]>1e-5]
assert coast_err and max(coast_err)<1e-12
manual={}
for name,B in [('locoonly',20.001),('wagononly',20.001),('both',40),('bothbonus',80)]:
    a=trace(R/'matrix-runs'/name/'stdout.log'); err=[abs(x[1]-y[1]-B/3000) for x,y in zip(a,a[1:]) if x[3]==y[3]==2 and x[1]>y[1]>0]
    assert err and max(err)<2e-12
    manual[name]={'nominal_decel':B/3000,'intervals':len(err),'max_error':max(err)}
for n in ('','auto'):
    x=trace(R/'matrix-runs'/f'{n}locoonly'/'stdout.log');y=trace(R/'matrix-runs'/f'{n}wagononly'/'stdout.log')
    assert x==y,(n,'native trace differs')

cases={}
for p in (R/'runs').glob('*/stdout.log'):
    s=p.read_text(); name=p.parent.name; rows=[l.split('[EST] ')[1].split() for l in s.splitlines() if '[EST] ' in l]
    res=re.search(r'\[EST RESULT\] \S+ hypothetical=([\d.]+) actual=([\d.]+)',s)
    assert 'Test passed at tick' in s and res
    hypothetical,actual=map(float,res.groups());assert 0<=hypothetical<=actual+.05
    assert all(0<=float(x[1])<=2000000/60+.001 and float(x[1])<=float(x[2])+.001 for x in rows)
    assert abs(sum(float(x[1]) for x in rows)-hypothetical)<.001
    cases[name]={'actual_fuel_J':actual,'hypothetical_J':hypothetical,'max_per_tick_J':max(float(x[1]) for x in rows),'reasons':dict(collections.Counter(x[3] for x in rows))}
    if name in ('coast','starve','passive'): assert hypothetical==0
    if name=='cycle':assert s.count('[CYCLE STOP]')==3
    if name=='autocollision':
        a=trace(p); x,y=max(zip(a,a[1:]),key=lambda xy:xy[0][1]-xy[1][1]);r=next(q for q in rows if int(q[0])==int(y[0]));assert x[1]-y[1]>1 and float(r[1])==0 and '[DAMAGE]' in s
        cases[name]['collision']={'tick':int(y[0]),'v0':x[1],'v1':y[1],'grant_J':float(r[1])}
assert len(cases)==12
full={}
for p in (R/'fullruns').glob('*/stdout.log'):
    s=p.read_text(); rows=[l.split('[FEST] ')[1].split() for l in s.splitlines() if '[FEST] ' in l]; name=p.parent.name; last=rows[-1]
    assert 'Test passed at tick' in s
    hypot,actual=map(float,last[5:7]);assert 0<=hypot<=actual+.05
    assert all(0<=float(x[1])<=float(x[10].split('=')[1])/60+.001 and float(x[1])<=float(x[2])+.001 for x in rows)
    assert abs(sum(float(x[1]) for x in rows)-hypot)<.001
    full[name]={'estimated_fuel_J':actual,'hypothetical_J':hypot,'max_per_tick_J':max(float(x[1]) for x in rows),'B':last[7],'motorB':last[8],'friction':last[9],'capW':last[10],'reasons':dict(collections.Counter(x[3] for x in rows))}
    if name=='onboard-empty':assert hypot==actual==0
    else:assert hypot>0 and trace(p,'FULLTRACE')[-1][-1]==-696
assert len(full)==3
out={'training_min_C_by_case':training,'holdout_min_C_by_case':holdout,'coast_intervals':len(coast_err),'coast_max_error':max(coast_err),'manual':manual,'base_final':cases,'full_final':full}
(R/'observations.json').write_text(json.dumps(out,indent=2)+'\n');print(json.dumps(out,indent=2))
