import sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter
SRC='docs/asset-brief/store-art-sheet.png'
FONTS='/home/user/myhomes/app/assets/fonts/'
SHOTS='/home/user/myhomes/app/test/tmp_shot/'
OUT='/home/user/myhomes/docs/store/'
src=Image.open(SRC).convert('RGB')
top=src.crop((0,0,809,538)); bot=src.crop((0,565,809,1944))
INK=(63,46,34); ORANGE=(191,79,36)
def jua(n): return ImageFont.truetype(FONTS+'Jua-Regular.ttf',n)
def noto(n): return ImageFont.truetype(FONTS+'NotoSansKR-Bold.ttf',n)
T={'ko':dict(brand='우리집요정',feat=['가위 어디 뒀지?','요정에게 물어봐요'],head=['말로 물어보면','요정이 찾아 줘요'],sub='이름 · 초성 · 쓰임새 다 돼요'),
   'en':dict(brand='Home Fairy',feat=['Where are the scissors?','Just ask the fairy'],head=['Just ask out loud.','The fairy finds it.'],sub='Names, initials or what it is for')}
def fit(draw,text,font_fn,size,maxw):
    while size>10 and draw.textlength(text,font=font_fn(size))>maxw: size-=2
    return font_fn(size)
for lang,t in T.items():
    # Feature graphic 1024x500: the art at full height, the cream ground carried out to the sides.
    s=500/top.height; art=top.resize((round(top.width*s),500),Image.LANCZOS)
    fg=Image.new('RGB',(1024,500),(252,239,207)); ox=(1024-art.width)//2
    fg.paste(art,(ox,0))
    # soften the joins
    for x0 in (ox, ox+art.width):
        band=fg.crop((x0-12,0,x0+12,500)).filter(ImageFilter.GaussianBlur(6)); fg.paste(band,(x0-12,0))
    d=ImageDraw.Draw(fg)
    # speech bubble interior (art coords 300..760 x 45..270)
    bx0,bx1=ox+round(320*s),ox+round(745*s); by0,by1=round(55*s),round(260*s); cx=(bx0+bx1)/2
    f1=fit(d,t['brand'],noto,26,bx1-bx0-40)
    lines=t['feat']; big=min(fit(d,l,jua,52,bx1-bx0-40).size for l in lines); f2=jua(big)
    h=f1.size+12+len(lines)*(big+8); y=(by0+by1-h)/2
    d.text((cx,y),t['brand'],font=f1,fill=ORANGE,anchor='mt'); y+=f1.size+12
    for l in lines: d.text((cx,y),l,font=f2,fill=INK,anchor='mt'); y+=big+8
    fg.save(OUT+f'{lang}-feature.png')
    # Screenshot 7 (1080x1920): headline on top, the talk screen in a phone in the middle.
    s2=1080/bot.width; bg=bot.resize((1080,round(bot.height*s2)),Image.LANCZOS)
    shot=Image.new('RGB',(1080,1920),bg.getpixel((540,5))); shot.paste(bg,(0,1920-bg.height))
    d=ImageDraw.Draw(shot)
    y=110
    for l in t['head']:
        f=fit(d,l,jua,84,500); d.text((540,y),l,font=f,fill=INK,anchor='mt'); y+=f.size+14
    f=fit(d,t['sub'],noto,34,470); d.text((540,y+16),t['sub'],font=f,fill=ORANGE,anchor='mt')
    phone=Image.open(SHOTS+f'ask_{lang}.png').convert('RGB')
    pw=440; ph=round(phone.height*pw/phone.width); phone=phone.resize((pw,ph),Image.LANCZOS)
    frame=Image.new('RGBA',(pw+36,ph+36),(0,0,0,0)); fd=ImageDraw.Draw(frame)
    fd.rounded_rectangle((0,0,pw+35,ph+35),radius=64,fill=INK)
    mask=Image.new('L',(pw,ph),0); ImageDraw.Draw(mask).rounded_rectangle((0,0,pw-1,ph-1),radius=48,fill=255)
    frame.paste(phone,(18,18),mask)
    top_y=max(y+110,430)
    px0=1080-frame.width-36
    shadow=Image.new('RGBA',shot.size,(0,0,0,0)); ImageDraw.Draw(shadow).rounded_rectangle((px0+10,top_y+14,px0+frame.width+10,top_y+frame.height+14),radius=64,fill=(63,46,34,60))
    shot=Image.alpha_composite(shot.convert('RGBA'),shadow.filter(ImageFilter.GaussianBlur(12)))
    shot.alpha_composite(frame,(px0,top_y))
    shot.convert('RGB').save(OUT+f'{lang}-7-ask.png')
    print(lang,'phone bottom',top_y+frame.height)
