// Arena Edge Function entrypoint.
//
// Platform JWT verification is disabled (`verify_jwt = false` in
// supabase/config.toml) so the anonymous GET can resolve challenge links.
// Every POST verifies the bearer token here and the RPCs verify the session
// id again. Service-role keys stay inside this server-only file.

import { createClient } from "jsr:@supabase/supabase-js@2";
import { createApp } from "./lib/app.ts";
import { RpcFailure, type AuthClient, type Deps, type RpcClient, type StorageClient } from "./lib/deps.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const ALLOWED_ORIGINS = (Deno.env.get("ARENA_ALLOWED_ORIGINS") ?? "")
  .split(",")
  .map((origin) => origin.trim())
  .filter((origin) => origin.length > 0);

function base64UrlToBytes(value: string): Uint8Array {
  const base64 = value.replace(/-/g, "+").replace(/_/g, "/");
  const padded = base64 + "=".repeat((4 - (base64.length % 4)) % 4);
  const binary = atob(padded);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i += 1) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes;
}

/** Reads the session id from a token that Supabase Auth already verified. */
function decodeSessionId(token: string): string {
  const parts = token.split(".");
  if (parts.length !== 3) {
    return "";
  }
  try {
    const payload = JSON.parse(new TextDecoder().decode(base64UrlToBytes(parts[1])));
    return typeof payload.session_id === "string" ? payload.session_id : "";
  } catch {
    return "";
  }
}

function serviceClient() {
  return createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

function createDeps(): Deps {
  const authClient = createClient(SUPABASE_URL, ANON_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const service = serviceClient();
  const bucket = service.storage.from("arena-avatars");

  const rpc: RpcClient = {
    async call(functionName, args) {
      const { data, error } = await service.rpc(functionName, args);
      if (error) {
        throw new RpcFailure(error.code ?? "AR025", error.message);
      }
      return (data ?? {}) as Record<string, unknown>;
    },
  };

  const auth: AuthClient = {
    async getUser(token) {
      const { data, error } = await authClient.auth.getUser(token);
      if (error || !data.user) {
        return null;
      }
      const sessionId = decodeSessionId(token);
      if (!sessionId) {
        return null;
      }
      return { id: data.user.id, sessionId };
    },
    async deleteUser(userId) {
      const { error } = await service.auth.admin.deleteUser(userId);
      const status = (error as { status?: number } | null)?.status;
      if (error && status !== 404) {
        throw new RpcFailure("AR025", error.message);
      }
    },
  };

  const storage: StorageClient = {
    async upload(path, bytes, contentType) {
      const { error } = await bucket.upload(path, bytes, {
        contentType,
        upsert: true,
      });
      if (error) {
        throw new RpcFailure("AR025", error.message);
      }
    },
    async remove(paths) {
      const { error } = await bucket.remove(paths);
      if (error) {
        throw new RpcFailure("AR025", error.message);
      }
    },
    publicUrl(path) {
      return bucket.getPublicUrl(path).data.publicUrl;
    },
  };

  return { rpc, auth, storage };
}

const deps = createDeps();
const app = createApp({ deps, allowedOrigins: ALLOWED_ORIGINS });

Deno.serve(app);
