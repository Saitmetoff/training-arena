import { assert, assertEquals, assertThrowsCode } from "./assert.ts";
import {
  AVATAR_MAX_BYTES,
  decodeAvatar,
  sniffImageContentType,
} from "../lib/avatar.ts";

const PNG_MAGIC = new Uint8Array([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
const JPEG_MAGIC = new Uint8Array([0xff, 0xd8, 0xff, 0xdb, 0x00, 0x01]);
const WEBP_MAGIC = new Uint8Array([
  0x52, 0x49, 0x46, 0x46, 0x10, 0x00, 0x00, 0x00, 0x57, 0x45, 0x42, 0x50,
]);
// Complete 1x1 white images encoded by Pillow; signatures alone are not images.
const PNG_IMAGE = Uint8Array.from(atob("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGP4//8/AAX+Av4N70a4AAAAAElFTkSuQmCC"), c => c.charCodeAt(0));
const JPEG_IMAGE = Uint8Array.from(atob("/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCAABAAEDASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwD3+iiigD//2Q=="), c => c.charCodeAt(0));
const WEBP_IMAGE = Uint8Array.from(atob("UklGRiQAAABXRUJQVlA4IBgAAAAwAQCdASoBAAEAAUAmJaQAA3AA/vz0AAA="), c => c.charCodeAt(0));

function toBase64(bytes: Uint8Array): string {
  let binary = "";
  const chunk = 0x8000;
  for (let i = 0; i < bytes.length; i += chunk) {
    binary += String.fromCharCode(...bytes.subarray(i, i + chunk));
  }
  return btoa(binary);
}

Deno.test("sniffing accepts only JPEG, PNG and WebP signatures", () => {
  assertEquals(sniffImageContentType(PNG_MAGIC), "image/png");
  assertEquals(sniffImageContentType(JPEG_MAGIC), "image/jpeg");
  assertEquals(sniffImageContentType(WEBP_MAGIC), "image/webp");
  assertEquals(sniffImageContentType(new TextEncoder().encode("not an image")), null);
});

Deno.test("decodeAvatar accepts a PNG payload", () => {
  const image = decodeAvatar(toBase64(PNG_IMAGE), "image/png");
  assertEquals(image.contentType, "image/png");
  assertEquals(image.extension, "png");
  assertEquals(image.bytes.length, PNG_IMAGE.length);
});

Deno.test("decodeAvatar accepts JPEG and WebP payloads", () => {
  assertEquals(decodeAvatar(toBase64(JPEG_IMAGE), "image/jpeg").extension, "jpg");
  assertEquals(decodeAvatar(toBase64(WEBP_IMAGE), "image/webp").extension, "webp");
});

Deno.test("decodeAvatar accepts a matching data URL", () => {
  const dataUrl = `data:image/png;base64,${toBase64(PNG_IMAGE)}`;
  const image = decodeAvatar(dataUrl, "image/png");
  assertEquals(image.contentType, "image/png");
});

Deno.test("decodeAvatar rejects a data URL whose mime type differs", () => {
  const dataUrl = `data:image/jpeg;base64,${toBase64(JPEG_MAGIC)}`;
  assertThrowsCode(() => decodeAvatar(dataUrl, "image/png"), "avatar_invalid");
});

Deno.test("decodeAvatar rejects a declared type that does not match the signature", () => {
  assertThrowsCode(() => decodeAvatar(toBase64(PNG_IMAGE), "image/jpeg"), "avatar_invalid");
  assertThrowsCode(() => decodeAvatar(toBase64(JPEG_IMAGE), "image/webp"), "avatar_invalid");
});

Deno.test("decodeAvatar rejects signature-only and truncated image headers", () => {
  for (const [bytes, type] of [[PNG_MAGIC, "image/png"], [JPEG_MAGIC, "image/jpeg"], [WEBP_MAGIC, "image/webp"],
    [PNG_IMAGE.subarray(0, 32), "image/png"], [JPEG_IMAGE.subarray(0, 20), "image/jpeg"],
    [WEBP_IMAGE.subarray(0, 25), "image/webp"]] as const) {
    assertThrowsCode(() => decodeAvatar(toBase64(bytes), type), "avatar_invalid");
  }
});

Deno.test("decodeAvatar rejects text smuggled as an image", () => {
  const text = toBase64(new TextEncoder().encode("<script>alert(1)</script>"));
  assertThrowsCode(() => decodeAvatar(text, "image/png"), "avatar_invalid");
});

Deno.test("decodeAvatar rejects unsupported mime types", () => {
  assertThrowsCode(() => decodeAvatar(toBase64(PNG_MAGIC), "image/gif"), "avatar_invalid");
  assertThrowsCode(() => decodeAvatar(toBase64(PNG_MAGIC), "video/mp4"), "avatar_invalid");
});

Deno.test("decodeAvatar rejects empty and malformed data", () => {
  assertThrowsCode(() => decodeAvatar("", "image/png"), "avatar_invalid");
  assertThrowsCode(() => decodeAvatar("!!!!", "image/png"), "avatar_invalid");
  assertThrowsCode(() => decodeAvatar(42, "image/png"), "avatar_invalid");
});

Deno.test("decodeAvatar enforces the 2 MiB cap before decoding", () => {
  const huge = new Uint8Array(AVATAR_MAX_BYTES + 1);
  huge.set(PNG_MAGIC, 0);
  assertThrowsCode(() => decodeAvatar(toBase64(huge), "image/png"), "avatar_too_large");
  assert(huge.length > AVATAR_MAX_BYTES);
});
