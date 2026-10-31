/** Minimal assertions so the tests never depend on a network import. */

export function assert(condition: unknown, message = "assertion failed"): void {
  if (!condition) {
    throw new Error(message);
  }
}

export function assertEquals(actual: unknown, expected: unknown, message = ""): void {
  const left = JSON.stringify(actual);
  const right = JSON.stringify(expected);
  if (left !== right) {
    throw new Error(`${message} expected ${right} but received ${left}`);
  }
}

export async function assertRejects(
  fn: () => Promise<unknown>,
  message = "expected rejection",
): Promise<void> {
  try {
    await fn();
  } catch {
    return;
  }
  throw new Error(message);
}
