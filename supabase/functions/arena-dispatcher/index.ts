// Arena notification dispatcher (server-only).
//
// Leases rows from `arena_notification_outbox` with its own bearer secret and
// confirms them with lease/retry semantics. Platform delivery is best effort:
// when no FCM service account is configured (the local case) the dispatcher
// only runs maintenance and leaves pending notifications untouched, so the
// inbox remains authoritative and nothing is silently dropped.
//
// The FCM HTTP v1 send path lives in `lib/fcm.ts`; it never logs tokens and
// deletes device rows FCM reports as unregistered. The service account is a
// function secret (`FCM_SERVICE_ACCOUNT_JSON`) and is never committed.
//
// Request: POST /functions/v1/arena-dispatcher
//          Authorization: Bearer <ARENA_DISPATCHER_SECRET>
// Reply:   {data:{maintenance, leased, delivered, retried, skipped, delivery}}

import { createClient } from "jsr:@supabase/supabase-js@2";

import {
  createFcmSender,
  type FcmSender,
  type OutboxItem,
} from "./lib/fcm.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const DISPATCHER_SECRET = Deno.env.get("ARENA_DISPATCHER_SECRET") ?? "";
const FCM_SERVICE_ACCOUNT_JSON = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON") ?? "";

const LEASE_OWNER = `dispatcher-${crypto.randomUUID()}`;

function safeEqual(a: string, b: string): boolean {
  const left = new TextEncoder().encode(a);
  const right = new TextEncoder().encode(b);
  if (left.length !== right.length) {
    return false;
  }
  let diff = 0;
  for (let i = 0; i < left.length; i += 1) {
    diff |= left[i] ^ right[i];
  }
  return diff === 0;
}

function json(status: number, payload: unknown): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { "content-type": "application/json; charset=utf-8" },
  });
}

Deno.serve(async (request: Request): Promise<Response> => {
  if (request.method !== "POST") {
    return json(405, { error: { code: "method_not_allowed", message: "POST required" } });
  }
  if (!DISPATCHER_SECRET) {
    return json(503, {
      error: { code: "dispatcher_not_configured", message: "ARENA_DISPATCHER_SECRET is not set" },
    });
  }
  const header = request.headers.get("authorization") ?? "";
  const match = /^Bearer\s+(.+)$/i.exec(header);
  if (!match || !safeEqual(match[1].trim(), DISPATCHER_SECRET)) {
    return json(401, { error: { code: "unauthorized", message: "invalid dispatcher secret" } });
  }

  const service = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const maintenance = await service.rpc("arena_maintenance");
  if (maintenance.error) {
    return json(500, { error: { code: "internal_error", message: maintenance.error.message } });
  }

  if (!FCM_SERVICE_ACCOUNT_JSON) {
    return json(200, {
      data: {
        maintenance: maintenance.data,
        leased: 0,
        delivered: 0,
        retried: 0,
        skipped: 0,
        delivery: "not_configured",
      },
    });
  }

  let sender: FcmSender | null = null;
  try {
    sender = createFcmSender(FCM_SERVICE_ACCOUNT_JSON);
  } catch {
    sender = null;
  }
  if (sender === null) {
    // Never echo the secret; only the fact that it is unusable.
    return json(500, {
      error: {
        code: "dispatcher_not_configured",
        message: "FCM_SERVICE_ACCOUNT_JSON is not a usable service account",
      },
    });
  }

  const lease = await service.rpc("arena_outbox_lease", {
    p_owner: LEASE_OWNER,
    p_limit: 50,
    p_lease_seconds: 60,
  });
  if (lease.error) {
    return json(500, { error: { code: "internal_error", message: lease.error.message } });
  }

  const items = (lease.data ?? []) as OutboxItem[];
  let delivered = 0;
  let retried = 0;

  for (const item of items) {
    const result = item.devices.length === 0
      ? { delivered: false, error: "no_device", invalidTokens: <string[]>[] }
      : await sender.send(item);
    if (result.invalidTokens.length > 0) {
      const cleanup = await service
        .from("arena_devices")
        .delete()
        .in("token", result.invalidTokens);
      if (cleanup.error) {
        console.error("arena-dispatcher: device cleanup failed", cleanup.error.message);
      }
    }
    const confirm = await service.rpc("arena_outbox_confirm", {
      p_id: item.id,
      p_owner: LEASE_OWNER,
      p_delivered: result.delivered,
      p_error: result.error ?? null,
      p_retry_seconds: 60,
    });
    if (confirm.error) {
      console.error("arena-dispatcher: confirm failed", confirm.error.message);
      continue;
    }
    if (result.delivered) {
      delivered += 1;
    } else {
      retried += 1;
    }
  }

  return json(200, {
    data: {
      maintenance: maintenance.data,
      leased: items.length,
      delivered,
      retried,
      skipped: 0,
      delivery: "fcm_configured",
    },
  });
});
