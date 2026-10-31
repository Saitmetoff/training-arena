import { assert, assertEquals, assertRejects } from "./assert.ts";
import {
  buildFcmMessage,
  buildNotificationData,
  channelIdFor,
  classifySendResponse,
  createFcmSender,
  createServiceAccountAssertion,
  FcmAccessTokenProvider,
  notificationContent,
  parseServiceAccount,
  type FcmFetch,
  type OutboxItem,
} from "../lib/fcm.ts";

const item: OutboxItem = {
  id: "11111111-1111-4111-8111-111111111111",
  user_id: "22222222-2222-4222-8222-222222222222",
  kind: "challenge_request",
  payload: {
    request_id: "33333333-3333-4333-8333-333333333333",
    sender_username: "zuhra",
  },
  attempts: 1,
  devices: ["device-token-a"],
};

function bytesToBase64(bytes: Uint8Array): string {
  let binary = "";
  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }
  return btoa(binary);
}

async function generateServiceAccount(): Promise<{
  json: string;
  account: ReturnType<typeof parseServiceAccount>;
}> {
  const keyPair = await crypto.subtle.generateKey(
    {
      name: "RSASSA-PKCS1-v1_5",
      modulusLength: 2048,
      publicExponent: new Uint8Array([1, 0, 1]),
      hash: "SHA-256",
    },
    true,
    ["sign", "verify"],
  );
  const pkcs8 = await crypto.subtle.exportKey("pkcs8", keyPair.privateKey);
  const pem = `-----BEGIN PRIVATE KEY-----\n${
    bytesToBase64(new Uint8Array(pkcs8))
  }\n-----END PRIVATE KEY-----\n`;
  const json = JSON.stringify({
    project_id: "arena-test",
    client_email: "dispatcher@arena-test.iam.gserviceaccount.com",
    private_key: pem,
    token_uri: "https://oauth2.googleapis.com/token",
  });
  return { json, account: parseServiceAccount(json) };
}

Deno.test("parseServiceAccount fails closed on unusable values", () => {
  assertEquals(parseServiceAccount("not json"), null);
  assertEquals(parseServiceAccount("{}"), null);
  assertEquals(
    parseServiceAccount(JSON.stringify({ project_id: "p", client_email: "e" })),
    null,
  );
  const parsed = parseServiceAccount(JSON.stringify({
    project_id: "arena-test",
    client_email: "dispatcher@arena-test.iam.gserviceaccount.com",
    private_key: "test\\n-----BEGIN PRIVATE KEY-----\\nkey",
  }));
  assert(parsed !== null);
  assert(parsed!.private_key.includes("\n"));
  assertEquals(parsed!.token_uri, "https://oauth2.googleapis.com/token");
});

Deno.test("copy and Android channels are stable per kind", () => {
  assertEquals(notificationContent("challenge_request").title, "New challenge");
  assertEquals(notificationContent("match_ready").title, "Opponent found");
  assertEquals(notificationContent("something_else").title, "Fault");
  assertEquals(channelIdFor("challenge_request"), "arena_requests");
  assertEquals(channelIdFor("request_declined"), "arena_requests");
  assertEquals(channelIdFor("match_ready"), "arena_matches");
  assertEquals(channelIdFor("match_finished"), "arena_matches");
});

Deno.test("buildNotificationData flattens values to strings", () => {
  const data = buildNotificationData({
    ...item,
    payload: { request_id: "r1", retry: 2, nested: { a: 1 }, missing: null },
  });
  assertEquals(data.kind, "challenge_request");
  assertEquals(data.request_id, "r1");
  assertEquals(data.retry, "2");
  assertEquals(data.nested, '{"a":1}');
  assertEquals("missing" in data, false);
});

Deno.test("buildFcmMessage names channel, data and priority", () => {
  const message = buildFcmMessage("device-token-a", item) as {
    message: {
      token: string;
      notification: { title: string; body: string };
      data: Record<string, string>;
      android: { priority: string; notification: { channel_id: string } };
    };
  };
  assertEquals(message.message.token, "device-token-a");
  assertEquals(message.message.data.kind, "challenge_request");
  assertEquals(message.message.data.sender_username, "zuhra");
  assertEquals(message.message.android.notification.channel_id, "arena_requests");
  assertEquals(message.message.android.priority, "high");
});

Deno.test("classifySendResponse detects unregistered tokens", () => {
  assertEquals(classifySendResponse(200, {}), {
    delivered: true,
    invalidToken: false,
  });
  const notFound = classifySendResponse(404, {
    error: { status: "UNREGISTERED", message: "not found" },
  });
  assert(notFound.invalidToken);
  assert(!notFound.delivered);
  const server = classifySendResponse(503, {});
  assert(!server.invalidToken);
  assertEquals(server.error, "http_503");
});

Deno.test("access token provider signs RS256 and caches the token", async () => {
  const { json } = await generateServiceAccount();
  const account = parseServiceAccount(json)!;
  let calls = 0;
  let capturedBody = "";
  const fetchImpl: FcmFetch = async (input, init) => {
    calls += 1;
    capturedBody = init?.body ?? "";
    assertEquals(input, account.token_uri);
    return {
      status: 200,
      json: async () => ({ access_token: "access-1", expires_in: 3600 }),
    };
  };
  const provider = new FcmAccessTokenProvider(account, fetchImpl, () => 1000);
  assertEquals(await provider.get(), "access-1");
  assertEquals(await provider.get(), "access-1");
  assertEquals(calls, 1);

  const assertion = decodeURIComponent(capturedBody.split("assertion=")[1]);
  const [header, claims, signature] = assertion.split(".");
  assertEquals(
    JSON.parse(atob(header.replace(/-/g, "+").replace(/_/g, "/"))),
    { alg: "RS256", typ: "JWT" },
  );
  const parsedClaims = JSON.parse(
    atob(claims.replace(/-/g, "+").replace(/_/g, "/")),
  ) as { iss: string; scope: string };
  assertEquals(parsedClaims.iss, account.client_email);
  assertEquals(
    parsedClaims.scope,
    "https://www.googleapis.com/auth/firebase.messaging",
  );
  assert(signature.length > 0);

  // A rotated token is fetched again after the cache expires.
  const later = new FcmAccessTokenProvider(
    account,
    async () => ({
      status: 200,
      json: async () => ({ access_token: "access-2", expires_in: 3600 }),
    }),
    () => 1000 + 3600,
  );
  assertEquals(await later.get(), "access-2");
});

Deno.test("token request failures never leak secret material", async () => {
  const { json } = await generateServiceAccount();
  const account = parseServiceAccount(json)!;
  const provider = new FcmAccessTokenProvider(
    account,
    async () => ({ status: 401, json: async () => ({}) }),
    () => 1000,
  );
  await assertRejects(() => provider.get());
});

Deno.test("createFcmSender delivers per device and reports invalid tokens",
    async () => {
  const { json } = await generateServiceAccount();
  const sent: Array<{ url: string; body: Record<string, unknown> }> = [];
  const fetchImpl: FcmFetch = async (input, init) => {
    if (input === "https://oauth2.googleapis.com/token") {
      return {
        status: 200,
        json: async () => ({ access_token: "access-token", expires_in: 3600 }),
      };
    }
    sent.push({
      url: input,
      body: JSON.parse(init?.body ?? "{}") as Record<string, unknown>,
    });
    if (init?.body?.includes("device-bad")) {
      return {
        status: 404,
        json: async () => ({
          error: { status: "UNREGISTERED", message: "not found" },
        }),
      };
    }
    return { status: 200, json: async () => ({ name: "projects/p/messages/1" }) };
  };

  const sender = createFcmSender(json, fetchImpl, () => 1000)!;
  const result = await sender.send({
    ...item,
    devices: ["device-ok", "device-bad"],
  });

  assert(result.delivered);
  assertEquals(result.invalidTokens, ["device-bad"]);
  assertEquals(sent.length, 2);
  assertEquals(
    sent[0].url,
    "https://fcm.googleapis.com/v1/projects/arena-test/messages:send",
  );
  const message = sent[0].body.message as {
    data: Record<string, string>;
    android: { notification: { channel_id: string } };
  };
  assertEquals(message.data.request_id, "33333333-3333-4333-8333-333333333333");
  assertEquals(message.android.notification.channel_id, "arena_requests");

  assertEquals(createFcmSender("not json", fetchImpl, () => 1000), null);
});

Deno.test("every device failing is reported as not delivered", async () => {
  const { json } = await generateServiceAccount();
  const fetchImpl: FcmFetch = async (input) => {
    if (input === "https://oauth2.googleapis.com/token") {
      return {
        status: 200,
        json: async () => ({ access_token: "access-token", expires_in: 3600 }),
      };
    }
    return { status: 503, json: async () => ({}) };
  };
  const sender = createFcmSender(json, fetchImpl, () => 1000)!;
  const result = await sender.send({ ...item, devices: ["device-a"] });
  assert(!result.delivered);
  assertEquals(result.error, "http_503");
  assertEquals(result.invalidTokens, []);
});

Deno.test("assertion iat/exp follow the injected clock", async () => {
  const { json } = await generateServiceAccount();
  const account = parseServiceAccount(json)!;
  const assertion = await createServiceAccountAssertion(account, 5000);
  const claims = JSON.parse(
    atob(assertion.split(".")[1].replace(/-/g, "+").replace(/_/g, "/")),
  ) as { iat: number; exp: number };
  assertEquals(claims.iat, 5000);
  assertEquals(claims.exp, 8600);
});
