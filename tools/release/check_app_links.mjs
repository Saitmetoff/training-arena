#!/usr/bin/env node
/*
 * Training Arena App Link manifest check.
 *
 * Verifies that the Android manifest, the Gradle host property, the Dart
 * configuration and the challenge-web landing configuration agree on the
 * challenge link contract, and that release builds cannot silently ship the
 * `example.invalid` placeholder as a verified App Link.
 *
 * Usage:
 *   node tools/release/check_app_links.mjs
 *   node tools/release/check_app_links.mjs --release --host arena.example
 *   node tools/release/check_app_links.mjs --release --host arena.example \
 *     --fingerprint <sha256> --fetch-assetlinks
 *
 * Without --release the check allows the documented placeholder and reports
 * it as a warning. With --release the placeholder is a hard failure and a
 * real --host (or ARENA_LINK_HOST) is required.
 */
import { readFileSync } from 'node:fs';
import { join, resolve } from 'node:path';

const args = process.argv.slice(2);

function flag(name) {
  return args.includes(name);
}

function option(name) {
  const index = args.indexOf(name);
  return index >= 0 && index + 1 < args.length ? args[index + 1] : null;
}

const root = resolve(option('--root') ?? process.cwd());
const release = flag('--release');
const host = option('--host') ?? process.env.ARENA_LINK_HOST ?? null;
const fingerprint = option('--fingerprint') ?? process.env.ARENA_RELEASE_CERT_SHA256 ?? null;
const fetchAssetLinks = flag('--fetch-assetlinks');

const PLACEHOLDER = 'example.invalid';
const failures = [];
const warnings = [];

function fail(message) {
  failures.push(message);
}

function warn(message) {
  warnings.push(message);
}

function read(relativePath) {
  return readFileSync(join(root, relativePath), 'utf8');
}

const manifest = read('app/android/app/src/main/AndroidManifest.xml');
const buildGradle = read('app/android/app/build.gradle');
const dartConfig = read('app/lib/config/arena_config.dart');
const webConfig = read('challenge-web/config.js');
const assetLinksTemplate = read('challenge-web/.well-known/assetlinks.json.template');

// ---------------------------------------------------------------- manifest

if (!/android:autoVerify="true"/.test(manifest)) {
  fail('AndroidManifest.xml: the App Links filter must set android:autoVerify="true"');
}
if (!/android:scheme="https"/.test(manifest)) {
  fail('AndroidManifest.xml: the App Links filter must use https');
}
if (!/android:host="\$\{arenaLinkHost\}"/.test(manifest)) {
  fail('AndroidManifest.xml: the App Links host must come from ${arenaLinkHost}');
}
if (!/android:pathPrefix="\/c\/"/.test(manifest)) {
  fail('AndroidManifest.xml: the App Links filter must cover /c/');
}
if (!/android:scheme="trainingarena"/.test(manifest) || !/android:host="challenge"/.test(manifest)) {
  fail('AndroidManifest.xml: the trainingarena://challenge fallback filter is missing');
}
if (!/flutter_deeplinking_enabled/.test(manifest) || !/android:value="false"/.test(manifest)) {
  fail('AndroidManifest.xml: flutter_deeplinking_enabled must stay false for app_links');
}

// ------------------------------------------------------------------- gradle

const placeholderMatch = buildGradle.match(
  /arenaLinkHost\s*=\s*project\.findProperty\("arenaLinkHost"\)\s*\?\:\s*"([^"]+)"/,
);
if (!placeholderMatch) {
  fail('build.gradle: arenaLinkHost default not found');
} else if (placeholderMatch[1] !== PLACEHOLDER) {
  fail(`build.gradle: the safe default must be ${PLACEHOLDER}, found ${placeholderMatch[1]}`);
}
if (!/manifestPlaceholders\["arenaLinkHost"\]\s*=\s*arenaLinkHost/.test(buildGradle)) {
  fail('build.gradle: the manifest placeholder must use the shared arenaLinkHost value');
}
if (!/arenaLinkHost == "example.invalid"[\s\S]*?GradleException/.test(buildGradle)) {
  fail('build.gradle: a distributable release build must refuse the example.invalid placeholder');
}
if (!/applicationId\s*=\s*"app\.trainingarena\.mobile"/.test(buildGradle)) {
  fail('build.gradle: applicationId must stay app.trainingarena.mobile');
}
if (!/minSdk\s*=\s*24/.test(buildGradle)) {
  fail('build.gradle: minSdk must stay 24');
}

// --------------------------------------------------------------------- dart

if (!/String\.fromEnvironment\(\s*'ARENA_LINK_HOST'/.test(dartConfig)) {
  fail('arena_config.dart: ARENA_LINK_HOST must remain the link host key');
}
if (!/defaultLinkHost\s*=\s*'example\.invalid'/.test(dartConfig)) {
  fail('arena_config.dart: the safe link host default must be example.invalid');
}
if (!/https:\/\/play\.google\.com\/store\/apps\/details\?id=app\.trainingarena\.mobile/.test(dartConfig)) {
  fail('arena_config.dart: the Play URL must reference app.trainingarena.mobile');
}

// ---------------------------------------------------------------------- web

const webHost = webConfig.match(/linkHost:\s*'([^']+)'/);
if (!webHost) {
  fail('challenge-web/config.js: linkHost is missing');
} else if (webHost[1] !== PLACEHOLDER) {
  fail(`challenge-web/config.js: the committed default must be ${PLACEHOLDER}`);
}
if (!/app\.trainingarena\.mobile/.test(webConfig)) {
  fail('challenge-web/config.js: the Play URL must reference app.trainingarena.mobile');
}

// --------------------------------------------------------------- assetlinks

if (!/"delegate_permission\/common\.handle_all_urls"/.test(assetLinksTemplate)) {
  fail('assetlinks template: missing delegate_permission/common.handle_all_urls');
}
if (!/app\.trainingarena\.mobile/.test(assetLinksTemplate)) {
  fail('assetlinks template: package_name must be app.trainingarena.mobile');
}
if (!/REPLACE_WITH_RELEASE_CERT_SHA256_FINGERPRINT/.test(assetLinksTemplate)) {
  warn('assetlinks template: fingerprint placeholder is missing or already replaced');
}

// ------------------------------------------------------------ release gate

function validHost(value) {
  if (value === PLACEHOLDER) {
    return false;
  }
  if (/^localhost$|^127\.|^10\.|^192\.168\.|^172\.(1[6-9]|2\d|3[01])\./.test(value)) {
    return false;
  }
  return /^(?=.{4,253}$)([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,}$/.test(value);
}

if (release) {
  if (!host) {
    fail('release: --host <domain> (or ARENA_LINK_HOST) is required');
  } else if (!validHost(host)) {
    fail(`release: "${host}" is not a real HTTPS challenge domain`);
  } else if (host === PLACEHOLDER) {
    fail('release: example.invalid must never be handed to testers as a verified link');
  }
  if (!fingerprint) {
    warn('release: no --fingerprint/ARENA_RELEASE_CERT_SHA256 supplied; the deployed assetlinks.json cannot be validated');
  }
} else if (!host || host === PLACEHOLDER) {
  warn(`challenge host is still the placeholder ${PLACEHOLDER}; App Links cannot verify`);
}

// ---------------------------------------------------- optional live check

if (fetchAssetLinks) {
  const targetHost = host;
  if (!targetHost || !validHost(targetHost)) {
    fail('--fetch-assetlinks requires a valid real --host');
  } else {
    const url = `https://${targetHost}/.well-known/assetlinks.json`;
    try {
      const response = await fetch(url, { redirect: 'error' });
      if (!response.ok) {
        fail(`assetlinks: ${url} returned HTTP ${response.status}`);
      } else {
        const body = await response.json();
        const statements = Array.isArray(body) ? body : [body];
        const target = statements
          .flatMap((statement) => statement.target ? [statement.target] : [])
          .find((item) => item.package_name === 'app.trainingarena.mobile');
        if (!target) {
          fail(`assetlinks: ${url} does not target app.trainingarena.mobile`);
        } else if (fingerprint) {
          const normalized = fingerprint.replace(/:/g, '').toUpperCase();
          const prints = (target.sha256_cert_fingerprints ?? [])
            .map((value) => value.replace(/:/g, '').toUpperCase());
          if (!prints.includes(normalized)) {
            fail(`assetlinks: ${url} does not list the release certificate fingerprint`);
          }
        }
      }
    } catch (error) {
      fail(`assetlinks: could not fetch ${url} (${error.message})`);
    }
  }
}

for (const message of warnings) {
  console.error(`warning: ${message}`);
}
if (failures.length > 0) {
  console.error('app link check failed:');
  for (const message of failures) {
    console.error(` - ${message}`);
  }
  process.exit(1);
}
console.log(
  release
    ? `app link check passed for release host ${host}`
    : 'app link check passed (placeholder host intentionally allowed)',
);
