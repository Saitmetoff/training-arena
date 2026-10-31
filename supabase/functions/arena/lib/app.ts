/**
 * HTTP application for `/functions/v1/arena`.
 *
 *   POST {action,params} + Bearer token -> {data} | {error:{code,message}}
 *   GET  ?token=...  (anonymous, read-only link resolution)
 *
 * The bearer token is verified with Supabase Auth; the RPCs re-check the
 * session id, so a revoked session cannot act even with an unexpired token.
 * The service-role RPC client and storage client are injected and never
 * exposed to the request body.
 */

import { resolveAction } from "./actions.ts";
import { ArenaError, fail, mapRpcError } from "./errors.ts";
import { asObject, onlyKeys } from "./validate.ts";
import type { Deps } from "./deps.ts";

const MAX_BODY_BYTES = 4 * 1024 * 1024;
const LINK_TOKEN_RE = /^[a-z0-9]{12}$/;
const BEARER_RE = /^Bearer\s+(.+)$/i;

export interface AppOptions {
  deps: Deps;
  allowedOrigins: string[];
}

function corsHeaders(request: Request, allowedOrigins: string[]): Record<string, string> {
  const headers: Record<string, string> = { vary: "Origin" };
  const origin = request.headers.get("origin");
  if (origin && (allowedOrigins.includes("*") || allowedOrigins.includes(origin))) {
    headers["access-control-allow-origin"] = allowedOrigins.includes("*") ? "*" : origin;
    headers["access-control-allow-methods"] = "GET, POST, OPTIONS";
    headers["access-control-allow-headers"] =
      "authorization, apikey, content-type, x-client-info";
    headers["access-control-max-age"] = "86400";
  }
  return headers;
}

function json(status: number, payload: unknown, cors: Record<string, string>): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { "content-type": "application/json; charset=utf-8", ...cors },
  });
}

function ok(data: unknown, cors: Record<string, string>): Response {
  return json(200, { data }, cors);
}

function errorResponse(error: unknown, cors: Record<string, string>): Response {
  if (error instanceof ArenaError) {
    return json(error.status, { error: { code: error.code, message: error.message } }, cors);
  }
  const mapped = mapRpcError(error);
  if (mapped.code === "internal_error") {
    console.error("arena: unexpected failure", error);
  }
  return json(mapped.status, { error: { code: mapped.code, message: mapped.message } }, cors);
}

async function readEnvelope(request: Request): Promise<{ action: string; params: Record<string, unknown> }> {
  const contentLength = Number(request.headers.get("content-length") ?? "0");
  if (Number.isFinite(contentLength) && contentLength > MAX_BODY_BYTES) {
    // Do not leave an unread streaming body running after rejecting its header.
    void request.body?.cancel().catch(() => {});
    fail("payload_too_large", "request body is too large");
  }
  const reader = request.body?.getReader();
  const decoder = new TextDecoder();
  const parts: string[] = [];
  let bytesRead = 0;
  if (reader) {
    try {
      while (true) {
        const { value, done } = await reader.read();
        if (done) break;
        bytesRead += value.byteLength;
        if (bytesRead > MAX_BODY_BYTES) {
          // Check actual wire bytes, including when Content-Length is absent
          // or smaller than the stream. Cancel before reading any more chunks.
          void reader.cancel().catch(() => {});
          fail("payload_too_large", "request body is too large");
        }
        parts.push(decoder.decode(value, { stream: true }));
      }
      parts.push(decoder.decode());
    } finally {
      reader.releaseLock();
    }
  }
  const text = parts.join("");
  let parsed: unknown;
  try {
    parsed = JSON.parse(text);
  } catch {
    return fail("invalid_request", "request body must be JSON");
  }
  const envelope = asObject(parsed, "request body");
  onlyKeys(envelope, ["action", "params"]);
  const params = envelope.params === undefined || envelope.params === null
    ? {}
    : asObject(envelope.params);
  const action = envelope.action;
  if (typeof action !== "string" || action.length === 0) {
    fail("invalid_request", "action is required");
  }
  return { action, params };
}

function bearerToken(request: Request): string {
  const header = request.headers.get("authorization") ?? "";
  const match = BEARER_RE.exec(header);
  if (!match) {
    fail("unauthorized", "missing bearer token");
  }
  return match[1].trim();
}

export function createApp(options: AppOptions): (request: Request) => Promise<Response> {
  const { deps, allowedOrigins } = options;

  async function handleGet(request: Request, cors: Record<string, string>): Promise<Response> {
    const url = new URL(request.url);
    const rawToken = url.searchParams.get("token");
    if (!rawToken) {
      fail("invalid_request", "token is required");
    }
    const normalized = rawToken.trim().toLowerCase();
    if (!LINK_TOKEN_RE.test(normalized)) {
      fail("invalid_request", "token must be a 12-character challenge token");
    }
    const data = await deps.rpc.call("arena_resolve_link", { p_token: normalized });
    return ok(data, cors);
  }

  async function handlePost(request: Request, cors: Record<string, string>): Promise<Response> {
    const token = bearerToken(request);
    const identity = await deps.auth.getUser(token);
    if (!identity || !identity.id || !identity.sessionId) {
      fail("unauthorized", "invalid or expired access token");
    }
    const { action, params } = await readEnvelope(request);
    const spec = resolveAction(action);
    try {
      const data = await spec.run({
        actor: identity.id,
        session: identity.sessionId,
        params,
        deps,
      });
      return ok(data, cors);
    } catch (error) {
      if (error instanceof ArenaError) {
        throw error;
      }
      throw mapRpcError(error);
    }
  }

  return async function handle(request: Request): Promise<Response> {
    const cors = corsHeaders(request, allowedOrigins);
    try {
      if (request.method === "OPTIONS") {
        return new Response(null, { status: 204, headers: cors });
      }
      if (request.method === "GET") {
        return await handleGet(request, cors);
      }
      if (request.method !== "POST") {
        return fail("method_not_allowed", "arena accepts GET and POST");
      }
      return await handlePost(request, cors);
    } catch (error) {
      return errorResponse(error, cors);
    }
  };
}
