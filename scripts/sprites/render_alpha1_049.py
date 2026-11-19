"""CI art generator for alpha1. Five 32-frame PNG sheets from one model.
Render angles compensate 45-degree screen projection; all pivot (256,320).
No game packaging here; package_mod.py is the only install ZIP producer.
"""
from pathlib import Path
import argparse, hashlib, json, math
import numpy as np
import trimesh as tm
import vtk
from vtk.util.numpy_support import numpy_to_vtk, vtk_to_numpy
from PIL import Image, ImageDraw
import model_049 as base
import refine_049 as refined

N=32
S=512
COLS=8
LAYERS=("body","mask","shadow","pantograph-up","pantograph-down")

def camera_angle(i):
    t=2*math.pi*i/N
    return math.atan2(math.sin(t)/math.sqrt(2),math.cos(t))

def model_parts():
    # The v2 refiner copied old body_012..053 into its body_009..050.
    # Remove existing modeled bogies/wheels; native wheels are rendered by Factorio.
    parts=refined.model()
    assert len(parts)==318
    discard={f"body_{i:03}" for i in range(9,51)}
    assert len(discard & {name for name,_,_,_ in parts})==42
    return [(n,m,c,g) for n,m,c,g in parts if n not in discard]

def actor_for(mesh,c):
    p=vtk.vtkPoints();p.SetData(numpy_to_vtk(mesh.vertices,deep=True))
    data=vtk.vtkPolyData();data.SetPoints(p)
    cells=vtk.vtkCellArray()
    for face in mesh.faces:
        cells.InsertNextCell(3)
        for v in face:cells.InsertCellPoint(int(v))
    data.SetPolys(cells)
    mapper=vtk.vtkPolyDataMapper();mapper.SetInputData(data)
    actor=vtk.vtkActor();actor.SetMapper(mapper)
    prop=actor.GetProperty()
    prop.SetColor(*(np.array(c)/255))
    prop.SetAmbient(.43);prop.SetDiffuse(.70);prop.SetSpecular(.24);prop.SetSpecularPower(18)
    prop.SetInterpolationToFlat()
    return actor

def capture(win):
    win.Render()
    f=vtk.vtkWindowToImageFilter();f.SetInput(win);f.SetInputBufferTypeToRGBA()
    f.ReadFrontBufferOff();f.Update()
    return vtk_to_numpy(f.GetOutput().GetPointData().GetScalars()).reshape(S,S,4)[::-1].copy()

def rgba(arr):
    # VTK RGB at partially covered pixels is composited on black.
    # Convert to straight RGBA for PNG; fully transparent pixels are zero.
    a=arr[:,:,3].astype(np.float32)
    rgb=np.minimum(255,np.round(arr[:,:,:3].astype(np.float32)*255/np.maximum(a[:,:,None],1))).astype(np.uint8)
    rgb[a==0]=0
    return Image.fromarray(np.dstack((rgb,arr[:,:,3])),"RGBA")

def hull(points):
    # Monotone chain for the projected silhouette of each small mesh.
    pts=sorted(set(map(tuple,points)))
    def cr(o,a,b):return (a[0]-o[0])*(b[1]-o[1])-(a[1]-o[1])*(b[0]-o[0])
    lo=[];hi=[]
    for p in pts:
        while len(lo)>1 and cr(lo[-2],lo[-1],p)<=0:lo.pop()
        lo.append(p)
    for p in reversed(pts):
        while len(hi)>1 and cr(hi[-2],hi[-1],p)<=0:hi.pop()
        hi.append(p)
    return lo[:-1]+hi[:-1]

def shadow(parts,a):
    # Fixed screen-right light direction, body shadow only. Native wheel shadows retained.
    mul=2
    image=Image.new("L",(S*mul,S*mul));d=ImageDraw.Draw(image)
    for _,m,_,g in parts:
        if g not in ("body","mask"):continue
        x,y,z=m.vertices.T
        u=x*math.cos(a)+y*math.sin(a)+z*.45
        v=(-x*math.sin(a)+y*math.cos(a))/math.sqrt(2)-z*.10
        xy=np.column_stack(((256+u*64)*mul,(320-v*64)*mul))
        poly=hull(np.round(xy,2))
        if len(poly)>2:d.polygon(poly,fill=95)
    im=Image.new("RGBA",(S,S),(0,0,0,0));im.putalpha(image.resize((S,S),Image.Resampling.LANCZOS))
    return im

def generate(out,qa):
    out.mkdir(parents=True,exist_ok=True);qa.mkdir(parents=True,exist_ok=True)
    parts=model_parts()
    groups={}
    for _,mesh,mat,g in parts:groups.setdefault((g,mat),[]).append(mesh)
    ren=vtk.vtkRenderer();ren.SetBackground(0,0,0);ren.SetBackgroundAlpha(0)
    win=vtk.vtkEGLRenderWindow();win.SetOffScreenRendering(1);win.SetAlphaBitPlanes(1)
    win.SetMultiSamples(4);win.SetSize(S,S);win.AddRenderer(ren)
    actors=[]
    for (g,mat),meshes in groups.items():
        c=base.PALETTE["silver" if g=="mask" else mat][:3]
        act=actor_for(tm.util.concatenate(meshes),c);ren.AddActor(act)
        actors.append((act,g,c))
    ren.AutomaticLightCreationOff()
    light=vtk.vtkLight();light.SetFocalPoint(0,0,0);light.SetIntensity(1.05);ren.AddLight(light)
    cam=ren.GetActiveCamera();cam.ParallelProjectionOn();cam.SetParallelScale(4);cam.SetViewUp(0,0,1)
    sheets={k:Image.new("RGBA",(COLS*S,N//COLS*S)) for k in LAYERS}
    preview=Image.new("RGB",(4*256,4*256),(206,213,218))
    report={}
    for i in range(N):
        a=camera_angle(i);z0=math.sqrt(2)
        cam.SetFocalPoint(0,0,z0);cam.SetPosition(12*math.sin(a),-12*math.cos(a),12+z0)
        light.SetPosition(12*math.sin(a-.65),-12*math.cos(a-.65),18)
        def mode(groups,matte=False):
            for act,g,c in actors:
                act.SetVisibility(g in groups)
                p=act.GetProperty()
                p.SetColor(*((1,1,1) if g=="mask" else (0,0,0)) if matte else np.array(c)/255)
                p.SetLighting(not matte)
            ren.ResetCameraClippingRange()
            return capture(win)
        b=mode(("body","mask"));body=rgba(b)
        matte=mode(("body","mask"),True)
        alpha=np.minimum(matte[:,:,0],b[:,:,3])
        # Native multiply tint: use the same visible stripe shade, not flat white.
        # Clip highlight luminance to reserve color headroom; retain exact mask alpha.
        gray=np.rint(np.asarray(body.convert("L"),dtype=np.float32)*0.82).clip(96,222).astype(np.uint8)
        gray[alpha==0]=0
        mask=Image.fromarray(np.dstack((gray,gray,gray,alpha)),"RGBA")
        images={"body":body,"mask":mask,"shadow":shadow(parts,a)}
        for state in ("up","down"):
            images["pantograph-"+state]=rgba(mode((state,)))
        for k,img in images.items():
            bbox=img.getchannel("A").getbbox()
            assert bbox and min(bbox[0],bbox[1],S-bbox[2],S-bbox[3])>=2,(k,i,bbox)
            sheets[k].paste(img,((i%COLS)*S,(i//COLS)*S))
        # Actual composite proof (not Factorio tint shader or in-game image).
        if i%4==0:
            # Simulate documented normal multiply tint, not the Factorio GPU shader.
            pix=np.array(mask);pix[:,:,:3]=np.rint(pix[:,:,:3].astype(np.float32)*np.array([178,45,40])/255).astype(np.uint8)
            painted=Image.fromarray(pix,"RGBA")
            for j,state in enumerate(("down","up")):
                comp=Image.alpha_composite(images["shadow"],body)
                comp=Image.alpha_composite(comp,painted);comp=Image.alpha_composite(comp,images["pantograph-"+state])
                thumb=comp.resize((256,256),Image.Resampling.LANCZOS);idx=i//4+8*j
                preview.paste(thumb,((idx%4)*256,(idx//4)*256),thumb)
        print(f"049 render direction {i+1}/{N}",flush=True)
    win.Finalize()
    for k,sheet in sheets.items():
        path=out/(k+".png");sheet.save(path,compress_level=6)
        report[k]={"sha256":hashlib.sha256(path.read_bytes()).hexdigest(),"size":list(sheet.size),"frames":N}
    preview.save(qa/"locomotive-049-alpha1-preview.png")
    (qa/"locomotive-049-alpha1-assets.json").write_text(json.dumps(report,indent=2)+"\n")
    print("049 RENDER PASS: five 32-frame sheets, common pivot, no clipped/empty frames")

if __name__=="__main__":
    p=argparse.ArgumentParser();p.add_argument("--out",type=Path,required=True);p.add_argument("--qa",type=Path,required=True)
    args=p.parse_args();generate(args.out,args.qa)
