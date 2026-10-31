# Task 11 — prepare the secure release configuration and invited-pair pilot

You own release readiness for Training Arena. Work only in `D:\TrainingArena`, after task `10` has a QA report. Do not publish to Play, deploy backend infrastructure, send real notifications or rotate credentials without explicit owner authorization. Never touch `D:\Kiro`.

## Release identity and configuration

Verify the final app label **Training Arena**, application ID `app.trainingarena.mobile`, signing/keystore separation, versioning, privacy text, camera/notification disclosures and minimum Android API 24 support. Confirm custom scheme `trainingarena` and verified HTTPS App Links for the owner’s real domain; `example.invalid` must block release rather than silently ship as a verified link. Confirm Play Install Referrer, auth redirect allowlists, email/Google provider settings, FCM worker secret separation and Supabase RLS/service-role boundaries.

All secrets come from the release environment or CI secret store. Scan the repository and build artifacts for tokens, service keys, private URLs and debug Firebase files. Ensure camera frames, raw landmarks and auth tokens are absent from logs, analytics and share exports.

## Pilot plan

Prepare a small invited-pair pilot with coordinated play windows so the ranked queue has real people. Include a support/recovery script for link install, sign-in, permission denial, offline challenger, expired request, failed share and no-result. Define stop conditions for counter accuracy, crash rate, auth/link recovery, server consistency and notification abuse. Preserve an in-app request path when push permission is denied.

## Deliverables

- `docs/release/RELEASE_CHECKLIST.md`, `PILOT_PLAN.md`, `CONFIGURATION.md` and rollback/incident notes.
- CI checks for analyzer, tests, secret scan, App Link manifest and release artifact identity.
- A signed QA artifact only when signing is already configured; otherwise document the exact owner action without inventing credentials.
- Go/no-go recommendation that cites `qa/REPORT.md`, unresolved risks and the owner decision required for any deployment.

Acceptance means the artifact is safe to hand to invited testers, link recovery and identity are configured for the real domain, no secret is committed, and every remaining risk has an owner and explicit release decision. Publishing or production deployment remains a separate owner-approved action.

