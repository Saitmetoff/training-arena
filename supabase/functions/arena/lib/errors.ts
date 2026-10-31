/**
 * Error model and envelope helpers for the arena Edge Function.
 *
 * SQLSTATEs raised by the RPC migration (`AR0xx`) are the source of truth for
 * business errors; see docs/API.md for the client-facing catalogue. HTTP
 * status is 200 for every business error envelope, 401 for missing/invalid
 * credentials, 405 for a wrong method and 500 for an unexpected fault.
 */

export const ERROR_CODES = [
  "invalid_request",
  "unauthorized",
  "not_found",
  "username_taken",
  "username_invalid",
  "link_not_found",
  "request_closed",
  "request_expired",
  "request_exists",
  "blocked",
  "busy",
  "match_not_ready",
  "match_closed",
  "match_not_live",
  "rep_rejected",
  "tracking_stale",
  "rate_limited",
  "avatar_invalid",
  "avatar_too_large",
  "username_required",
  "forbidden",
  "invalid_action",
  "payload_too_large",
  "conflict",
  "internal_error",
  "method_not_allowed",
  "update_required",
] as const;

export type ErrorCode = (typeof ERROR_CODES)[number];

const SQLSTATE_TO_CODE: Record<string, ErrorCode> = {
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

const HTTP_STATUS: Partial<Record<ErrorCode, number>> = {
  unauthorized: 401,
  method_not_allowed: 405,
  internal_error: 500,
};

export class ArenaError extends Error {
  readonly code: ErrorCode;
  readonly status: number;

  constructor(code: ErrorCode, message?: string) {
    super(message ?? code);
    this.name = "ArenaError";
    this.code = code;
    this.status = HTTP_STATUS[code] ?? 200;
  }
}

export function fail(code: ErrorCode, message?: string): never {
  throw new ArenaError(code, message);
}

/** Maps an RPC failure (PostgREST error) to a client error without leaking SQL. */
export function mapRpcError(error: unknown): ArenaError {
  const candidate = error as { code?: unknown; message?: unknown };
  const sqlstate = typeof candidate?.code === "string" ? candidate.code : "";
  if (sqlstate === "AR001" && candidate.message === "counter_version must be an allowed semantic version") {
    return new ArenaError("update_required", "Update Fault to the latest build before joining a battle.");
  }
  const code = SQLSTATE_TO_CODE[sqlstate];
  if (!code) {
    return new ArenaError("internal_error", "unexpected server error");
  }
  if (code === "internal_error") {
    return new ArenaError(code, "unexpected server error");
  }
  const message =
    typeof candidate.message === "string" && candidate.message.length > 0
      ? candidate.message
      : code;
  return new ArenaError(code, message);
}
