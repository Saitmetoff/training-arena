import { assertEquals, assertRejectsCode } from "./assert.ts";
import { ACTIONS, resolveAction } from "../lib/actions.ts";
import type { Deps, RpcClient, StorageClient } from "../lib/deps.ts";
import { RpcFailure } from "../lib/deps.ts";

const ACTOR = "11111111-1111-4111-8111-111111111111";
const SESSION = "91111111-1111-4111-8111-111111111111";

interface Captured {
  fn: string;
  args: Record<string, unknown>;
}

function makeDeps(): { deps: Deps; calls: Captured[]; uploads: string[]; removed: string[] } {
  const calls: Captured[] = [];
  const uploads: string[] = [];
  const removed: string[] = [];
  const rpc: RpcClient = {
    call(fn, args) {
      calls.push({ fn, args });
      return Promise.resolve({ ok: true, profile: { id: ACTOR } });
    },
  };
  const storage: StorageClient = {
    upload(path) {
      uploads.push(path);
      return Promise.resolve();
    },
    remove(paths) {
      removed.push(...paths);
      return Promise.resolve();
    },
    publicUrl(path) {
      return `https://example.invalid/storage/${path}`;
    },
  };
  return {
    deps: {
      rpc,
      auth: {
        getUser: () => Promise.resolve({ id: ACTOR, sessionId: SESSION }),
        deleteUser: () => Promise.resolve(),
      },
      storage,
    },
    calls,
    uploads,
    removed,
  };
}

async function run(action: string, params: Record<string, unknown>) {
  const harness = makeDeps();
  const data = await ACTIONS[action].run({
    actor: ACTOR,
    session: SESSION,
    params,
    deps: harness.deps,
  });
  return { ...harness, data };
}

Deno.test("ready, restore and heartbeat require numeric versions before calling RPCs", async () => {
  for (const action of ["ready", "match_state", "heartbeat"]) {
    const base = {match_id: "33333333-3333-4333-8333-333333333333",
      ...(action !== "match_state" ? {tracking: true} : {}),
      ...(action === "ready" ? {practice_complete: true} : {})};
    for (const version of [undefined, "", "arena-counter/1.2.1", "1.3", " 1.3.0"]) {
      const h = makeDeps();
      await assertRejectsCode(() => ACTIONS[action].run({actor: ACTOR, session: SESSION,
        params: {...base, counter_version: version}, deps: h.deps}), "update_required");
      assertEquals(h.calls.length, 0);
    }
    const {calls} = await run(action, {...base, counter_version: "1.3.0"});
    assertEquals(calls[0].fn, `arena_match_${action === "match_state" ? "state" : action}_versioned`);
    assertEquals(calls[0].args.p_counter_version, "1.3.0");
  }
});

Deno.test("the action registry matches docs/API.md exactly", () => {
  const documented = [
    "profile",
    "profile_update",
    "avatar_update",
    "avatar_remove",
    "resolve_link",
    "inbox",
    "request_send",
    "request_rematch",
    "request_accept",
    "request_respond",
    "queue_join",
    "queue_poll",
    "queue_leave",
    "match_state",
    "ready",
    "heartbeat",
    "rep",
    "leave",
    "leaderboard",
    "history",
    "profile_public",
    "link_rotate",
    "report",
    "block",
    "unblock",
    "blocked",
    "device_register",
    "delete_account",
    "analytics",
  ];
  assertEquals(Object.keys(ACTIONS).sort(), documented.sort());
});

Deno.test("unknown actions fail closed", () => {
  try {
    resolveAction("admin_rating_override");
    throw new Error("should have failed");
  } catch (error) {
    assertEquals((error as { code?: string }).code, "invalid_action");
  }
});

Deno.test("actor and session always come from the verified JWT", async () => {
  const { calls, data } = await run("profile", {});
  assertEquals(calls[0].fn, "arena_get_profile");
  assertEquals(calls[0].args.p_actor, ACTOR);
  assertEquals(calls[0].args.p_session, SESSION);
  assertEquals(data, { ok: true, profile: { id: ACTOR } });
});

Deno.test("profile rejects smuggled user ids", async () => {
  await assertRejectsCode(
    () => run("profile", { user_id: "22222222-2222-4222-8222-222222222222" }),
    "invalid_request",
  );
  await assertRejectsCode(
    () => run("history", { p_actor: "22222222-2222-4222-8222-222222222222" }),
    "invalid_request",
  );
});

Deno.test("rep parses and forwards the documented event fields", async () => {
  const { calls } = await run("rep", {
    match_id: "33333333-3333-4333-8333-333333333333",
    event_id: "44444444-4444-4444-8444-444444444444",
    sequence: 7,
    observed_at: new Date().toISOString(),
    counter_version: "1.2.0",
  });
  assertEquals(calls[0].fn, "arena_match_rep");
  assertEquals(calls[0].args.p_sequence, 7);
  assertEquals(calls[0].args.p_counter_version, "1.2.0");
});

Deno.test("rep rejects a zero sequence and a non-uuid event id", async () => {
  await assertRejectsCode(
    () =>
      run("rep", {
        match_id: "33333333-3333-4333-8333-333333333333",
        event_id: "44444444-4444-4444-8444-444444444444",
        sequence: 0,
        observed_at: new Date().toISOString(),
        counter_version: "1",
      }),
    "invalid_request",
  );
  await assertRejectsCode(
    () =>
      run("rep", {
        match_id: "33333333-3333-4333-8333-333333333333",
        event_id: "nope",
        sequence: 1,
        observed_at: new Date().toISOString(),
        counter_version: "1",
      }),
    "invalid_request",
  );
});

Deno.test("request_respond only accepts decline or cancel", async () => {
  const { calls } = await run("request_respond", {
    request_id: "44444444-4444-4444-8444-444444444444",
    response: "decline",
  });
  assertEquals(calls[0].fn, "arena_request_respond");
  await assertRejectsCode(
    () =>
      run("request_respond", {
        request_id: "44444444-4444-4444-8444-444444444444",
        response: "expire",
      }),
    "invalid_request",
  );
});

Deno.test("report treats match_id as optional and validates the reason", async () => {
  const { calls } = await run("report", {
    target_user_id: "22222222-2222-4222-8222-222222222222",
    reason: "poor conduct",
  });
  assertEquals(calls[0].fn, "arena_report");
  assertEquals(calls[0].args.p_match_id, null);

  await assertRejectsCode(
    () =>
      run("report", {
        target_user_id: "22222222-2222-4222-8222-222222222222",
        reason: "x",
      }),
    "invalid_request",
  );
});

Deno.test("device_register defaults to android and caps the token", async () => {
  const { calls } = await run("device_register", { token: "fixture-device-token" });
  assertEquals(calls[0].args.p_platform, "android");
  await assertRejectsCode(
    () => run("device_register", { token: "short", platform: "ios" }),
    "invalid_request",
  );
  await assertRejectsCode(
    () => run("device_register", { token: "fixture-device-token", platform: "windows" }),
    "invalid_request",
  );
});

Deno.test("analytics rejects oversized properties", async () => {
  await assertRejectsCode(
    () => run("analytics", { event: "queue_joined", properties: { blob: "x".repeat(9000) } }),
    "payload_too_large",
  );
});

Deno.test("profile_update validates the username server-side shape", async () => {
  const { calls } = await run("profile_update", { username: "fixture_alice" });
  assertEquals(calls[0].args.p_username, "fixture_alice");
  await assertRejectsCode(
    () => run("profile_update", { username: "bad name" }),
    "invalid_request",
  );
});

Deno.test("rpc failures map through the error catalogue", async () => {
  const harness = makeDeps();
  harness.deps.rpc.call = () => Promise.reject(new RpcFailure("AR010", "challenge is not available"));
  try {
    await ACTIONS.request_send.run({
      actor: ACTOR,
      session: SESSION,
      params: { token: "fixturealice" },
      deps: harness.deps,
    });
    throw new Error("should have failed");
  } catch (error) {
    assertEquals((error as { code?: string }).code, "AR010");
  }
});
