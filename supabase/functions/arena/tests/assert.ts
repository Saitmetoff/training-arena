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

export function assertThrowsCode(fn: () => unknown, code: string): void {
  try {
    fn();
  } catch (error) {
    const actual = (error as { code?: string }).code;
    if (actual !== code) {
      throw new Error(`expected code ${code} but received ${actual}: ${error}`);
    }
    return;
  }
  throw new Error(`expected ${code} to be thrown`);
}

export async function assertRejectsCode(
  fn: () => Promise<unknown>,
  code: string,
): Promise<void> {
  try {
    await fn();
  } catch (error) {
    const actual = (error as { code?: string }).code;
    if (actual !== code) {
      throw new Error(`expected code ${code} but received ${actual}: ${error}`);
    }
    return;
  }
  throw new Error(`expected ${code} to be rejected`);
}
