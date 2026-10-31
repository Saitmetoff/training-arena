import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import test from 'node:test';

const script = fileURLToPath(new URL('../../run-dev.ps1', import.meta.url));
const windows = process.platform === 'win32';
function plan(args = [], environment = {}) {
  const env = { ...process.env };
  for (const key of Object.keys(env)) if (key.startsWith('ARENA_')) delete env[key];
  return spawnSync('powershell.exe', ['-NoProfile', '-File', script, '-PrintOnly', ...args], {
    encoding: 'utf8', env: { ...env, ...environment },
  });
}

test('default development plan launches offline solo with real ports and release holds', { skip: !windows }, () => {
  const result = plan();
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /ARENA_FEATURE_SOLO_MODE=true/);
  for (const name of ['PREVIEW_FIXTURES', 'RANKED_MATCHMAKING', 'PUSH_NOTIFICATIONS', 'CAMERA_COUNTING', 'CAMERA_TRACE']) {
    assert.match(result.stdout, new RegExp(`ARENA_FEATURE_${name}=false`));
  }
});

test('backend plan requires credentials, forwards public configuration and permits email-only auth', { skip: !windows }, () => {
  const missing = plan(['-Mode', 'Backend']);
  assert.notEqual(missing.status, 0);
  assert.match(missing.stderr, /ARENA_SUPABASE_URL/);
  const configured = plan(['-Mode', 'Backend'], {
    ARENA_SUPABASE_URL: 'https://example.supabase.co',
    ARENA_SUPABASE_ANON_KEY: 'test-public-value',
    ARENA_AUTH_REDIRECT_URL: 'trainingarena://challenge/auth',
    ARENA_LINK_HOST: 'arena.example',
  });
  assert.equal(configured.status, 0, configured.stderr);
  assert.match(configured.stdout, /ARENA_FEATURE_PREVIEW_FIXTURES=false/);
  assert.match(configured.stdout, /ARENA_FEATURE_CHALLENGE_LINKS=true/);
  assert.match(configured.stdout, /Android App Links host supplied from environment/);
  assert.doesNotMatch(configured.stdout, /test-public-value/);
  assert.equal(plan(['-Mode', 'Backend'], {
    ARENA_SUPABASE_URL: 'https://example.supabase.co',
    ARENA_SUPABASE_ANON_KEY: 'test-public-value',
  }).status, 0, 'email OTP does not require Google OAuth redirect configuration');
});

test('fixtures and camera diagnostics need explicit choices', { skip: !windows }, () => {
  const fixture = plan(['-Mode', 'Fixtures']);
  assert.equal(fixture.status, 0, fixture.stderr);
  assert.match(fixture.stdout, /ARENA_FEATURE_PREVIEW_FIXTURES=true/);
  const camera = plan(['-EnableCameraCounting', '-EnableCameraTrace']);
  assert.equal(camera.status, 0, camera.stderr);
  assert.match(camera.stdout, /ARENA_FEATURE_CAMERA_COUNTING=true/);
  assert.match(camera.stdout, /ARENA_FEATURE_CAMERA_TRACE=true/);
  const invalid = plan(['-EnableCameraTrace']);
  assert.notEqual(invalid.status, 0);
});
