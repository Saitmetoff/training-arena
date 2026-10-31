#!/usr/bin/env node
/*
 * Training Arena Android bundle / native compatibility check.
 *
 * Inspects an AAB (and optionally a derived APK) for the Play 2026
 * requirements that a configured SDK number alone cannot prove:
 *
 *   - final merged manifest: package, versionCode/Name, min/target SDK,
 *     debuggable flag, permissions, features
 *   - arm64-v8a (and other ABI) native libraries present
 *   - every packaged .so is 16 KB ELF-aligned (PT_LOAD p_align >= 16384)
 *   - uncompressed .so entries are 16 KB ZIP-aligned
 *   - delivery size estimate from bundletool for a representative device
 *   - optional upload-key certificate pin (AAB JAR signature via keytool)
 *
 * bundletool is pinned and verified by SHA-256; it is downloaded to the
 * build tree on first use. zipalign is used when available.
 *
 * Usage:
 *   node tools/release/check_android_bundle.mjs --aab <path> [--apk <path>]
 *     [--expect-target-sdk 36] [--expect-version-name 1.0.0]
 *     [--expect-version-code 1] [--expect-uploader-sha256 <hex>]
 */
import { execFileSync } from 'node:child_process';
import { existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { inflateRawSync } from 'node:zlib';

import {
  BUNDLETOOL_URL,
  BUNDLETOOL_VERSION,
  resolveBundletool,
} from './bundletool.mjs';

const args = process.argv.slice(2);

function flag(name) {
  return args.includes(name);
}

function option(name, fallback = null) {
  const index = args.indexOf(name);
  return index >= 0 && index + 1 < args.length ? args[index + 1] : fallback;
}

const root = resolve(option('--root') ?? process.cwd());
const aabPath = option('--aab');
const apkPath = option('--apk');
const expectTargetSdk = option('--expect-target-sdk', '36');
const expectMinSdk = option('--expect-min-sdk', '24');
const expectPackage = option('--expect-package', 'app.trainingarena.mobile');
const expectVersionName = option('--expect-version-name');
const expectVersionCode = option('--expect-version-code');
const expectUploader = option('--expect-uploader-sha256');
const toolCache = resolve(option('--tool-cache', join(root, 'app', 'build', 'tools')));

const failures = [];
const notes = [];

function fail(message) {
  failures.push(message);
}

function note(message) {
  notes.push(message);
  console.log(`note: ${message}`);
}

if (!aabPath && !apkPath) {
  console.error('usage: check_android_bundle.mjs --aab <path> [--apk <path>]');
  process.exit(2);
}

// ------------------------------------------------------------- bundletool

function javaBin() {
  const home = process.env.JAVA_HOME;
  if (home) {
    const candidate = join(home, 'bin', process.platform === 'win32' ? 'java.exe' : 'java');
    if (existsSync(candidate)) {
      return candidate;
    }
  }
  return 'java';
}

function keytoolBin() {
  const home = process.env.JAVA_HOME;
  if (home) {
    const candidate = join(home, 'bin', process.platform === 'win32' ? 'keytool.exe' : 'keytool');
    if (existsSync(candidate)) {
      return candidate;
    }
  }
  return 'keytool';
}

function downloadBundletool(cached) {
  console.log(`downloading bundletool ${BUNDLETOOL_VERSION} ...`);
  mkdirSync(toolCache, { recursive: true });
  const script = process.platform === 'win32'
    ? `Invoke-WebRequest -Uri '${BUNDLETOOL_URL}' -OutFile '${cached}' -UseBasicParsing`
    : `curl -s -L --fail -o '${cached}' '${BUNDLETOOL_URL}'`;
  execFileSync(process.platform === 'win32' ? 'powershell' : 'bash',
    [process.platform === 'win32' ? '-Command' : '-c', script], { stdio: 'inherit' });
}

// Resolves the pinned bundletool and verifies its SHA-256 before any Java
// process may start. A mismatched or unreadable JAR (cached or explicit) is
// refused here, so unverified bytes are never executed.
function bundletool() {
  const explicit = option('--bundletool') ?? process.env.BUNDLETOOL_JAR;
  const cached = join(toolCache, `bundletool-all-${BUNDLETOOL_VERSION}.jar`);
  const result = resolveBundletool({
    explicit: explicit ? resolve(explicit) : null,
    cachedPath: cached,
    exists: existsSync,
    readFile: readFileSync,
    download: () => downloadBundletool(cached),
  });
  if (!result.ok) {
    console.error('android bundle check failed:');
    console.error(` - ${result.error}`);
    console.error(' - refusing to execute an unverified bundletool jar');
    process.exit(1);
  }
  return result.path;
}

function runBundletool(toolArgs) {
  return execFileSync(javaBin(), ['-jar', bundletool(), ...toolArgs], {
    encoding: 'utf8',
    maxBuffer: 64 * 1024 * 1024,
  });
}

// ------------------------------------------------------------------- zip

function readZipEntries(file) {
  const buffer = readFileSync(file);
  let eocd = -1;
  for (let i = buffer.length - 22; i >= Math.max(0, buffer.length - 65558); i--) {
    if (buffer.readUInt32LE(i) === 0x06054b50) {
      eocd = i;
      break;
    }
  }
  if (eocd < 0) {
    throw new Error(`not a zip file: ${file}`);
  }
  const count = buffer.readUInt16LE(eocd + 10);
  let offset = buffer.readUInt32LE(eocd + 16);
  const entries = [];
  for (let i = 0; i < count; i++) {
    if (buffer.readUInt32LE(offset) !== 0x02014b50) {
      throw new Error(`bad central directory entry at ${offset}`);
    }
    const method = buffer.readUInt16LE(offset + 10);
    const compressedSize = buffer.readUInt32LE(offset + 20);
    const uncompressedSize = buffer.readUInt32LE(offset + 24);
    const nameLength = buffer.readUInt16LE(offset + 28);
    const extraLength = buffer.readUInt16LE(offset + 30);
    const commentLength = buffer.readUInt16LE(offset + 32);
    const localOffset = buffer.readUInt32LE(offset + 42);
    const name = buffer.toString('utf8', offset + 46, offset + 46 + nameLength);
    entries.push({ name, method, compressedSize, uncompressedSize, localOffset, buffer });
    offset += 46 + nameLength + extraLength + commentLength;
  }
  return entries;
}

function entryData(entry) {
  const { buffer, localOffset } = entry;
  if (buffer.readUInt32LE(localOffset) !== 0x04034b50) {
    throw new Error(`bad local header for ${entry.name}`);
  }
  const nameLength = buffer.readUInt16LE(localOffset + 26);
  const extraLength = buffer.readUInt16LE(localOffset + 28);
  const dataOffset = localOffset + 30 + nameLength + extraLength;
  const raw = buffer.subarray(dataOffset, dataOffset + entry.compressedSize);
  if (entry.method === 0) {
    return { data: raw, dataOffset, stored: true };
  }
  if (entry.method === 8) {
    return { data: inflateRawSync(raw), dataOffset, stored: false };
  }
  throw new Error(`unsupported compression method ${entry.method} for ${entry.name}`);
}

// ------------------------------------------------------------------- elf

function elfAlignment(data) {
  if (data.length < 64 || data[0] !== 0x7f || data[1] !== 0x45 ||
      data[2] !== 0x4c || data[3] !== 0x46) {
    return { valid: false };
  }
  const is64 = data[4] === 2;
  const little = data[5] === 1;
  const read = (offset, size) => {
    let value = 0n;
    for (let i = size - 1; i >= 0; i--) {
      const byte = little ? data[offset + i] : data[offset + (size - 1 - i)];
      value = (value << 8n) | BigInt(byte);
    }
    return value;
  };
  const phoff = Number(is64 ? read(32, 8) : read(28, 4));
  const phentsize = Number(is64 ? read(54, 2) : read(42, 2));
  const phnum = Number(is64 ? read(56, 2) : read(44, 2));
  const machine = Number(read(18, 2));
  const loads = [];
  for (let i = 0; i < phnum; i++) {
    const base = phoff + i * phentsize;
    const type = Number(read(base, 4));
    if (type !== 1) {
      continue;
    }
    const align = Number(is64 ? read(base + 48, 8) : read(base + 28, 4));
    loads.push(align);
  }
  return { valid: true, machine, loads };
}

const MACHINES = { 0x28: 'arm', 0xb7: 'aarch64', 0x3e: 'x86_64', 0x03: 'x86' };

function checkNativeLibs(artifact, label, requireArm64) {
  const entries = readZipEntries(artifact).filter((entry) => /^base\/lib\/.*\.so$/.test(entry.name) ||
    /^lib\/.*\.so$/.test(entry.name));
  if (entries.length === 0) {
    fail(`${label}: no native libraries found`);
    return;
  }
  const abis = new Set();
  let bad = 0;
  for (const entry of entries) {
    const parts = entry.name.split('/');
    const abi = parts[parts.length - 2] ?? 'unknown';
    abis.add(abi);
    const { data, dataOffset, stored } = entryData(entry);
    const elf = elfAlignment(data);
    if (!elf.valid) {
      fail(`${label}: ${entry.name} is not an ELF file`);
      bad++;
      continue;
    }
    const minAlign = Math.min(...elf.loads, Infinity);
    // 16 KB page-size devices are 64-bit only; 32-bit ARM/x86 libraries run
    // on 4 KB kernels and are not part of the Play 16 KB requirement.
    const is64Bit = elf.machine === 0xb7 || elf.machine === 0x3e;
    if (is64Bit && (!Number.isFinite(minAlign) || minAlign < 16384)) {
      fail(`${label}: ${entry.name} PT_LOAD alignment ${minAlign} < 16384`);
      bad++;
    } else if (!is64Bit && (!Number.isFinite(minAlign) || minAlign < 4096)) {
      fail(`${label}: ${entry.name} PT_LOAD alignment ${minAlign} < 4096`);
      bad++;
    }
    if (stored && dataOffset % 16384 !== 0 && is64Bit) {
      fail(`${label}: ${entry.name} stored at offset ${dataOffset}, not 16 KB aligned`);
      bad++;
    }
  }
  console.log(`${label}: ${entries.length} native libraries, ABIs: ${[...abis].sort().join(', ')}`);
  for (const entry of entries) {
    const { data } = entryData(entry);
    const elf = elfAlignment(data);
    const minAlign = Math.min(...elf.loads, Infinity);
    console.log(`  ${entry.name} (${MACHINES[elf.machine] ?? 'unknown'}${entry.method === 0 ? ', stored' : ', compressed'}, p_align ${minAlign})`);
  }
  if (requireArm64 && !abis.has('arm64-v8a')) {
    fail(`${label}: arm64-v8a native libraries are missing`);
  }
  if (bad > 0) {
    console.log(`${label}: ${bad} alignment/native failures`);
  }
}

// ---------------------------------------------------------------- manifest

function parseManifest(xml) {
  const parsed = { permissions: [], features: [] };
  parsed.package = xml.match(/package="([^"]+)"/)?.[1];
  parsed.versionCode = xml.match(/android:versionCode="([^"]+)"/)?.[1];
  parsed.versionName = xml.match(/android:versionName="([^"]+)"/)?.[1];
  parsed.minSdk = xml.match(/android:minSdkVersion="([^"]+)"/)?.[1];
  parsed.targetSdk = xml.match(/android:targetSdkVersion="([^"]+)"/)?.[1];
  parsed.debuggable = /android:debuggable="true"/.test(xml);
  parsed.extractNativeLibs = xml.match(/android:extractNativeLibs="([^"]+)"/)?.[1];
  for (const match of xml.matchAll(/<uses-permission[^>]*android:name="([^"]+)"/g)) {
    parsed.permissions.push(match[1]);
  }
  for (const match of xml.matchAll(/<uses-feature[^>]*android:name="([^"]+)"[^>]*>/g)) {
    parsed.features.push(match[1]);
  }
  return parsed;
}

function checkManifest(parsed, label) {
  if (parsed.package !== expectPackage) {
    fail(`${label}: package is ${parsed.package}, expected ${expectPackage}`);
  }
  if (parsed.minSdk !== expectMinSdk) {
    fail(`${label}: minSdk is ${parsed.minSdk}, expected ${expectMinSdk}`);
  }
  if (parsed.targetSdk !== expectTargetSdk) {
    fail(`${label}: targetSdk is ${parsed.targetSdk}, expected ${expectTargetSdk}`);
  }
  if (expectVersionName && parsed.versionName !== expectVersionName) {
    fail(`${label}: versionName is ${parsed.versionName}, expected ${expectVersionName}`);
  }
  if (expectVersionCode && parsed.versionCode !== String(expectVersionCode)) {
    fail(`${label}: versionCode is ${parsed.versionCode}, expected ${expectVersionCode}`);
  }
  if (parsed.debuggable) {
    fail(`${label}: manifest is debuggable`);
  }
  for (const permission of ['android.permission.INTERNET', 'android.permission.CAMERA']) {
    if (!parsed.permissions.includes(permission)) {
      fail(`${label}: missing permission ${permission}`);
    }
  }
  console.log(`${label}: ${parsed.package} ${parsed.versionName}+${parsed.versionCode} ` +
    `minSdk ${parsed.minSdk} targetSdk ${parsed.targetSdk} ` +
    `extractNativeLibs=${parsed.extractNativeLibs ?? 'default'}`);
  console.log(`${label}: permissions ${parsed.permissions.sort().join(', ')}`);
  console.log(`${label}: features ${parsed.features.sort().join(', ') || '(none)'}`);
}

// -------------------------------------------------------------------- main

const tool = bundletool();

if (aabPath) {
  const artifact = resolve(root, aabPath);
  if (!existsSync(artifact)) {
    fail(`AAB not found: ${artifact}`);
  } else {
    const manifestXml = runBundletool(['dump', 'manifest', '--bundle', artifact, '--module', 'base']);
    checkManifest(parseManifest(manifestXml), 'aab manifest');
    checkNativeLibs(artifact, 'aab', true);

    const apks = join(toolCache, 'arena-inspect.apks');
    runBundletool(['build-apks', '--bundle', artifact, '--output', apks, '--overwrite',
      '--mode', 'default']);
    const deviceSpec = join(toolCache, 'arena-device-spec.json');
    writeFileSync(deviceSpec, JSON.stringify({
      supportedAbis: ['arm64-v8a'],
      supportedLocales: ['en-US'],
      screenDensity: 420,
      sdkVersion: 36,
    }));
    const sizeOutput = runBundletool(['get-size', 'total', '--apks', apks,
      '--device-spec', deviceSpec, '--dimensions', 'ALL']);
    console.log('bundle delivery sizes (arm64-v8a, en-US, 420dpi, API 36):');
    console.log(sizeOutput.trim());

    if (expectUploader) {
      const printed = execFileSync(keytoolBin(),
        ['-printcert', '-jarfile', artifact], { encoding: 'utf8' });
      const digest = printed.match(/SHA256:\s*([0-9A-F:]+)/i);
      if (!digest) {
        fail('aab: keytool reported no certificate');
      } else {
        const actual = digest[1].replace(/:/g, '').toUpperCase();
        const expected = expectUploader.replace(/:/g, '').toUpperCase();
        console.log(`aab uploader certificate sha256: ${actual}`);
        if (actual !== expected) {
          fail('aab: upload-key certificate does not match --expect-uploader-sha256');
        }
      }
    } else {
      note('AAB signer not pinned (no --expect-uploader-sha256); unsigned AAB is expected until the owner provides the upload key.');
    }
  }
}

if (apkPath) {
  const artifact = resolve(root, apkPath);
  if (!existsSync(artifact)) {
    fail(`APK not found: ${artifact}`);
  } else {
    checkNativeLibs(artifact, 'apk', true);
    const sdkRoot = process.env.ANDROID_HOME ?? process.env.ANDROID_SDK_ROOT ??
      (() => {
        try {
          const local = readFileSync(join(root, 'app', 'android', 'local.properties'), 'utf8');
          const match = local.match(/^sdk\.dir\s*=\s*(.+)\s*$/m);
          return match ? match[1].trim().replace(/\\\\/g, '\\').replace(/\\:/g, ':') : null;
        } catch {
          return null;
        }
      })();
    if (sdkRoot) {
      const buildTools = join(sdkRoot, 'build-tools');
      if (existsSync(buildTools)) {
        const versions = readdirSync(buildTools)
          .sort((a, b) => b.localeCompare(a, undefined, { numeric: true }));
        for (const version of versions) {
          const zipalign = join(buildTools, version,
            process.platform === 'win32' ? 'zipalign.exe' : 'zipalign');
          if (existsSync(zipalign)) {
            try {
              execFileSync(zipalign, ['-c', '-P', '16', '-v', '4', artifact],
                { encoding: 'utf8', stdio: 'pipe' });
              console.log(`apk: zipalign -P 16 verification passed (build-tools ${version})`);
            } catch (error) {
              fail(`apk: zipalign -P 16 failed: ${String(error.stdout ?? error).split('\n')[0]}`);
            }
            break;
          }
        }
      }
    }
  }
}

if (failures.length > 0) {
  console.error('android bundle check failed:');
  for (const message of failures) {
    console.error(` - ${message}`);
  }
  process.exit(1);
}
console.log('android bundle check passed');
