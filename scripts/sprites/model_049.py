"""Original procedural 3D test model. Dependencies: numpy, trimesh, vtk, Pillow.
Coordinates: front +Y, Z up, 1 unit provisional tile. Not calibrated game art.
"""
import argparse, math
from pathlib import Path
import numpy as np
import trimesh as tm
from PIL import Image, ImageDraw

PALETTE={'silver':(192,199,202,255),'roof':(66,71,75,255),'steel':(94,101,106,255),'dark':(36,40,43,255),'black':(22,25,27,255),'panel':(130,138,142,255),'stripe':(176,44,33,255),'arm':(171,53,39,255),'ceramic':(194,188,173,255),'gold':(178,136,48,255)}

def make_model():
    parts=[]
    def add(mesh,mat,group='body',name=None):
        mesh.visual.face_colors=PALETTE[mat]
        parts.append((name or f'{group}_{len(parts):03d}',mesh,mat,group))
    def box(pos,dim,mat,group='body'):
        m=tm.creation.box(extents=dim);m.apply_translation(pos);add(m,mat,group)
    def rod(a,b,r,mat,group='body',sections=10):
        m=tm.creation.cylinder(radius=r,segment=[a,b],sections=sections);add(m,mat,group)
    def loft(rings,mat,group='body'):
        # Ring order viewed along +Y: lower left, lower right, upper right, upper left.
        v=np.array([p for ring in rings for p in ring]);n=len(rings[0]);f=[]
        for i in range(len(rings)-1):
            for j in range(n):
                a=i*n+j;b=i*n+(j+1)%n;c=b+n;d=a+n
                f.extend([(a,b,c),(a,c,d)])
        for j in range(1,n-1):f.extend([(0,j+1,j),((len(rings)-1)*n,(len(rings)-1)*n+j,(len(rings)-1)*n+j+1)])
        m=tm.Trimesh(v,f,process=True);m.fix_normals();add(m,mat,group)
    # Shell: tapered front, blunter rear, chamfered shoulders, no glazing.
    sections=[(-2.83,.42,.72,1.30),(-2.60,.68,.59,1.62),(-2.24,.74,.53,1.76),(1.88,.74,.53,1.76),(2.26,.68,.58,1.59),(2.58,.53,.65,1.20),(2.80,.38,.72,.94)]
    def ring(y,w,lo,hi):
        return [(-w*.76,y,lo),(w*.76,y,lo),(w,y,lo+.16),(w,y,hi-.25),(w*.79,y,hi),(-w*.79,y,hi),(-w,y,hi-.25),(-w,y,lo+.16)]
    loft([ring(*s) for s in sections],'silver')
    # Dark roof follows the shell rather than a rectangular cab.
    loft([[(-w*.98,y,hi-.245),(w*.98,y,hi-.245),(w*.79,y,hi+.012),(-w*.79,y,hi+.012)] for y,w,lo,hi in sections],'roof')
    # Wrap-around lower stripe, separate material; tapered ends match shell.
    loft([[(-w-.005,y,lo+.19),(w+.005,y,lo+.19),(w+.005,y,lo+.43),(-w-.005,y,lo+.43)] for y,w,lo,hi in sections],'stripe','mask')
    box((0,0,.43),(1.22,5.32,.29),'dark')
    for sign in [-1,1]:
        box((0,sign*2.80,.46),(.92,.26,.23),'dark')
        box((0,sign*3.00,.42),(.28,.24,.20),'black')
        for x in [-.43,.43]:box((x,sign*2.69,.60),(.19,.13,.12),'steel')
    # Bogies, wheels, axle housings and side frames.
    for y in [-1.93,1.93]:
        box((0,y,.35),(1.28,1.14,.25),'dark')
        for yy in [y-.33,y+.33]:
            rod((-.68,yy,.26),(.68,yy,.26),.075,'steel')
            for x in [-.63,.63]:
                rod((x-.075,yy,.26),(x+.075,yy,.26),.24,'dark',sections=20)
                rod((x-.09,yy,.26),(x+.09,yy,.26),.16,'steel',sections=16)
                rod((x-.10,yy,.26),(x+.10,yy,.26),.077,'panel')
        for x in [-.70,.70]:
            box((x,y,.36),(.10,1.04,.14),'steel')
            for yy in [y-.25,y+.25]:box((x,yy,.46),(.13,.19,.12),'dark')
    # Underframe boxes and side technical panels, no windows or headlamps.
    for side in [-1,1]:
        x=side*.746
        for y in [-1.35,-.7,-.05,.6,1.25]:
            box((side*.58,y,.39),(.25,.52,.25),'roof')
            box((side*.711,y,.38),(.03,.43,.16),'steel')
        for y in [-1.95,1.55]:
            box((x,y,1.20),(.025,.48,.44),'panel')
            box((x+side*.02,y,1.20),(.025,.42,.38),'silver')
            box((x+side*.037,y+.13,1.17),(.025,.025,.11),'dark')
        for y in [-.95,.55]:
            box((x+side*.016,y,1.35),(.045,.80,.30),'dark')
            for k in range(9):box((x+side*.045,y-.34+k*.085,1.35),(.025,.038,.255),'steel')
        for y in np.linspace(-1.7,1.65,7):
            box((x+side*.006,float(y),1.01),(.015,.014,.30),'steel')
    # Roof cabinets, radiator grilles, hatches and cable runs.
    for y in [-2.03,1.47,1.90]:
        box((0,y,1.79),(.95,.36,.11),'roof')
        box((0,y,1.86),(.76,.27,.04),'steel')
    box((0,.43,1.84),(1.05,1.05,.22),'roof')
    box((0,.43,1.97),(.88,.86,.04),'dark')
    for k in range(10):box((0,.02+k*.088,2.005),(.85,.037,.035),'steel')
    for x in [-.33,.33]:
        rod((x,-1.98,1.80),(x,-.63,1.80),.028,'steel')
    # Fixed insulators and independent single-arm pantograph states.
    py=-1.12
    box((0,py,1.82),(.85,.72,.07),'dark')
    for x in [-.24,.24]:
        for y in [py-.22,py+.22]:
            rod((x,y,1.85),(x,y,2.02),.065,'ceramic')
            for z in [1.88,1.93,1.98]:rod((x,y,z),(x,y,z+.018),.087,'ceramic')
    box((0,py,2.04),(.66,.51,.055),'roof')
    for group,elbow,tip in [('up',(-.48,2.56),(.19,3.24)),('down',(-.39,2.17),(.27,2.24))]:
        y0=py+.20;ye=py+elbow[0];ze=elbow[1];yt=py+tip[0];zt=tip[1]
        for x in [-.14,.14]:
            rod((x,y0,2.07),(x,ye,ze),.052,'arm',group)
            rod((x,ye,ze),(x,yt,zt-.055),.036,'arm',group)
        rod((-.19,ye,ze),(.19,ye,ze),.045,'steel',group)
        for dy in [-.095,.095]:
            box((0,yt+dy,zt),(1.05,.075,.045),'black',group)
            for sign in [-1,1]:rod((sign*.49,yt+dy,zt),(sign*.59,yt+dy,zt-.07),.026,'steel',group)
        for x in [-.25,.25]:rod((x,yt-.12,zt-.04),(x,yt+.12,zt-.04),.03,'steel',group)
    return parts

def export(parts,out):
    # glTF is Y-up, retain named nodes for editable parts.
    rot=tm.transformations.rotation_matrix(-math.pi/2,[1,0,0])
    for state in ['up','down']:
        scene=tm.Scene()
        for name,m,mat,g in parts:
            if g not in ['body','mask',state]:continue
            mesh=m.copy();mesh.apply_transform(rot);scene.add_geometry(mesh,geom_name=name,node_name=name)
        (out/f'locomotive_049_{state}.glb').write_bytes(scene.export(file_type='glb'))

def render(parts,out,count=8,calibrated=False):
    import vtk
    from vtk.util.numpy_support import numpy_to_vtk, vtk_to_numpy
    ren=vtk.vtkRenderer();ren.SetBackground(.94,.95,.96);ren.SetBackgroundAlpha(0)
    win=vtk.vtkEGLRenderWindow();win.SetOffScreenRendering(1);win.SetAlphaBitPlanes(1);win.SetMultiSamples(4);win.AddRenderer(ren);win.SetSize(512,512)
    actors=[]
    for name,m,mat,g in parts:
        pts=vtk.vtkPoints();pts.SetData(numpy_to_vtk(m.vertices,deep=True));poly=vtk.vtkPolyData();poly.SetPoints(pts)
        cells=vtk.vtkCellArray()
        for face in m.faces:cells.InsertNextCell(3);[cells.InsertCellPoint(int(v)) for v in face]
        poly.SetPolys(cells);mapper=vtk.vtkPolyDataMapper();mapper.SetInputData(poly)
        actor=vtk.vtkActor();actor.SetMapper(mapper);p=actor.GetProperty();p.SetColor(*(np.array(PALETTE[mat][:3])/255));p.SetAmbient(.43 if calibrated else .65);p.SetDiffuse(.70 if calibrated else .55);p.SetSpecular(.24 if calibrated else .18);p.SetSpecularPower(18);p.SetInterpolationToFlat();ren.AddActor(actor);actors.append((actor,g,mat))
    ren.AutomaticLightCreationOff();light=vtk.vtkLight();light.SetPosition(-5,-5,10);light.SetFocalPoint(0,0,0);light.SetIntensity(1.05);ren.AddLight(light)
    cam=ren.GetActiveCamera();cam.ParallelProjectionOn();cam.SetParallelScale(4 if calibrated else 3.65);cam.SetViewUp(0,0,1)
    frames={}
    for state in ['up','down']:
        folder=out/state;folder.mkdir(exist_ok=True)
        for act,g,mat in actors:act.SetVisibility(g in ['body','mask',state])
        for i in range(count):
            a=2*math.pi*i/count;z0=math.sqrt(2) if calibrated else 1.05;cam.SetFocalPoint(0,0,z0);cam.SetPosition(12*math.sin(a),-12*math.cos(a),12+z0);light.SetPosition(12*math.sin(a-.65),-12*math.cos(a-.65),18);ren.ResetCameraClippingRange();win.Render()
            grab=vtk.vtkWindowToImageFilter();grab.SetInput(win);grab.SetInputBufferTypeToRGBA();grab.ReadFrontBufferOff();grab.Update()
            arr=vtk_to_numpy(grab.GetOutput().GetPointData().GetScalars()).reshape(512,512,4)[::-1].copy();im=Image.fromarray(arr,'RGBA');im.save(folder/f'{i:03}.png');frames[state,i]=im
    win.Finalize()
    if count==8:
        cell=310;sheet=Image.new('RGB',(cell*4,cell*4+54),(231,235,239));d=ImageDraw.Draw(sheet);d.text((16,14),'EM 0.1.49 / ONE 3D MODEL / 8 VIEWS / TWO STATES',fill='#27333e')
        for si,state in enumerate(['up','down']):
            for i in range(8):
                x=(i%4)*cell;y=54+(si*2+i//4)*cell;d.rounded_rectangle((x+5,y+5,x+cell-5,y+cell-5),radius=10,fill='#f9fafb',outline='#c4ccd2');im=frames[state,i].resize((296,296),Image.Resampling.LANCZOS);sheet.paste(im,(x+7,y+7),im);d.text((x+15,y+15),f'{state.upper()} / {i*45:03} deg',fill='#34434f')
        sheet.save(out/'preview_049.png')

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--out',type=Path,default=Path('build/qa/locomotive049'));p.add_argument('--views',type=int,default=8);p.add_argument('--no-render',action='store_true');a=p.parse_args();a.out.mkdir(parents=True,exist_ok=True);parts=make_model();export(parts,a.out)
    if not a.no_render:render(parts,a.out,a.views)
    print(f'{len(parts)} named components; {a.views} views per state; {a.out}')
