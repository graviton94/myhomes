// Bakes the House Fairy poses and the launcher icon from design/fairy/parts.svg.
// Flutter cannot draw the crayon SVG filters, so the app ships pre-rendered WebP.
//
//   node tool/bake_fairy.mjs     (from app/, needs Playwright + Chromium)
//
// Writes assets/fairy/<pose>.webp and <pose>_dark.webp (360x420, 3x of 120x140)
// and android/app/src/main/res/mipmap-*/ launcher icons.
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { createRequire } from 'node:module';
import path from 'node:path';

const require = createRequire(import.meta.url);
const { chromium } = require(process.env.PLAYWRIGHT_MODULE ?? 'playwright');

const app = path.resolve(path.dirname(new URL(import.meta.url).pathname), '..');
const parts = readFileSync(path.join(app, '../design/fairy/parts.svg'), 'utf8');

const POSES = {
  hello: ['eyes', 'arms-wave'],
  found: ['eyes-happy', 'arms-found'],
  carry: ['eyes', 'arms-box'],
  worry: ['eyes-worry', 'arms-clock'],
  cheer: ['eyes-happy', 'arms-cheer'],
  sleep: ['eyes-sleep', 'arms-rest', 'zz'],
};

function figure(layers, { dark = false, viewBox = '-10 -8 140 163', w = 360, h = 420 } = {}) {
  const uses = layers
    .map((l) =>
      l === 'zz'
        ? '<text class="fy-z" x="92" y="40">z</text><text class="fy-z" x="100" y="28" style="font-size:16px">Z</text>'
        : `<use href="#${l}"/>`,
    )
    .join('');
  const body = `<use href="#fy-base" width="120" height="140"/>${uses}`;
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${viewBox}" width="${w}" height="${h}" style="overflow:visible">
    <g ${dark ? 'filter="url(#sticker)"' : ''}>${body}</g></svg>`;
}

const page = await (await chromium.launch()).newPage({ deviceScaleFactor: 1 });

async function render(svg, w, h, background = 'transparent') {
  await page.setViewportSize({ width: w, height: h });
  await page.setContent(
    `<html><body style="margin:0;background:${background}">${parts}<div id="f" style="width:${w}px;height:${h}px">${svg}</div></body></html>`,
  );
  await page.waitForTimeout(100);
  return (await page.$('#f')).screenshot({ omitBackground: background === 'transparent' });
}

async function toWebp(png, quality = 0.9) {
  const url = await page.evaluate(
    async ({ b64, q }) => {
      const img = new Image();
      img.src = `data:image/png;base64,${b64}`;
      await img.decode();
      const c = document.createElement('canvas');
      c.width = img.width;
      c.height = img.height;
      c.getContext('2d').drawImage(img, 0, 0);
      return c.toDataURL('image/webp', q);
    },
    { b64: png.toString('base64'), q: quality },
  );
  return Buffer.from(url.split(',')[1], 'base64');
}

const out = path.join(app, 'assets/fairy');
mkdirSync(out, { recursive: true });
for (const [name, layers] of Object.entries(POSES)) {
  for (const dark of [false, true]) {
    const png = await render(figure(layers, { dark }), 360, 420);
    const file = path.join(out, `${name}${dark ? '_dark' : ''}.webp`);
    writeFileSync(file, await toWebp(png));
    console.log(path.relative(app, file));
  }
}

// Launcher icon: fairy face and hat on the persimmon colour.
const res = path.join(app, 'android/app/src/main/res');
const head = (size) => figure(['eyes'], { viewBox: '22 -6 76 84', w: size, h: size });
const densities = { mdpi: 1, hdpi: 1.5, xhdpi: 2, xxhdpi: 3, xxxhdpi: 4 };
for (const [d, k] of Object.entries(densities)) {
  mkdirSync(path.join(res, `mipmap-${d}`), { recursive: true });
  // Legacy square icon (48dp) with rounded background.
  const s = Math.round(48 * k);
  const legacy = await render(
    `<div style="width:${s}px;height:${s}px;border-radius:${s * 0.22}px;background:#BF4F24;display:grid;place-items:center">${head(Math.round(s * 0.86))}</div>`,
    s,
    s,
  );
  writeFileSync(path.join(res, `mipmap-${d}/ic_launcher.png`), legacy);
  // Adaptive foreground (108dp canvas, art inside the 66dp safe zone).
  const f = Math.round(108 * k);
  const fg = await render(
    `<div style="width:${f}px;height:${f}px;display:grid;place-items:center">${head(Math.round(66 * k))}</div>`,
    f,
    f,
  );
  writeFileSync(path.join(res, `mipmap-${d}/ic_launcher_foreground.png`), fg);
  console.log(`mipmap-${d}`);
}
process.exit(0);
