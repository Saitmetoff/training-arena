/*
 * Unit tests for the public pages' owner-field filler and the external
 * account-deletion client.
 *
 * Run with: node --test challenge-web/test/public_pages.test.mjs
 *
 * The deletion client is loaded as the shipped file (no copy), with a fake
 * fetch, so the assertions cover the real request shapes, the ownership flow
 * and the error/retry behavior. No test performs a network call.
 */
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { dirname, join } from 'node:path';
import { test } from 'node:test';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const require = createRequire(import.meta.url);
const deletion = require(join(root, 'delete_account.js'));

const CONFIG = {
  apiBase: 'https://project.example',
  supabaseAnonKey: 'anon-key-value',
};

function jsonResponse(status, payload) {
  return { status, json: async () => payload };
}

function recordingFetch(plan) {
  const calls = [];
  const fetchImpl = async (url, init) => {
    calls.push({ url, init, body: JSON.parse(init.body) });
    const step = plan(calls.length - 1, calls[calls.length - 1]);
    if (step instanceof Error) {
      throw step;
    }
    return step;
  };
  return { calls, fetchImpl };
}

function deferred() {
  let resolve;
  const promise = new Promise((res) => {
    resolve = res;
  });
  return { promise, resolve };
}

test('rejects a malformed email without any network call', async () => {
  const { calls, fetchImpl } = recordingFetch(() => jsonResponse(200, {}));
  const client = deletion.createDeletionClient(CONFIG, fetchImpl);
  const result = await client.requestCode('not-an-email');
  assert.equal(result.ok, false);
  assert.equal(result.error.code, 'email_invalid');
  assert.equal(calls.length, 0);
});

test('is not configured without an apiBase and anon key', async () => {
  const client = deletion.createDeletionClient({ apiBase: '', supabaseAnonKey: '' });
  assert.equal(client.configured(), false);
  const result = await client.requestCode('player@example.com');
  assert.equal(result.ok, false);
  assert.equal(result.error.code, 'not_configured');
});

test('requests the code with create_user:false and the project anon key', async () => {
  const { calls, fetchImpl } = recordingFetch(() => jsonResponse(200, {}));
  const client = deletion.createDeletionClient(CONFIG, fetchImpl);
  const result = await client.requestCode('player@example.com');
  assert.equal(result.ok, true);
  assert.equal(calls.length, 1);
  assert.equal(calls[0].url, 'https://project.example/auth/v1/otp');
  assert.equal(calls[0].init.method, 'POST');
  assert.equal(calls[0].init.headers.apikey, 'anon-key-value');
  assert.equal(calls[0].init.headers.authorization, 'Bearer anon-key-value');
  assert.deepEqual(calls[0].body, {
    email: 'player@example.com',
    create_user: false,
  });
});

test('maps a rate limit to a retryable error', async () => {
  const { fetchImpl } = recordingFetch(() =>
    jsonResponse(429, { error_code: 'over_email_send_rate_limit' }));
  const client = deletion.createDeletionClient(CONFIG, fetchImpl);
  const result = await client.requestCode('player@example.com');
  assert.equal(result.ok, false);
  assert.equal(result.error.code, 'rate_limited');
  assert.equal(result.error.retryable, true);
});

test('verifies the code and deletes with the verified session bearer', async () => {
  const { calls, fetchImpl } = recordingFetch((index) => {
    if (index === 0) {
      return jsonResponse(200, { access_token: 'session-token-1234' });
    }
    return jsonResponse(200, { data: { ok: true, already_deleted: false } });
  });
  const client = deletion.createDeletionClient(CONFIG, fetchImpl);
  const verified = await client.verifyCode('player@example.com', '123 456');
  assert.equal(verified.ok, true);
  assert.equal(client.hasSession(), true);
  assert.equal(calls[0].url, 'https://project.example/auth/v1/verify');
  assert.deepEqual(calls[0].body, {
    type: 'email',
    email: 'player@example.com',
    token: '123456',
  });

  const removed = await client.deleteAccount();
  assert.equal(removed.ok, true);
  assert.equal(removed.alreadyDeleted, false);
  assert.equal(client.hasSession(), false);
  assert.equal(calls[1].url, 'https://project.example/functions/v1/arena');
  assert.equal(calls[1].init.headers.authorization, 'Bearer session-token-1234');
  assert.deepEqual(calls[1].body, { action: 'delete_account', params: {} });

  const again = await client.deleteAccount();
  assert.equal(again.ok, false);
  assert.equal(again.error.code, 'not_verified');
  assert.equal(calls.length, 2);
});

test('an expired code is reported and no session is kept', async () => {
  const { fetchImpl } = recordingFetch(() =>
    jsonResponse(401, { error_code: 'otp_expired' }));
  const client = deletion.createDeletionClient(CONFIG, fetchImpl);
  const result = await client.verifyCode('player@example.com', '000000');
  assert.equal(result.ok, false);
  assert.equal(result.error.code, 'code_invalid');
  assert.equal(client.hasSession(), false);
});

test('a network failure keeps the verified session so the retry is safe', async () => {
  const { calls, fetchImpl } = recordingFetch((index) => {
    if (index === 0) {
      return jsonResponse(200, { access_token: 'session-token-1234' });
    }
    if (index === 1) {
      return new Error('socket down');
    }
    return jsonResponse(200, { data: { ok: true, already_deleted: false } });
  });
  const client = deletion.createDeletionClient(CONFIG, fetchImpl);
  assert.equal((await client.verifyCode('player@example.com', '123456')).ok, true);
  const failed = await client.deleteAccount();
  assert.equal(failed.ok, false);
  assert.equal(failed.error.retryable, true);
  assert.equal(client.hasSession(), true);
  const retried = await client.deleteAccount();
  assert.equal(retried.ok, true);
  assert.equal(calls.length, 3);
});

test('a dead session after deletion is not presented as a retryable failure', async () => {
  const { fetchImpl } = recordingFetch((index) => {
    if (index === 0) {
      return jsonResponse(200, { access_token: 'session-token-1234' });
    }
    return jsonResponse(401, { error: { code: 'unauthorized' } });
  });
  const client = deletion.createDeletionClient(CONFIG, fetchImpl);
  assert.equal((await client.verifyCode('player@example.com', '123456')).ok, true);
  const result = await client.deleteAccount();
  assert.equal(result.ok, false);
  assert.equal(result.error.code, 'session_expired');
  assert.equal(result.error.retryable, false);
});

test('a late verification for A cannot authenticate or delete for B', async () => {
  const verifyA = deferred();
  const calls = [];
  const fetchImpl = async (url, init) => {
    calls.push({ url, init, body: JSON.parse(init.body) });
    if (url.endsWith('/auth/v1/verify')) {
      return init.body.includes('111111')
        ? verifyA.promise
        : jsonResponse(200, { access_token: 'session-b' });
    }
    if (url.endsWith('/auth/v1/otp')) {
      return jsonResponse(200, {});
    }
    return jsonResponse(200, { data: { ok: true, already_deleted: false } });
  };
  const client = deletion.createDeletionClient(CONFIG, fetchImpl);

  const pendingA = client.verifyCode('a@example.com', '111111');
  // Restart and complete an unrelated verification for B.
  client.forget();
  assert.equal((await client.requestCode('b@example.com')).ok, true);
  assert.equal((await client.verifyCode('b@example.com', '222222')).ok, true);

  // A's stale success must not authenticate anything.
  verifyA.resolve(jsonResponse(200, { access_token: 'session-a' }));
  const lateA = await pendingA;
  assert.equal(lateA.ok, false);
  assert.equal(lateA.error.code, 'superseded');
  assert.equal(client.hasSession(), true);

  // The destructive action must use B's identity, never A's.
  assert.equal((await client.deleteAccount()).ok, true);
  const deleteCall = calls.filter((call) => call.url.endsWith('/functions/v1/arena')).pop();
  assert.equal(deleteCall.init.headers.authorization, 'Bearer session-b');
});

test('an out-of-order code request cannot overwrite a newer one', async () => {
  const first = deferred();
  const fetchImpl = (url, init) => {
    if (url.endsWith('/auth/v1/otp')) {
      return JSON.parse(init.body).email === 'a@example.com'
        ? first.promise
        : Promise.resolve(jsonResponse(200, {}));
    }
    return Promise.resolve(jsonResponse(200, {}));
  };
  const client = deletion.createDeletionClient(CONFIG, fetchImpl);

  const pendingA = client.requestCode('a@example.com');
  assert.equal((await client.requestCode('b@example.com')).ok, true);

  first.resolve(jsonResponse(200, {}));
  const lateA = await pendingA;
  assert.equal(lateA.ok, false);
  assert.equal(lateA.error.code, 'superseded');
});

test('a late delete completion after restart is ignored', async () => {
  const pendingDelete = deferred();
  const fetchImpl = (url) => {
    if (url.endsWith('/auth/v1/verify')) {
      return Promise.resolve(jsonResponse(200, { access_token: 'session-token-1234' }));
    }
    if (url.endsWith('/functions/v1/arena')) {
      return pendingDelete.promise;
    }
    return Promise.resolve(jsonResponse(200, {}));
  };
  const client = deletion.createDeletionClient(CONFIG, fetchImpl);
  assert.equal((await client.verifyCode('a@example.com', '123456')).ok, true);

  const deletes = client.deleteAccount();
  client.forget();
  pendingDelete.resolve(jsonResponse(200, { data: { ok: true } }));

  const late = await deletes;
  assert.equal(late.ok, false);
  assert.equal(late.error.code, 'superseded');
  assert.equal(client.hasSession(), false);
});

test('an HTTP 200 business error is not a confirmed deletion', async () => {
  const { calls, fetchImpl } = recordingFetch((index) => {
    if (index === 0) {
      return jsonResponse(200, { access_token: 'session-token-1234' });
    }
    if (index === 1) {
      return jsonResponse(200, {
        data: null,
        error: { code: 'conflict', message: 'rejected' },
      });
    }
    return jsonResponse(200, { data: { ok: true, already_deleted: false } });
  });
  const client = deletion.createDeletionClient(CONFIG, fetchImpl);
  assert.equal((await client.verifyCode('player@example.com', '123456')).ok, true);

  const rejected = await client.deleteAccount();
  assert.equal(rejected.ok, false);
  assert.equal(rejected.error.code, 'conflict');
  assert.equal(client.hasSession(), true, 'a business error must keep the session');

  assert.equal((await client.deleteAccount()).ok, true);
  assert.equal(calls.length, 3);
});

test('a malformed success payload is rejected and keeps retry state', async () => {
  const { fetchImpl } = recordingFetch((index) => {
    if (index === 0) {
      return jsonResponse(200, { access_token: 'session-token-1234' });
    }
    return jsonResponse(200, { data: {} });
  });
  const client = deletion.createDeletionClient(CONFIG, fetchImpl);
  assert.equal((await client.verifyCode('player@example.com', '123456')).ok, true);

  const result = await client.deleteAccount();
  assert.equal(result.ok, false);
  assert.equal(client.hasSession(), true);
});

test('the shipped deletion script never logs and never persists', () => {
  const source = readFileSync(join(root, 'delete_account.js'), 'utf8');
  assert.doesNotMatch(source, /console\.(log|error|warn|debug|info|trace)/);
  assert.doesNotMatch(source, /localStorage|sessionStorage|document\.cookie/);
  assert.doesNotMatch(source, /create_user:\s*true/);
});

test('every owner field used by a page exists in config.js', () => {
  const config = readFileSync(join(root, 'config.js'), 'utf8');
  for (const name of ['privacy.html', 'support.html', 'delete-account.html']) {
    const html = readFileSync(join(root, name), 'utf8');
    const fields = [...html.matchAll(/data-arena-field="([a-zA-Z0-9_]+)"/g)]
      .map((match) => match[1]);
    for (const field of new Set(fields)) {
      assert.match(config, new RegExp(`\\b${field}\\s*:`),
        `${name} uses ${field}, which is missing from config.js`);
    }
  }
});
