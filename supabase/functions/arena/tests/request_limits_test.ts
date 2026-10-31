import { assertEquals } from "./assert.ts";
import { createApp } from "../lib/app.ts";
import type { Deps } from "../lib/deps.ts";

const MAX_BODY_BYTES = 4 * 1024 * 1024;
const encoder = new TextEncoder();

function setup() {
  let calls = 0;
  const deps: Deps = {
    auth: {
      getUser: () => Promise.resolve({ id: "actor", sessionId: "session" }),
      deleteUser: () => Promise.resolve(),
    },
    rpc: {
      call: () => {
        calls++;
        return Promise.resolve({ ok: true });
      },
    },
    storage: {
      upload: () => Promise.resolve(),
      remove: () => Promise.resolve(),
      publicUrl: () => "https://example.invalid/avatar.png",
    },
  };
  return { app: createApp({ deps, allowedOrigins: [] }), calls: () => calls };
}

function post(body: BodyInit, headers: Record<string, string> = {}) {
  return new Request("https://example.invalid/functions/v1/arena", {
    method: "POST",
    headers: {
      authorization: "Bearer fixture",
      "content-type": "application/json",
      ...headers,
    },
    body,
  });
}

Deno.test("request body accepts exactly 4 MiB and rejects one byte more without Content-Length", async () => {
  const harness = setup();
  const json = '{"action":"queue_leave","params":{}}';
  const atLimit = json +
    " ".repeat(MAX_BODY_BYTES - encoder.encode(json).byteLength);
  const accepted = await harness.app(post(atLimit));
  assertEquals(await accepted.json(), { data: { ok: true } });
  assertEquals(harness.calls(), 1);

  const rejected = await harness.app(post(atLimit + " "));
  assertEquals(rejected.status, 200);
  assertEquals((await rejected.json()).error.code, "payload_too_large");
  assertEquals(harness.calls(), 1);
});

Deno.test("request limit counts UTF-8 bytes rather than JavaScript characters", async () => {
  const harness = setup();
  // Less than 4 MiB of JS characters, but over 4 MiB on the wire.
  const body = JSON.stringify({
    action: "queue_leave",
    params: { text: "😀".repeat(MAX_BODY_BYTES / 4) },
  });
  const rejected = await harness.app(post(body));
  assertEquals(rejected.status, 200);
  assertEquals((await rejected.json()).error.code, "payload_too_large");
  assertEquals(harness.calls(), 0);
});

Deno.test("chunked body is cancelled as soon as its byte limit is exceeded", async () => {
  const harness = setup();
  let pulls = 0;
  let cancelled = false;
  const body = new ReadableStream<Uint8Array>({
    pull(controller) {
      pulls++;
      controller.enqueue(new Uint8Array(MAX_BODY_BYTES / 2 + 1));
      if (pulls === 8) controller.close();
    },
    cancel() {
      cancelled = true;
    },
  }, { highWaterMark: 0 });
  // A client-supplied smaller Content-Length must not bypass the actual limit.
  const rejected = await harness.app(post(body, { "content-length": "1" }));
  assertEquals(rejected.status, 200);
  assertEquals((await rejected.json()).error.code, "payload_too_large");
  assertEquals(pulls, 2);
  assertEquals(cancelled, true);
  assertEquals(harness.calls(), 0);
});

Deno.test("oversized Content-Length cancels the body without reading it", async () => {
  const harness = setup();
  let pulls = 0;
  let cancelled = false;
  const body = new ReadableStream<Uint8Array>({
    pull(controller) {
      pulls++;
      controller.enqueue(encoder.encode("{}"));
      controller.close();
    },
    cancel() {
      cancelled = true;
    },
  }, { highWaterMark: 0 });
  const rejected = await harness.app(
    post(body, { "content-length": String(MAX_BODY_BYTES + 1) }),
  );
  assertEquals(rejected.status, 200);
  assertEquals((await rejected.json()).error.code, "payload_too_large");
  assertEquals(pulls, 0);
  assertEquals(cancelled, true);
  assertEquals(harness.calls(), 0);
});

Deno.test("streaming JSON preserves a UTF-8 character split across chunks", async () => {
  const harness = setup();
  const json = encoder.encode(
    '{"action":"analytics","params":{"event":"fixture","properties":{"text":"😀"}}}',
  );
  let offset = 0;
  const body = new ReadableStream<Uint8Array>({
    pull(controller) {
      if (offset === json.length) return controller.close();
      controller.enqueue(json.subarray(offset, ++offset));
    },
  }, { highWaterMark: 0 });
  const accepted = await harness.app(post(body));
  assertEquals(await accepted.json(), { data: { ok: true } });
  assertEquals(harness.calls(), 1);
});
