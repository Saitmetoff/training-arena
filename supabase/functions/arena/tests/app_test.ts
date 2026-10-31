import { assert, assertEquals } from "./assert.ts";
import { createApp } from "../lib/app.ts";
import { RpcFailure, type Deps, type RpcClient, type StorageClient } from "../lib/deps.ts";

const ACTOR = "11111111-1111-4111-8111-111111111111";
const SESSION = "91111111-1111-4111-8111-111111111111";
const OTHER = "22222222-2222-4222-8222-222222222222";

const PNG_BASE64 =
  "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==";

interface Harness {
  app: (request: Request) => Promise<Response>;
  calls: { fn: string; args: Record<string, unknown> }[];
  uploads: { path: string; contentType: string }[];
  removed: string[];
  deletedUsers: string[];
}

function setup(options: {
  rpc?: (fn: string, args: Record<string, unknown>) => Promise<Record<string, unknown>>;
  authUser?: { id: string; sessionId: string } | null;
} = {}): Harness {
  const calls: { fn: string; args: Record<string, unknown> }[] = [];
  const uploads: { path: string; contentType: string }[] = [];
  const removed: string[] = [];
  const deletedUsers: string[] = [];

  const rpc: RpcClient = {
    call(fn, args) {
      calls.push({ fn, args });
      if (options.rpc) {
        return options.rpc(fn, args);
      }
      return Promise.resolve({ ok: true });
    },
  };
  const storage: StorageClient = {
    upload(path, _bytes, contentType) {
      uploads.push({ path, contentType });
      return Promise.resolve();
    },
    remove(paths) {
      removed.push(...paths);
      return Promise.resolve();
    },
    publicUrl(path) {
      return `https://example.invalid/storage/v1/object/public/arena-avatars/${path}`;
    },
  };
  const deps: Deps = {
    rpc,
    auth: {
      getUser(token) {
        if (options.authUser === null) {
          return Promise.resolve(null);
        }
        if (token !== "good-token") {
          return Promise.resolve(null);
        }
        return Promise.resolve(options.authUser ?? { id: ACTOR, sessionId: SESSION });
      },
      deleteUser(userId) {
        deletedUsers.push(userId);
        return Promise.resolve();
      },
    },
    storage,
  };

  const app = createApp({ deps, allowedOrigins: ["https://app.example"] });
  return { app, calls, uploads, removed, deletedUsers };
}

function post(body: unknown, headers: Record<string, string> = {}): Request {
  return new Request("https://project.supabase.co/functions/v1/arena", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      authorization: "Bearer good-token",
      ...headers,
    },
    body: typeof body === "string" ? body : JSON.stringify(body),
  });
}

Deno.test("rematch accepts only a finished match id and uses the verified actor", async () => {
  const matchId = "33333333-3333-4333-8333-333333333333";
  const request = { id: "44444444-4444-4444-8444-444444444444", status: "pending" };
  const harness = setup({ rpc: () => Promise.resolve({ request }) });
  const response = await harness.app(post({ action: "request_rematch", params: { match_id: matchId } }));
  assertEquals(response.status, 200);
  assertEquals(await response.json(), { data: { request } });
  assertEquals(harness.calls[0], {
    fn: "arena_request_rematch", args: { p_actor: ACTOR, p_session: SESSION, p_match_id: matchId },
  });
  const smuggled = await harness.app(post({ action: "request_rematch", params: { match_id: matchId, user_id: OTHER } }));
  assertEquals((await smuggled.json()).error.code, 'invalid_request');
  const invalid = await harness.app(post({ action: "request_rematch", params: { match_id: "not-a-match" } }));
  assertEquals((await invalid.json()).error.code, 'invalid_request');
});

function get(query: string, method = "GET", headers: Record<string, string> = {}): Request {
  return new Request(`https://project.supabase.co/functions/v1/arena${query}`, {
    method,
    headers,
  });
}

interface Envelope {
  data?: unknown;
  error?: { code: string; message: string };
}

async function bodyOf(response: Response): Promise<Envelope> {
  return await response.json() as Envelope;
}

Deno.test("CORS preflight is answered for allowed origins only", async () => {
  const { app } = setup();
  const allowed = await app(
    new Request("https://project.supabase.co/functions/v1/arena", {
      method: "OPTIONS",
      headers: { origin: "https://app.example" },
    }),
  );
  assertEquals(allowed.status, 204);
  assertEquals(allowed.headers.get("access-control-allow-origin"), "https://app.example");

  const denied = await app(
    new Request("https://project.supabase.co/functions/v1/arena", {
      method: "OPTIONS",
      headers: { origin: "https://evil.example" },
    }),
  );
  assertEquals(denied.status, 204);
  assertEquals(denied.headers.get("access-control-allow-origin"), null);
});

Deno.test("GET resolves a link anonymously and normalizes the token", async () => {
  const { app, calls } = setup({
    rpc: () =>
      Promise.resolve({
        owner: { id: ACTOR, username: "fixture_alice" },
        available: true,
      }),
  });
  const response = await app(get("?token=FiXtUrEaLiCe"));
  assertEquals(response.status, 200);
  const body = await bodyOf(response);
  assertEquals(body.data, {
    owner: { id: ACTOR, username: "fixture_alice" },
    available: true,
  });
  assertEquals(calls[0].fn, "arena_resolve_link");
  assertEquals(calls[0].args, { p_token: "fixturealice" });
});

Deno.test("GET never creates anything and fails closed on bad input", async () => {
  const { app, calls } = setup();
  const missing = await app(get(""));
  assertEquals(missing.status, 200);
  assertEquals((await bodyOf(missing)).error, {
    code: "invalid_request",
    message: "token is required",
  });

  const malformed = await app(get("?token=not-a-token"));
  assertEquals((await bodyOf(malformed)).error, {
    code: "invalid_request",
    message: "token must be a 12-character challenge token",
  });
  assertEquals(calls.length, 0);
});

Deno.test("POST without a bearer token is unauthorized", async () => {
  const { app, calls } = setup();
  const response = await app(
    new Request("https://project.supabase.co/functions/v1/arena", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ action: "profile", params: {} }),
    }),
  );
  assertEquals(response.status, 401);
  assertEquals((await bodyOf(response)).error, {
    code: "unauthorized",
    message: "missing bearer token",
  });
  assertEquals(calls.length, 0);
});

Deno.test("POST with a token Auth rejects is unauthorized", async () => {
  const { app } = setup({ authUser: null });
  const response = await app(post({ action: "profile", params: {} }));
  assertEquals(response.status, 401);
  assertEquals((await bodyOf(response)).error, {
    code: "unauthorized",
    message: "invalid or expired access token",
  });
});

Deno.test("malformed envelopes and unknown actions fail closed", async () => {
  const { app, calls } = setup();
  const notJson = await app(post("{not json"));
  assertEquals((await bodyOf(notJson)).error, {
    code: "invalid_request",
    message: "request body must be JSON",
  });

  const unknown = await app(post({ action: "grant_rating", params: {} }));
  assertEquals((await bodyOf(unknown)).error, {
    code: "invalid_action",
    message: "unknown action: grant_rating",
  });

  const extraEnvelopeKey = await app(post({ action: "profile", params: {}, user_id: OTHER }));
  assertEquals((await bodyOf(extraEnvelopeKey)).error?.code, "invalid_request");
  assertEquals(calls.length, 0);
});

Deno.test("valid POSTs are dispatched with the JWT actor and session", async () => {
  const { app, calls } = setup({
    rpc: () => Promise.resolve({ ok: true }),
  });
  const response = await app(post({ action: "queue_leave", params: {} }));
  assertEquals(response.status, 200);
  assertEquals(await bodyOf(response), { data: { ok: true } });
  assertEquals(calls[0].fn, "arena_queue_leave");
  assertEquals(calls[0].args, { p_actor: ACTOR, p_session: SESSION });
});

Deno.test("RPC failures map to documented error codes and statuses", async () => {
  const { app } = setup({
    rpc: () => Promise.reject(new RpcFailure("AR006", "challenge link is not available")),
  });
  const failed = await app(post({ action: "request_send", params: { token: "fixturealice" } }));
  assertEquals(failed.status, 200);
  assertEquals(await bodyOf(failed), {
    error: { code: "link_not_found", message: "challenge link is not available" },
  });

  const broken = setup({
    rpc: () => Promise.reject(new RpcFailure("XX000", "driver exploded")),
  });
  const internal = await broken.app(post({ action: "profile", params: {} }));
  assertEquals(internal.status, 500);
  assertEquals((await bodyOf(internal)).error, {
    code: "internal_error",
    message: "unexpected server error",
  });
});

Deno.test("avatar_update uploads, records and removes the previous object", async () => {
  const previous = `avatars/${ACTOR}/old.png`;
  const { app, uploads, removed, calls } = setup({
    rpc: (_fn, args) =>
      Promise.resolve({
        profile: { id: ACTOR },
        previous_avatar_path: previous,
        echoed_path: args.p_avatar_path,
      }),
  });
  const response = await app(
    post({ action: "avatar_update", params: { base64: PNG_BASE64, mime_type: "image/png" } }),
  );
  const body = await bodyOf(response);
  assertEquals(body.data, { profile: { id: ACTOR } });
  assertEquals(uploads.length, 1);
  assert(uploads[0].path.startsWith(`avatars/${ACTOR}/`));
  assert(uploads[0].path.endsWith(".png"));
  assertEquals(uploads[0].contentType, "image/png");
  assertEquals(removed, [previous]);
  assertEquals(calls[0].fn, "arena_set_avatar");
  assertEquals(calls[0].args.p_avatar_path, uploads[0].path);
  assert(String(calls[0].args.p_avatar_url).startsWith("https://"));
});

Deno.test("avatar_update rejects non-image payloads before uploading", async () => {
  const { app, uploads, calls } = setup();
  const response = await app(
    post({ action: "avatar_update", params: { base64: PNG_BASE64, mime_type: "image/gif" } }),
  );
  assertEquals((await bodyOf(response)).error?.code, "avatar_invalid");
  assertEquals(uploads.length, 0);
  assertEquals(calls.length, 0);
});

Deno.test("avatar_update cleans up the new object when the RPC fails", async () => {
  const { app, uploads, removed } = setup({
    rpc: () => Promise.reject(new RpcFailure("AR018", "avatar path is not owned by the actor")),
  });
  const response = await app(
    post({ action: "avatar_update", params: { base64: PNG_BASE64, mime_type: "image/png" } }),
  );
  assertEquals((await bodyOf(response)).error?.code, "avatar_invalid");
  assertEquals(uploads.length, 1);
  assertEquals(removed, [uploads[0].path]);
});

Deno.test("delete_account removes storage, deletes the auth user and stays idempotent", async () => {
  const paths = [`avatars/${ACTOR}/a.png`, `avatars/${ACTOR}/b.webp`];
  const { app, removed, deletedUsers } = setup({
    rpc: () => Promise.resolve({ ok: true, already_deleted: false, avatar_paths: paths }),
  });
  const response = await app(post({ action: "delete_account", params: {} }));
  assertEquals(await bodyOf(response), { data: { ok: true } });
  assertEquals(removed, paths);
  assertEquals(deletedUsers, [ACTOR]);
});

Deno.test("unsupported methods are rejected", async () => {
  const { app } = setup();
  const response = await app(get("", "PUT"));
  assertEquals(response.status, 405);
  assertEquals((await bodyOf(response)).error?.code, "method_not_allowed");
});
