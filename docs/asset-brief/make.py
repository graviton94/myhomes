import sys
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage
src, out = sys.argv[1], sys.argv[2]
rgb=np.array(Image.open(src).convert('RGB')).astype(int)
mx=rgb.max(2); mn=rgb.min(2)
bgish=(mn>205)&((mx-mn)<14)
lab,_=ndimage.label(bgish)
border=set(np.unique(np.concatenate([lab[0],lab[-1],lab[:,0],lab[:,-1]])))-{0}
bgm=np.isin(lab,list(border))
# Pockets the outline closes off (inside a bent arm) still show the
# checkerboard: two greys alternating, unlike the flat white dress.
lum=rgb.mean(2)
for c in range(1,lab.max()+1):
    if c in border: continue
    cm=lab==c
    if cm.sum()>30 and lum[cm].std()>4: bgm|=cm
fg=~bgm
lab2,n2=ndimage.label(fg)
idx=range(1,n2+1)
sizes=ndimage.sum(fg,lab2,idx)
inked=ndimage.maximum(((mx-mn)>40)|(mn<120),lab2,idx)
big=[i+1 for i,s in enumerate(sizes) if s>20000]
cent={b:ndimage.center_of_mass(lab2==b) for b in big}
order=sorted(big,key=lambda b:(round(cent[b][0]/300),cent[b][1]))
names=['listen','think','answer','notfound','ask']
assign={b:[b] for b in big}
for i,s in enumerate(sizes):
    c=i+1
    if c in big or s<40 or not inked[i]: continue
    cy,cx=ndimage.center_of_mass(lab2==c)
    near=min(big,key=lambda b:(cent[b][0]-cy)**2+(cent[b][1]-cx)**2)
    assign[near].append(c)
for name,b in zip(names,order):
    m=np.isin(lab2,assign[b])
    m=ndimage.binary_erosion(m,iterations=1)
    ys,xs=np.where(lab2==b); by0,by1=ys.min(),ys.max(); bcx=(xs.min()+xs.max())/2
    ys2,xs2=np.where(m); y0,y1,x0,x1=ys2.min(),ys2.max(),xs2.min(),xs2.max()
    rgba=np.dstack([rgb.astype('uint8'),(m*255).astype('uint8')])
    crop=Image.fromarray(rgba,'RGBA').crop((x0,y0,x1+1,y1+1))
    s=324/(by1-by0+1)
    crop=crop.resize((max(1,round(crop.width*s)),max(1,round(crop.height*s))),Image.LANCZOS)
    canvas=Image.new('RGBA',(360,420),(0,0,0,0))
    px=round(180-(bcx-x0)*s); py=round(32-(by0-y0)*s)
    px=min(max(px,4),360-crop.width-4)
    canvas.alpha_composite(crop,(px,py))
    canvas.save(f'{out}/{name}.webp',quality=90)
    a=canvas.getchannel('A'); halo=a.filter(ImageFilter.MaxFilter(13))
    dark=Image.new('RGBA',(360,420),(253,253,251,0)); dark.putalpha(halo)
    dark.alpha_composite(canvas); dark.save(f'{out}/{name}_dark.webp',quality=90)
    print(name,canvas.getchannel('A').getbbox(),len(assign[b]))
