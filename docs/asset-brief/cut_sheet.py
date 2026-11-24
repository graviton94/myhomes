import sys
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage
src, out = sys.argv[1], sys.argv[2]
rgb=np.array(Image.open(src).convert('RGB')).astype(int)
mx=rgb.max(2); mn=rgb.min(2)
neutral=(mn>=232)&((mx-mn)<=3)
lab,n=ndimage.label(neutral)
border=set(np.unique(np.concatenate([lab[0],lab[-1],lab[:,0],lab[:,-1]])))-{0}
sizes=ndimage.sum(neutral,lab,range(1,n+1))
lum=rgb.mean(2)
# Closed-off pockets (inside a bent arm) are background only when as flat as
# the sheet's white; faces and dresses have paper texture (spread ~3).
pockets=set()
for i,sz in enumerate(sizes):
    c=i+1
    if c in border or sz<60: continue
    v=lum[lab==c]
    if v.std()<1.5 and v.mean()>253: pockets.add(c)
bg=np.isin(lab,list(border|pockets))
fg=~bg
lab2,n2=ndimage.label(fg)
idx=range(1,n2+1)
sizes2=ndimage.sum(fg,lab2,idx)
inked=ndimage.maximum(((mx-mn)>40)|(mn<120),lab2,idx)
big=[i+1 for i,s in enumerate(sizes2) if s>15000]
cent={b:ndimage.center_of_mass(lab2==b) for b in big}
order=sorted(big,key=lambda b:(round(cent[b][0]/400),cent[b][1]))
print('figures',len(order))
assign={b:[b] for b in big}
for i,s in enumerate(sizes2):
    c=i+1
    if c in big or s<30 or not inked[i]: continue
    cy,cx=ndimage.center_of_mass(lab2==c)
    near=min(big,key=lambda b:(cent[b][0]-cy)**2+(cent[b][1]-cx)**2)
    assign[near].append(c)
names=['hello','found','carry','worry','cheer','sleep','icon_bust','icon_house']
for name,b in zip(names,order):
    m=np.isin(lab2,assign[b])
    m=ndimage.binary_erosion(m,iterations=1)
    ys2,xs2=np.where(m); y0,y1,x0,x1=ys2.min(),ys2.max(),xs2.min(),xs2.max()
    rgba=np.dstack([rgb.astype('uint8'),(m*255).astype('uint8')])
    crop=Image.fromarray(rgba,'RGBA').crop((x0,y0,x1+1,y1+1))
    if name.startswith('icon'):
        crop.save(f'{out}/{name}.png'); print(name,crop.size); continue
    ys,xs=np.where(lab2==b); by0,by1=ys.min(),ys.max(); bcx=(xs.min()+xs.max())/2
    s=324/(by1-by0+1)
    crop=crop.resize((max(1,round(crop.width*s)),max(1,round(crop.height*s))),Image.LANCZOS)
    canvas=Image.new('RGBA',(360,420),(0,0,0,0))
    px=round(180-(bcx-x0)*s); py=round(32-(by0-y0)*s)
    px=min(max(px,4),360-crop.width-4)
    canvas.alpha_composite(crop,(px,py))
    canvas.save(f'{out}/{name}.webp',quality=90)
    halo=canvas.getchannel('A').filter(ImageFilter.MaxFilter(13))
    dark=Image.new('RGBA',(360,420),(253,253,251,0)); dark.putalpha(halo)
    dark.alpha_composite(canvas); dark.save(f'{out}/{name}_dark.webp',quality=90)
    print(name,canvas.getchannel('A').getbbox(),len(assign[b]))
