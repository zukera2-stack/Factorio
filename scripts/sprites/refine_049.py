"""Development-only refinement of model_049; not game sprites.
Original geometry, 45-degree orthographic reference, 64 source px per tile.
"""
import argparse, math, json
from pathlib import Path
import numpy as np
import trimesh as tm
import model_049 as base

H_LONG=3.375+64/64-1.5
H_SHORT=.51125+55/64+1.5
WIRE=(H_LONG+H_SHORT)/2
Z_TOP=WIRE*math.sqrt(2)

def model():
    parts=[]
    def add(m,mat,g='body'):
        m.visual.face_colors=base.PALETTE[mat]
        parts.append((f'{g}_{len(parts):03d}',m,mat,g))
    def box(pos,dim,mat,g='body'):
        m=tm.creation.box(extents=dim);m.apply_translation(pos);add(m,mat,g)
    def rod(a,b,r,mat,g='body',n=12):
        add(tm.creation.cylinder(radius=r,segment=[a,b],sections=n),mat,g)
    for name,m,mat,g in base.make_model():
        if g in ('up','down','mask') or name in ('body_000','body_001'):continue
        m=m.copy();m.vertices[:,1]*=1.055;add(m,mat,g)
    sections=[(-3.02,.39,.78,1.22),(-2.88,.50,.66,1.40),(-2.72,.62,.57,1.59),(-2.53,.72,.53,1.73),(-2.30,.74,.53,1.77),(-1.60,.74,.53,1.77),(-.70,.74,.53,1.77),(1.83,.74,.53,1.77),(2.13,.73,.55,1.72),(2.35,.67,.58,1.61),(2.55,.60,.61,1.44),(2.75,.50,.66,1.20),(2.96,.38,.73,.96)]
    def loft(rings,mat,g='body'):
        v=[p for ring in rings for p in ring];n=len(rings[0]);f=[]
        for i in range(len(rings)-1):
            for j in range(n):
                a=i*n+j;b=i*n+(j+1)%n;c=b+n;d=a+n;f.extend([(a,b,c),(a,c,d)])
        for j in range(1,n-1):f.extend([(0,j+1,j),((len(rings)-1)*n,(len(rings)-1)*n+j,(len(rings)-1)*n+j+1)])
        m=tm.Trimesh(v,f,process=True);m.fix_normals();add(m,mat,g)
    def ring(y,w,lo,hi):
        return [(-w*.74,y,lo),(w*.74,y,lo),(w,y,lo+.16),(w,y,hi-.25),(w*.89,y,hi-.09),(w*.69,y,hi),(-w*.69,y,hi),(-w*.89,y,hi-.09),(-w,y,hi-.25),(-w,y,lo+.16)]
    loft([ring(*s) for s in sections],'silver')
    loft([[(-w-.002,y,hi-.25),(w+.002,y,hi-.25),(w*.89+.002,y,hi-.088),(w*.69,y,hi+.012),(-w*.69,y,hi+.012),(-w*.89-.002,y,hi-.088)] for y,w,lo,hi in sections],'roof')
    # Stripe bound to shell. Use fractional height between lower and upper edge.
    def stripe(y,w,lo,hi):
        rise=.17*min(1,max(0,(-y-.70)/.90))
        low=lo+.16+min(rise,max(0,hi-lo-.45))
        high=min(low+.22,hi-.25)
        return [(-w-.008,y,low),(w+.008,y,low),(w+.008,y,high),(-w-.008,y,high)]
    loft([stripe(*s) for s in sections if s[3]-s[2]>.41],'stripe','mask')
    for side in (-1,1):
        x=side*.756
        for y in (-1.60,-.82,.02,.86,1.68):
            for z in (.92,1.57):
                for dy in (-.22,.22):rod((x,y+dy,z),(x+side*.012,y+dy,z),.022,'steel',n=8)
        for y in (-2.05,-1.19,.12,1.24,2.03):
            box((side*.71,y,.50),(.08,.55,.19),'dark')
            for dy in (-.16,.16):box((side*.76,y+dy,.50),(.025,.045,.13),'steel')
        for y in (-1.05,1.12):
            box((x,y,1.62),(.035,.44,.11),'roof')
            for k in range(5):box((x+side*.022,y-.16+.08*k,1.62),(.018,.025,.075),'steel')
    for sign in (-1,1):
        for k in range(4):box((0,sign*(2.91 if sign==1 else 2.99),.79+k*.035),(.45,.025,.014),'dark')
        box((0,sign*3.24,.43),(.28,.28,.18),'steel')
        box((0,sign*3.39,.43),(.23,.08,.16),'dark')
    for y in (-2.12,1.55,2.0):
        for x in (-.28,.28):box((x,y,1.90),(.30,.24,.07),'panel')
    for x in (-.50,.50):rod((x,-1.9,1.78),(x,1.82,1.78),.024,'steel')
    # Same two rigid link lengths in both positions (two-link planar IK).
    pivot=np.array([-.92*1.055,2.07]);L1=1.18;L2=1.18
    for g,y,top in [('up',-.93*1.055,Z_TOP),('down',float(pivot[0]),2.2625)]:
        tip=np.array([y,top-.0225-.055]);v=tip-pivot;d=np.linalg.norm(v)
        assert abs(L1-L2)<d<L1+L2
        t=(L1*L1-L2*L2+d*d)/(2*d);h=math.sqrt(L1*L1-t*t)
        elbow=pivot+t*v/d+h*np.array([-v[1],v[0]])/d
        assert abs(np.linalg.norm(elbow-pivot)-L1)<1e-9 and abs(np.linalg.norm(tip-elbow)-L2)<1e-9
        for x in (-.14,.14):
            rod((x,*pivot),(x,*elbow),.052,'arm',g)
            rod((x,*elbow),(x,*tip),.038,'arm',g)
        rod((-.19,*elbow),(.19,*elbow),.05,'steel',g)
        for dy in (-.095,.095):
            box((0,y+dy,top-.0225),(1.05,.075,.045),'black',g)
            for s in (-1,1):rod((s*.49,y+dy,top-.0225),(s*.59,y+dy,top-.0925),.026,'steel',g)
        for x in (-.25,.25):rod((x,y-.12,top-.0625),(x,y+.12,top-.0625),.03,'steel',g)
    return parts

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--out',type=Path,default=Path('build/qa/locomotive049_v2'));a=p.parse_args();a.out.mkdir(parents=True,exist_ok=True);parts=model();base.export(parts,a.out);base.render(parts,a.out,8,calibrated=True)
    print(json.dumps({'components':len(parts),'common':sum(g in ('body','mask') for _,m,t,g in parts),'wire_screen_tiles':WIRE,'top_z':Z_TOP,'native_game_px':WIRE*32},indent=2))
