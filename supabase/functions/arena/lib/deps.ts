/**
 * Dependency boundary for the arena Edge Function.
 *
 * `index.ts` wires the real Supabase clients; tests wire in-memory doubles.
 * The handler logic never imports the Supabase SDK directly, so every
 * authorization/state path is testable without a network or a database.
 */

export class RpcFailure extends Error {
  readonly code: string;

  constructor(code: string, message: string) {
    super(message);
    this.name = "RpcFailure";
    this.code = code;
  }
}

export interface RpcClient {
  /** Calls a service-role-only RPC; throws RpcFailure on database errors. */
  call(functionName: string, args: Record<string, unknown>): Promise<Record<string, unknown>>;
}

export interface AuthIdentity {
  id: string;
  sessionId: string;
}

export interface AuthClient {
  /** Validates a Supabase access token; null when it is not active. */
  getUser(token: string): Promise<AuthIdentity | null>;
  /** Deletes the auth user with the service role; 404 is treated as success. */
  deleteUser(userId: string): Promise<void>;
}

export interface StorageClient {
  upload(path: string, bytes: Uint8Array, contentType: string): Promise<void>;
  remove(paths: string[]): Promise<void>;
  publicUrl(path: string): string;
}

export interface Deps {
  rpc: RpcClient;
  auth: AuthClient;
  storage: StorageClient;
}
