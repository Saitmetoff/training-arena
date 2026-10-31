// Local end-to-end smoke test for the arena Edge Function (task 04).
//
// It signs development JWTs for the local seed fixtures and calls the served
// function over HTTP:
//
//   supabase start
//   supabase db reset
//   supabase functions serve --no-verify-jwt --env-file supabase/.env.local
//   node backend/e2e/arena_smoke.mjs
//
// The fallback signing secret is Supabase's documented *local development*
// default. A hosted project has a unique secret, so this script can never
// authenticate against production. Override it with ARENA_LOCAL_JWT_SECRET.
//
// When ARENA_DISPATCHER_SECRET is set, the smoke additionally checks the
// dispatcher worker boundary (missing/wrong/valid bearer) and the shared
// outage reconciliation: both clients disappear for more than the 10 s
// absence window and the scheduled worker closes the match as
// `no_result`/`service_outage` with no rating change (L05). Without the
// variable the section is skipped and the smoke stays the task-04 smoke.
import crypto from "node:crypto";

const API = process.env.ARENA_API ?? "http://127.0.0.1:54521";
const ANON_KEY = process.env.ARENA_ANON_KEY ?? "";
const DISPATCHER_SECRET = process.env.ARENA_DISPATCHER_SECRET ?? "";
const SECRET =
  process.env.ARENA_LOCAL_JWT_SECRET ??
  "super-secret-jwt-token-with-at-least-32-characters-long";

const ALICE = {
  id: "11111111-1111-4111-8111-111111111111",
  session: "91111111-1111-4111-8111-111111111111",
  email: "fixture.alice@arena.invalid",
};
const CAROL = {
  id: "33333333-3333-4333-8333-333333333333",
  session: "93333333-3333-4333-8333-333333333333",
  email: "fixture.carol@arena.invalid",
};

function b64url(value) {
  return Buffer.from(value).toString("base64url");
}

function sign(payload, secret = SECRET) {
  const header = b64url(JSON.stringify({ alg: "HS256", typ: "JWT" }));
  const body = b64url(JSON.stringify(payload));
  const signature = crypto
    .createHmac("sha256", secret)
    .update(`${header}.${body}`)
    .digest("base64url");
  return `${header}.${body}.${signature}`;
}

function tokenFor(user, secret = SECRET) {
  const now = Math.floor(Date.now() / 1000);
  return sign(
    {
      aud: "authenticated",
      exp: now + 3600,
      iat: now,
      iss: `${API}/auth/v1`,
      sub: user.id,
      role: "authenticated",
      session_id: user.session,
      email: user.email,
    },
    secret,
  );
}

let failures = 0;
function check(name, condition, detail = "") {
  if (condition) {
    console.log(`ok   - ${name}`);
  } else {
    failures += 1;
    console.log(`FAIL - ${name} ${detail}`);
  }
}

async function callGet(token) {
  const response = await fetch(`${API}/functions/v1/arena?token=${token}`);
  return { status: response.status, body: await response.json() };
}

async function callPost(jwt, action, params) {
  if (["ready", "match_state", "heartbeat"].includes(action)) {
    params = { ...params, counter_version: "1.3.0" };
  }
  const response = await fetch(`${API}/functions/v1/arena`, {
    method: "POST",
    headers: { "content-type": "application/json", authorization: `Bearer ${jwt}` },
    body: JSON.stringify({ action, params }),
  });
  return { status: response.status, body: await response.json() };
}

async function callDispatcher(secret) {
  const headers = { "content-type": "application/json" };
  if (secret) {
    headers.authorization = `Bearer ${secret}`;
  }
  const response = await fetch(`${API}/functions/v1/arena-dispatcher`, {
    method: "POST",
    headers,
    body: "{}",
  });
  return { status: response.status, body: await response.json() };
}

// Sanity: the local JWT secret is the documented development default.
if (ANON_KEY) {
  const [header, payload, signature] = ANON_KEY.split(".");
  const expected = crypto
    .createHmac("sha256", SECRET)
    .update(`${header}.${payload}`)
    .digest("base64url");
  if (expected !== signature) {
    console.error("local JWT secret is not the expected development default");
    process.exit(2);
  }
}

const aliceJwt = tokenFor(ALICE);
const carolJwt = tokenFor(CAROL);

// Anonymous GET link resolution.
const resolved = await callGet("fixturealice");
check(
  "GET resolves a valid fixture link",
  resolved.status === 200 && resolved.body.data?.available === true,
  JSON.stringify(resolved.body),
);
check("GET owner is the safe public profile", resolved.body.data?.owner?.username === "fixture_alice");
const unknown = await callGet("zzzzzzzzzzzz");
check(
  "GET unknown link is available:false",
  unknown.body.data?.available === false && unknown.body.data?.owner === null,
);
const malformed = await callGet("nope");
check("GET malformed token is invalid_request", malformed.body.error?.code === "invalid_request");

// Auth boundaries.
const noAuth = await callPost("not-a-jwt", "profile", {});
check("POST rejects a bogus token", noAuth.status === 401 && noAuth.body.error?.code === "unauthorized");
const wrongSecret = await callPost(tokenFor(ALICE, "attacker-secret-attacker-secret"), "profile", {});
check("POST rejects a token signed with another secret", wrongSecret.status === 401);

// Authenticated actions.
const profile = await callPost(aliceJwt, "profile", {});
check("POST profile returns the fixture profile", profile.body.data?.profile?.username === "fixture_alice", JSON.stringify(profile.body));
check("profile includes a durable link", profile.body.data?.link?.token?.length === 12);

const injected = await callPost(aliceJwt, "profile", { user_id: CAROL.id });
check("POST profile rejects a smuggled user id", injected.body.error?.code === "invalid_request");

// Make the smoke repeatable: cancel any pending carol -> alice request first.
const carolInbox = await callPost(carolJwt, "inbox", {});
for (const item of carolInbox.body.data?.requests ?? []) {
  if (item.status === "pending" && item.recipient?.id === ALICE.id) {
    await callPost(carolJwt, "request_respond", { request_id: item.id, response: "cancel" });
  }
}

const request = await callPost(carolJwt, "request_send", { token: "fixturealice" });
check(
  "POST request_send creates a pending request",
  request.body.data?.request?.status === "pending",
  JSON.stringify(request.body),
);
const duplicate = await callPost(carolJwt, "request_send", { token: "fixturealice" });
check("POST duplicate request is request_exists", duplicate.body.error?.code === "request_exists", duplicate.body.error?.code);

const inbox = await callPost(aliceJwt, "inbox", {});
const pending = (inbox.body.data?.requests ?? []).some((r) => r.status === "pending");
check("POST inbox shows the pending request", pending, JSON.stringify(inbox.body).slice(0, 200));

const history = await callPost(aliceJwt, "history", {});
check("POST history returns an array", Array.isArray(history.body.data?.receipts));

const analytics = await callPost(aliceJwt, "analytics", { event: "e2e_smoke", properties: { source: "local" } });
check("POST analytics accepts a valid event", analytics.body.data?.ok === true);
const badAnalytics = await callPost(aliceJwt, "analytics", { event: "Bad Name", properties: {} });
check("POST analytics rejects a bad event name", badAnalytics.body.error?.code === "invalid_request");

const unknownAction = await callPost(aliceJwt, "set_my_rating", {});
check("POST unknown action is invalid_action", unknownAction.body.error?.code === "invalid_action");

// Dispatcher worker boundary and abandoned-match reconciliation (L05).
if (DISPATCHER_SECRET) {
  const anonymous = await callDispatcher("");
  check(
    "dispatcher rejects a missing bearer secret",
    anonymous.status === 401 || anonymous.status === 503,
    JSON.stringify(anonymous.body),
  );
  const intruder = await callDispatcher("not-the-dispatcher-secret");
  check("dispatcher rejects a wrong bearer secret", intruder.status === 401);

  const aliceInbox = await callPost(aliceJwt, "inbox", {});
  const pendingRequest = (aliceInbox.body.data?.requests ?? []).find(
    (item) => item.status === "pending" && item.sender?.id === CAROL.id,
  );
  check("alice still has carol's pending request", Boolean(pendingRequest));

  const accepted = pendingRequest
    ? await callPost(aliceJwt, "request_accept", { request_id: pendingRequest.id })
    : { body: {} };
  const matchId = accepted.body.data?.match?.id;
  check(
    "accepting the request creates a preparing match",
    accepted.body.data?.match?.status === "preparing",
    JSON.stringify(accepted.body).slice(0, 200),
  );

  if (matchId) {
    await callPost(aliceJwt, "ready", {
      match_id: matchId,
      tracking: true,
      practice_complete: true,
    });
    const carolReady = await callPost(carolJwt, "ready", {
      match_id: matchId,
      tracking: true,
      practice_complete: true,
    });
    check(
      "both ready starts the server countdown",
      ["countdown", "live"].includes(carolReady.body.data?.match?.status),
      JSON.stringify(carolReady.body).slice(0, 200),
    );

    // Both clients disappear: no heartbeat for longer than the 10 s absence
    // window, then the worker (the thing a hosted schedule calls) sweeps.
    await new Promise((resolve) => setTimeout(resolve, 17000));
    const sweep = await callDispatcher(DISPATCHER_SECRET);
    check(
      "the dispatcher runs maintenance with its own secret",
      sweep.status === 200 && typeof sweep.body.data?.maintenance === "object",
      JSON.stringify(sweep.body).slice(0, 200),
    );
    const state = await callPost(aliceJwt, "match_state", { match_id: matchId });
    check(
      "both clients gone closes the match as no_result",
      state.body.data?.match?.status === "no_result",
      JSON.stringify(state.body).slice(0, 300),
    );
    check(
      "the shared-outage reason is recorded",
      state.body.data?.match?.receipt?.reason === "service_outage",
      JSON.stringify(state.body?.data?.match?.receipt ?? {}).slice(0, 200),
    );

    // A fresh live round ends by a server-confirmed forfeit. This tests the
    // request/receipt protocol, not exercise counting or physical accuracy.
    const nextRequest = await callPost(carolJwt, "request_send", { token: "fixturealice" });
    const nextMatch = await callPost(aliceJwt, "request_accept", {
      request_id: nextRequest.body.data?.request?.id,
    });
    const finishedId = nextMatch.body.data?.match?.id;
    if (finishedId) {
      await callPost(aliceJwt, "ready", { match_id: finishedId, tracking: true, practice_complete: true });
      await callPost(carolJwt, "ready", { match_id: finishedId, tracking: true, practice_complete: true });
      await new Promise(resolve => setTimeout(resolve, 6000));
      await callPost(carolJwt, "heartbeat", { match_id: finishedId, tracking: true });
      const finished = await callPost(aliceJwt, "leave", { match_id: finishedId });
      check("rematch starts from a server-confirmed finished match", finished.body.data?.match?.status === "finished");
      const receipt = finished.body.data?.match?.receipt;
      const rematch = await callPost(aliceJwt, "request_rematch", { match_id: finishedId });
      const requestId = rematch.body.data?.request?.id;
      check("rematch creates only a pending casual request", rematch.body.data?.request?.status === "pending");
      const repeated = await callPost(aliceJwt, "request_rematch", { match_id: finishedId });
      check("repeated rematch returns the same pending request", repeated.body.data?.request?.id === requestId);
      const opposite = await callPost(carolJwt, "request_rematch", { match_id: finishedId });
      check("opposite-direction rematch recovers the same request", opposite.body.data?.request?.id === requestId);
      const oldMatch = await callPost(aliceJwt, "match_state", { match_id: finishedId });
      check("rematch keeps the old receipt unchanged", JSON.stringify(oldMatch.body.data?.match?.receipt) === JSON.stringify(receipt));
      const fresh = await callPost(carolJwt, "request_accept", { request_id: requestId });
      const freshMatch = fresh.body.data?.match;
      check("accepting rematch creates a different match", Boolean(freshMatch?.id) && freshMatch.id !== finishedId);
      check("rematch needs fresh preparation and readiness", freshMatch?.status === "preparing" && freshMatch.mode === "casual" && freshMatch.players.every(p => !p.ready && p.score === 0));
      if (freshMatch?.id) await callPost(aliceJwt, "leave", { match_id: freshMatch.id });
    } else check("rematch fixture creates a fresh match", false);
  }
} else {
  console.log("skip - dispatcher checks (set ARENA_DISPATCHER_SECRET)");
}

console.log(failures === 0 ? "ALL E2E CHECKS PASSED" : `${failures} E2E CHECKS FAILED`);
process.exit(failures === 0 ? 0 : 1);
