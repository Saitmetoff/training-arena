/**
 * Avatar intake. Avatars are deliberate public profile content; camera frames
 * are never accepted anywhere in the arena API. The function accepts only
 * JPEG/PNG/WebP, checks both the declared mime type and the file signature,
 * and caps the decoded size at 2 MiB.
 */

import { fail } from "./errors.ts";

export const AVATAR_MAX_BYTES = 2 * 1024 * 1024;
export const AVATAR_MAX_DIMENSION = 1024;

export type AvatarContentType = "image/jpeg" | "image/png" | "image/webp";

export interface AvatarImage {
  bytes: Uint8Array;
  contentType: AvatarContentType;
  extension: "jpg" | "png" | "webp";
}

const MIME_INFO: Record<string, { extension: "jpg" | "png" | "webp" }> = {
  "image/jpeg": { extension: "jpg" },
  "image/png": { extension: "png" },
  "image/webp": { extension: "webp" },
};

const DATA_URL_RE = /^data:(image\/(?:jpeg|png|webp));base64,(.*)$/s;

export function sniffImageContentType(bytes: Uint8Array): AvatarContentType | null {
  if (bytes.length >= 3 && bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff) {
    return "image/jpeg";
  }
  if (
    bytes.length >= 8 &&
    bytes[0] === 0x89 &&
    bytes[1] === 0x50 &&
    bytes[2] === 0x4e &&
    bytes[3] === 0x47 &&
    bytes[4] === 0x0d &&
    bytes[5] === 0x0a &&
    bytes[6] === 0x1a &&
    bytes[7] === 0x0a
  ) {
    return "image/png";
  }
  if (
    bytes.length >= 12 &&
    bytes[0] === 0x52 && // R
    bytes[1] === 0x49 && // I
    bytes[2] === 0x46 && // F
    bytes[3] === 0x46 && // F
    bytes[8] === 0x57 && // W
    bytes[9] === 0x45 && // E
    bytes[10] === 0x42 && // B
    bytes[11] === 0x50 // P
  ) {
    return "image/webp";
  }
  return null;
}

function decodeBase64(value: string): Uint8Array {
  try {
    const binary = atob(value);
    const bytes = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; i += 1) {
      bytes[i] = binary.charCodeAt(i);
    }
    return bytes;
  } catch {
    return fail("avatar_invalid", "avatar is not valid base64");
  }
}

/** Parse image header dimensions only; this is not a complete image decoder. */
export function imageDimensions(bytes: Uint8Array, type: AvatarContentType):
  { width: number; height: number } | null {
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  const fourCC = (offset: number) => String.fromCharCode(...bytes.subarray(offset, offset + 4));
  const u24 = (offset: number) => bytes[offset] | (bytes[offset + 1] << 8) | (bytes[offset + 2] << 16);
  if (type === "image/png") {
    if (bytes.length < 33 || sniffImageContentType(bytes) !== type ||
        view.getUint32(8) !== 13 || fourCC(12) !== "IHDR") return null;
    return { width: view.getUint32(16), height: view.getUint32(20) };
  }
  if (type === "image/jpeg") {
    if (sniffImageContentType(bytes) !== type) return null;
    let offset = 2;
    const sof = new Set([0xc0,0xc1,0xc2,0xc3,0xc5,0xc6,0xc7,0xc9,0xca,0xcb,0xcd,0xce,0xcf]);
    while (offset < bytes.length) {
      if (bytes[offset++] !== 0xff) return null;
      while (offset < bytes.length && bytes[offset] === 0xff) offset++;
      if (offset >= bytes.length) return null;
      const marker = bytes[offset++];
      if (marker === 0xda || marker === 0xd9 || marker === 0 || marker === 0xd8) return null;
      if (marker === 0x01 || (marker >= 0xd0 && marker <= 0xd7)) continue;
      if (offset + 2 > bytes.length) return null;
      const size = view.getUint16(offset);
      if (size < 2 || offset + size > bytes.length) return null;
      if (sof.has(marker)) {
        if (size < 8 || bytes[offset + 7] === 0 || size !== 8 + 3 * bytes[offset + 7]) return null;
        return { width: view.getUint16(offset + 5), height: view.getUint16(offset + 3) };
      }
      offset += size;
    }
    return null;
  }
  if (sniffImageContentType(bytes) !== "image/webp") return null;
  const end = view.getUint32(4, true) + 8;
  if (end > bytes.length || end < 12) return null;
  for (let offset = 12; offset + 8 <= end;) {
    const chunk = fourCC(offset);
    const size = view.getUint32(offset + 4, true);
    const data = offset + 8;
    if (data + size > end) return null;
    if (chunk === "VP8X") {
      if (size !== 10) return null;
      return { width: 1 + u24(data + 4), height: 1 + u24(data + 7) };
    }
    if (chunk === "VP8L") {
      if (size < 5 || bytes[data] !== 0x2f || (bytes[data + 4] >> 5) !== 0) return null;
      const bits = view.getUint32(data + 1, true);
      return { width: 1 + (bits & 0x3fff), height: 1 + ((bits >>> 14) & 0x3fff) };
    }
    if (chunk === "VP8 ") {
      if (size < 10 || (bytes[data] & 1) !== 0 || bytes[data + 3] !== 0x9d ||
          bytes[data + 4] !== 0x01 || bytes[data + 5] !== 0x2a) return null;
      return { width: view.getUint16(data + 6, true) & 0x3fff,
        height: view.getUint16(data + 8, true) & 0x3fff };
    }
    offset = data + size + (size & 1);
  }
  return null;
}

export function decodeAvatar(rawBase64: unknown, rawMimeType: unknown): AvatarImage {
  if (typeof rawMimeType !== "string" || !(rawMimeType.toLowerCase() in MIME_INFO)) {
    fail("avatar_invalid", "avatar must be JPEG, PNG or WebP");
  }
  const declared = rawMimeType.toLowerCase() as AvatarContentType;

  if (typeof rawBase64 !== "string" || rawBase64.length === 0) {
    fail("avatar_invalid", "avatar data is required");
  }

  let payload = rawBase64;
  const dataUrl = DATA_URL_RE.exec(rawBase64);
  if (dataUrl) {
    if (dataUrl[1].toLowerCase() !== declared) {
      fail("avatar_invalid", "avatar data does not match its mime type");
    }
    payload = dataUrl[2];
  }

  // 2 MiB of decoded data is at most ~2.8M base64 characters. Reject early so
  // an oversized payload never gets decoded into memory.
  if (payload.length > Math.ceil((AVATAR_MAX_BYTES * 4) / 3) + 16) {
    fail("avatar_too_large", "avatar exceeds 2 MiB");
  }
  if (!/^[A-Za-z0-9+/=\r\n]+$/.test(payload)) {
    fail("avatar_invalid", "avatar is not valid base64");
  }

  const bytes = decodeBase64(payload);
  if (bytes.length === 0) {
    fail("avatar_invalid", "avatar data is empty");
  }
  if (bytes.length > AVATAR_MAX_BYTES) {
    fail("avatar_too_large", "avatar exceeds 2 MiB");
  }
  const sniffed = sniffImageContentType(bytes);
  if (sniffed === null || sniffed !== declared) {
    fail("avatar_invalid", "avatar data does not match its mime type");
  }
  const dimensions = imageDimensions(bytes, declared);
  if (!dimensions || dimensions.width <= 0 || dimensions.height <= 0) {
    fail("avatar_invalid", "avatar dimensions cannot be parsed");
  }
  if (dimensions.width > AVATAR_MAX_DIMENSION || dimensions.height > AVATAR_MAX_DIMENSION) {
    fail("avatar_too_large", "avatar exceeds 1024 by 1024 pixels");
  }
  return { bytes, contentType: declared, extension: MIME_INFO[declared].extension };
}
