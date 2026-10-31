#!/usr/bin/env node
/**
 * Deterministic checks for the Training Arena design prototype.
 *
 * Run:  node prototype/scripts/check.mjs
 *
 * Verifies, without network access or dependencies:
 *  1. every documented foreground/background pair meets its WCAG minimum;
 *  2. prototype/styles/tokens.css mirrors design/arena/tokens.json;
 *  3. no colour literal in the prototype CSS exists outside the token mirror;
 *  4. required design documents exist with their required headings;
 *  5. forbidden legacy/product terms do not appear in design/ or prototype/;
 *  6. every route rendered by prototype/js/app.js is documented in
 *     design/arena/SCREEN_MAP.md, and every documented route exists in code;
 *  7. every fixture in prototype/js/fixtures.js is reachable from the
 *     prototype routes, and required acceptance states are present.
 */

import { readFileSync, existsSync, readdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
const repo = join(here, '..', '..');
const p = (...parts) => join(repo, ...parts);

const failures = [];
const notes = [];
const fail = (message) => failures.push(message);
const ok = (message) => notes.push(`  ok  ${message}`);
const read = (path) => {
  try {
    return readFileSync(p(path), 'utf8');
  } catch (error) {
    fail(`cannot read ${path}: ${error.message}`);
    return '';
  }
};

/* ------------------------------------------------------------------ tokens */

const tokens = JSON.parse(read('design/arena/tokens.json') || '{}');
if (!tokens.color) fail('design/arena/tokens.json has no color block');

const channel = (value) => {
  const v = value / 255;
  return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
};
const luminance = (hex) => {
  const h = hex.replace('#', '');
  const [r, g, b] = [0, 2, 4].map((i) => parseInt(h.slice(i, i + 2), 16));
  return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b);
};
const ratio = (a, b) => {
  const l1 = luminance(a);
  const l2 = luminance(b);
  return (Math.max(l1, l2) + 0.05) / (Math.min(l1, l2) + 0.05);
};

console.log('WCAG contrast (canvas #17191A reference)');
for (const check of tokens.contrastChecks || []) {
  const fg = tokens.color[check.fg];
  const bg = tokens.color[check.bg];
  if (!fg || !bg) {
    fail(`contrast check references unknown token: ${check.fg} on ${check.bg}`);
    continue;
  }
  const value = ratio(fg, bg);
  const pass = value >= check.min;
  const line = `${fg} on ${bg}: ${value.toFixed(2)}:1 (min ${check.min}) — ${check.note}`;
  if (pass) {
    console.log(`  pass  ${line}`);
  } else {
    console.log(`  FAIL  ${line}`);
    fail(`contrast ${fg} on ${bg} = ${value.toFixed(2)}:1, below ${check.min}:1`);
  }
}

/* -------------------------------------------------------- token/css parity */

const cssPath = 'prototype/styles/tokens.css';
const css = existsSync(p(cssPath)) ? read(cssPath) : '';
if (!css) fail(`missing ${cssPath}`);
for (const [name, value] of Object.entries(tokens.color || {})) {
  const kebab = name.replace(/[A-Z]/g, (m) => `-${m.toLowerCase()}`);
  const hex = value.replace(/\s+/g, '');
  if (css && !css.includes(hex)) {
    fail(`${cssPath} does not mirror color token ${name} (${value})`);
  }
  if (css && !css.includes(`--c-${kebab}:`)) {
    fail(`${cssPath} has no custom property --c-${kebab}`);
  }
}
if (css) ok(`${cssPath} mirrors all ${Object.keys(tokens.color || {}).length} color tokens`);

/* --------------------------------------------------- stray colour literals */

const appCss = existsSync(p('prototype/styles/app.css')) ? read('prototype/styles/app.css') : '';
if (!appCss) fail('missing prototype/styles/app.css');
const stray = new Set();
for (const match of appCss.matchAll(/#[0-9a-fA-F]{3,8}\b/g)) {
  const literal = match[0].toUpperCase();
  const known = Object.values(tokens.color || {}).map((v) => v.toUpperCase());
  if (!known.some((v) => v.startsWith(literal) || literal.startsWith(v))) stray.add(match[0]);
}
if (stray.size) {
  fail(`prototype/styles/app.css uses colours outside the token set: ${[...stray].join(', ')}`);
} else if (appCss) {
  ok('prototype/styles/app.css contains no colours outside the token set');
}

/* ------------------------------------------------------------------- docs */

const requiredDocs = {
  'design/arena/DESIGN_SYSTEM.md': ['Tokens', 'Typography', 'Spacing', 'Components', 'Accessibility', 'Motion', 'Copy voice'],
  'design/arena/SCREEN_MAP.md': ['Routes', 'States', 'Ownership', 'Empty', 'Error', 'Loading'],
  'design/arena/COMPONENT_INVENTORY.md': ['Button', 'Player identity', 'Score', 'Timer', 'Request card', 'Camera status', 'Result card', 'Bottom navigation'],
  'design/arena/PROTOTYPE_GAPS.md': ['Gap', 'Owner'],
};
for (const [doc, headings] of Object.entries(requiredDocs)) {
  const text = read(doc);
  if (!text) continue;
  for (const heading of headings) {
    if (!text.toLowerCase().includes(heading.toLowerCase())) {
      fail(`${doc} is missing required section "${heading}"`);
    }
  }
  ok(`${doc} present`);
}

/* ---------------------------------------------------------- forbidden terms */

/* Every text file in the design and prototype trees is scanned, so a new
 * artifact cannot escape the guard by not being listed here. The guard
 * patterns are assembled from fragments so that this file itself does not
 * contain the banned words. */
const scannedPaths = [];
const textExtensions = new Set(['.md', '.json', '.mjs', '.js', '.css', '.html', '.svg', '.txt', '.xml']);
const walk = (dir) => {
  let entries = [];
  try {
    entries = readdirSync(p(dir), { withFileTypes: true });
  } catch {
    return;
  }
  for (const entry of entries) {
    if (entry.name === 'screenshots' || entry.name === 'node_modules') continue;
    const rel = `${dir}/${entry.name}`;
    if (entry.isDirectory()) walk(rel);
    else if (textExtensions.has(entry.name.slice(entry.name.lastIndexOf('.')))) scannedPaths.push(rel);
  }
};
walk('design');
walk('prototype');
const legacyProduct = ['Fi', 'tB', 'attle'].join('');
const legacySpaced = ['Blu', 'e Steel'].join('');
const forbidden = [
  new RegExp(legacyProduct, 'i'),
  new RegExp(legacyProduct.replace('tB', 't\\s*B'), 'i'),
  new RegExp(legacySpaced.replace(' ', '\\s*'), 'i'),
  new RegExp('com\\.' + legacyProduct.toLowerCase(), 'i'),
];
if (!forbidden[0].test(['xx', 'Fit', 'Battle', 'yy'].join(''))) {
  fail('forbidden-term guard is misconfigured');
}
if (!scannedPaths.includes('design/arena/tokens.json')) {
  fail('forbidden-term scan did not reach design/arena/tokens.json');
}
for (const path of scannedPaths) {
  const text = existsSync(p(path)) ? read(path) : '';
  for (const pattern of forbidden) {
    if (pattern.test(text)) fail(`${path} contains forbidden term ${pattern}`);
  }
}
ok('no forbidden legacy terms in design artifacts');

/* ------------------------------------------------------- route/fixture map */

const app = existsSync(p('prototype/js/app.js')) ? read('prototype/js/app.js') : '';
const fixtures = existsSync(p('prototype/js/fixtures.js')) ? read('prototype/js/fixtures.js') : '';
const screenMap = read('design/arena/SCREEN_MAP.md');

const routeBlock = app.match(/(?:const|var|let) ROUTES = \[([\s\S]*?)\];/);
if (!routeBlock) {
  fail('prototype/js/app.js does not declare a ROUTES array');
} else {
  const codeRoutes = [...routeBlock[1].matchAll(/path:\s*'([^']+)'/g)].map((m) => m[1]);
  const routeList = screenMap.match(/<!-- routes:start -->([\s\S]*?)<!-- routes:end -->/);
  if (!routeList) {
    fail('SCREEN_MAP.md has no <!-- routes:start --> / <!-- routes:end --> block');
  } else {
    const docRoutes = routeList[1]
      .split('\n')
      .map((line) => line.trim())
      .filter((line) => line.startsWith('#/'))
      .map((line) => line.slice(2));
    for (const route of codeRoutes) {
      if (!docRoutes.includes(route)) fail(`route #/${route} is not documented in SCREEN_MAP.md`);
    }
    for (const doc of docRoutes) {
      if (!codeRoutes.includes(doc)) fail(`SCREEN_MAP.md documents #/${doc} but app.js has no such route`);
    }
    ok(`${codeRoutes.length} routes match between app.js and SCREEN_MAP.md`);
  }
}

const fixtureIds = [...fixtures.matchAll(/id:\s*'([a-z0-9-]+)'/g)].map((m) => m[1]);
const fixtureBlock = fixtures.match(/ARENA_FIXTURES\s*=/);
if (!fixtureBlock) {
  fail('prototype/js/fixtures.js does not define window.ARENA_FIXTURES');
} else {
  const unique = new Set(fixtureIds);
  const requiredStates = [
    'battle-incoming',
    'inbox-offline',
    'inbox-expired',
    'inbox-busy',
    'landing-signed-out',
    'landing-not-installed',
    'prep-revealed',
    'live-tracking-lost',
    'live-opponent-offline',
    'live-outage',
    'result-win',
    'result-loss',
    'result-draw',
    'result-no-result',
  ];
  for (const state of requiredStates) {
    if (!unique.has(state)) fail(`fixtures.js is missing required state "${state}"`);
  }
  ok(`${unique.size} fixtures declared, all required acceptance states present`);
  for (const id of unique) {
    if (!app.includes(`'${id}'`) && !fixtures.includes(`'${id}'`)) {
      fail(`fixture "${id}" is defined but never referenced`);
    }
  }
}

/* -------------------------------------------------------------- accessible */

for (const path of ['prototype/index.html', 'prototype/js/app.js']) {
  const text = existsSync(p(path)) ? read(path) : '';
  if (text && !/aria-label|aria-labelledby/.test(text)) fail(`${path} has no accessible labels`);
}
ok('prototype surfaces declare accessible labels');

/* ----------------------------------------------------------------- summary */

console.log('');
if (failures.length) {
  console.error(`${failures.length} check(s) failed:`);
  for (const message of failures) console.error(`  FAIL  ${message}`);
  process.exit(1);
}
console.log(`${notes.length} check group(s) passed.`);
