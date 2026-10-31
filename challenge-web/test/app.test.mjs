import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { test } from 'node:test';
import { runInNewContext } from 'node:vm';

const require = createRequire(import.meta.url);
const ArenaLink = require('../link.js');
const source = readFileSync(new URL('../app.js', import.meta.url), 'utf8');
const configSource = readFileSync(new URL('../config.js', import.meta.url), 'utf8');

async function renderPage({ config = {}, pathname = '/c/ab12cd34ef56', payload, failure } = {}) {
  const app = { innerHTML: '' };
  const calls = [];
  const window = { ArenaLink, location: { pathname, search: '' } };
  runInNewContext(configSource, { window });
  Object.assign(window.ARENA_WEB_CONFIG, config);
  runInNewContext(source, {
    window,
    document: {
      readyState: 'complete',
      getElementById: (id) => id === 'challenge-app' ? app : null,
    },
    fetch: async (url, init) => {
      calls.push({ url, init });
      if (failure) throw failure;
      return { ok: true, json: async () => payload };
    },
  });
  await new Promise((resolve) => setImmediate(resolve));
  return { html: app.innerHTML, calls };
}

test('shipped blank backend never invents a live challenge or install offer', async () => {
  const { html, calls } = await renderPage();
  assert.match(html, /Challenge availability is not configured/);
  assert.match(html, /AB12-CD34-EF56/);
  assert.doesNotMatch(html, /Live 60-second battle|challenges you|Get it on Google Play|trainingarena:\/\//);
  assert.equal(calls.length, 0);
});

test('whitespace backend configuration is unavailable without fetching', async () => {
  const { html, calls } = await renderPage({ config: { apiBase: '   ' } });
  assert.match(html, /Challenge availability is not configured/);
  assert.equal(calls.length, 0);
});

test('configured valid challenge resolves read-only and retains its app and install recovery', async () => {
  const { html, calls } = await renderPage({
    config: { apiBase: 'https://project.example/' },
    payload: { data: { available: true, owner: { username: 'fixture_player' } } },
  });
  assert.match(html, /@fixture_player challenges you/);
  assert.match(html, /Live 60-second battle/);
  assert.match(html, /trainingarena:\/\/challenge\/ab12cd34ef56/);
  assert.match(html, /referrer=challenge%3Dab12cd34ef56/);
  assert.match(html, /Reopen this link after installing/);
  assert.equal(calls.length, 1);
  assert.equal(calls[0].url, 'https://project.example/functions/v1/arena?token=ab12cd34ef56');
  assert.equal(calls[0].init.method, 'GET');
  assert.equal(calls[0].init.credentials, 'omit');
  assert.equal(calls[0].init.cache, 'no-store');
  assert.equal(calls[0].init.body, undefined);
});

test('failed or revoked resolution never becomes a live challenge', async () => {
  for (const options of [
    { failure: new Error('offline') },
    { payload: { data: { available: false, reason: 'link_revoked' } } },
  ]) {
    const { html } = await renderPage({ config: { apiBase: 'https://project.example' }, ...options });
    assert.doesNotMatch(html, /Live 60-second battle|challenges you|Get it on Google Play/);
    assert.match(html, /AB12-CD34-EF56/);
  }
});

test('invalid links make no resolution request', async () => {
  const { html, calls } = await renderPage({ config: { apiBase: 'https://project.example' }, pathname: '/c/no' });
  assert.match(html, /not a readable challenge link/);
  assert.equal(calls.length, 0);
});

test('static metadata and noscript never assert a checked challenge or store availability', () => {
  const html = readFileSync(new URL('../index.html', import.meta.url), 'utf8');
  const metadata = [...html.matchAll(/<meta[^>]+(?:name="(?:description|twitter:description)"|property="og:description")[^>]+>/g)]
    .map((match) => match[0]).join('\n');
  assert.match(metadata, /Availability/);
  assert.doesNotMatch(metadata, /You have|Install Fault|Camera-counted|accept the live challenge/);
  const noscript = html.match(/<noscript>([\s\S]*?)<\/noscript>/)[1];
  assert.match(noscript, /has not been checked/);
  assert.doesNotMatch(noscript, /install it from Google Play/);
});
