#!/usr/bin/env node
/**
 * Capture the prototype state matrix as PNG files without external packages.
 *
 * Run:  node prototype/scripts/capture.mjs
 *       node prototype/scripts/capture.mjs --only=result
 *
 * Uses a locally installed Chromium browser (Microsoft Edge or Google Chrome)
 * through the DevTools protocol and writes to prototype/screenshots/.
 * Override the browser with ARENA_BROWSER=<path to exe>.
 *
 * The state list below is the same matrix that design/arena/SCREEN_MAP.md and
 * task 10 QA use: each entry maps a route + fixture to one file name.
 */

import { mkdirSync, writeFileSync } from 'node:fs';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { dirname, join } from 'node:path';
import { launchBrowser, sleep } from './cdp.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const prototypeDir = join(here, '..');
const outDir = join(prototypeDir, 'screenshots');
const indexUrl = pathToFileURL(join(prototypeDir, 'index.html')).href;

const MOBILE = { width: 390, height: 844 };
const NARROW = { width: 320, height: 720 };
const DESKTOP = { width: 1200, height: 900 };

const STATES = [
  { file: '01-battle-home-incoming', route: 'battle', fixture: 'battle-incoming' },
  { file: '02-battle-home-clear', route: 'battle', fixture: 'battle-clear' },
  { file: '03-battle-ranked-search', route: 'battle', fixture: 'battle-searching', fast: '0' },
  { file: '04-battle-search-timeout', route: 'battle', fixture: 'battle-search-timeout' },
  { file: '05-inbox-pending', route: 'inbox', fixture: 'inbox-pending' },
  { file: '06-inbox-offline', route: 'inbox', fixture: 'inbox-offline' },
  { file: '07-inbox-expired', route: 'inbox', fixture: 'inbox-expired' },
  { file: '08-inbox-busy', route: 'inbox', fixture: 'inbox-busy' },
  { file: '09-inbox-loading', route: 'inbox', fixture: 'inbox-loading' },
  { file: '10-inbox-error', route: 'inbox', fixture: 'inbox-error' },
  { file: '11-landing-signed-in', route: 'c/9f2k4p7q', fixture: 'landing-default' },
  { file: '12-landing-signed-out', route: 'c/9f2k4p7q/signin', fixture: 'landing-signed-out' },
  { file: '13-landing-not-installed', route: 'c/9f2k4p7q/install', fixture: 'landing-not-installed' },
  { file: '14-landing-unavailable', route: 'c/9f2k4p7q', fixture: 'landing-unavailable' },
  { file: '15-prepare-pushups', route: 'prepare/prep-9f2', fixture: 'prep-revealed' },
  { file: '16-prepare-squats', route: 'prepare/prep-9f2', fixture: 'prep-squats' },
  { file: '17-ready-waiting', route: 'match/m1/ready', fixture: 'ready-waiting' },
  { file: '18-countdown', route: 'match/m1/countdown', fixture: 'countdown', fast: '0', settle: 300 },
  { file: '19-live-normal', route: 'match/m1/live', fixture: 'live-normal', settle: 3000 },
  { file: '20-live-tracking-lost', route: 'match/m1/live', fixture: 'live-tracking-lost', settle: 3000 },
  { file: '21-live-opponent-reconnecting', route: 'match/m1/live', fixture: 'live-opponent-reconnecting', settle: 3000 },
  { file: '22-live-opponent-offline', route: 'match/m1/live', fixture: 'live-opponent-offline', settle: 3000 },
  { file: '23-live-outage', route: 'match/m1/live', fixture: 'live-outage', settle: 3000 },
  { file: '24-result-win', route: 'match/m1/result', fixture: 'result-win' },
  { file: '25-result-loss', route: 'match/m1/result', fixture: 'result-loss' },
  { file: '26-result-draw', route: 'match/m1/result', fixture: 'result-draw' },
  { file: '27-result-no-result', route: 'match/m1/result', fixture: 'result-no-result' },
  { file: '28-result-ranked-win', route: 'match/m1/result', fixture: 'result-ranked-win' },
  { file: '29-share-new', route: 'share/new', fixture: 'share-new' },
  { file: '30-share-after-result', route: 'share/result', fixture: 'share-result' },
  { file: '31-profile', route: 'profile', fixture: 'profile' },
  { file: '32-leaderboard', route: 'leaderboard', fixture: 'leaderboard' },
  { file: '33-settings', route: 'settings', fixture: 'settings' },
  { file: '34-preview-panel', route: 'battle', fixture: 'battle-incoming', click: '[data-action="open-preview"]' },
  { file: '35-share-sheet-dialog', route: 'share/result', fixture: 'share-result', click: '[data-action="sim-share-sheet"]' },
  { file: '36-join-code-dialog', route: 'battle', fixture: 'battle-incoming', click: '[data-action="join-code"]' },
  { file: '37-share-after-loss', route: 'share/result', fixture: 'share-result', query: 'from=result-loss' },

  { file: '40-desktop-battle-home', route: 'battle', fixture: 'battle-incoming', viewport: DESKTOP },
  { file: '41-desktop-live', route: 'match/m1/live', fixture: 'live-normal', settle: 3000, viewport: DESKTOP },
  { file: '42-desktop-landing', route: 'c/9f2k4p7q', fixture: 'landing-default', viewport: DESKTOP },
  { file: '43-desktop-result', route: 'match/m1/result', fixture: 'result-win', viewport: DESKTOP },

  { file: '44-narrow-battle-home', route: 'battle', fixture: 'battle-incoming', viewport: NARROW },
  { file: '45-narrow-live', route: 'match/m1/live', fixture: 'live-normal', settle: 3000, viewport: NARROW },
  { file: '46-narrow-result', route: 'match/m1/result', fixture: 'result-win', viewport: NARROW },

  { file: '50-text-200-battle', route: 'battle', fixture: 'battle-incoming', zoom: '200' },
  { file: '51-text-200-live', route: 'match/m1/live', fixture: 'live-normal', settle: 3000, zoom: '200' },
  { file: '52-text-200-share', route: 'share/result', fixture: 'share-result', zoom: '200' },
];

const only = process.argv.find((arg) => arg.startsWith('--only='));
const selected = only ? STATES.filter((state) => state.file.includes(only.slice(7))) : STATES;

function urlFor(state) {
  const query = [`fixture=${state.fixture}`];
  if (state.fast) query.push(`fast=${state.fast}`);
  if (state.zoom) query.push(`zoom=${state.zoom}`);
  if (state.query) query.push(state.query);
  return `${indexUrl}#/${state.route}?${query.join('&')}`;
}

async function main() {
  mkdirSync(outDir, { recursive: true });
  const cdp = await launchBrowser();
  const send = (method, params) => cdp.send(method, params);

  let captured = 0;
  for (const state of selected) {
    const viewport = state.viewport || MOBILE;
    await send('Emulation.setDeviceMetricsOverride', {
      width: viewport.width,
      height: viewport.height,
      deviceScaleFactor: 1,
      mobile: viewport.width < 600,
    });
    await send('Page.navigate', { url: 'about:blank' });
    await sleep(60);
    await send('Page.navigate', { url: urlFor(state) });
    await sleep(state.settle || 900);
    if (state.click) {
      await send('Runtime.evaluate', { expression: `document.querySelector('${state.click}')?.click()` });
      await sleep(400);
    }
    const shot = await send('Page.captureScreenshot', { format: 'png', fromSurface: true });
    writeFileSync(join(outDir, `${state.file}.png`), Buffer.from(shot.data, 'base64'));
    captured += 1;
    process.stdout.write(`captured ${state.file}.png (${viewport.width}x${viewport.height})\n`);
  }

  console.log(`\n${captured} screenshots written to ${outDir}`);
  cdp.close();
  process.exit(0);
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
