// FCM HTTP v1 delivery for the arena outbox worker (task 08).
//
// Server-only. The service account arrives through the
// `FCM_SERVICE_ACCOUNT_JSON` function secret and is never logged, echoed or
// committed. Delivery is best effort: a failed send is retried by the outbox
// lease/confirm cycle and the in-app inbox remains authoritative.
//
// The module is dependency free so its tests run without network imports.

export interface OutboxItem {
  id: string;
  user_id: string;
  kind: string;
  payload: Record<string, unknown>;
  attempts: number;
  devices: string[];
}

export interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
  token_uri: string;
}

export interface FcmDeliveryResult {
  delivered: boolean;
  error?: string;
  /** Device tokens FCM reported as unregistered; safe to delete. */
  invalidTokens: string[];
}

export interface FcmSender {
  send(item: OutboxItem): Promise<FcmDeliveryResult>;
}

export type FcmFetch = (
  input: string,
  init?: {
    method?: string;
    headers?: Record<string, string>;
    body?: string;
  },
) => Promise<{ status: number; json(): Promise<unknown> }>;

/**
 * Parses the service account JSON. Returns null for anything unusable so the
 * dispatcher can fail closed without printing secret material.
 */
export function parseServiceAccount(raw: string): ServiceAccount | null {
  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch {
    return null;
  }
  if (typeof parsed !== "object" || parsed === null) {
    return null;
  }
  const account = parsed as Record<string, unknown>;
  const projectId =
    typeof account.project_id === "string" ? account.project_id.trim() : "";
  const clientEmail =
    typeof account.client_email === "string" ? account.client_email.trim() : "";
  const privateKey =
    typeof account.private_key === "string"
      ? account.private_key.replace(/\\n/g, "\n").trim()
      : "";
  const tokenUri =
    typeof account.token_uri === "string" && account.token_uri.trim() !== ""
      ? account.token_uri.trim()
      : "https://oauth2.googleapis.com/token";
  if (
    projectId === "" ||
    clientEmail === "" ||
    !privateKey.includes("PRIVATE KEY")
  ) {
    return null;
  }
  return {
    project_id: projectId,
    client_email: clientEmail,
    private_key: privateKey,
    token_uri: tokenUri,
  };
}

/** Push copy for one outbox kind. */
export function notificationContent(kind: string): {
  title: string;
  body: string;
} {
  switch (kind) {
    case "challenge_request":
      return {
        title: "New challenge",
        body: "A friend challenged you to a battle.",
      };
    case "request_accepted":
      return {
        title: "Challenge accepted",
        body: "Your challenge was accepted. Get ready.",
      };
    case "request_declined":
      return {
        title: "Challenge update",
        body: "A challenge was declined or cancelled.",
      };
    case "match_ready":
      return {
        title: "Opponent found",
        body: "Your battle is ready when both players are.",
      };
    case "match_finished":
      return { title: "Battle finished", body: "Your result is ready." };
    default:
      return { title: "Fault", body: "You have an update." };
  }
}

/** Android channel per kind; both channels are created by the native host. */
export function channelIdFor(kind: string): string {
  switch (kind) {
    case "challenge_request":
    case "request_declined":
      return "arena_requests";
    case "request_accepted":
    case "match_ready":
    case "match_finished":
      return "arena_matches";
    default:
      return "arena_requests";
  }
}

/**
 * Flattens the outbox payload into FCM data values. FCM data entries are
 * always strings; the client parses them with `PushPayload.fromData`.
 */
export function buildNotificationData(
  item: OutboxItem,
): Record<string, string> {
  const data: Record<string, string> = { kind: item.kind };
  for (const [key, value] of Object.entries(item.payload ?? {})) {
    if (value === null || value === undefined) {
      continue;
    }
    data[key] = typeof value === "string" ? value : JSON.stringify(value);
  }
  return data;
}

/** One FCM HTTP v1 message for one device token. */
export function buildFcmMessage(
  deviceToken: string,
  item: OutboxItem,
): Record<string, unknown> {
  const { title, body } = notificationContent(item.kind);
  return {
    message: {
      token: deviceToken,
      notification: { title, body },
      data: buildNotificationData(item),
      android: {
        priority: "high",
        notification: {
          channel_id: channelIdFor(item.kind),
          default_vibrate_timings: true,
        },
        ttl: "3600s",
      },
      apns: {
        headers: { "apns-priority": "10" },
        payload: { aps: { sound: "default" } },
      },
    },
  };
}

/** Classifies one FCM send response. Never throws on malformed bodies. */
export function classifySendResponse(
  status: number,
  body: unknown,
): { delivered: boolean; invalidToken: boolean; error?: string } {
  if (status === 200) {
    return { delivered: true, invalidToken: false };
  }
  const details = extractError(body);
  const unregistered =
    status === 404 ||
    (details !== undefined && details.toUpperCase().includes("UNREGISTERED"));
  return {
    delivered: false,
    invalidToken: unregistered,
    error: details ?? `http_${status}`,
  };
}

function extractError(body: unknown): string | undefined {
  if (typeof body !== "object" || body === null) {
    return undefined;
  }
  const error = (body as { error?: unknown }).error;
  if (typeof error !== "object" || error === null) {
    return undefined;
  }
  const record = error as { status?: unknown; message?: unknown };
  const parts: string[] = [];
  if (typeof record.status === "string") {
    parts.push(record.status);
  }
  if (typeof record.message === "string") {
    parts.push(record.message);
  }
  return parts.length > 0 ? parts.join(": ").slice(0, 500) : undefined;
}

/** Mints and caches the OAuth2 access token for FCM HTTP v1. */
export class FcmAccessTokenProvider {
  constructor(
    private readonly account: ServiceAccount,
    private readonly fetchImpl: FcmFetch = fetch as unknown as FcmFetch,
    private readonly nowSeconds: () => number = () =>
      Math.floor(Date.now() / 1000),
  ) {}

  private cachedToken = "";
  private expiresAt = 0;

  async get(): Promise<string> {
    const now = this.nowSeconds();
    if (this.cachedToken !== "" && now < this.expiresAt - 60) {
      return this.cachedToken;
    }
    const assertion = await createServiceAccountAssertion(this.account, now);
    const response = await this.fetchImpl(this.account.token_uri, {
      method: "POST",
      headers: { "content-type": "application/x-www-form-urlencoded" },
      body:
        "grant_type=" +
        encodeURIComponent("urn:ietf:params:oauth:grant-type:jwt-bearer") +
        "&assertion=" +
        encodeURIComponent(assertion),
    });
    let body: unknown = {};
    try {
      body = await response.json();
    } catch {
      body = {};
    }
    if (response.status !== 200) {
      throw new Error("fcm_token_request_failed");
    }
    const accessToken = (body as { access_token?: unknown }).access_token;
    const expiresIn = (body as { expires_in?: unknown }).expires_in;
    if (typeof accessToken !== "string" || accessToken === "") {
      throw new Error("fcm_token_missing");
    }
    this.cachedToken = accessToken;
    this.expiresAt =
      now + (typeof expiresIn === "number" ? expiresIn : 3600);
    return accessToken;
  }
}

/** Builds the RS256-signed OAuth2 assertion for a service account. */
export async function createServiceAccountAssertion(
  account: ServiceAccount,
  nowSeconds: number,
): Promise<string> {
  const header = base64UrlEncodeJson({ alg: "RS256", typ: "JWT" });
  const claims = base64UrlEncodeJson({
    iss: account.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: account.token_uri,
    iat: nowSeconds,
    exp: nowSeconds + 3600,
  });
  const signingInput = `${header}.${claims}`;
  const keyBytes = pemToBytes(account.private_key);
  const keyData = keyBytes.buffer.slice(
    keyBytes.byteOffset,
    keyBytes.byteOffset + keyBytes.byteLength,
  ) as ArrayBuffer;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    keyData,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(signingInput),
  );
  return `${signingInput}.${base64UrlEncode(new Uint8Array(signature))}`;
}

/**
 * Builds the sender used by the worker. Returns null when the service
 * account cannot be parsed; the caller then fails closed.
 */
export function createFcmSender(
  rawServiceAccount: string,
  fetchImpl?: FcmFetch,
  nowSeconds?: () => number,
): FcmSender | null {
  const account = parseServiceAccount(rawServiceAccount);
  if (account === null) {
    return null;
  }
  const doFetch = fetchImpl ?? (fetch as unknown as FcmFetch);
  const tokens = new FcmAccessTokenProvider(account, doFetch, nowSeconds);
  const endpoint = `https://fcm.googleapis.com/v1/projects/${
    encodeURIComponent(account.project_id)
  }/messages:send`;

  return {
    async send(item: OutboxItem): Promise<FcmDeliveryResult> {
      const invalidTokens: string[] = [];
      let delivered = false;
      let lastError: string | undefined;
      let accessToken: string;
      try {
        accessToken = await tokens.get();
      } catch {
        return { delivered: false, error: "fcm_auth_failed", invalidTokens };
      }
      for (const device of item.devices) {
        try {
          const response = await doFetch(endpoint, {
            method: "POST",
            headers: {
              authorization: `Bearer ${accessToken}`,
              "content-type": "application/json",
            },
            body: JSON.stringify(buildFcmMessage(device, item)),
          });
          let body: unknown = {};
          try {
            body = await response.json();
          } catch {
            body = {};
          }
          const result = classifySendResponse(response.status, body);
          if (result.delivered) {
            delivered = true;
          } else if (result.invalidToken) {
            invalidTokens.push(device);
          } else {
            lastError = result.error;
          }
        } catch {
          lastError = "fcm_unreachable";
        }
      }
      return {
        delivered,
        error: delivered ? undefined : lastError ?? "fcm_failed",
        invalidTokens,
      };
    },
  };
}

function base64UrlEncodeJson(value: unknown): string {
  return base64UrlEncode(new TextEncoder().encode(JSON.stringify(value)));
}

function base64UrlEncode(bytes: Uint8Array): string {
  let binary = "";
  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(
    /=+$/g,
    "",
  );
}

function pemToBytes(pem: string): Uint8Array {
  const base64 = pem
    .replace(/-----BEGIN [^-]+-----/g, "")
    .replace(/-----END [^-]+-----/g, "")
    .replace(/\s+/g, "");
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i += 1) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes;
}
