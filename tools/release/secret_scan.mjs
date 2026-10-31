#!/usr/bin/env node
/*
 * Training Arena release secret scan.
 *
 * Scans the files that would be committed (default) or every non-build file in
 * the tree (--all), plus built Android artifacts (--artifacts) for credentials,
 * service keys, private URLs and debug Firebase files.
 *
 * Usage:
 *   node tools/release/secret_scan.mjs
 *   node tools/release/secret_scan.mjs --artifacts
 *   node tools/release/secret_scan.mjs --all
 *   node tools/release/secret_scan.mjs --json
 *
 * Exit code 1 on any finding. The scan is high-signal by design: it flags
 * real key material and forbidden files, not the words "service role" in
 * documentation. It never prints a secret value in full.
 */
import { execFileSync } from 'node:child_process';
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { basename, extname, join, relative, resolve, sep } from 'node:path';
import { inflateRawSync } from 'node:zlib';

const args = process.argv.slice(2);

function flag(name) {
  return args.includes(name);
}

function option(name) {
  const index = args.indexOf(name);
  return index >= 0 && index + 1 < args.length ? args[index + 1] : null;
}

const root = resolve(option('--root') ?? process.cwd());
const jsonOutput = flag('--json');
const scanArtifacts = flag('--artifacts');
const scanIgnored = flag('--all');

const MAX_TEXT_BYTES = 2 * 1024 * 1024;
const MAX_ARTIFACT_BYTES = 512 * 1024 * 1024;
const MAX_ZIP_MEMBER_BYTES = 4 * 1024 * 1024;

const SKIP_DIRS = new Set([
  '.git',
  'node_modules',
  '.dart_tool',
  '.gradle',
  'build',
  'gradle-home',
]);

const TEXT_EXTENSIONS = new Set([
  '.dart', '.kt', '.java', '.kts', '.gradle', '.xml', '.json', '.yaml', '.yml',
  '.toml', '.sql', '.ts', '.mjs', '.js', '.html', '.css', '.md', '.txt',
  '.properties', '.env', '.pem', '.cfg', '.sh', '.ps1', '.bat',
]);

const CONTENT_RULES = [
  {
    id: 'private-key-block',
    // A real key is a complete PEM block: header, base64 body and matching
    // footer. Bare headers in templates and interpolated test fixtures are not
    // key material. Whole-file scan so the compact `\n` JSON form matches too.
    re: /-----BEGIN (?:ENCRYPTED |RSA |EC |DSA |OPENSSH |PGP )?PRIVATE KEY-----[\sA-Za-z0-9+/=]{64,}?-----END (?:ENCRYPTED |RSA |EC |DSA |OPENSSH |PGP )?PRIVATE KEY-----/,
    why: 'private key material',
    wholeText: true,
  },
  {
    id: 'google-api-key',
    re: /\bAIza[0-9A-Za-z_-]{35}\b/,
    why: 'Google API key',
  },
  {
    id: 'firebase-service-account',
    re: /"type"\s*:\s*"service_account"/,
    why: 'Firebase/FCM service account JSON',
  },
  {
    id: 'firebase-private-key-id',
    re: /"private_key_id"\s*:\s*"[0-9a-f]{16,}"/,
    why: 'Firebase service account private key id',
  },
  {
    id: 'stripe-live-key',
    re: /\b(?:sk|rk)_live_[0-9A-Za-z]{16,}\b/,
    why: 'Stripe live secret key',
  },
  {
    id: 'aws-access-key',
    re: /\bAKIA[0-9A-Z]{16}\b/,
    why: 'AWS access key id',
  },
  {
    id: 'github-token',
    re: /\bgh[pousr]_[A-Za-z0-9]{36,}\b/,
    why: 'GitHub token',
  },
  {
    id: 'slack-token',
    re: /\bxox[baprs]-[0-9A-Za-z-]{10,}\b/,
    why: 'Slack token',
  },
  {
    id: 'supabase-service-role-jwt',
    re: /\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b/,
    why: 'JWT carrying the service_role claim (service key)',
    jwtOnly: true,
  },
  {
    id: 'url-basic-auth',
    re: /\bhttps?:\/\/[^\s\/'":@]+:[^\s\/'":@]+@[^\s'"]+/,
    why: 'URL with embedded credentials',
  },
  {
    id: 'supabase-signed-url',
    re: /\bhttps?:\/\/[^\s'"]+\/storage\/v1\/object\/[^\s'"]*[?&]token=[A-Za-z0-9._-]+/,
    why: 'signed storage URL carrying a temporary credential',
  },
  {
    id: 'assigned-secret-value',
    re: /(?:service[_-]?role[_-]?key|dispatcher[_-]?secret|client[_-]?secret|admin[_-]?secret|private[_-]?key)\s*[:=]\s*['"]([^'"]{10,})['"]/i,
    why: 'secret-looking value assigned in source',
    valueGroup: 1,
  },
];

const FORBIDDEN_FILES = [
  { re: /(^|[\\/])google-services\.json$/i, why: 'debug Firebase config must not ship' },
  { re: /(^|[\\/])GoogleService-Info\.plist$/i, why: 'debug Firebase config must not ship' },
  { re: /(^|[\\/])firebase_options\.dart$/i, why: 'debug Firebase bootstrap must not ship' },
  { re: /(^|[\\/])key\.properties$/i, why: 'signing passwords must stay outside the repository' },
  { re: /\.(jks|keystore|p12|pfx)$/i, why: 'keystore/private key material must stay outside the repository' },
  { re: /(^|[\\/])\.env(\.|$)/i, why: 'environment secret files must not be committed' },
  { re: /(^|[\\/])service[_-]?account[^\\/]*\.json$/i, why: 'service account JSON is server-only' },
  { re: /(^|[\\/])client[_-]?secret[^\\/]*\.json$/i, why: 'OAuth client secret is server-only' },
];

const findings = [];

function finding(kind, file, detail, why) {
  findings.push({ kind, file: relative(root, file), detail, why });
}

function redact(value) {
  if (typeof value !== 'string' || value.length === 0) {
    return value;
  }
  if (value.length <= 8) {
    return '***';
  }
  return `${value.slice(0, 4)}…${value.slice(-4)} (${value.length} chars)`;
}

function decodeJwtPayload(token) {
  try {
    const part = token.split('.')[1];
    const normalized = part.replace(/-/g, '+').replace(/_/g, '/');
    const padded = normalized + '='.repeat((4 - (normalized.length % 4)) % 4);
    return JSON.parse(Buffer.from(padded, 'base64').toString('utf8'));
  } catch {
    return null;
  }
}

function looksLikePlaceholder(value) {
  return /^(env\(|\$\{?\{?|<\s|REPLACE|CHANGE|YOUR_|EXAMPLE|PLACEHOLDER|example|dummy|fake|test)/i
    .test(value);
}

function scanText(text, file, { isArtifactMember = false } = {}) {
  const lines = text.split(/\r?\n/);
  for (const rule of CONTENT_RULES) {
    if (rule.wholeText) {
      const match = rule.re.exec(text);
      if (match) {
        const line = text.slice(0, match.index).split(/\r?\n/).length;
        finding(isArtifactMember ? 'artifact-content' : 'content', file,
          `${rule.id} (line ${line}, ${match[0].length} chars)`, rule.why);
      }
      continue;
    }
    lines.forEach((line, index) => {
      const match = rule.re.exec(line);
      if (!match) {
        return;
      }
      if (rule.jwtOnly) {
        const payload = decodeJwtPayload(match[0]);
        if (!payload || payload.role !== 'service_role') {
          return;
        }
      }
      if (rule.valueGroup && looksLikePlaceholder(match[rule.valueGroup])) {
        return;
      }
      const detail = rule.jwtOnly || rule.valueGroup
        ? redact(match[rule.valueGroup] ?? match[0])
        : `match at column ${match.index + 1}`;
      finding(isArtifactMember ? 'artifact-content' : 'content', file,
        `${rule.id} (${detail})`, rule.why);
    });
  }
}

function checkFileName(file) {
  const name = basename(file);
  if (name === '.env.example' || name === '.env.sample') {
    return;
  }
  const lookup = file.split(sep).join('/');
  for (const rule of FORBIDDEN_FILES) {
    if (rule.re.test(lookup)) {
      finding('file', file, rule.re.source, rule.why);
    }
  }
}

function listGitFiles() {
  try {
    const output = execFileSync(
      'git',
      ['ls-files', '--cached', '--others', '--exclude-standard', '-z'],
      { cwd: root, encoding: 'buffer', maxBuffer: 64 * 1024 * 1024 },
    );
    return output.toString('utf8').split('\0').filter(Boolean);
  } catch {
    return null;
  }
}

function walkDirs(dir, files) {
  let entries;
  try {
    entries = readdirSync(dir, { withFileTypes: true });
  } catch {
    return;
  }
  for (const entry of entries) {
    if (entry.name === '.git' || SKIP_DIRS.has(entry.name)) {
      continue;
    }
    const full = join(dir, entry.name);
    if (entry.isDirectory()) {
      walkDirs(full, files);
    } else if (entry.isFile()) {
      files.push(relative(root, full));
    }
  }
}

function scanRepository() {
  let files;
  if (scanIgnored) {
    files = [];
    walkDirs(root, files);
  } else {
    files = listGitFiles();
    if (files === null) {
      console.error('secret_scan: git not available; use --all to walk the tree');
      process.exit(2);
    }
  }

  for (const relativePath of files) {
    const full = join(root, relativePath);
    checkFileName(full);
    let stats;
    try {
      stats = statSync(full);
    } catch {
      continue;
    }
    if (stats.size > MAX_TEXT_BYTES) {
      continue;
    }
    const extension = extname(full).toLowerCase();
    if (extension && !TEXT_EXTENSIONS.has(extension)) {
      continue;
    }
    let text;
    try {
      text = readFileSync(full, 'utf8');
    } catch {
      continue;
    }
    scanText(text, full);
  }
}

// --------------------------------------------------------------- zip reader

function readZipEntries(buffer) {
  const eocdSignature = 0x06054b50;
  const minimumEocd = 22;
  const maximumComment = 65535;
  const searchStart = Math.max(0, buffer.length - minimumEocd - maximumComment);
  let eocd = -1;
  for (let index = buffer.length - minimumEocd; index >= searchStart; index -= 1) {
    if (buffer.readUInt32LE(index) === eocdSignature) {
      eocd = index;
      break;
    }
  }
  if (eocd < 0) {
    return null;
  }
  const totalEntries = buffer.readUInt16LE(eocd + 10);
  const centralOffset = buffer.readUInt32LE(eocd + 16);
  const entries = [];
  let cursor = centralOffset;
  for (let index = 0; index < totalEntries; index += 1) {
    if (cursor + 46 > buffer.length || buffer.readUInt32LE(cursor) !== 0x02014b50) {
      break;
    }
    const method = buffer.readUInt16LE(cursor + 10);
    const compressedSize = buffer.readUInt32LE(cursor + 20);
    const uncompressedSize = buffer.readUInt32LE(cursor + 24);
    const nameLength = buffer.readUInt16LE(cursor + 28);
    const extraLength = buffer.readUInt16LE(cursor + 30);
    const commentLength = buffer.readUInt16LE(cursor + 32);
    const localOffset = buffer.readUInt32LE(cursor + 42);
    const name = buffer.toString('utf8', cursor + 46, cursor + 46 + nameLength);
    entries.push({ name, method, compressedSize, uncompressedSize, localOffset });
    cursor += 46 + nameLength + extraLength + commentLength;
  }
  return entries;
}

function readZipMember(buffer, entry) {
  const localOffset = entry.localOffset;
  if (localOffset + 30 > buffer.length || buffer.readUInt32LE(localOffset) !== 0x04034b50) {
    return null;
  }
  const nameLength = buffer.readUInt16LE(localOffset + 26);
  const extraLength = buffer.readUInt16LE(localOffset + 28);
  const dataStart = localOffset + 30 + nameLength + extraLength;
  const dataEnd = dataStart + entry.compressedSize;
  if (dataEnd > buffer.length) {
    return null;
  }
  const payload = buffer.subarray(dataStart, dataEnd);
  try {
    if (entry.method === 0) {
      return payload;
    }
    if (entry.method === 8) {
      return inflateRawSync(payload);
    }
  } catch {
    return null;
  }
  return null;
}

function scanArtifact(file) {
  let buffer;
  try {
    const stats = statSync(file);
    if (stats.size > MAX_ARTIFACT_BYTES) {
      finding('artifact', file, 'artifact exceeds scan size limit', 'artifact not scanned');
      return;
    }
    buffer = readFileSync(file);
  } catch {
    return;
  }
  const entries = readZipEntries(buffer);
  if (!entries) {
    return;
  }
  for (const entry of entries) {
    const fakePath = join(root, entry.name);
    checkFileName(fakePath);
    if (
      entry.uncompressedSize > 0 &&
      entry.uncompressedSize <= MAX_ZIP_MEMBER_BYTES &&
      (TEXT_EXTENSIONS.has(extname(entry.name).toLowerCase()) ||
        entry.name.toLowerCase().endsWith('androidmanifest.xml') ||
        entry.name.startsWith('assets/'))
    ) {
      const member = readZipMember(buffer, entry);
      if (member && member.length <= MAX_ZIP_MEMBER_BYTES) {
        scanText(member.toString('utf8'), fakePath, { isArtifactMember: true });
      }
    }
  }
}

function listArtifacts() {
  const outputs = join(root, 'app', 'build', 'app', 'outputs');
  const found = [];
  try {
    const stack = [outputs];
    while (stack.length > 0) {
      const dir = stack.pop();
      for (const entry of readdirSync(dir, { withFileTypes: true })) {
        const full = join(dir, entry.name);
        if (entry.isDirectory()) {
          stack.push(full);
        } else if (/\.(apk|aab)$/i.test(entry.name)) {
          found.push(full);
        }
      }
    }
  } catch {
    return found;
  }
  return found;
}

scanRepository();

if (scanArtifacts) {
  for (const artifact of listArtifacts()) {
    scanArtifact(artifact);
  }
}

if (jsonOutput) {
  console.log(JSON.stringify({ ok: findings.length === 0, findings }, null, 2));
  if (findings.length > 0) {
    process.exit(1);
  }
} else if (findings.length === 0) {
  console.log('secret scan passed: no credential, key or forbidden file found');
} else {
  console.error(`secret scan failed: ${findings.length} finding(s)`);
  for (const item of findings) {
    console.error(` - [${item.kind}] ${item.file}: ${item.detail} (${item.why})`);
  }
  process.exit(1);
}
