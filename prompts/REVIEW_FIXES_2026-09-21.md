# Release review fixes — 21 September 2026

Coordinator: Codex. Sole source writer: OpenCode with `opencode-go/deepseek-v4.1-flash`.
Review baseline: `3efdc07`; reviewed candidate: `1561673` (product freeze `1de6127`).
Read the current contract and launch task pack. Preserve the owner's uncommitted L09/L10 drafts and their PROJECT_STATUS/GO_NO_GO sections. Do not touch D:/Kiro. No hosted changes, credentials, purchases, publication, or invented device evidence.

Use RTK for shell commands: `C:/Users/ADMIN/AppData/Local/Microsoft/WinGet/Packages/rtk-ai.rtk_Microsoft.Winget.Source_8wekyb3d8bbwe/rtk.exe`; `proxy` handles other commands. Do not retry denied external-directory reads or change permission policies. Public dependency documentation is available online. Source reading/editing stays in D:/TrainingArena. Existing toolchain: Flutter at D:/toolchains/flutter-3.47.5/flutter; Android SDK D:/toolchains/android-sdk; JAVA_HOME D:/Kiro/.tooling/jdk17 is read-only; GRADLE_USER_HOME D:/gradle-home; TEMP/TMP D:/ta-tmp. Do not delete caches or reset databases for these fixes.

## Batch A — session durability and meaningful guard tests

Implement this batch only, then return to the coordinator for review. Do not commit or rewrite shared release reports yet; other read-only reviews are running. Add only focused regressions that fail before the corresponding correction. Use existing test tools and boundaries; no new framework.

1. `SecureAuthSessionStore._removeLegacy` ignores the boolean from `SharedPreferences.remove` and swallows failures. `clearSession`/`clearPkceVerifier` can consequently report success after deleting the secure copy while a plaintext copy remains on disk. Restart then migrates that old credential back. The preferences cache also removes its entry before a failed persistence operation, making the current `containsKey` retry check insufficient. Handle false returns, exceptions, unavailable preferences and fresh persisted reads honestly. A durable clear must not claim success when either storage location could not be cleared. Preserve the original legacy value until secure persistence is verified. Test native preference removal failure (not just secure-delete failure), retry and a fresh store/reload for both session and PKCE. Reuse the existing preferences testing seam where practical; no extra production abstraction just for a mock.

2. Audit overlapping migration/write/clear operations and delayed auth responses. A migration or refresh started before logout must not write a session after the clear and resurrect sign-in. A delayed old-account response must not overwrite a newer account. Reproduce the real lifecycle with controlled futures and put the smallest ordering/generation guard at the shared owner, preserving failed-server-deletion retry and offline behavior. Do not scatter guards across UI callers.

3. Cold PKCE restore clears the verifier for retryable network/server errors. Preserve pending invitation and retryable state. Do not claim a consumed single-use authorization code can always be retried after token-exchange success followed by a storage failure; define an honest recover/restart-sign-in path. Keep provider/storage errors free of secrets.

4. `ranked_flag_test.dart`'s preview regression calls ready before completing practice and checks rep calls immediately after an asynchronous stream emit. Strengthen it to assert ready eligibility, assert live/tracking state, and await event delivery. Prove the same permissive harness would send a ready/rep without preview, then verify preview prevents them. Keep the effective ranked AND camera guard and confirmed result-sharing fallback.

5. Check device secure-storage tests don't wipe real app credentials or require real credentials. Use an isolated test namespace/application context and synthetic values; report emulator coverage separately from physical hardware. Preserve existing camera/media gates.

Run focused tests and analyzer, report exact commands/exits plus changed files and unresolved concerns. Do not broaden to unrelated app redesign or stop at a test-only workaround.

## Next batch (coordinator will dispatch after review)

Native push/account switching and disabled-feature behavior; release flag defaults and downloaded-tool integrity; additional independently confirmed spec findings. No external resource setup can be substituted for the owner's missing target/device/signing information.
