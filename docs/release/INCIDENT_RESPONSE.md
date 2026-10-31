# Training Arena incident response notes

Owner: task `11`. Companion to `ROLLBACK.md` and `PILOT_PLAN.md` §7. During the
invited-pair pilot, any stop condition or S1/S2 incident pauses the pilot.

## 1. Severity

| Level | Examples | Response |
| --- | --- | --- |
| S1 | credential/key exposure, camera frame or auth token leak, account takeover, wrong rating affecting many matches, Play policy action | immediate pause, owner paged, containment within the hour |
| S2 | core loop down (sign-in, links, battles, receipts), crash on most devices, server inconsistency | pause the pilot, fix or roll back before the next window |
| S3 | one device/one flow degraded, failed share, slow queue, expired-request edge | workaround + fix before pilot exit |
| S4 | cosmetic copy/layout, non-blocking analytics gap | backlog with an owner |

## 2. First 30 minutes

1. **Pause**: stop distributing, stop queue windows, disable the feature flag or
   artifact involved.
2. **Contain**: rotate/blank the relevant secret; if data is at risk, revoke
   sessions or unblock the affected action server-side.
3. **Capture**: keep the failing build SHA-256, redacted logs, screenshots and
   the exact reproduction steps. Never copy tokens, emails or frames into the
   incident log.
4. **Communicate**: post status (impact, scope, next update time) in the pilot
   channel; do not speculate about causes.
5. **Decide**: rollback (`ROLLBACK.md`) or forward fix; one owner decides and
   records it.

## 3. Contact roles

Filled by the owner at pilot start; no invented names.

| Role | Responsibility | Contact |
| --- | --- | --- |
| Pilot owner | go/no-go, pause/resume, owner decisions | _______ |
| Release/support | builds, distribution, tester comms | _______ |
| Backend on-call | Supabase, dispatcher, data consistency | _______ |
| Security/privacy | S1 handling and notifications | _______ |

## 4. Playbooks

### 4.1 Leaked secret (S1)

- Identify the secret and the exposure surface (repository, artifact, log,
  screenshot, chat).
- Remove from the source; assume it is compromised even if deleted later.
- Rotate per `ROLLBACK.md` §5; redeploy; verify old value is rejected.
- If a service-role key or signing key is involved, treat all arena data and
  builds as suspect and page the owner immediately.

### 4.2 Auth outage or redirect regression (S2)

- Check Supabase Auth status, redirect allowlist and SMTP.
- A redirect mismatch fails closed in the app; confirm
  `ARENA_AUTH_REDIRECT_URL` equals a hosted allowlisted URL.
- Roll back the auth-related configuration change; never disable the session
  check to "make it work".

### 4.3 Match/receipt inconsistency (S1/S2)

- Freeze ranked queue (`queue_leave` consumers, owner-approved action).
- Pull the affected matches, receipts and rating history via the owner's
  read-only queries; do not edit immutable rows by hand.
- Forward-fix by correcting the RPC/migration and replaying conservatively;
  report affected players only after the owner approves the wording.

### 4.4 Notification abuse (S2)

- The pilot ships with `ARENA_FEATURE_PUSH_NOTIFICATIONS=false` (R4): no real
  push is enabled in this tree and no `google-services.json` exists. If a
  notification appears, treat it as a configuration breach: blank
  `ARENA_DISPATCHER_SECRET`, blank `FCM_SERVICE_ACCOUNT_JSON`, delete the
  worker schedule, and audit function logs. Native delivery hardening (review
  Batch C / R17) is an open pre-push gate, which is why any Firebase
  configuration in this pilot is itself the breach.
- Duplicate taps must be harmless; a second action from one tap is an S2.

### 4.5 Camera privacy report (S1)

- Preserve the device, build and reproduction; do not inspect or copy camera
  content.
- Verify no frame/landmark artifact exists on disk or in traffic
  (`docs/camera/CAMERA_QA.md` §4.2 step 7).
- If any artifact is found, pause the camera flag, page the owner and follow
  the privacy notification process.

### 4.6 Tester data request or deletion

- Sign-out is local-first; account deletion is the in-app
  **Settings → Delete account** path (`delete_account` revokes links, cancels
  queue seats, closes matches, removes avatars, deletes the auth user).
- If a tester reports a partial deletion, do not re-run destructive SQL by
  hand; capture the user id (never the email in shared logs) and escalate to
  the backend on-call.

### 4.7 Placeholder host reached testers (S2)

- If a pilot build was made with `example.invalid` (or without a verified
  `assetlinks.json`), pause the pilot, pull the artifact from the channel and
  re-verify `node tools/release/check_app_links.mjs --release --host <host>`.
- `example.invalid` must never be announced as a verified link; shipping it is
  a release-process failure even when no data is lost.

## 5. Evidence rules

- Redact tokens, emails and any camera content from every artifact.
- Keep incident records under `qa/pilot/incidents/` (created during the pilot)
  with severity, timeline, impact, action, owner and follow-ups.
- Logs used for a fix are deleted after the post-incident review unless the
  owner asks to keep redacted excerpts.

## 6. Post-incident review

Within 48 hours of closure: root cause, what detected it, what contained it,
what made it worse, and concrete follow-ups with owners and dates. Update this
file or the relevant checklist when a lesson changes the process.
