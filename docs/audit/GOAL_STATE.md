# Training Arena goal state

Historical WP0–WP4 snapshot below. For the current launch review and fresh
checks, use [21 October launch review](LAUNCH_REVIEW_2026-10-21.md). “DONE” in
this file describes the old bounded task, not release readiness.

Scope: WP0–WP4 in the owner's attached brief, performed in order. All camera simulations are SYNTHETIC. No real-device validation has been performed.

| WP | Status | Evidence |
| --- | --- | --- |
| WP0 Baseline | DONE | FIX_LOG.md: pinned Flutter 3.47.5, analyze exit 0, 626 tests passed / 2 skipped |
| WP1 Counter engine | BLOCKED | FIX_LOG.md: WP1 attempt 2; protected-test conflicts and noise seed 4 has 9 outcomes/10 descents. Engine edits stopped before third rewrite. Trace/HUD tests recorded; physical sessions NEEDS-OWNER. |
| WP2 Server hardening | BLOCKED | New arena_goal_hardening migration/pgTAP and avatar tests written. FIX_LOG.md: local reset/test cannot connect; Deno NOT RUN. Strict semver conflicts with legacy wire value; protected signature-only avatar fixtures conflict with dimension validation. |
| WP3 Release hygiene | DONE | FIX_LOG.md: 10 public-output/hold fixtures passed; live gate refuses 11 placeholder files; git ls-files tmp/pdfs empty. Legal drafts carry the notice. UGC change is saved as own patch because owner's draft is untracked. |
| WP4 Player UX | DONE | FIX_LOG.md: 5 targeted copy/placement/feedback tests passed. Platform sound/haptic calls verified on SYNTHETIC stream; physical audibility NEEDS-OWNER. |

## Assumptions
- Use the current branch and preserve the initial dirty/untracked tree. Commit only this run's changes, one commit per WP.
- No hosted configuration or physical-device evidence is supplied. Do not provision or fabricate it.
- Follow the closed WP list and bounded fix attempts in the brief.

## NEEDS-OWNER
- Physical-device traces: follow qa/camera/TRACE_RUNBOOK.md after WP1.
- Hosted Supabase, domain, keystore and Firebase: configure the owner-controlled services and release credentials using the existing release configuration/runbooks.
- Custom SMTP and captcha keys: provision and configure owner credentials in Supabase.
- Git remote: create a private git remote; the repo has none, so the CI workflow can never run. After creation, run `rtk git remote add origin <owner-private-remote>` and `rtk git push -u origin codex/training-arena`. Do not put credentials in the URL.
- Crash reporting: choose the service and supply its configuration.
- Localization and target markets: choose markets and languages; the current app is English-only.
- Second brand Fault versus applicationId: decide the identity; no applicationId change in this run.
- Lawyer review: have a qualified lawyer review all legal/privacy drafts before publication.
- Depth policy: owner to approve whether candidate 105/145 degree bands represent a full rep.

## FOLLOW-UPS
- Existing UGC strategy still contains unverified model/quota and biomechanics claims outside the permitted guardrail edits; review those separately before using that plan.

## Final verification (run once; stopped)
- Pinned flutter analyze: exit 0, no issues.
- Full flutter test: exit 1, 637 passed / 2 skipped / 3 WP1 failures.
- Existing release hold: exit 0.
- Local Supabase reset/test: NOT RUN in final pass, unavailable Docker/PostgreSQL confirmed; initial WP2 failure outputs retained.
- Deno tests: NOT RUN, executable absent.
- BEFORE/AFTER table and all actual outputs: FIX_LOG.md.
- One commit per WP: 74d28fd (WP0), 5700dbc (WP1), 3d18b88 (WP2), 5c77700 (WP3), ec270d5 (WP4).
- Required owner steps: NEEDS_OWNER_ACTIONS.md. No real-device validation has been performed.
