#!/usr/bin/env node
/*
 * Release flag hold check.
 *
 * `docs/decisions/10-native-push-host-interface-decisions.md` keeps ranked
 * matchmaking disabled until two physical phones validate it, and the L06
 * launch task requires push and preview fixtures to stay off. This check
 * protects those holds (and the explicit, owner-approved camera choice) from
 * being silently reversed while configuring release secrets.
 *
 * Usage:
 *   node tools/release/check_release_flags.mjs [--workflow <path>]
 */
import { readFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..');

function option(name, fallback) {
  const index = process.argv.indexOf(name);
  return index >= 0 && index + 1 < process.argv.length
    ? process.argv[index + 1]
    : fallback;
}

/**
 * Returns the list of hold violations in the workflow source. Empty means the
 * documented release holds are intact.
 */
export function checkReleaseFlags(source) {
  const failures = [];

  if (/ARENA_FEATURE_RANKED_MATCHMAKING\s*=\s*true\b/.test(source)) {
    failures.push(
      'ARENA_FEATURE_RANKED_MATCHMAKING must not be true: ranked stays on hold ' +
      'until two physical phones validate it (decision 10, L06)',
    );
  }
  if (!/ARENA_FEATURE_RANKED_MATCHMAKING\s*=\s*false\b/.test(source)) {
    failures.push(
      'release workflow must pin ARENA_FEATURE_RANKED_MATCHMAKING=false',
    );
  }
  if (!/ARENA_FEATURE_PUSH_NOTIFICATIONS\s*=\s*false\b/.test(source)) {
    failures.push(
      'release workflow must keep ARENA_FEATURE_PUSH_NOTIFICATIONS=false',
    );
  }
  if (!/ARENA_FEATURE_PREVIEW_FIXTURES\s*=\s*false\b/.test(source)) {
    failures.push(
      'release workflow must keep ARENA_FEATURE_PREVIEW_FIXTURES=false',
    );
  }
  if (/ARENA_FEATURE_SOLO_MODE\s*=\s*false\b/.test(source) ||
      !/ARENA_FEATURE_SOLO_MODE\s*=\s*true\b/.test(source)) {
    failures.push(
      'release workflow must pin ARENA_FEATURE_SOLO_MODE=true for the beta ' +
      '(decision 12)',
    );
  }
  if (/ARENA_FEATURE_CAMERA_TRACE\s*=\s*true\b/.test(source)) {
    failures.push(
      'ARENA_FEATURE_CAMERA_TRACE must not be true: the landmark trace is a ' +
      'debug tool and its file must never ship (task F3)',
    );
  }
  if (!/ARENA_FEATURE_CAMERA_TRACE\s*=\s*false\b/.test(source)) {
    failures.push(
      'release workflow must pin ARENA_FEATURE_CAMERA_TRACE=false',
    );
  }
  if (!/ARENA_FEATURE_CAMERA_COUNTING\s*=\s*\$\{\{\s*inputs\.enable_camera_counting\s*\}\}/.test(source)) {
    failures.push(
      'camera counting must keep its explicit owner-approved ' +
      'inputs.enable_camera_counting choice',
    );
  }

  return failures;
}

const invokedDirectly =
  process.argv[1] &&
  pathToFileURL(resolve(process.argv[1])).href === import.meta.url;

if (invokedDirectly) {
  const workflowPath = resolve(
    option('--workflow', join(root, '.github', 'workflows', 'release-checks.yml')),
  );
  const failures = checkReleaseFlags(readFileSync(workflowPath, 'utf8'));
  if (failures.length > 0) {
    console.error('release flag check failed:');
    for (const failure of failures) {
      console.error(` - ${failure}`);
    }
    process.exit(1);
  }
  console.log('release flag check passed');
}
