"""Original synthetic variant 02; no recorded samples or stochastic noise."""
from pathlib import Path
import numpy as np, soundfile as sf, subprocess, json
from scipy.signal import welch
root=Path(__file__).parent
sr=44100
sizes={'em-electric-drive-loop':round(4.446326530612245*sr),'em-electric-start':round(.38634920634920633*sr),'em-electric-stop':round(.6073015873015873*sr)}
def smooth(x):
 x=np.clip(x,0,1);return x*x*(3-2*x)
def level(x,db): return x*10**(db/20)/np.sqrt(np.mean(x*x))
def stats(x):
 f,p=welch(x[:,0],sr,nperseg=min(16384,len(x)));return dict(samples=len(x),seconds=len(x)/sr,channels=x.shape[1],hz=sr,rms_dbfs=20*np.log10(np.sqrt(np.mean(x*x))),peak_dbfs=20*np.log10(np.max(np.abs(x))),dominant_hz=float(f[np.argmax(p)]),seam_max=float(np.max(np.abs(x[0]-x[-1]))),p99_adjacent_step=float(np.quantile(np.abs(np.diff(x,axis=0)),.99)))
metrics={}
for name,n in sizes.items():
 t=np.arange(n)/sr;T=n/sr
 if 'loop' in name:
  # Whole cycles over the exact vanilla duration: no phase jump at wrap.
  f=round(98*T)/T; twin=round(100.75*T)/T; inv=round(760*T)/T
  def synth(delay):
   s=lambda hz,ph=0:np.sin(2*np.pi*hz*(t+delay)+ph)
   return .085*(s(f)+.38*s(2*f,.25)+.15*s(3*f)+.37*s(twin,1.2))+.067*(s(inv)+.30*s(inv+f)+.23*s(inv-f)+.055*s(2*inv))
  y=np.column_stack([synth(-.00008),synth(.00008)])
  # Preserve electric texture, reduce sharpness and loudness versus the older loop.
  y=level(np.tanh(y*1.25),-20.5)
 else:
  q=t/T if 'start' in name else 1-t/T
  f=43+55*smooth(q); inv=660+1.15*f
  phase=lambda freq:2*np.pi*np.cumsum(freq)/sr
  pf,pi=phase(f),phase(inv)
  def synth(delay):
   a=pf+2*np.pi*f*delay;b=pi+2*np.pi*inv*delay
   return .06*(np.sin(a)+.38*np.sin(2*a))+.046*(np.sin(b)+.30*np.sin(b+a)+.23*np.sin(b-a))
  envelope=smooth(t/(T*.17))*(1-smooth((t-T*.58)/(T*.42)))
  y=level(np.column_stack([synth(-.00008),synth(.00008)])*envelope[:,None],-23 if 'start' in name else -24)
 assert np.max(np.abs(y))<.8
 wav=root/(name+'.wav'); ogg=root/(name+'.ogg');sf.write(wav,y,sr,subtype='PCM_24')
 subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-i',str(wav),'-c:a','libvorbis','-q:a','6',str(ogg)],check=True)
 d,rate=sf.read(ogg,always_2d=True);assert rate==sr and d.shape==(n,2)
 m=stats(d);m['bytes']=ogg.stat().st_size;m['source_seam_max']=float(np.max(np.abs(y[0]-y[-1])));metrics[name]=m
 if 'loop' in name: assert m['seam_max']<m['p99_adjacent_step']*1.5
 else: assert max(np.max(np.abs(d[0])),np.max(np.abs(d[-1])))<.002
 print(name,json.dumps(m))
(root/'audio_metrics.json').write_text(json.dumps(metrics,indent=2)+'\n')
# Preview is a concatenation of the exact shipped assets; not a recording of Factorio.
parts=[sf.read(root/(n+'.ogg'))[0] for n in ('em-electric-start','em-electric-drive-loop','em-electric-drive-loop','em-electric-stop')]
preview=np.concatenate(parts);sf.write(root/'preview.wav',preview,sr,subtype='PCM_16')
subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-i',str(root/'preview.wav'),'-c:a','libmp3lame','-b:a','192k','/mnt/data/EM138_0.2.4_preview.mp3'],check=True)
