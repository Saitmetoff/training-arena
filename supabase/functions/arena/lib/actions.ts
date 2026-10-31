/**
 * Action registry for `POST /functions/v1/arena`.
 *
 * Every action maps to exactly one RPC and one strict parameter parser. The
 * actor and session always come from the verified JWT; nothing here reads a
 * user id from `params`. Actions that touch Storage (avatars, account
 * deletion) are the only handlers with custom logic.
 */

import { decodeAvatar } from "./avatar.ts";
import { fail } from "./errors.ts";
import type { Deps } from "./deps.ts";
import {
  asObject,
  bool,
  eventName,
  int,
  isoTimestamp,
  jsonObject,
  jsonSizeBytes,
  onlyKeys,
  optionalStr,
  str,
  token,
  username,
  uuid,
  type Params,
} from "./validate.ts";

export interface ActionContext {
  actor: string;
  session: string;
  params: Params;
  deps: Deps;
}

export interface ActionSpec {
  run(context: ActionContext): Promise<unknown>;
}

type Parser = (params: Params) => Params;

function rpcAction(functionName: string, parse: Parser): ActionSpec {
  return {
    run({ actor, session, params, deps }) {
      const args = parse(params);
      return deps.rpc.call(functionName, {
        p_actor: actor,
        p_session: session,
        ...args,
      });
    },
  };
}

const noParams: Parser = (params) => {
  onlyKeys(params, []);
  return {};
};

// Missing and legacy wire versions require an app update, not transport retry.
function counterVersion(params: Params): string {
  const value = params.counter_version;
  if (typeof value !== "string" || value.length > 32 || !/^[0-9]+\.[0-9]+\.[0-9]+$/.test(value)) {
    fail("update_required", "Update Fault on both phones before starting a battle.");
  }
  return value;
}

async function removeQuietly(deps: Deps, path: string): Promise<void> {
  try {
    await deps.storage.remove([path]);
  } catch (error) {
    console.error("arena: avatar cleanup failed", { path, error: String(error) });
  }
}

const avatarUpdate: ActionSpec = {
  async run({ actor, session, params, deps }) {
    onlyKeys(params, ["base64", "mime_type"]);
    const image = decodeAvatar(params.base64, params.mime_type);
    const path = `avatars/${actor}/${crypto.randomUUID()}.${image.extension}`;
    await deps.storage.upload(path, image.bytes, image.contentType);
    try {
      const result = await deps.rpc.call("arena_set_avatar", {
        p_actor: actor,
        p_session: session,
        p_avatar_url: deps.storage.publicUrl(path),
        p_avatar_path: path,
      });
      const previous = result.previous_avatar_path;
      if (typeof previous === "string" && previous.length > 0) {
        await removeQuietly(deps, previous);
      }
      return { profile: result.profile };
    } catch (error) {
      await removeQuietly(deps, path);
      throw error;
    }
  },
};

const avatarRemove: ActionSpec = {
  async run({ actor, session, params, deps }) {
    onlyKeys(params, []);
    const result = await deps.rpc.call("arena_clear_avatar", {
      p_actor: actor,
      p_session: session,
    });
    const previous = result.previous_avatar_path;
    if (typeof previous === "string" && previous.length > 0) {
      await removeQuietly(deps, previous);
    }
    return { profile: result.profile };
  },
};

const deleteAccount: ActionSpec = {
  async run({ actor, session, params, deps }) {
    onlyKeys(params, []);
    const result = await deps.rpc.call("arena_delete_account", {
      p_actor: actor,
      p_session: session,
    });
    const paths = Array.isArray(result.avatar_paths)
      ? result.avatar_paths.filter((path): path is string => typeof path === "string")
      : [];
    for (const path of paths) {
      await removeQuietly(deps, path);
    }
    await deps.auth.deleteUser(actor);
    return { ok: true };
  },
};

export const ACTIONS: Record<string, ActionSpec> = {
  profile: rpcAction("arena_get_profile", noParams),
  profile_update: rpcAction("arena_update_profile", (params) => {
    onlyKeys(params, ["username"]);
    return { p_username: username(params, "username") };
  }),
  avatar_update: avatarUpdate,
  avatar_remove: avatarRemove,
  resolve_link: rpcAction("arena_resolve_link", (params) => {
    onlyKeys(params, ["token"]);
    return { p_token: token(params, "token") };
  }),
  inbox: rpcAction("arena_inbox", noParams),
  request_send: rpcAction("arena_request_send", (params) => {
    onlyKeys(params, ["token"]);
    return { p_token: token(params, "token") };
  }),
  request_rematch: rpcAction("arena_request_rematch", (params) => {
    onlyKeys(params, ["match_id"]);
    return { p_match_id: uuid(params, "match_id") };
  }),
  request_accept: rpcAction("arena_request_accept", (params) => {
    onlyKeys(params, ["request_id"]);
    return { p_request_id: uuid(params, "request_id") };
  }),
  request_respond: rpcAction("arena_request_respond", (params) => {
    onlyKeys(params, ["request_id", "response"]);
    return {
      p_request_id: uuid(params, "request_id"),
      p_response: str(params, "response", {
        pattern: /^(decline|cancel)$/,
        patternMessage: "response must be decline or cancel",
      }),
    };
  }),
  queue_join: rpcAction("arena_queue_join", noParams),
  queue_poll: rpcAction("arena_queue_poll", noParams),
  queue_leave: rpcAction("arena_queue_leave", noParams),
  match_state: rpcAction("arena_match_state_versioned", (params) => {
    onlyKeys(params, ["match_id", "counter_version"]);
    return { p_match_id: uuid(params, "match_id"), p_counter_version: counterVersion(params) };
  }),
  ready: rpcAction("arena_match_ready_versioned", (params) => {
    onlyKeys(params, ["match_id", "tracking", "practice_complete", "counter_version"]);
    return {
      p_counter_version: counterVersion(params),
      p_match_id: uuid(params, "match_id"),
      p_tracking: bool(params, "tracking"),
      p_practice_complete: bool(params, "practice_complete"),
    };
  }),
  heartbeat: rpcAction("arena_match_heartbeat_versioned", (params) => {
    onlyKeys(params, ["match_id", "tracking", "counter_version"]);
    return {
      p_counter_version: counterVersion(params),
      p_match_id: uuid(params, "match_id"),
      p_tracking: bool(params, "tracking"),
    };
  }),
  rep: rpcAction("arena_match_rep", (params) => {
    onlyKeys(params, [
      "match_id",
      "event_id",
      "sequence",
      "observed_at",
      "counter_version",
    ]);
    return {
      p_match_id: uuid(params, "match_id"),
      p_event_id: uuid(params, "event_id"),
      p_sequence: int(params, "sequence", { min: 1, max: 1_000_000 }),
      p_observed_at: isoTimestamp(params, "observed_at"),
      p_counter_version: str(params, "counter_version", { min: 1, max: 32 }),
    };
  }),
  leave: rpcAction("arena_match_leave", (params) => {
    onlyKeys(params, ["match_id"]);
    return { p_match_id: uuid(params, "match_id") };
  }),
  leaderboard: rpcAction("arena_leaderboard", noParams),
  history: rpcAction("arena_history", noParams),
  profile_public: rpcAction("arena_public_profile", (params) => {
    onlyKeys(params, ["user_id"]);
    return { p_user_id: uuid(params, "user_id") };
  }),
  link_rotate: rpcAction("arena_rotate_link", noParams),
  report: rpcAction("arena_report", (params) => {
    onlyKeys(params, ["target_user_id", "match_id", "reason"]);
    const matchId = params.match_id;
    return {
      p_target_user_id: uuid(params, "target_user_id"),
      p_match_id: matchId === undefined || matchId === null
        ? null
        : uuid(params, "match_id"),
      p_reason: str(params, "reason", { min: 3, max: 500 }),
    };
  }),
  block: rpcAction("arena_block", (params) => {
    onlyKeys(params, ["target_user_id"]);
    return { p_target_user_id: uuid(params, "target_user_id") };
  }),
  unblock: rpcAction("arena_unblock", (params) => {
    onlyKeys(params, ["target_user_id"]);
    return { p_target_user_id: uuid(params, "target_user_id") };
  }),
  blocked: rpcAction("arena_blocked", noParams),
  device_register: rpcAction("arena_device_register", (params) => {
    onlyKeys(params, ["token", "platform"]);
    const platform = optionalStr(params, "platform", { max: 16 });
    if (platform !== undefined && platform !== "android" && platform !== "ios") {
      fail("invalid_request", "platform must be android or ios");
    }
    return {
      p_token: str(params, "token", { min: 8, max: 4096 }),
      p_platform: platform ?? "android",
    };
  }),
  delete_account: deleteAccount,
  analytics: rpcAction("arena_analytics", (params) => {
    onlyKeys(params, ["event", "properties"]);
    const properties = params.properties === undefined || params.properties === null
      ? {}
      : jsonObject(params, "properties");
    if (jsonSizeBytes(properties) > 8192) {
      fail("payload_too_large", "properties are too large");
    }
    return {
      p_event: eventName(params, "event"),
      p_properties: properties,
    };
  }),
};

export function resolveAction(name: unknown): ActionSpec {
  if (typeof name !== "string" || name.length === 0) {
    fail("invalid_request", "action is required");
  }
  const spec = ACTIONS[name];
  if (!spec) {
    fail("invalid_action", `unknown action: ${name}`);
  }
  return spec;
}

export { asObject };
