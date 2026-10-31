import { assert, assertEquals, assertThrowsCode } from "./assert.ts";
import {
  asObject,
  bool,
  eventName,
  int,
  isoTimestamp,
  jsonSizeBytes,
  onlyKeys,
  str,
  token,
  username,
  uuid,
} from "../lib/validate.ts";

Deno.test("asObject rejects arrays, scalars and null", () => {
  assertThrowsCode(() => asObject(null), "invalid_request");
  assertThrowsCode(() => asObject([]), "invalid_request");
  assertThrowsCode(() => asObject("params"), "invalid_request");
  assertEquals(asObject({ a: 1 }), { a: 1 });
});

Deno.test("onlyKeys rejects unknown parameters", () => {
  onlyKeys({ username: "ok" }, ["username"]);
  assertThrowsCode(() => onlyKeys({ user_id: "spoof" }, ["username"]), "invalid_request");
});

Deno.test("str enforces bounds and patterns", () => {
  assertEquals(str({ v: "abcd" }, "v", { min: 2, max: 4 }), "abcd");
  assertThrowsCode(() => str({ v: "a" }, "v", { min: 2 }), "invalid_request");
  assertThrowsCode(() => str({ v: "abcde" }, "v", { max: 4 }), "invalid_request");
  assertThrowsCode(() => str({ v: 5 }, "v"), "invalid_request");
  assertThrowsCode(() => str({ v: "nope" }, "v", { pattern: /^ok$/ }), "invalid_request");
});

Deno.test("uuid, token and username validate their shapes", () => {
  assertEquals(
    uuid({ id: "11111111-1111-4111-8111-111111111111" }, "id"),
    "11111111-1111-4111-8111-111111111111",
  );
  assertThrowsCode(() => uuid({ id: "not-a-uuid" }, "id"), "invalid_request");

  // Challenge tokens are case-insensitive on input and lowercased in the API.
  assertEquals(token({ t: "FiXtUrEaLiCe" }, "t"), "fixturealice");
  assertThrowsCode(() => token({ t: "short" }, "t"), "invalid_request");
  assertThrowsCode(() => token({ t: "fixture-alic" }, "t"), "invalid_request");

  assertEquals(username({ u: "fixture_alice" }, "u"), "fixture_alice");
  assertThrowsCode(() => username({ u: "no spaces" }, "u"), "invalid_request");
  assertThrowsCode(() => username({ u: "ab" }, "u"), "invalid_request");
});

Deno.test("bool and int reject non-types", () => {
  assertEquals(bool({ b: true }, "b"), true);
  assertThrowsCode(() => bool({ b: "true" }, "b"), "invalid_request");
  assertEquals(int({ n: 2 }, "n", { min: 1, max: 3 }), 2);
  assertThrowsCode(() => int({ n: 1.5 }, "n"), "invalid_request");
  assertThrowsCode(() => int({ n: 0 }, "n", { min: 1 }), "invalid_request");
});

Deno.test("isoTimestamp rejects implausible clocks", () => {
  const now = new Date().toISOString();
  assertEquals(isoTimestamp({ t: now }, "t"), now);
  assertThrowsCode(
    () => isoTimestamp({ t: "2001-01-01T00:00:00.000Z" }, "t"),
    "invalid_request",
  );
  assertThrowsCode(
    () => isoTimestamp({ t: "2999-01-01T00:00:00.000Z" }, "t"),
    "invalid_request",
  );
  assertThrowsCode(() => isoTimestamp({ t: "not a date" }, "t"), "invalid_request");
});

Deno.test("event names are lowercased and constrained", () => {
  assertEquals(eventName({ e: "Queue_Joined" }, "e"), "queue_joined");
  assertEquals(eventName({ e: "UPPER" }, "e"), "upper");
  assertThrowsCode(() => eventName({ e: "a b" }, "e"), "invalid_request");
  assertThrowsCode(() => eventName({ e: "1starts_with_digit" }, "e"), "invalid_request");
});

Deno.test("jsonSizeBytes detects oversized analytics payloads", () => {
  assert(jsonSizeBytes({ ok: true }) < 8192);
  assert(jsonSizeBytes({ blob: "x".repeat(9000) }) > 8192);
});
