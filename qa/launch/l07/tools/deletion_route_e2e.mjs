// L07 external account-deletion route — local end-to-end check.
//
// Exercises the *shipped* `challenge-web/delete_account.js` client against the
// local Supabase stack over HTTP, exactly as the public page does:
//
//   create a test account (normal sign-up) ->
//   request email code from the deletion page (create_user:false) ->
//   read the code from the local mail catcher -> verify -> delete_account ->
//   confirm the auth user is gone.
//
// No hosted service is contacted and no credential is printed: only method,
// path and status are logged, and the access token stays in memory.
//
// Run (local stack up; anon key from `supabase status -o env`):
//   $env:ARENA_ANON_KEY = '<local anon key>'
//   node qa/launch/l07/tools/deletion_route_e2e.mjs
import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";

const require = createRequire(import.meta.url);
const deletion = require(fileURLToPath(
  new URL("../../../../challenge-web/delete_account.js", import.meta.url),
));

const API = process.env.ARENA_API ?? "http://127.0.0.1:54321";
const ANON = process.env.ARENA_ANON_KEY ?? "";
const SERVICE = process.env.ARENA_SERVICE_ROLE_KEY ?? "";
const MAILPIT = process.env.ARENA_MAILPIT_URL ?? "http://127.0.0.1:54324";
const EMAIL = process.env.ARENA_E2E_EMAIL ?? "l07-deletion@arena.invalid";

if (!ANON) {
  console.error("FAIL set ARENA_ANON_KEY from `supabase status -o env`");
  process.exit(2);
}

let failures = 0;
const trace = [];
let deletingBearer = null;

function check(name, ok, detail = "") {
  console.log(`${ok ? "ok  " : "FAIL"} - ${name}${ok ? "" : ` ${detail}`}`);
  if (!ok) {
    failures += 1;
  }
}

function tracedFetch(input, init) {
  const url = new URL(String(input));
  const bearer = init?.headers?.authorization ?? "";
  if (url.pathname.endsWith("/functions/v1/arena") &&
      bearer.startsWith("Bearer ") && bearer !== `Bearer ${ANON}`) {
    deletingBearer = bearer.slice("Bearer ".length);
  }
  return globalThis.fetch(input, init).then((response) => {
    trace.push(`${init.method} ${url.pathname} -> ${response.status}`);
    return response;
  });
}

async function readMailboxCode() {
  // Local stack mail catcher (Mailpit in this Supabase CLI version). The
  // hosted project uses a real SMTP provider; this helper is local-only.
  for (let attempt = 0; attempt < 20; attempt += 1) {
    const listResponse = await globalThis.fetch(
      `${MAILPIT}/api/v1/search?query=${encodeURIComponent(`to:${EMAIL}`)}`,
    );
    if (listResponse.ok) {
      const result = await listResponse.json();
      const messages = Array.isArray(result.messages) ? result.messages : [];
      if (messages.length > 0) {
        const bodyResponse = await globalThis.fetch(
          `${MAILPIT}/api/v1/message/${messages[0].ID}`,
        );
        if (bodyResponse.ok) {
          const message = await bodyResponse.json();
          const body = `${message.Text ?? ""}\n${message.HTML ?? ""}`;
          const match = body.match(/\b(\d{6})\b/);
          if (match) {
            return match[1];
          }
        }
      }
    }
    await new Promise((resolve) => setTimeout(resolve, 500));
  }
  return null;
}

async function requestOtp(createUser) {
  const response = await globalThis.fetch(`${API}/auth/v1/otp`, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      apikey: ANON,
      authorization: `Bearer ${ANON}`,
    },
    body: JSON.stringify({ email: EMAIL, create_user: createUser }),
  });
  trace.push(`POST /auth/v1/otp(create_user:${createUser}) -> ${response.status}`);
  return response.status;
}

async function createTestUser() {
  if (SERVICE) {
    // Local service-role admin call: creates a confirmed user without sending
    // an email, so the deletion flow keeps the single email it needs inside
    // the local 2/h send limit. The key is read from the environment only.
    const response = await globalThis.fetch(`${API}/auth/v1/admin/users`, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        apikey: SERVICE,
        authorization: `Bearer ${SERVICE}`,
      },
      body: JSON.stringify({ email: EMAIL, email_confirm: true }),
    });
    trace.push(`POST /auth/v1/admin/users -> ${response.status}`);
    // 422 means the user already exists from an earlier run: still a pass.
    return response.status < 300 || response.status === 422;
  }
  const status = await requestOtp(true);
  return status < 300;
}

const client = deletion.createDeletionClient(
  { apiBase: API, supabaseAnonKey: ANON },
  tracedFetch,
);
check("shipped deletion client is configured", client.configured());

// 1. Create the test account through the normal account path.
check("test account exists before the deletion flow", await createTestUser());

// 2. The public page flow: request a code for the existing account, verify it
//    and delete.
const requested = await client.requestCode(EMAIL);
check("deletion page requested a code with create_user:false", requested.ok,
  requested.ok ? "" : requested.error.code);

const code = await readMailboxCode();
check("deletion code readable from the local mail catcher", code !== null);

if (code) {
  const verified = await client.verifyCode(EMAIL, code);
  check("deletion page verified the email code", verified.ok,
    verified.ok ? "" : verified.error.code);
  check("verified session kept in memory for the retry", client.hasSession());

  if (verified.ok) {
    const removed = await client.deleteAccount();
    check("delete_account completed through the public page client", removed.ok,
      removed.ok ? "" : removed.error.code);
    check("session cleared after the deletion", !client.hasSession());

    if (deletingBearer) {
      const probe = await globalThis.fetch(`${API}/auth/v1/user`, {
        headers: { apikey: ANON, authorization: `Bearer ${deletingBearer}` },
      });
      trace.push(`GET /auth/v1/user -> ${probe.status}`);
      check("auth user is gone after the deletion",
        probe.status === 401 || probe.status === 403, `status ${probe.status}`);
      deletingBearer = null;
    } else {
      check("access token observed for the identity probe", false);
    }
  }
}

console.log("--- request trace (method, path, status only) ---");
for (const line of trace) {
  console.log(line);
}
console.log(failures === 0 ? "PASS deletion route e2e" : `FAIL ${failures} check(s)`);
process.exit(failures === 0 ? 0 : 1);
