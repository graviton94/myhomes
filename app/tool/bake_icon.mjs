// Bakes the launcher and store icon: the fairy's face and hat looking out of
// a cream crayon house ("우리집요정") on the persimmon colour, drawn with the
// same parts and crayon filter as the fairy (design/fairy/parts.svg).
//
//   node tool/bake_icon.mjs     (from app/, needs Playwright + Chromium)
//
// Writes android/app/src/main/res/mipmap-*/ic_launcher(.png|_foreground.png)
// and ../docs/store/icon-512.png.
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { createRequire } from 'node:module';
import path from 'node:path';

const require = createRequire(import.meta.url);
const { chromium } = require(process.env.PLAYWRIGHT_MODULE ?? 'playwright');
const app = path.resolve(path.dirname(new URL(import.meta.url).pathname), '..');
const parts = readFileSync(path.join(app, '../design/fairy/parts.svg'), 'utf8');
const page = await (await chromium.launch()).newPage({ deviceScaleFactor: 1 });

// The house and the fairy's head in one 100x100 drawing.
function art(size) {
  const house = 'M50 7 L94 45 L84 45 L84 93 L16 93 L16 45 L6 45 Z';
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="${size}" height="${size}" style="overflow:visible">
    <defs><clipPath id="inside"><path d="${house}"/></clipPath></defs>
    <path d="${house}" fill="#FCEFC9" filter="url(#crayon)"/>
    <g clip-path="url(#inside)">
      <svg x="20" y="30" width="60" height="66" viewBox="22 -6 76 84" style="overflow:visible">
        <use href="#fy-base" width="120" height="140"/><use href="#eyes"/>
      </svg>
    </g>
    <path d="${house}" fill="none" stroke="#3F2E22" stroke-width="5" stroke-linejoin="round" filter="url(#crayon)"/>
  </svg>`;
}

async function render(html, s) {
  await page.setViewportSize({ width: s, height: s });
  await page.setContent(`<html><body style="margin:0;background:transparent">${parts}<div id="f" style="width:${s}px;height:${s}px">${html}</div></body></html>`);
  await page.waitForTimeout(100);
  return (await page.$('#f')).screenshot({ omitBackground: true });
}

const square = (s, radius) =>
  `<div style="width:${s}px;height:${s}px;border-radius:${radius}px;background:#BF4F24;display:grid;place-items:center">${art(Math.round(s * 0.78))}</div>`;

const res = path.join(app, 'android/app/src/main/res');
for (const [d, k] of Object.entries({ mdpi: 1, hdpi: 1.5, xhdpi: 2, xxhdpi: 3, xxxhdpi: 4 })) {
  mkdirSync(path.join(res, `mipmap-${d}`), { recursive: true });
  const s = Math.round(48 * k);
  writeFileSync(path.join(res, `mipmap-${d}/ic_launcher.png`), await render(square(s, s * 0.22), s));
  // Adaptive foreground: 108dp canvas, the house inside the 66dp safe zone.
  const f = Math.round(108 * k);
  writeFileSync(
    path.join(res, `mipmap-${d}/ic_launcher_foreground.png`),
    await render(`<div style="width:${f}px;height:${f}px;display:grid;place-items:center">${art(Math.round(64 * k))}</div>`, f),
  );
  console.log(`mipmap-${d}`);
}
// Play Store icon: a full square (Play rounds the corners itself).
writeFileSync(path.join(app, '../docs/store/icon-512.png'), await render(square(512, 0), 512));
console.log('docs/store/icon-512.png');
process.exit(0);
