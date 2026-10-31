#!/usr/bin/env node
/*
 * Training Arena release artifact identity check.
 *
 * Without --apk this verifies the committed release identity sources:
 * application ID, namespace, label, minSdk, version and the signing guard.
 *
 * With --apk it additionally runs `aapt dump badging` on a built APK and
 * asserts package name, minimum SDK, label, version and (with --release) that
 * the artifact is not debuggable. With --expect-signer-sha256 it uses
 * `apksigner verify --print-certs` to pin the signing certificate.
 *
 * Usage:
 *   node tools/release/check_artifact_identity.mjs
 *   node tools/release/check_artifact_identity.mjs --apk <path> [--release]
 *   node tools/release/check_artifact_identity.mjs --apk <path> \
 *     --expect-signer-sha256 <sha256>
 */
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { existsSync, readFileSync, readdirSync, statSync } from 'node:fs';
import { join, resolve } from 'node:path';

const args = process.argv.slice(2);

function flag(name) {
  return args.includes(name);
}

function option(name, fallback = null) {
  const index = args.indexOf(name);
  return index >= 0 && index + 1 < args.length ? args[index + 1] : fallback;
}

const root = resolve(option('--root') ?? process.cwd());
const apk = option('--apk');
const release = flag('--release');
const expectPackage = option('--expect-package', 'app.trainingarena.mobile');
const expectMinSdk = option('--expect-min-sdk', '24');
const expectTargetSdk = option('--expect-target-sdk', '36');
const expectLabel = option('--expect-label', 'Training Arena');
const expectVersionName = option('--expect-version-name');
const expectVersionCode = option('--expect-version-code');
const expectSigner = option('--expect-signer-sha256');

const failures = [];

function fail(message) {
  failures.push(message);
}

function read(relativePath) {
  return readFileSync(join(root, relativePath), 'utf8');
}

// ------------------------------------------------------------ source checks

const buildGradle = read('app/android/app/build.gradle');
const settingsGradle = read('app/android/settings.gradle');
const wrapperProperties = read('app/android/gradle/wrapper/gradle-wrapper.properties');
const workflow = read('.github/workflows/release-checks.yml');
const pubspec = read('app/pubspec.yaml');
const manifest = read('app/android/app/src/main/AndroidManifest.xml');
const dartMain = read('app/lib/arena_app.dart');

if (!new RegExp(`applicationId\\s*=\\s*"${expectPackage.replace(/\./g, '\\.')}"`).test(buildGradle)) {
  fail(`build.gradle: applicationId must be ${expectPackage}`);
}
if (!new RegExp(`namespace\\s*=\\s*"${expectPackage.replace(/\./g, '\\.')}"`).test(buildGradle)) {
  fail(`build.gradle: namespace must be ${expectPackage}`);
}
if (!new RegExp(`minSdk\\s*=\\s*${expectMinSdk}\\b`).test(buildGradle)) {
  fail(`build.gradle: minSdk must be ${expectMinSdk}`);
}
if (!new RegExp(`compileSdk\\s*=\\s*${expectTargetSdk}\\b`).test(buildGradle)) {
  fail(`build.gradle: compileSdk must be pinned to ${expectTargetSdk}`);
}
if (!new RegExp(`targetSdk\\s*=\\s*${expectTargetSdk}\\b`).test(buildGradle)) {
  fail(`build.gradle: targetSdk must be pinned to ${expectTargetSdk}`);
}
if (!/arenaLinkHost/.test(buildGradle)) {
  fail('build.gradle: arenaLinkHost placeholder is missing');
}
if (!/allowDebugSignedRelease/.test(buildGradle) || !/GradleException/.test(buildGradle)) {
  fail('build.gradle: release signing must fail closed when no keystore is configured');
}
if (!/allowUnsignedRelease/.test(buildGradle)) {
  fail('build.gradle: unsigned compatibility builds need the explicit allowUnsignedRelease opt-in');
}

// Pinned toolchain (L02): Flutter/AGP/Gradle/Kotlin combination.
if (!/com\.android\.application"?\s+version\s+"9\.1\.0"/.test(settingsGradle)) {
  fail('settings.gradle: Android Gradle Plugin must be pinned to 9.1.0');
}
if (!/org\.jetbrains\.kotlin\.android"?\s+version\s+"2\.4\.0"/.test(settingsGradle)) {
  fail('settings.gradle: Kotlin Gradle Plugin must be pinned to 2.4.0');
}
if (!/gradle-9\.3\.1-all\.zip/.test(wrapperProperties)) {
  fail('gradle-wrapper.properties: Gradle must be pinned to 9.3.1');
}
if (!/FLUTTER_VERSION:\s*3\.47\.5/.test(workflow)) {
  fail('release-checks.yml: FLUTTER_VERSION must be pinned to 3.47.5');
}
if (!/appbundle --release/.test(workflow)) {
  fail('release-checks.yml: the release AAB build path is missing');
}

const pubspecVersion = pubspec.match(/^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)\s*$/m);
if (!pubspecVersion) {
  fail('pubspec.yaml: version must keep the <name>+<code> shape');
} else {
  const [, name, code] = pubspecVersion;
  if (expectVersionName && name !== expectVersionName) {
    fail(`pubspec.yaml: version name is ${name}, expected ${expectVersionName}`);
  }
  if (expectVersionCode && code !== String(expectVersionCode)) {
    fail(`pubspec.yaml: version code is ${code}, expected ${expectVersionCode}`);
  }
}

if (!new RegExp(`android:label="${expectLabel}"`).test(manifest)) {
  fail(`AndroidManifest.xml: application label must be ${expectLabel}`);
}
if (!/title:\s*'Training Arena'/.test(dartMain)) {
  fail("arena_app.dart: MaterialApp title must be 'Training Arena'");
}

// ------------------------------------------------------------------- aapt

function findTool(tool) {
  const extensions = process.platform === 'win32' ? ['.exe', '.bat', ''] : [''];
  const candidates = [];

  const sdkRoots = [process.env.ANDROID_HOME, process.env.ANDROID_SDK_ROOT]
    .filter(Boolean);
  // Local developer runs may only have app/android/local.properties.
  try {
    const localProperties = readFileSync(
      join(root, 'app', 'android', 'local.properties'),
      'utf8',
    );
    const match = localProperties.match(/^sdk\.dir\s*=\s*(.+)\s*$/m);
    if (match) {
      const unescaped = match[1].trim().replace(/\\\\/g, '\\').replace(/\\:/g, ':');
      sdkRoots.push(unescaped);
    }
  } catch {
    // no local.properties
  }
  for (const sdk of sdkRoots) {
    const buildTools = join(sdk, 'build-tools');
    if (!existsSync(buildTools)) {
      continue;
    }
    const versions = readdirSync(buildTools).sort((a, b) =>
      a.localeCompare(b, undefined, { numeric: true }));
    for (const version of versions.reverse()) {
      for (const extension of extensions) {
        candidates.push(join(buildTools, version, `${tool}${extension}`));
      }
    }
  }

  for (const candidate of candidates) {
    if (existsSync(candidate)) {
      return candidate;
    }
  }
  try {
    const locator = process.platform === 'win32' ? 'where' : 'which';
    const output = execFileSync(locator, [tool], { encoding: 'utf8' });
    const first = output.split(/\r?\n/).find((line) => line.trim().length > 0);
    if (first) {
      return first.trim();
    }
  } catch {
    // fall through
  }
  return null;
}

function parseBadging(text) {
  const parsed = { permissions: [], features: [] };
  for (const line of text.split(/\r?\n/)) {
    let match = line.match(/^package: name='([^']+)' versionCode='([^']*)' versionName='([^']*)'/);
    if (match) {
      parsed.package = match[1];
      parsed.versionCode = match[2];
      parsed.versionName = match[3];
      continue;
    }
    match = line.match(/^sdkVersion:'([^']*)'/);
    if (match) {
      parsed.minSdk = match[1];
      continue;
    }
    match = line.match(/^targetSdkVersion:'([^']*)'/);
    if (match) {
      parsed.targetSdk = match[1];
      continue;
    }
    match = line.match(/^application-label:'([^']*)'/);
    if (match) {
      parsed.label = match[1];
      continue;
    }
    if (/^application-debuggable/.test(line)) {
      parsed.debuggable = true;
      continue;
    }
    match = line.match(/^uses-permission: name='([^']+)'/);
    if (match) {
      parsed.permissions.push(match[1]);
      continue;
    }
    match = line.match(/^uses-feature-not-required: name='([^']+)'/);
    if (match) {
      parsed.features.push({ name: match[1], required: false });
      continue;
    }
  }
  return parsed;
}

if (apk) {
  const artifactPath = resolve(root, apk);
  if (!existsSync(artifactPath)) {
    fail(`artifact not found: ${artifactPath}`);
  } else {
    const aapt = findTool('aapt');
    if (!aapt) {
      fail('aapt not found; set ANDROID_HOME or put build-tools on PATH');
    } else {
      const badging = execFileSync(aapt, ['dump', 'badging', artifactPath], {
        encoding: 'utf8',
        maxBuffer: 32 * 1024 * 1024,
      });
      const parsed = parseBadging(badging);

      if (parsed.package !== expectPackage) {
        fail(`artifact: package is ${parsed.package}, expected ${expectPackage}`);
      }
      if (parsed.minSdk !== expectMinSdk) {
        fail(`artifact: minSdk is ${parsed.minSdk}, expected ${expectMinSdk}`);
      }
      if (parsed.targetSdk !== expectTargetSdk) {
        fail(`artifact: targetSdk is ${parsed.targetSdk}, expected ${expectTargetSdk}`);
      }
      if (parsed.label !== expectLabel) {
        fail(`artifact: label is ${parsed.label}, expected ${expectLabel}`);
      }
      if (expectVersionName && parsed.versionName !== expectVersionName) {
        fail(`artifact: versionName is ${parsed.versionName}, expected ${expectVersionName}`);
      }
      if (expectVersionCode && parsed.versionCode !== String(expectVersionCode)) {
        fail(`artifact: versionCode is ${parsed.versionCode}, expected ${expectVersionCode}`);
      }
      if (release && parsed.debuggable) {
        fail('artifact: release check refused a debuggable APK');
      }
      if (!parsed.permissions.includes('android.permission.INTERNET')) {
        fail('artifact: INTERNET permission is missing');
      }
      if (!parsed.permissions.includes('android.permission.CAMERA')) {
        fail('artifact: CAMERA permission is missing');
      }

      const sha256 = createHash('sha256')
        .update(readFileSync(artifactPath))
        .digest('hex');
      const size = statSync(artifactPath).size;
      console.log(`artifact: ${artifactPath}`);
      console.log(`artifact sha256: ${sha256}`);
      console.log(`artifact bytes: ${size}`);
      console.log(`artifact identity: ${parsed.package} ${parsed.versionName}+${parsed.versionCode} ` +
        `minSdk ${parsed.minSdk} targetSdk ${parsed.targetSdk} label "${parsed.label}"` +
        `${parsed.debuggable ? ' [debuggable]' : ''}`);

      if (expectSigner) {
        const apksigner = findTool('apksigner');
        if (!apksigner) {
          fail('apksigner not found; cannot verify the signing certificate');
        } else {
          const verify = execFileSync(
            apksigner,
            ['verify', '--print-certs', artifactPath],
            { encoding: 'utf8', maxBuffer: 16 * 1024 * 1024 },
          );
          const digest = verify.match(
            /Signer #1 certificate SHA-256 digest:\s*([0-9a-fA-F:]+)/,
          );
          if (!digest) {
            fail('apksigner: no signer certificate reported');
          } else {
            const actual = digest[1].replace(/:/g, '').toUpperCase();
            const expected = expectSigner.replace(/:/g, '').toUpperCase();
            console.log(`artifact signer sha256: ${actual}`);
            if (actual !== expected) {
              fail('artifact: signing certificate does not match --expect-signer-sha256');
            }
          }
        }
      }
    }
  }
}

if (failures.length > 0) {
  console.error('artifact identity check failed:');
  for (const message of failures) {
    console.error(` - ${message}`);
  }
  process.exit(1);
}
console.log(apk ? 'artifact identity check passed' : 'source identity check passed');
