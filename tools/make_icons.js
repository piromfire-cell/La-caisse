// Génère les icônes PNG (Android + web) à partir des SVG de assets/icons.
// Usage : node tools/make_icons.js   (nécessite Playwright + Chromium)
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..', 'assets', 'icons');
const jobs = [
  ['icon.svg', 'icon_512.png', 512],
  ['icon.svg', 'icon_192.png', 192],
  ['icon.svg', 'icon_180.png', 180],
  ['icon.svg', 'icon_144.png', 144],
  ['src/icon_fg.svg', 'icon_fg_432.png', 432, true],
  ['src/icon_bg.svg', 'icon_bg_432.png', 432],
];

(async () => {
  const browser = await chromium.launch();
  for (const [src, out, size, transparent] of jobs) {
    const svg = fs.readFileSync(path.join(root, src), 'utf8');
    const page = await browser.newPage({ viewport: { width: size, height: size } });
    await page.setContent(`<html><body style="margin:0;background:transparent">
      <div style="width:${size}px;height:${size}px">${svg.replace(/width="\d+" height="\d+"/, `width="${size}" height="${size}"`)}</div></body></html>`);
    await page.screenshot({ path: path.join(root, out), omitBackground: true, clip: { x: 0, y: 0, width: size, height: size } });
    await page.close();
    console.log('✓', out);
  }
  await browser.close();
})();
