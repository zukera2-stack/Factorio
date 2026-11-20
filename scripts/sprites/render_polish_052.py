"""052: full 256-direction model-space wear and inventory icon.
Eight independent 32-frame chunks; shared mesh, projection and pivot.
"""
from pathlib import Path
import argparse,hashlib,json,math
import numpy as np
import trimesh as tm
import vtk
from vtk.util.numpy_support import numpy_to_vtk
from PIL import Image
import render_alpha1_049 as old
import refine_049 as refined
import model_049 as base

N=256
S=512
COLS=8
BATCH=32
LAYERS=("body","mask","shadow","pantograph-up","pantograph-down")

def angle(i):
    t=2*math.pi*i/N
    return math.atan2(math.sin(t)/math.sqrt(2),math.cos(t))

def weathered_actor(meshes,material,group):
    fine=[]
    for m in meshes:
        if m.area_faces.max()>.055:
            v,f=tm.remesh.subdivide_to_size(m.vertices,m.faces,max_edge=.18,max_iter=9)
            m=tm.Trimesh(vertices=v,faces=f,process=False)
        fine.append(m)
    mesh=tm.util.concatenate(fine)
    rgb=np.array(base.PALETTE["silver" if group=="mask" else material][:3],dtype=float)
    x,y,z=mesh.vertices.T
    lower=np.clip((1.30-z)/.82,0,1)
    roof=np.clip((z-1.55)/.45,0,1)
    wave=.5+.5*np.sin(12*y+3*np.sin(5*y)+2*x)*np.sin(7*z+5*x)
    streak=(.5+.5*np.sin(28*y+1.5*x))**6
    factor=1-(.08+.06*wave)*lower-(.025+.025*wave)*roof-.045*streak*lower
    if group in ("up","down"):factor=1-.035*wave
    dirt=np.array([106.,102.,92.])
    col=np.clip(rgb[None,:]*factor[:,None]+dirt[None,:]*(1-factor[:,None])*.26,0,255).astype(np.uint8)
    act=old.actor_for(mesh,(255,255,255))
    mapper=act.GetMapper()
    scalars=numpy_to_vtk(np.ascontiguousarray(col),deep=True,array_type=vtk.VTK_UNSIGNED_CHAR)
    scalars.SetName("model_surface_weather")
    mapper.GetInput().GetPointData().SetScalars(scalars)
    mapper.SetColorModeToDirectScalars();mapper.SetScalarModeToUsePointData();mapper.ScalarVisibilityOn()
    return act

def painted_mask(mask):
    pix=np.array(mask)
    pix[:,:,:3]=np.rint(pix[:,:,:3].astype(np.float32)*np.array([178,45,40])/255).astype(np.uint8)
    return Image.fromarray(pix,"RGBA")

def generate(out,qa,chunk):
    out.mkdir(parents=True,exist_ok=True);qa.mkdir(parents=True,exist_ok=True)
    parts=old.model_parts()
    groups={}
    for _,mesh,mat,g in parts:groups.setdefault((g,mat),[]).append(mesh)
    ren=vtk.vtkRenderer();ren.SetBackground(0,0,0);ren.SetBackgroundAlpha(0)
    win=vtk.vtkEGLRenderWindow();win.SetOffScreenRendering(1);win.SetAlphaBitPlanes(1)
    win.SetMultiSamples(4);win.SetSize(S,S);win.AddRenderer(ren)
    actors=[]
    for (g,mat),meshes in groups.items():
        act=weathered_actor(meshes,mat,g);ren.AddActor(act);actors.append((act,g))
    ren.AutomaticLightCreationOff()
    light=vtk.vtkLight();light.SetFocalPoint(0,0,0);light.SetIntensity(1.05);ren.AddLight(light)
    cam=ren.GetActiveCamera();cam.ParallelProjectionOn();cam.SetParallelScale(4);cam.SetViewUp(0,0,1)
    sheets={k:Image.new("RGBA",(COLS*S,4*S)) for k in LAYERS}
    report={}
    for i in range(chunk*BATCH,(chunk+1)*BATCH):
        a=angle(i);z0=math.sqrt(2)
        cam.SetFocalPoint(0,0,z0);cam.SetPosition(12*math.sin(a),-12*math.cos(a),12+z0)
        light.SetPosition(12*math.sin(a-.65),-12*math.cos(a-.65),18)
        def mode(groups,matte=False):
            for act,g in actors:
                act.SetVisibility(g in groups)
                p=act.GetProperty();act.GetMapper().SetScalarVisibility(not matte)
                p.SetColor(*((1,1,1) if g=="mask" else (0,0,0)) if matte else (1,1,1))
                p.SetLighting(not matte)
            ren.ResetCameraClippingRange()
            return old.capture(win)
        body=old.rgba(mode(("body","mask")))
        matte=mode(("body","mask"),True)
        alpha=np.minimum(matte[:,:,0],np.array(body)[:,:,3])
        gray=np.rint(np.asarray(body.convert("L"),dtype=np.float32)*.82).clip(96,222).astype(np.uint8)
        gray[alpha==0]=0
        mask=Image.fromarray(np.dstack((gray,gray,gray,alpha)),"RGBA")
        images={"body":body,"mask":mask,"shadow":old.shadow(parts,a)}
        for state in ("up","down"):
            images["pantograph-"+state]=old.rgba(mode((state,)))
        j=i%BATCH
        for k,img in images.items():
            bbox=img.getchannel("A").getbbox()
            assert bbox and min(bbox[0],bbox[1],S-bbox[2],S-bbox[3])>=2,(k,i,bbox)
            sheets[k].paste(img,((j%COLS)*S,(j//COLS)*S))
        if i%32==0:
            comp=Image.alpha_composite(body,painted_mask(mask))
            for state in ("up","down"):
                Image.alpha_composite(comp,images["pantograph-"+state]).save(qa/f"view-{i:03}-{state}.png")
        if i==(160 if json.loads((Path(__file__).resolve().parents[2]/"ElectrifiedMainline/info.json").read_text())["version"] in ("0.1.57","0.1.58","0.1.59","0.1.60") else 96):
            # Only inventory thumbnail includes modeled wheels: running art uses native wheels.
            wheel_parts=[m for n,m,mat,g in refined.model() if n in {f"body_{k:03}" for k in range(9,51)}]
            wheels=old.actor_for(tm.util.concatenate(wheel_parts),(70,74,77))
            ren.AddActor(wheels)
            full=Image.alpha_composite(old.rgba(mode(("body","mask","down"))),painted_mask(mask))
            cropped=full.crop(full.getchannel("A").getbbox())
            cropped.thumbnail((60,60),Image.Resampling.LANCZOS)
            icon=Image.new("RGBA",(64,64));icon.paste(cropped,((64-cropped.width)//2,(64-cropped.height)//2))
            icon.save(out/"icon.png");ren.RemoveActor(wheels)
        print(f"052 view {i+1}/{N}",flush=True)
    win.Finalize()
    for k,sheet in sheets.items():
        path=out/f"{k}-{chunk:02}.png";sheet.save(path,compress_level=4)
        report[path.name]={"sha256":hashlib.sha256(path.read_bytes()).hexdigest(),"size":list(sheet.size),"first_frame":chunk*BATCH,"frames":BATCH}
    (qa/f"chunk-{chunk:02}.json").write_text(json.dumps(report,indent=2)+"\n")

if __name__=="__main__":
    p=argparse.ArgumentParser();p.add_argument("--out",type=Path,required=True);p.add_argument("--qa",type=Path,required=True);p.add_argument("--chunk",type=int,choices=range(8),required=True)
    a=p.parse_args();generate(a.out,a.qa,a.chunk)
