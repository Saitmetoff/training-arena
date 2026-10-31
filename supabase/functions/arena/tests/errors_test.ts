import { assert, assertEquals, assertThrowsCode } from "./assert.ts";
import { ArenaError, ERROR_CODES, mapRpcError } from "../lib/errors.ts";

Deno.test("SQLSTATE errors map to the documented catalogue", () => {
  assertEquals(ERROR_CODES.length, 27);
  const expectations: Record<string, string> = {
    AR001: "invalid_request",
    AR002: "unauthorized",
    AR003: "not_found",
    AR004: "username_taken",
    AR005: "username_invalid",
    AR006: "link_not_found",
    AR007: "request_closed",
    AR008: "request_expired",
    AR009: "request_exists",
    AR010: "blocked",
    AR011: "busy",
    AR012: "match_not_ready",
    AR013: "match_closed",
    AR014: "match_not_live",
    AR015: "rep_rejected",
    AR016: "tracking_stale",
    AR017: "rate_limited",
    AR018: "avatar_invalid",
    AR019: "avatar_too_large",
    AR020: "username_required",
    AR021: "forbidden",
    AR022: "invalid_action",
    AR023: "payload_too_large",
    AR024: "conflict",
    AR025: "internal_error",
  };
  for (const [sqlstate, code] of Object.entries(expectations)) {
    const mapped = mapRpcError({ code: sqlstate, message: "message" });
    assertEquals(mapped.code, code, sqlstate);
    // AR025 is sanitized so SQL details never reach the client.
    const expectedMessage = code === "internal_error" ? "unexpected server error" : "message";
    assertEquals(mapped.message, expectedMessage, sqlstate);
  }
});

Deno.test("unsupported counter versions require an update without weakening other invalid requests", () => {
  const mapped = mapRpcError({ code: "AR001", message: "counter_version must be an allowed semantic version" });
  assertEquals(mapped.code, "update_required");
  assertEquals(mapped.status, 200);
  assertEquals(mapped.message, "Update Fault to the latest build before joining a battle.");
  assertEquals(mapRpcError({ code: "AR001", message: "sequence must be a positive integer" }).code, "invalid_request");
});

Deno.test("unauthorized and internal SQLSTATEs carry the right HTTP status", () => {
  assertEquals(mapRpcError({ code: "AR002" }).status, 401);
  assertEquals(mapRpcError({ code: "AR025" }).status, 500);
  assertEquals(mapRpcError({ code: "AR006" }).status, 200);
});

Deno.test("unknown database failures never leak SQL details", () => {
  const mapped = mapRpcError({ code: "23505", message: "duplicate key value ..." });
  assertEquals(mapped.code, "internal_error");
  assertEquals(mapped.status, 500);
  assertEquals(mapped.message, "unexpected server error");
});

Deno.test("ArenaError defaults its message and status", () => {
  const error = new ArenaError("blocked");
  assertEquals(error.message, "blocked");
  assertEquals(error.status, 200);
  assert(error instanceof Error);
});

Deno.test("invalid SQLSTATE strings are internal errors", () => {
  assertThrowsCode(() => {
    throw mapRpcError({ code: Object(1), message: 2 });
  }, "internal_error");
});
