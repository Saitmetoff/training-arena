import { createRequire } from 'node:module';
import { test } from 'node:test';
import assert from 'node:assert/strict';

const require = createRequire(import.meta.url);
const ArenaLink = require('../link.js');

test('tokenFromPath reads /c/<token> with fake tokens', () => {
  assert.equal(ArenaLink.tokenFromPath('/c/ab12cd34ef56'), 'ab12cd34ef56');
  assert.equal(ArenaLink.tokenFromPath('/c/ABCDEF123456/'), 'abcdef123456');
  assert.equal(ArenaLink.tokenFromPath('/c/9f2k4p7q'), '9f2k4p7q');
  assert.equal(ArenaLink.tokenFromPath('/c/no'), null);
  assert.equal(ArenaLink.tokenFromPath('/c/'), null);
  assert.equal(ArenaLink.tokenFromPath('/other/ab12cd34ef56'), null);
});

test('tokenFromQuery supports code fallback', () => {
  assert.equal(ArenaLink.tokenFromQuery('?token=Ab12Cd34Ef56'), 'ab12cd34ef56');
  assert.equal(ArenaLink.tokenFromQuery('?code=9F2K4P7Q'), '9f2k4p7q');
  assert.equal(ArenaLink.tokenFromQuery('?code=%'), null);
});

test('readableCode groups tokens for reading aloud', () => {
  assert.equal(ArenaLink.readableCode('9f2k4p7q'), '9F2K-4P7Q');
  assert.equal(ArenaLink.readableCode('ab12cd34ef56'), 'AB12-CD34-EF56');
});

test('withReferrer encodes the install recovery token', () => {
  const url = ArenaLink.withReferrer(
    'https://play.google.com/store/apps/details?id=app.trainingarena.mobile',
    'ab12cd34ef56'
  );
  assert.ok(url.includes('referrer=challenge%3Dab12cd34ef56'));
});

test('statusFromResolution fails closed for revoked and unknown input', () => {
  assert.equal(
    ArenaLink.statusFromResolution({ available: true, owner: { username: 'zuhra' } }),
    'available'
  );
  assert.equal(
    ArenaLink.statusFromResolution({ available: true, owner_offline: true }),
    'owner_offline'
  );
  assert.equal(
    ArenaLink.statusFromResolution({ available: false, reason: 'link_revoked' }),
    'revoked'
  );
  assert.equal(ArenaLink.statusFromResolution({ available: false }), 'unavailable');
  assert.equal(ArenaLink.statusFromResolution(null), 'unavailable');
});

test('usernameOf only reads a public owner name', () => {
  assert.equal(ArenaLink.usernameOf({ owner: { username: 'zuhra' } }), 'zuhra');
  assert.equal(ArenaLink.usernameOf({ owner: {} }), '');
  assert.equal(ArenaLink.usernameOf({}), '');
});
