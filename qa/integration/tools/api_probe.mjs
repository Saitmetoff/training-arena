// Local QA probe for the arena Edge Function (task 10 evidence tool).
// Signs a development JWT for a local auth session and prints raw responses.
// Local-only: the fallback secret is Supabase's documented dev default.
import crypto from "node:crypto";

const API = process.env.ARENA_API ?? "http://127.0.0.1:54321";
const SECRET =
  process.env.ARENA_LOCAL_JWT_SECRET ??
  "super-secret-jwt-token-with-at-least-32-characters-long";
const USER = process.env.PROBE_USER;
const SESSION = process.env.PROBE_SESSION;
const EMAIL = process.env.PROBE_EMAIL ?? "qa.recipient1@arena.invalid";

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
  sub: USER,
  role: "authenticated",
  session_id: SESSION,
  email: EMAIL,
});

const [action, ...pairs] = process.argv.slice(2);
const params = {};
for (const pair of pairs) {
  const index = pair.indexOf("=");
  if (index > 0) {
    const key = pair.slice(0, index);
    const raw = pair.slice(index + 1);
    params[key] =
      raw === "true" ? true : raw === "false" ? false : /^\d+$/.test(raw) ? Number(raw) : raw;
  }
}
const response = await fetch(`${API}/functions/v1/arena`, {
  method: "POST",
  headers: {
    "content-type": "application/json",
    authorization: `Bearer ${jwt}`,
  },
  body: JSON.stringify({ action, params }),
});
const text = await response.text();
console.log(`== ${action} HTTP ${response.status}`);
console.log(text.slice(0, 2000));
