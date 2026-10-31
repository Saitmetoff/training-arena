/*
 * Regression: the release workflow must keep the documented feature holds.
 *
 * Run with: node --test tools/release/test/check_release_flags.test.mjs
 */
import assert from 'node:assert/strict';
import { dirname, join, resolve } from 'node:path';
import { test } from 'node:test';
import { fileURLToPath } from 'node:url';
import { readFileSync } from 'node:fs';

import { checkReleaseFlags } from '../check_release_flags.mjs';

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..', '..');

function held(overrides = {}) {
  const defines = {
    CAMERA: '--dart-define=ARENA_FEATURE_CAMERA_COUNTING=${{ inputs.enable_camera_counting }}',
    RANKED: '--dart-define=ARENA_FEATURE_RANKED_MATCHMAKING=false',
    PUSH: '--dart-define=ARENA_FEATURE_PUSH_NOTIFICATIONS=false',
    PREVIEW: '--dart-define=ARENA_FEATURE_PREVIEW_FIXTURES=false',
    SOLO: '--dart-define=ARENA_FEATURE_SOLO_MODE=true',
    TRACE: '--dart-define=ARENA_FEATURE_CAMERA_TRACE=false',
    ...overrides,
  };
  return Object.values(defines).join('\n');
}

test('the shipped release workflow keeps every documented hold', () => {
  const source = readFileSync(
    join(repoRoot, '.github', 'workflows', 'release-checks.yml'),
    'utf8',
  );
  assert.deepEqual(checkReleaseFlags(source), []);
});

test('a ranked=true define is rejected', () => {
  const failures = checkReleaseFlags(held({
    RANKED: '--dart-define=ARENA_FEATURE_RANKED_MATCHMAKING=true',
  }));
  assert.ok(failures.some((message) => /must not be true/.test(message)));
  assert.ok(failures.some((message) => /RANKED_MATCHMAKING=false/.test(message)));
});

test('a missing ranked=false pin is rejected', () => {
  const source = held({ RANKED: '' });
  const failures = checkReleaseFlags(source);
  assert.ok(failures.some((message) => /RANKED_MATCHMAKING=false/.test(message)));
});

test('push or preview enabled is rejected', () => {
  const push = checkReleaseFlags(held({
    PUSH: '--dart-define=ARENA_FEATURE_PUSH_NOTIFICATIONS=true',
  }));
  assert.ok(push.some((message) => /PUSH_NOTIFICATIONS=false/.test(message)));
  const preview = checkReleaseFlags(held({
    PREVIEW: '--dart-define=ARENA_FEATURE_PREVIEW_FIXTURES=true',
  }));
  assert.ok(preview.some((message) => /PREVIEW_FIXTURES=false/.test(message)));
});

test('the explicit camera choice is required', () => {
  const failures = checkReleaseFlags(held({
    CAMERA: '--dart-define=ARENA_FEATURE_CAMERA_COUNTING=true',
  }));
  assert.equal(failures.length, 1);
  assert.match(failures[0], /enable_camera_counting/);
});

test('beta requires solo mode enabled and rejects a disabled or missing pin', () => {
  assert.deepEqual(checkReleaseFlags(held()), []);
  const disabled = checkReleaseFlags(held({
    SOLO: '--dart-define=ARENA_FEATURE_SOLO_MODE=false',
  }));
  assert.ok(disabled.some((message) => /SOLO_MODE=true/.test(message)));
  const missing = checkReleaseFlags(held({ SOLO: '' }));
  assert.ok(missing.some((message) => /SOLO_MODE=true/.test(message)));
});

test('the debug camera trace enabled or unpinned is rejected', () => {
  const enabled = checkReleaseFlags(held({
    TRACE: '--dart-define=ARENA_FEATURE_CAMERA_TRACE=true',
  }));
  assert.ok(enabled.some((message) => /must not be true/.test(message)));
  assert.ok(enabled.some((message) => /CAMERA_TRACE=false/.test(message)));
  const missing = checkReleaseFlags(held({ TRACE: '' }));
  assert.ok(missing.some((message) => /CAMERA_TRACE=false/.test(message)));
});
