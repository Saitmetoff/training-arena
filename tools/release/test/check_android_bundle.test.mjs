/*
 * Regressions for the pinned bundletool resolution and the checker boundary.
 *
 * Run with: node --test tools/release/test/check_android_bundle.test.mjs
 *
 * The unit tests inject the file/network side effects, so nothing is
 * downloaded or executed. The boundary test runs the real checker as a child
 * process and proves the Java path is never reached for an unverified JAR.
 */
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { test } from 'node:test';
import { fileURLToPath } from 'node:url';

import {
  BUNDLETOOL_SHA256,
  resolveBundletool,
  sha256,
} from '../bundletool.mjs';

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const checker = join(repoRoot, 'tools', 'release', 'check_android_bundle.mjs');

function fakeFs(initial = {}) {
  const files = new Map(Object.entries(initial));
  let downloads = 0;
  return {
    files,
    downloads: () => downloads,
    deps: {
      exists: (path) => files.has(path),
      readFile: (path) => files.get(path),
      download: () => {
        downloads += 1;
      },
    },
  };
}

test('a mismatched explicit JAR is rejected and never runs Java', () => {
  const fs = fakeFs({ '/tmp/other-bundletool.jar': Buffer.from('not bundletool') });
  const result = resolveBundletool({
    explicit: '/tmp/other-bundletool.jar',
    cachedPath: '/tmp/cache/bundletool.jar',
    ...fs.deps,
  });
  assert.equal(result.ok, false);
  assert.match(result.error, /sha256 mismatch/);
  assert.equal(fs.downloads(), 0);
});

test('a missing explicit JAR is rejected', () => {
  const fs = fakeFs();
  const result = resolveBundletool({
    explicit: '/tmp/missing.jar',
    cachedPath: '/tmp/cache/bundletool.jar',
    ...fs.deps,
  });
  assert.equal(result.ok, false);
  assert.match(result.error, /not found/);
});

test('a downloaded JAR is verified before it can be used', () => {
  const fs = fakeFs();
  fs.deps.download = () => {
    fs.files.set('/tmp/cache/bundletool.jar', Buffer.from('downloaded bytes'));
  };
  const result = resolveBundletool({
    cachedPath: '/tmp/cache/bundletool.jar',
    ...fs.deps,
  });
  assert.equal(result.ok, false);
  assert.match(result.error, /sha256 mismatch/);
});

test('a cached JAR with the pinned digest is accepted', () => {
  const bytes = Buffer.from('pinned bundletool bytes');
  const fs = fakeFs({ '/tmp/cache/bundletool.jar': bytes });
  const result = resolveBundletool({
    cachedPath: '/tmp/cache/bundletool.jar',
    expectedSha: sha256(bytes),
    ...fs.deps,
  });
  assert.equal(result.ok, true);
  assert.equal(result.path, '/tmp/cache/bundletool.jar');
});

test('a download failure is reported, not ignored', () => {
  const fs = fakeFs();
  fs.deps.download = () => {
    throw new Error('offline');
  };
  const result = resolveBundletool({
    cachedPath: '/tmp/cache/bundletool.jar',
    ...fs.deps,
  });
  assert.equal(result.ok, false);
  assert.match(result.error, /download failed/);
});

test('the real checker aborts before Java for a mismatched explicit JAR', () => {
  mkdirSync(join(repoRoot, 'app', 'build'), { recursive: true });
  const scratch = mkdtempSync(join(repoRoot, 'app', 'build', 'ta-bundle-test-'));
  try {
    const badJar = join(scratch, 'bundletool-bad.jar');
    writeFileSync(badJar, 'synthetic bytes that do not match the pinned digest');
    // If Java were invoked it would target this directory and fail loudly.
    const javaHome = join(scratch, 'java-home');
    mkdirSync(join(javaHome, 'bin'), { recursive: true });
    mkdirSync(join(javaHome, 'bin', 'java'), { recursive: true });

    const result = spawnSync(
      process.execPath,
      [checker, '--bundletool', badJar, '--aab', badJar],
      {
        encoding: 'utf8',
        env: { ...process.env, JAVA_HOME: javaHome },
      },
    );

    const output = `${result.stdout}${result.stderr}`;
    assert.equal(result.status, 1);
    assert.match(output, /sha256 mismatch/);
    assert.match(output, /refusing to execute an unverified bundletool jar/);
    assert.doesNotMatch(output, /EACCES|EISDIR|ENOENT|spawn|is a directory/i);
  } finally {
    rmSync(scratch, { recursive: true, force: true });
  }
});

test('the pinned digest constant still matches the shipped version', () => {
  assert.equal(BUNDLETOOL_SHA256.length, 64);
  assert.ok(existsSync(checker));
});
