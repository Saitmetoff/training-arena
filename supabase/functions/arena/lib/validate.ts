/**
 * Input validation for the arena Edge Function.
 *
 * Validators only enforce shape, type and obvious bounds. Product rules
 * (authorization, match state, rating, sequence ordering, round clock) are
 * enforced again inside the RPCs; nothing here is trusted by the database.
 * Unknown keys are rejected so a client can never smuggle a user id, role,
 * score, outcome or timestamp the API does not accept.
 */

import { fail } from "./errors.ts";

export type Params = Record<string, unknown>;

const UUID_RE =
  /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;
const TOKEN_RE = /^[a-z0-9]{12}$/;
const USERNAME_RE = /^[A-Za-z0-9_]{3,20}$/;
const EVENT_RE = /^[a-z][a-z0-9_]{1,48}$/;

export function asObject(value: unknown, label = "params"): Params {
  if (value === null || typeof value !== "object" || Array.isArray(value)) {
    fail("invalid_request", `${label} must be an object`);
  }
  return value as Params;
}

export function onlyKeys(params: Params, allowed: readonly string[]): void {
  for (const key of Object.keys(params)) {
    if (!allowed.includes(key)) {
      fail("invalid_request", `unknown parameter: ${key}`);
    }
  }
}

export function str(
  params: Params,
  key: string,
  options: { min?: number; max?: number; pattern?: RegExp; patternMessage?: string } = {},
): string {
  const value = params[key];
  if (typeof value !== "string") {
    fail("invalid_request", `${key} must be a string`);
  }
  if (options.min !== undefined && value.length < options.min) {
    fail("invalid_request", `${key} is too short`);
  }
  if (options.max !== undefined && value.length > options.max) {
    fail("invalid_request", `${key} is too long`);
  }
  if (options.pattern && !options.pattern.test(value)) {
    fail("invalid_request", options.patternMessage ?? `${key} has an invalid format`);
  }
  return value;
}

export function optionalStr(
  params: Params,
  key: string,
  options: { min?: number; max?: number; pattern?: RegExp } = {},
): string | undefined {
  if (params[key] === undefined || params[key] === null) {
    return undefined;
  }
  return str(params, key, options);
}

export function bool(params: Params, key: string): boolean {
  const value = params[key];
  if (typeof value !== "boolean") {
    fail("invalid_request", `${key} must be a boolean`);
  }
  return value;
}

export function optionalBool(params: Params, key: string): boolean | undefined {
  if (params[key] === undefined || params[key] === null) {
    return undefined;
  }
  return bool(params, key);
}

export function int(
  params: Params,
  key: string,
  options: { min?: number; max?: number } = {},
): number {
  const value = params[key];
  if (typeof value !== "number" || !Number.isInteger(value)) {
    fail("invalid_request", `${key} must be an integer`);
  }
  if (options.min !== undefined && value < options.min) {
    fail("invalid_request", `${key} is below the minimum`);
  }
  if (options.max !== undefined && value > options.max) {
    fail("invalid_request", `${key} is above the maximum`);
  }
  return value;
}

export function uuid(params: Params, key: string): string {
  return str(params, key, {
    min: 36,
    max: 36,
    pattern: UUID_RE,
    patternMessage: `${key} must be a UUID`,
  });
}

export function token(params: Params, key: string): string {
  const value = str(params, key, { min: 12, max: 12 });
  const lower = value.toLowerCase();
  if (!TOKEN_RE.test(lower)) {
    fail("invalid_request", `${key} must be a 12-character challenge token`);
  }
  return lower;
}

export function username(params: Params, key: string): string {
  return str(params, key, {
    min: 3,
    max: 20,
    pattern: USERNAME_RE,
    patternMessage: `${key} may only contain letters, digits and underscore`,
  });
}

export function isoTimestamp(params: Params, key: string): string {
  const value = str(params, key, { min: 20, max: 40 });
  const parsed = Date.parse(value);
  if (!Number.isFinite(parsed)) {
    fail("invalid_request", `${key} must be an ISO timestamp`);
  }
  const now = Date.now();
  if (parsed > now + 5 * 60 * 1000 || parsed < now - 24 * 60 * 60 * 1000) {
    fail("invalid_request", `${key} is outside the plausible window`);
  }
  return value;
}

export function eventName(params: Params, key: string): string {
  const value = str(params, key, { min: 2, max: 49 });
  const lower = value.toLowerCase();
  if (!EVENT_RE.test(lower)) {
    fail("invalid_request", `${key} has an invalid format`);
  }
  return lower;
}

export function jsonObject(params: Params, key: string): Params {
  return asObject(params[key], key);
}

export function jsonSizeBytes(value: unknown): number {
  return new TextEncoder().encode(JSON.stringify(value ?? null)).length;
}
