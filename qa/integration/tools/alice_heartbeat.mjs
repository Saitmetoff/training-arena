// Keeps the local fixture challenger present during a device QA round.
// Local-only development JWT (Supabase documented default secret).
import crypto from "node:crypto";

const API = process.env.ARENA_API ?? "http://127.0.0.1:54321";
const SECRET =
  process.env.ARENA_LOCAL_JWT_SECRET ??
  "super-secret-jwt-token-with-at-least-32-characters-long";
const MATCH = process.env.MATCH_ID;
const SECONDS = Number(process.env.HEARTBEAT_SECONDS ?? "75");

function b64url(value) {
  return Buffer.from(value).toString("base64url");
}

function sign(payload) {
  const header = b64url(JSON.stringify({ alg: "HS256", typ: "JWT" }));
  const body = b64url(JSON.stringify(payload));
  const signature = crypto
    .createHmac("sha256", SECRET)
    .update(`${header}.${body}`)
    .digest("base64url");
  return `${header}.${body}.${signature}`;
}

const now = Math.floor(Date.now() / 1000);
const jwt = sign({
  aud: "authenticated",
  exp: now + 3600,
  iat: now,
  iss: `${API}/auth/v1`,
  sub: "11111111-1111-4111-8111-111111111111",
  role: "authenticated",
  session_id: "91111111-1111-4111-8111-111111111111",
  email: "fixture.alice@arena.invalid",
});

async function post(action, params) {
  const response = await fetch(`${API}/functions/v1/arena`, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      authorization: `Bearer ${jwt}`,
    },
    body: JSON.stringify({ action, params }),
  });
  return { status: response.status, body: await response.json() };
}

for (let i = 0; i < SECONDS; i += 1) {
  const result = await post("heartbeat", { match_id: MATCH, tracking: true });
  const match = result.body?.data?.match;
  console.log(
    `${new Date().toISOString()} heartbeat=${i} status=${match?.status} alice_score=${match?.players?.[1]?.score}`,
  );
  if (match?.status === "finished" || match?.status === "no_result") {
    console.log(`closed with ${match.status}`);
    break;
  }
  await new Promise((resolve) => setTimeout(resolve, 1000));
}
