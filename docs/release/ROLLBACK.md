# Training Arena rollback notes

Owner: task `11`. Use with `INCIDENT_RESPONSE.md` and the stop conditions in
`PILOT_PLAN.md` §7. Destructive rollback of a hosted project or a Play release
requires explicit owner authorization; task `11` never executes it.

## 1. Decision order

1. **Contain first**: stop invites/queue windows, disable the affected surface.
2. **Roll back the smallest thing**: feature flag or distribution artifact
   before server schema.
3. **Preserve evidence**: keep the failing build, logs (redacted) and the
   artifact SHA-256.
4. **Record** the trigger, action, time and owner in the pilot channel.

## 2. Client and feature-flag rollback (preferred)

Distribute the previous signed artifact or rebuild with stricter flags:

```powershell
$env:ORG_GRADLE_PROJECT_arenaLinkHost = "<real-host>"
flutter build apk --release `
  --dart-define=ARENA_LINK_HOST="<real-host>" `
  --dart-define=ARENA_PUBLIC_URL="https://<real-host>" `
  --dart-define=ARENA_SUPABASE_URL="<project-url>" `
  --dart-define=ARENA_SUPABASE_ANON_KEY="<anon-key>" `
  --dart-define=ARENA_AUTH_REDIRECT_URL="trainingarena://challenge/auth" `
  --dart-define=ARENA_FEATURE_CAMERA_COUNTING=false `
  --dart-define=ARENA_FEATURE_CHALLENGE_LINKS=false `
  --dart-define=ARENA_FEATURE_RANKED_MATCHMAKING=false `
  --dart-define=ARENA_FEATURE_RESULT_SHARING=false `
  --dart-define=ARENA_FEATURE_PUSH_NOTIFICATIONS=false `
  --dart-define=ARENA_FEATURE_PREVIEW_FIXTURES=false
```

Caveats (verified in code on 2026-09-18):

- `ARENA_FEATURE_CAMERA_COUNTING=false` disables camera sessions; there is no
  manual score path, so competitive battles cannot run in this mode.
- `ARENA_FEATURE_PUSH_NOTIFICATIONS=false` is the pilot default and is
  enforced in `notification_runtime.dart`; the in-app inbox remains
  authoritative either way. The native delivery path is **not yet** guarded by
  the same flag (review Batch C / R17), so a build that adds Firebase
  configuration is out of scope for the pilot until R17 closes.
- `ARENA_FEATURE_PREVIEW_FIXTURES=true` is a design-review mode that cannot
  produce receipts. Never use it as a rollback.
- `ARENA_FEATURE_CHALLENGE_LINKS` is enforced in the challenge entry route.
- `ARENA_FEATURE_RESULT_SHARING` is enforced at the composition-root factory
  `app/lib/arena_app.dart:136` (L01 entry-path audit in `qa/launch/L01.md`);
  when off, challenge sharing falls back to task-05's plain text share. It is
  safe to rely on this flag for the share card, but not as a general kill
  switch.
- `ARENA_FEATURE_RANKED_MATCHMAKING` is enforced since L03 (R11a closed): with
  it off — **or with camera counting off** — `BattleController.startRankedSearch`
  refuses to queue from every entry path and the Battle tab hides the ranked
  action. It is still a **build-time** scope control, not a remote kill switch:
  changing it requires a new build, and an installed build can only be stopped
  server-side (R15 proposal in
  `docs/decisions/07-matchmaking-incident-control-proposal.md`).

## 3. Server rollback

### 3.1 Local/staging (supported)

```sh
supabase db reset          # rebuild migrations + local seed fixtures
supabase functions serve arena --no-verify-jwt
```

### 3.2 Hosted project (owner-approved only)

- Before any real data exists, the drop order is the one in
  `supabase/README.md` (functions, then tables/types, then the trigger and
  bucket row).
- With real data, prefer forward fixes: deploy a corrected migration, revoke
  the dispatcher secret, disable queue/request actions by undeploying the
  function or tightening `ARENA_ALLOWED_ORIGINS`.
- Never run `db reset`, truncate or drop against a hosted project without the
  owner's written approval and a verified backup.

### 3.3 Dispatcher / notifications

- Rotate or blank `ARENA_DISPATCHER_SECRET` and redeploy the dispatcher to stop
  outbox leases immediately. Deleting the schedule stops recurring runs.
- The dispatcher's FCM send path is implemented (task `08`/L06,
  `supabase/functions/arena-dispatcher/lib/fcm.ts`) but inert without
  `FCM_SERVICE_ACCOUNT_JSON`; the pilot never sets it, so `delivery` reports
  `not_configured`. If a notification appears in the no-push pilot, treat it
  as a configuration breach (`INCIDENT_RESPONSE.md` §4.4) and blank both the
  dispatcher secret and the FCM secret before auditing.

## 4. Landing page and App Links rollback

- If the landing page misbehaves, serve a static maintenance page that keeps
  **Reopen this link after installing** and the readable code; do not remove
  `/.well-known/assetlinks.json` while installed builds depend on verified
  links.
- If `assetlinks.json` is wrong, fixing it is forward recovery; Android
  re-verifies on request (`adb shell pm verify-app-links --reverify
  app.trainingarena.mobile`). Do not tell testers to clear app data unless the
  support script says so.
- `example.invalid` must never be deployed or announced as verified.

## 5. Secret compromise rollback

| Secret | Immediate action | Follow-up |
| --- | --- | --- |
| `ARENA_DISPATCHER_SECRET` | rotate in function settings, redeploy dispatcher | audit dispatcher logs for unexpected callers |
| `SUPABASE_SERVICE_ROLE_KEY` | rotate in Supabase and redeploy functions; treat project as compromised | review auth/RLS audit; investigate every server-only access |
| FCM service account | delete/rotate the key in Google Cloud, redeploy with the new JSON | verify no device token was exposed |
| Supabase anon key | rotate; requires a new app build (compiled value) | coordinate with pilot testers |
| Signing keystore | cannot be rotated for an installed application ID; escalate to the owner and Play if applicable | revoke, re-plan distribution under owner decision |

A leaked secret is an S1 incident: follow `INCIDENT_RESPONSE.md` §4.

## 6. Verification after rollback

1. Previous artifact installs and signs in.
2. `Challenge a friend` end to end with two test devices.
3. `adb shell pm get-app-links app.trainingarena.mobile` reports the expected
   link state.
4. Server: one confirmed casual and one ranked receipt, no double rating.
5. `node tools/release/secret_scan.mjs --artifacts` and
   `node tools/release/check_artifact_identity.mjs --apk <rolled-back apk>`
   pass on the artifact being redistributed.
6. Announce the rollback, the artifact SHA-256 and the next review time.
