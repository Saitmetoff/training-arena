/*
 * Pinned bundletool resolution and digest verification.
 *
 * The cached JAR and any explicit `--bundletool` / `BUNDLETOOL_JAR` path are
 * all verified against the pinned SHA-256 before the caller may execute Java.
 * The file/network side effects are injected so the ordering can be tested
 * without downloading or executing anything.
 */
import { createHash } from 'node:crypto';

export const BUNDLETOOL_VERSION = '1.18.2';
export const BUNDLETOOL_SHA256 =
  '378b5434cd1378bef6b2bc527b8c7f0ff2584b273830335bce54d6d0813c8584';
export const BUNDLETOOL_URL =
  `https://github.com/google/bundletool/releases/download/${BUNDLETOOL_VERSION}/bundletool-all-${BUNDLETOOL_VERSION}.jar`;

export function sha256(buffer) {
  return createHash('sha256').update(buffer).digest('hex');
}

/**
 * Resolves a bundletool JAR and verifies its digest. Returns
 * `{ ok: true, path }` only when the bytes hash to the pinned digest, or
 * `{ ok: false, error }` (and never a path) otherwise. This must run before
 * any Java process is started.
 *
 * @param {object} deps
 * @param {string|null} deps.explicit    caller-supplied `--bundletool` / env path
 * @param {string} deps.cachedPath       pinned cache location
 * @param {(path: string) => boolean} deps.exists
 * @param {(path: string) => Buffer} deps.readFile
 * @param {() => void} deps.download     fetches the pinned JAR into the cache
 * @param {string} [deps.expectedSha]    override for tests only
 */
export function resolveBundletool({
  explicit = null,
  cachedPath,
  exists,
  readFile,
  download,
  expectedSha = BUNDLETOOL_SHA256,
}) {
  const path = explicit || cachedPath;

  if (explicit) {
    if (!exists(path)) {
      return { ok: false, error: `bundletool jar not found: ${path}` };
    }
  } else if (!exists(cachedPath)) {
    try {
      download();
    } catch (error) {
      return { ok: false, error: `bundletool download failed: ${error}` };
    }
    if (!exists(cachedPath)) {
      return { ok: false, error: `bundletool download produced no file: ${cachedPath}` };
    }
  }

  let digest;
  try {
    digest = sha256(readFile(path));
  } catch (error) {
    return { ok: false, error: `bundletool could not be read: ${error}` };
  }

  if (digest !== expectedSha) {
    return {
      ok: false,
      error: `bundletool sha256 mismatch for ${path}: ${digest}`,
      digest,
    };
  }

  return { ok: true, path };
}
