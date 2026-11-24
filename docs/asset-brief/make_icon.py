"""App and store icons from the ordered art (icon_house.png, cut by cut_sheet.py).

  python3 docs/asset-brief/make_icon.py      (from the repository root)
"""
from PIL import Image, ImageDraw

PERSIMMON = (191, 79, 36, 255)
house = Image.open('docs/asset-brief/icon_house.png').convert('RGBA')
RES = 'app/android/app/src/main/res'


def art(width):
    h = round(house.height * width / house.width)
    return house.resize((width, h), Image.LANCZOS)


def place(canvas, a, lift=0.0):
    s = canvas.width
    canvas.alpha_composite(a, ((s - a.width) // 2, (s - a.height) // 2 + round(s * lift)))


def square(s, radius):
    c = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    m = Image.new('L', (s, s), 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, s - 1, s - 1), radius=radius, fill=255)
    c.paste(Image.new('RGBA', (s, s), PERSIMMON), (0, 0), m)
    place(c, art(round(s * 0.78)), 0.02)
    return c


for d, k in {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}.items():
    s = round(48 * k)
    square(s, round(s * 0.22)).save(f'{RES}/mipmap-{d}/ic_launcher.png')
    # Adaptive foreground: 108dp canvas, the house inside the 66dp safe zone.
    f = round(108 * k)
    fg = Image.new('RGBA', (f, f), (0, 0, 0, 0))
    place(fg, art(round(64 * k)), 0.01)
    fg.save(f'{RES}/mipmap-{d}/ic_launcher_foreground.png')
square(512, 0).convert('RGB').save('docs/store/icon-512.png')  # Play rounds the corners itself
print('icons written')
