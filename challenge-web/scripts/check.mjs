/*
 * Static checks for the challenge landing page and the public policy,
 * support and account-deletion pages.
 *
 * Run with: node challenge-web/scripts/check.mjs
 *           node challenge-web/scripts/check.mjs --release
 *
 * Verifies the constraints that matter for a link that must stay read-only:
 * no mutation verbs, no secrets, passive social preview and the reopen
 * instruction. It also checks that the deletion page uses the documented
 * ownership flow, keeps the session in memory only and never logs, and that
 * every owner field used by a page exists in config.js. With `--release` it
 * additionally refuses to pass while any owner value or endpoint is still a
 * placeholder, so an unfinished policy cannot be published. It does not test
 * hosting, App Links verification or a live deletion request.
 */
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const release = process.argv.includes('--release');
const failures = [];

function read(name) {
  return readFileSync(join(root, name), 'utf8');
}

function check(condition, message) {
  if (!condition) {
    failures.push(message);
  }
}

const app = read('app.js');
const html = read('index.html');
const config = read('config.js');
const link = read('link.js');

check(!/method:\s*['"]POST['"]/i.test(app), 'app.js must not POST');
check(!/method:\s*['"](PUT|PATCH|DELETE)['"]/i.test(app), 'app.js must not mutate');
check(/method:\s*['"]GET['"]/.test(app), 'app.js resolve must be an explicit GET');
check(/\/functions\/v1\/arena\?token=/.test(app), 'resolve must use the documented GET path');
check(!/document\.cookie/.test(app), 'landing must not use cookies');
check(!/localStorage|sessionStorage/.test(app), 'landing must not persist client state');

const secretPatterns = [
  /service[_-]?role\s*[:=]\s*["'][^"']+["']/i,
  /dispatcher[_-]?secret\s*[:=]/i,
  /BEGIN [A-Z ]*PRIVATE KEY/,
  /eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}/,
];
for (const pattern of secretPatterns) {
  check(!pattern.test(config), `config.js must not contain ${pattern}`);
  check(!pattern.test(app), `app.js must not contain ${pattern}`);
}

check(/property="og:title"/.test(html), 'index.html needs a passive og:title');
check(/name="description"/.test(html), 'index.html needs a description');
check(!/\$\{token\}|%TOKEN%/i.test(html), 'social preview must not embed the token');

check(/Reopen this link after installing/.test(app), 'app.js must show the reopen instruction');
check(/readableCode/.test(app), 'app.js must render the readable short code');
check(/statusFromResolution/.test(app), 'app.js must map resolve states');
check(/withReferrer/.test(app), 'app.js must build the Play referrer URL');
check(/TOKEN_PATTERN = \/\^\[A-Za-z0-9\]\{6,32\}\$\//.test(link), 'link.js token pattern changed');

// --- Public policy, support and deletion pages ---------------------------
const privacy = read('privacy.html');
const support = read('support.html');
const deletion = read('delete-account.html');
const deletionJs = read('delete_account.js');
const ownerFields = read('pages.js');

check(/create_user:\s*false/.test(deletionJs),
  'deletion OTP request must use create_user:false (never create an account)');
check(/\/auth\/v1\/otp/.test(deletionJs) && /\/auth\/v1\/verify/.test(deletionJs),
  'deletion flow must use the documented email OTP endpoints');
check(/action:\s*'delete_account'/.test(deletionJs),
  'deletion flow must call the documented delete_account action');
check(!/localStorage|sessionStorage|document\.cookie/.test(deletionJs),
  'deletion flow must not persist anything in the browser');
check(!/console\.(log|error|warn|debug|info|trace)/.test(deletionJs + deletion),
  'deletion flow must not log (a token or code could reach a console log)');
check(!/access_token/.test(deletion),
  'delete-account.html must not embed an access token');
check(/role="status"/.test(deletion) && /aria-live/.test(deletion),
  'deletion page needs an accessible status region');
check(/\[\[/.test(privacy) && /data-arena-field/.test(privacy),
  'privacy.html must keep owner-specific values as data-arena-field placeholders');
check(/data-arena-draft/.test(privacy) && /data-arena-draft/.test(support) &&
  /data-arena-draft/.test(deletion),
  'every public page needs the draft banner');
check(/Camera frames and pose landmarks stay on your device/i.test(privacy),
  'privacy.html must state where camera frames and landmarks go');
check(!/no data is collected/i.test(privacy),
  'privacy.html must not claim that no data is collected');

for (const [name, html] of [['privacy.html', privacy], ['support.html', support],
  ['delete-account.html', deletion]]) {
  const fields = [...html.matchAll(/data-arena-field="([a-zA-Z0-9_]+)"/g)]
    .map((match) => match[1]);
  for (const field of new Set(fields)) {
    check(new RegExp(`\\b${field}\\s*:`).test(config),
      `${name} uses ${field}, which is missing from config.js`);
  }
}

for (const [name, text] of [['privacy.html', privacy], ['support.html', support],
  ['delete-account.html', deletion], ['delete_account.js', deletionJs],
  ['pages.js', ownerFields]]) {
  for (const pattern of secretPatterns) {
    check(!pattern.test(text), `${name} must not contain ${pattern}`);
  }
}

// config.js carries public client values only. The anon key may be a JWT, so
// the generic eyJ rule would be a false positive here; instead decode any
// JWT-shaped value and fail only if it claims the service role.
for (const pattern of secretPatterns.slice(0, 3)) {
  check(!pattern.test(config), `config.js must not contain ${pattern}`);
}
for (const token of [...config.matchAll(/eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]+/g)]) {
  let role = '';
  try {
    const payload = token[0].split('.')[1];
    role = JSON.parse(Buffer.from(payload, 'base64url').toString('utf8')).role ?? '';
  } catch {
    role = 'unreadable';
  }
  check(role === 'anon' || role === 'authenticated',
    `config.js contains a JWT with role "${role}"; only the public anon key is allowed`);
}

if (release) {
  const pending = [];
  for (const field of [
    'legalEntity', 'legalAddress', 'privacyEmail', 'supportEmail',
    'supportResponseTime', 'effectiveDate', 'childrenPolicy', 'emailProvider',
    'retentionMatchHistory', 'retentionAnalytics', 'retentionModeration',
    'retentionBackups',
  ]) {
    if (!new RegExp(`\\b${field}\\s*:\\s*'[^']`).test(config)) {
      pending.push(field);
    }
  }
  check(pending.length === 0,
    `--release requires owner values in config.js; still pending: ${pending.join(', ')}`);
  check(/apiBase:\s*'https:\/\/[^']+/.test(config),
    '--release requires a real apiBase in config.js');
  check(/supabaseAnonKey:\s*'[^']+/.test(config),
    '--release requires the project anon key in config.js');
}

if (failures.length > 0) {
  console.error('challenge-web check failed:');
  for (const failure of failures) {
    console.error(` - ${failure}`);
  }
  process.exit(1);
}
console.log('challenge-web check passed');
