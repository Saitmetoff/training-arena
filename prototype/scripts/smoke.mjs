#!/usr/bin/env node
/**
 * Functional smoke test for the prototype's primary review path.
 *
 * Run:  node prototype/scripts/smoke.mjs
 *
 * Drives a real Chromium browser through:
 *   landing -> accept -> practice rep -> ready -> countdown -> live -> result
 *   -> share -> new challenge
 * plus keyboard focus, dialog Escape handling, the fixture panel and the
 * "no unattended start" rule. Fails on any uncaught page exception.
 *
 * Requires Node 21+ (global WebSocket) and a local Chromium browser.
 */

import { fileURLToPath, pathToFileURL } from 'node:url';
import { dirname, join } from 'node:path';
import { launchBrowser, sleep } from './cdp.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const indexUrl = pathToFileURL(join(here, '..', 'index.html')).href;

const failures = [];
const passes = [];

function check(name, condition, detail) {
  if (condition) passes.push(name);
  else failures.push(`${name}${detail ? ` — ${detail}` : ''}`);
}

async function main() {
  const cdp = await launchBrowser();
  const exceptions = [];
  cdp.on('Runtime.exceptionThrown', (params) => {
    exceptions.push(params.exceptionDetails?.exception?.description || 'unknown exception');
  });

  const evaluate = async (expression) => {
    const result = await cdp.send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
    if (result.exceptionDetails) {
      throw new Error(result.exceptionDetails.exception?.description || 'evaluate failed');
    }
    return result.result.value;
  };

  const hash = () => evaluate('location.hash');
  const text = () => evaluate('document.body.innerText');

  const navigate = async (fragment) => {
    await cdp.send('Page.navigate', { url: 'about:blank' });
    await sleep(80);
    await cdp.send('Page.navigate', { url: `${indexUrl}${fragment}` });
    await sleep(800);
  };

  const click = async (selector) => {
    const clicked = await evaluate(
      `(() => { const el = document.querySelector(${JSON.stringify(selector)}); if (!el) return false; el.click(); return true; })()`
    );
    if (!clicked) throw new Error(`selector not found: ${selector}`);
    await sleep(350);
  };

  const waitFor = async (expression, label, timeout = 30000) => {
    const started = Date.now();
    while (Date.now() - started < timeout) {
      if (await evaluate(expression)) return true;
      await sleep(200);
    }
    check(label, false, `timed out after ${timeout}ms waiting for ${expression}`);
    return false;
  };

  const pressEscape = async () => {
    await cdp.send('Input.dispatchKeyEvent', { type: 'rawKeyDown', key: 'Escape', code: 'Escape', windowsVirtualKeyCode: 27 });
    await cdp.send('Input.dispatchKeyEvent', { type: 'keyUp', key: 'Escape', code: 'Escape', windowsVirtualKeyCode: 27 });
    await sleep(250);
  };

  /* Accessibility audit: names, headings and landmarks per screen ---------- */

  await cdp.send('Accessibility.enable');
  const interactiveRoles = new Set([
    'button',
    'link',
    'tab',
    'checkbox',
    'combobox',
    'listbox',
    'menuitem',
    'radio',
    'slider',
    'switch',
    'textbox',
  ]);
  const auditA11y = async (screen) => {
    const { nodes } = await cdp.send('Accessibility.getFullAXTree');
    const unnamed = nodes.filter(
      (node) =>
        !node.ignored &&
        interactiveRoles.has(node.role?.value) &&
        !(node.name?.value || '').trim()
    );
    check(
      `${screen}: every control has an accessible name`,
      unnamed.length === 0,
      unnamed.map((node) => node.role.value).join(', ')
    );
    const h1s = nodes.filter(
      (node) =>
        !node.ignored &&
        node.role?.value === 'heading' &&
        (node.properties || []).some((property) => property.name === 'level' && property.value?.value === 1)
    );
    check(`${screen}: has exactly one h1`, h1s.length === 1, `found ${h1s.length}`);
    check(
      `${screen}: has a main landmark`,
      nodes.some((node) => !node.ignored && node.role?.value === 'main')
    );
  };

  /* 1. Landing page and keyboard entry ------------------------------------ */

  await navigate('#/c/9f2k4p7q?fixture=landing-default');
  const landingText = await text();
  check('landing shows the challenger', landingText.includes('@zuhra challenges you'));
  check('landing shows the exercise explanation', landingText.includes('How this works'));
  check('landing shows the privacy note', landingText.includes('camera stays on your phone'));
  check('landing offers one accept action', (landingText.match(/Accept challenge/g) || []).length === 1);
  await auditA11y('landing');

  await evaluate('document.body.focus()');
  await cdp.send('Input.dispatchKeyEvent', { type: 'rawKeyDown', key: 'Tab', code: 'Tab', windowsVirtualKeyCode: 9 });
  await cdp.send('Input.dispatchKeyEvent', { type: 'keyUp', key: 'Tab', code: 'Tab', windowsVirtualKeyCode: 9 });
  await sleep(150);
  const firstFocus = await evaluate('document.activeElement.textContent.trim()');
  check('first Tab reaches the skip link', firstFocus === 'Skip to main content', `got "${firstFocus}"`);

  /* 2. Friend-link path --------------------------------------------------- */

  await click('[data-action="accept-request"]');
  await sleep(300);
  check('accept opens preparation', (await hash()).startsWith('#/prepare/'));
  const prepareText = await text();
  check('preparation reveals one exercise', /exercise revealed/i.test(prepareText) && /push-ups|squats/i.test(prepareText));
  check('preparation keeps the demo placeholder honest', prepareText.includes('3D demonstration placeholder'));
  check('preparation labels the camera placeholder', prepareText.includes('Camera preview placeholder'));
  check('ready is blocked before the practice rep', await evaluate('document.querySelector(\'[data-action="ready-up"]\').getAttribute("aria-disabled") === "true"'));
  await auditA11y('preparation');

  await click('[data-action="ready-up"]');
  check('blocked ready keeps the reviewer on preparation', (await hash()).startsWith('#/prepare/'));
  await click('[data-action="practice-rep"]');
  check('practice rep counts once', (await text()).includes('1 of 1'));
  await click('[data-action="ready-up"]');

  await waitFor('location.hash.startsWith("#/match")', 'ready check opens');
  check('ready check shows the unattended rule', (await text()).includes('Nothing starts unattended'));
  await waitFor('location.hash.includes("/countdown")', 'countdown starts', 12000);
  await waitFor('location.hash.includes("/live")', 'live round starts', 12000);
  check('live shows two score panels', (await evaluate('document.querySelectorAll(".score-panel").length')) === 2);
  await auditA11y('live');

  await waitFor('location.hash.includes("/result")', 'result arrives', 30000);
  const resultText = await text();
  check('result is factual', /I beat @zuhra by \d+/.test(resultText));
  check('result confirms the server receipt', resultText.includes('Confirmed by the server'));
  check('result does not promise a replay', resultText.includes('It never replays this match'));
  check('result exposes the share action', await evaluate('!!document.querySelector(\'[data-action="share-challenge"]\')'));
  await auditA11y('result');

  /* 3. Share screen and dialogs ------------------------------------------ */

  await click('[data-action="share-challenge"]');
  await sleep(300);
  check('share screen opens', (await hash()).startsWith('#/share/'));
  check('share screen shows honest notes', (await text()).includes('Honest preview notes'));
  check('story/feed toggle exists', (await evaluate('document.querySelectorAll(\'[data-action="share-format"]\').length')) === 2);
  await auditA11y('share');

  await click('[data-action="share-format"][data-format="feed"]');
  check('feed export can be previewed', await evaluate('!!document.querySelector(".share-card--feed")'));

  await click('[data-action="sim-share-sheet"]');
  check('simulated share sheet opens', await evaluate('!!document.querySelector(".dialog__card")'));
  await pressEscape();
  check('Escape closes the dialogs', await evaluate('!document.querySelector(".dialog__card")'));

  await click('[data-action="start-new-challenge"]');
  check('new challenge returns to Battle', (await hash()).startsWith('#/battle'));
  await auditA11y('battle');

  /* 4. Fixture panel and Battle actions ---------------------------------- */

  await click('[data-action="open-preview"]');
  check('preview panel opens', await evaluate('!!document.querySelector(".panel__card")'));
  await pressEscape();
  check('preview panel closes with Escape', await evaluate('!document.querySelector(".panel__card")'));

  await click('[data-action="join-code"]');
  check('join with code explains the simulation', (await text()).includes('looking up a code never creates a request or match'));
  await pressEscape();

  await click('[data-action="find-opponent"]');
  check('ranked search claims nobody is promised online', (await text()).includes('Nobody is promised to be online'));

  /* 5. Result-to-share honesty -------------------------------------------- */

  await navigate('#/match/m1/result?fixture=result-loss');
  await click('[data-action="share-challenge"]');
  const lossShare = await text();
  check('share keeps the loss result', lossShare.includes('@zuhra beat me by 5'));
  check('share card does not fake a win', !lossShare.includes('I beat @zuhra'));
  check(
    'share back link returns to the same result',
    (await evaluate('document.querySelector(".screen-head a").getAttribute("href")')) ===
      '#/match/m1/result?fixture=result-loss'
  );

  await navigate('#/match/m1/result?fixture=result-no-result');
  await click('[data-action="share-challenge"]');
  check('no-result share claims no win or loss', (await text()).includes('No confirmed result to show'));

  /* 6. Narrow width and 200% text reflow ---------------------------------- */

  const overflow = () => evaluate('document.documentElement.scrollWidth - window.innerWidth');
  const setViewport = (width, height) =>
    cdp.send('Emulation.setDeviceMetricsOverride', { width, height, deviceScaleFactor: 1, mobile: true });

  await setViewport(320, 720);
  await navigate('#/battle?fixture=battle-incoming');
  check('battle fits a 320px screen', (await overflow()) <= 1);
  await navigate('#/match/m1/live?fixture=live-normal');
  check('live scores fit a 320px screen', (await overflow()) <= 1);
  await navigate('#/share/result?fixture=share-result&zoom=200');
  check('share reflows at 200% text on a 320px screen', (await overflow()) <= 1);
  await cdp.send('Emulation.clearDeviceMetricsOverride');

  /* 7. Summary ------------------------------------------------------------ */

  check('no uncaught page exceptions', exceptions.length === 0, exceptions.join('; '));

  for (const name of passes) console.log(`  pass  ${name}`);
  if (failures.length) {
    console.error(`\n${failures.length} smoke check(s) failed:`);
    for (const failure of failures) console.error(`  FAIL  ${failure}`);
    cdp.close();
    process.exit(1);
  }
  console.log(`\n${passes.length} smoke checks passed.`);
  cdp.close();
  process.exit(0);
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
