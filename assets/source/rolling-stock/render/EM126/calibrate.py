import json, math, sys
from pathlib import Path
import numpy as np, trimesh as tm
from scipy.spatial import ConvexHull
from scipy.optimize import least_squares
W=Path('/mnt/data/EM126_work'); S=Path('/mnt/data/wagon_anim_work'); qa=json.loads((S/'models-v2/output/dimension_qa.json').read_text())['models']; scale=6.86/tm.load(S/'Locomotive_v3_body.glb',force='scene',process=False).extents[2]; T=tm.transformations.rotation_matrix(math.pi/2,[1,0,0]);T[:3,:3]*=scale
# Alpha >=128 bounding boxes of original 2.1.25 sprite files on owner's PC; index is native raw render angle.
native={'cargo':{0:(136,402),16:(290,384),24:(359,351),32:(406,307),40:(432,260),48:(440,212),64:(436,127),80:(438,211),96:(400,304),112:(288,380),127:(144,403)},'tank':{0:(134,414),16:(278,395),24:(342,362),32:(384,323),40:(406,278),48:(414,233),64:(398,149),80:(414,233),96:(384,323),112:(278,395),127:(142,415)}}
vertices={}
for kind in ['cargo','tank','battery']:
 scene=tm.load(S/f'models-v2/output/{kind}.glb',force='scene',process=False); vs=[]
 for n in scene.graph.nodes_geometry:
  if qa[kind]['part_groups'][n].startswith('V3_bogie'):continue
  mat,key=scene.graph[n]; v=tm.transform_points(scene.geometry[key].vertices,T@mat);vs.append(v)
 v=np.concatenate(vs);vertices[kind]=v[ConvexHull(v).vertices]
# Fitting the body envelope only; do not infer native mesh dimensions from pixels.
def project(v,a,p):
 sx,sz,sy_e,sy_n=p; sy=sy_e+(sy_n-sy_e)*math.cos(a)**2
 x,y,z=(v*np.array([sx,sy,sz])).T; u=x*math.cos(a)+y*math.sin(a); vv=(-x*math.sin(a)+y*math.cos(a)+z)/math.sqrt(2); return np.stack((u,vv),axis=1)*64

def residual(p):
 out=[]
 for k,frames in native.items():
  for i,wh in frames.items():
   a=i*math.tau/256; pred=np.ptp(project(vertices[k],a,p),axis=0);out.extend((pred-np.array(wh))/np.array([135,165]))
 return out
# Shared profile, keep east-west length unchanged; fit width, height, northward longitudinal deformation.
r=least_squares(lambda p:residual([p[0],1,1,p[1]]),[1.25,1.15],bounds=([1,1],[1.5,1.35]));p=[float(r.x[0]),1,1,float(r.x[1])]
report={'native_raw_bbox_px':native,'parameters':p,'formula':'sx constant, sz constant, sy = 1+(sy_n-1)*cos(raw_camera_azimuth)^2; east-west length kept; preprojected direction index theta uses atan2(sin(theta)/sqrt(2),cos(theta))','baseline_rmse_normalized':float(np.sqrt(np.mean(np.array(residual([1,1,1,1]))**2))),'candidate_rmse_normalized':float(np.sqrt(np.mean(np.array(residual(p))**2))),'directions':{}}
for k,v in vertices.items():
 report['directions'][k]={}
 for i in [0,16,32,48,64,96,128,192]:
  th=i*math.tau/256;a=math.atan2(math.sin(th)/math.sqrt(2),math.cos(th)); report['directions'][k][i]={'raw_index':a*256/math.tau%256,'old_wh_px':np.ptp(project(v,a,[1,1,1,1]),axis=0).round(2).tolist(),'new_wh_px':np.ptp(project(v,a,p),axis=0).round(2).tolist()}
(W/'calibration.json').write_text(json.dumps(report,indent=2));print(json.dumps({k:v for k,v in report.items() if k not in ('native_raw_bbox_px','directions')},indent=2));print(report['directions']['cargo'][0],report['directions']['cargo'][64])
