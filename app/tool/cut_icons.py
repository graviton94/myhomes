"""Cuts the ordered pictogram sheets (docs/asset-brief/sheets/sheet-NN.png,
7×7 each) into one SVG per icon with potrace, named pSSCC (sheet, cell).
Each shape goes to the cell its middle is in, so icons that lean over a
cell line are still whole. Writes design/icons/sheets/*.svg and a preview.

    python3 tool/cut_icons.py
"""
import glob, json, os, subprocess, tempfile
import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHEETS = os.path.join(ROOT, '..', 'docs', 'asset-brief', 'sheets')
OUT = os.path.join(ROOT, '..', 'design', 'icons', 'sheets')
PREVIEW = os.path.join(ROOT, '..', 'docs', 'asset-brief', 'sheets-preview')


def cells(path):
    g = np.asarray(Image.open(path).convert('L'), dtype=np.uint8)
    ink = g < 128
    ys, xs = np.nonzero(ink)
    x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    cw, ch = (x1 - x0) / 7, (y1 - y0) / 7
    lab, n = ndimage.label(ink)
    found = ndimage.find_objects(lab)
    sums = ndimage.sum(ink, lab, range(1, n + 1))
    boxes = [[] for _ in range(49)]
    for i, sl in enumerate(found):
        if sums[i] < 12:  # specks
            continue
        cy = (sl[0].start + sl[0].stop) / 2
        cx = (sl[1].start + sl[1].stop) / 2
        c = min(6, max(0, int((cx - x0) // cw)))
        r = min(6, max(0, int((cy - y0) // ch)))
        boxes[r * 7 + c].append((i + 1, sl))
    out = []
    for parts in boxes:
        if not parts:
            out.append(None)
            continue
        t = min(s[0].start for _, s in parts); b = max(s[0].stop for _, s in parts)
        l = min(s[1].start for _, s in parts); rr = max(s[1].stop for _, s in parts)
        mask = np.isin(lab[t:b, l:rr], [k for k, _ in parts])
        out.append(mask)
    return out


def to_svg(mask, path):
    h, w = mask.shape
    side = max(h, w)
    pad = int(side * 0.06)
    canvas = np.zeros((side + 2 * pad, side + 2 * pad), dtype=bool)
    oy, ox = pad + (side - h) // 2, pad + (side - w) // 2
    canvas[oy:oy + h, ox:ox + w] = mask
    with tempfile.NamedTemporaryFile(suffix='.pbm', delete=False) as f:
        Image.fromarray(~canvas).convert('1').save(f.name)
        subprocess.run(['potrace', f.name, '-s', '-o', path, '--flat', '-t', '6', '-O', '0.4'], check=True)
        os.unlink(f.name)
    _flatten(path)


def _flatten(path):
    """potrace's group transform folded into one path on a 24×24 grid, the
    form tool/build_icons.py reads (as design/icons/*.svg)."""
    import re
    import xml.etree.ElementTree as ET
    from fontTools.pens.svgPathPen import SVGPathPen
    from fontTools.pens.transformPen import TransformPen
    from fontTools.svgLib.path import parse_path
    ns = '{http://www.w3.org/2000/svg}'
    root = ET.parse(path).getroot()
    side = float(root.get('viewBox').split()[2])
    g = root.find(ns + 'g')
    tx, ty = map(float, re.search(r'translate\(([-\d.]+),([-\d.]+)\)', g.get('transform')).groups())
    sx, sy = map(float, re.search(r'scale\(([-\d.]+),([-\d.]+)\)', g.get('transform')).groups())
    k = 24 / side
    pen = SVGPathPen(None, ntos=lambda v: f'{v:.2f}'.rstrip('0').rstrip('.'))
    for p in g.iter(ns + 'path'):
        parse_path(p.get('d'), TransformPen(pen, (sx * k, 0, 0, sy * k, tx * k, ty * k)))
    open(path, 'w').write(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path fill="currentColor" d="{pen.getCommands()}"/></svg>\n')


def main():
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(PREVIEW, exist_ok=True)
    report = {}
    for path in sorted(glob.glob(os.path.join(SHEETS, 'sheet-*.png'))):
        n = int(os.path.basename(path)[6:8])
        cs = cells(path)
        missing = [i + 1 for i, m in enumerate(cs) if m is None]
        report[n] = missing
        tiles = []
        for i, m in enumerate(cs):
            if m is None:
                tiles.append(Image.new('L', (64, 64), 200))
                continue
            to_svg(m, os.path.join(OUT, f'p{n:02d}{i + 1:02d}.svg'))
            t = Image.fromarray(np.where(m, 0, 255).astype(np.uint8))
            t.thumbnail((56, 56))
            tile = Image.new('L', (64, 64), 255)
            tile.paste(t, ((64 - t.width) // 2, (64 - t.height) // 2))
            tiles.append(tile)
        sheet = Image.new('L', (7 * 66, 7 * 66), 230)
        for i, t in enumerate(tiles):
            sheet.paste(t, ((i % 7) * 66 + 1, (i // 7) * 66 + 1))
        sheet.save(os.path.join(PREVIEW, f'sheet-{n:02d}.png'))
    print(json.dumps({k: v for k, v in report.items() if v}) or 'all 49 everywhere')


if __name__ == '__main__':
    main()
