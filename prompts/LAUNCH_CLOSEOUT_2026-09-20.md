# Training Arena launch closeout prompts — 20 September 2026

Use these for remaining work only; do not replay tasks 00–11. This pack is a proposed execution sequence, not evidence that a launch scope or external deployment has already been approved.
Read docs/release/LAUNCH_PLAN_2026-09-20.md for assumptions, sources and timing.

## Coordinator/executor contract

Codex coordinates and reviews. OpenCode writes application code using opencode-go/deepseek-v4.1-flash, confirmed available and successfully invoked on 20 September. Keep one writer. No subagents or concurrent shared-tree edits.

From D:/TrainingArena, launch the installed OpenCode CLI with:
opencode --model opencode-go/deepseek-v4.1-flash
Paste the common preamble and exactly one task below. For automation, use the locally verified opencode run --help interface; do not pass a task path as though that automatically executes its contents. Confirm the exact model in the run banner. Do not silently substitute another model on an auth/rate-limit failure.

RTK is installed but was not on this task's PATH. Its discovered executable is:
C:/Users/ADMIN/AppData/Local/Microsoft/WinGet/Packages/rtk-ai.rtk_Microsoft.Winget.Source_8wekyb3d8bbwe/rtk.exe
Use RTK per the owner's global instructions; do not install a second copy.

Each implementation submission must include:
- Exact repository, branch, starting/ending commit and actual model.
- What changed and the relevant diff; no completion-by-summary alone.
- Actual commands, exit status, evidence path and skipped checks.
- Each acceptance criterion: PASS, FAIL or BLOCKED.
- Remaining dependencies, human decisions, measured active time and revised estimate.
- Scoped commit only after secret scan and relevant verification; never blanket-stage generated artifacts or unrelated edits.

Coordinator reviews the changed flow and all callers, independently verifies decisive evidence and rejects invented device tests, signature checks, deployments or approvals. Store external credentials only through the proper secret UI/environment.

## Common preamble — include with every task

You are the sole coding executor for Training Arena in D:/TrainingArena. Model: opencode-go/deepseek-v4.1-flash. Do not change D:/Kiro or upgrade its shared toolchain. Read docs/CONTRACT.md, the latest entry in docs/PROJECT_STATUS.md, docs/release/LAUNCH_PLAN_2026-09-20.md and only the evidence relevant to this task. Preserve all unrelated dirty/untracked files. Trace all callers before a fix. Reuse the existing design, API and test tools. No product expansion, speculative framework, generated fake evidence or weakened release gates. Make a short plan, implement the smallest complete fix, verify, and update the project status with exact remaining work.

Existing user authorization persists. For external actions, use the specifically authorized environment, account and scope; do not invent a target or spend. If something essential is missing, finish independent local work and report the exact missing input. Do not request a blanket approval before producing a concrete reviewable result.

## L01 — Reconcile, reproduce and freeze the actual app

Dependencies: none. Estimated active work: 4–8 hours.

Audit the current Training Arena working tree, including every untracked implementation directory from tasks 01–11. Capture status, HEAD, branch and scope before changes. The old baseline is bfaa6bd, not a complete implementation. Do not create a fresh checkout that silently loses the uncommitted app.

Reconcile docs/PROJECT_STATUS.md, qa/REPORT.md and docs/release/GO_NO_GO.md with actual files. Close stale compile-blocker claims only if current checks prove them. Keep historical test results dated. Specifically split R11: ranked flag is unused, while result sharing already has a factory guard requiring a complete entry-path audit.

Run the existing analyzer/full Flutter suite, backend Deno/pgTAP/HTTP smoke and web/prototype checks in the correct repository with isolated tool caches. If Docker/device/runtime is missing, report the exact blocked check instead of starting the wrong project's services. Do not refactor working features.

Review intended source/config/assets/docs, run the existing secret scanner, exclude caches/raw QA captures/credentials, and create one scoped integration baseline commit when all included work is understood. If unrelated or unknown changes cannot be safely classified, preserve them and report a proposed explicit path list instead of guessing. Record the freeze hash and how later work will preserve the implementation.

Acceptance: reproducible baseline or precise failing command; intended source safely captured; no user work lost; fresh evidence separated from the historical 416-test count. Return the standard handoff and stop.

## L02 — Bring the Android artifact to current Play requirements

Depends on L01. Estimated active work: 8–16 hours.

Own Android/Flutter toolchain configuration and .github/workflows/release-checks.yml plus tools/release artifact checks. Read current official Google API/AAB/native compatibility guidance; on 20 September the target requirement was API 36. Use a compatible supported Flutter/AGP/Gradle/Kotlin/NDK combination with the smallest necessary changes; pin it and record why. Install or use an independent SDK outside D:/Kiro rather than upgrading that project's SDK.

Produce a release AAB path in CI and locally; keep release-equivalent APKs for device smoke. Extend existing checks rather than adding a new release framework. Keep fail-closed signing and placeholder-host refusal. Distinguish upload-key certificate, local APK certificate and Play app-signing certificate. Include the correct Play certificate(s) in the App Links/OAuth setup instructions.

Inspect final merged manifests, package/version/min/target SDK, arm64 support, all packaged native ELF/ZIP alignment, and 16 KB runtime behavior. A configured SDK version or successful debug APK is not acceptance. Report delivery-size estimates from bundle tooling; do not present the old 307 MB debug APK as the user's download size.

Run analyzer/tests and Android build checks appropriate to the migration; test API 36 UI/permissions/edge-to-edge and the declared older-device support. If signing is missing, complete pipeline changes and unsigned compatibility checks and name signing as the only artifact blocker; never call a debug-signed output release-ready.

Acceptance: current Play-compatible build path, pinned reproducible tools, documented native checks and an AAB inspection record when signing is available. Stop before uploading.

## L03 — Enforce release scope and protect sessions

Depends on L01; run after L02 to avoid overlapping app edits. Estimate: 6–12 hours.

Trace every ranked-entry path and BattleController.startRankedSearch caller. Wire ARENA_FEATURE_RANKED_MATCHMAKING through the composition root into shared action enforcement and honest UI. Disabled ranked must not queue or claim camera-counted availability. Audit existing camera, challenge, sharing, push and preview gates; preserve valid sharing fallback behavior instead of rewriting it.

Build-time flags are not remote kill switches. Audit whether the existing backend has an operational way to refuse new matches/queue entry during an incident; reuse it if present. If absent, propose the smallest scoped server enforcement needed for the selected launch, with tests and a compatibility plan. Do not pretend changing a Dart define disables already-installed builds.

Audit auth_store.dart, backup/data-extraction rules and token logging. Use existing secure platform support or a justified focused dependency for Android Keystore-backed session storage. Preserve pending challenge and PKCE continuity. Migrate existing local sessions safely, remove the old plaintext only after successful secure persistence, and fail predictably on storage failure. No home-grown cryptography.

Add minimal regression checks at the shared boundaries: disabled flag cannot be bypassed by alternate entry/controller calls; preview cannot emit competitive reports; secure-storage failure/migration/logout/delete behavior is correct. Keep deletion failure from discarding the user's valid session.

Acceptance: actual scoped behavior matches the flags; current result-sharing guard is preserved; credential and backup behavior documented and verified; no unsupported kill-switch claims.

## L04 — Resolve camera and instructional-media evidence

Depends on L02 for current runtime compatibility. Begin device/reviewer scheduling immediately. Estimate: 10–20 support/fix hours, plus real-human availability.

Read docs/camera/CAMERA_QA.md, qa/camera/device_validation_checklist.md and docs/media/FORM_REVIEW.md fully. Inspect the device inventory. Prepare one concrete validation packet listing device slots, build hash, scenario, human count, device count and pass threshold. Reuse existing tests and capture tools.

Run the prescribed physical-device protocol with actual testers and a human observer. Do not use emulator fixtures, API-ready bypasses, synthetic poses or generated videos as physical accuracy evidence. Do not simulate reviewer signatures. Cover both movements, low-end/mid/flagship devices, applicable Tensor checkpoint, lighting/framing/tracking loss, permissions, rotation, app background/return, heat and camera release. Respect exercise fatigue and tester consent.

Route each reproduced counter defect to the shared camera state machine or native adapter responsible; add the smallest regression reproducer and rerun affected physical cases. No threshold weakening to meet a date. Have a qualified person review the media and record asset hashes, observations and actual sign-off. If assets are rejected, fix or exclude them with a reviewed instructional alternative; do not silently ship unreviewed fallback posters.

Acceptance: the existing signed camera and media gates pass. If no devices/reviewer are available, complete the packet and report BLOCKED with exact missing resources. A camera-off demo is not a completed battle release. Re-estimate launch immediately if native crashes or systematic counting errors appear.

## L05 — Connect hosted infrastructure, sign-in and real invitation links

Depends on L01/L02; can be the next coding task while L04 human sessions are being arranged. Estimate: 8–16 hours.

First identify the owner's actual domain, hosting destination, Supabase project, supported auth method, SMTP ownership and secret locations. Never copy local fixture data or development service JWTs to hosted services. Prepare exact config/migration/rollback changes before any external step. Use existing authorization for a named target; request only missing target/scope information when required.

Apply the existing migrations to the authorized test/pilot environment, deploy the arena functions, establish maintenance/outbox scheduling with worker-secret separation, and verify that a match can settle/expire if both clients disappear. Use the existing service boundary and deny-all RLS model; do not expose privileged RPCs or service credentials.

Host challenge-web with real config, verified assetlinks and correct Play app-signing fingerprints. Verify domain consistency across Gradle, Dart and web. Configure email OTP with real delivery and auth redirect allowlists. Prepare Google OAuth if its owner values are available; finish it in L06 if not.

Test a fresh user, unique username conflict, expired session, process death, cold/warm links, explicit acceptance, unavailable/expired challenge, and return to exactly the pending invitation. Use the Play-installed artifact for Play referrer proof later; a sideload cannot prove it. Record backups/recovery, logs without tokens, cost visibility and a small measured concurrent-pair load test.

Acceptance: real hosted/auth/link evidence, no placeholder runtime values, no production fixture data, and documented operational ownership.

## L06 — Finish native push, Google return and ranked release scope

Depends on L03/L05. Estimate: 14–32 hours for the fuller release, including ranked device validation. Optional for the first email/no-push pilot, not silently omitted from the intended full product.

Implement the missing Android host for the exact channels in platform_push_transport.dart using Firebase's current supported SDK and the existing dispatcher contract. Do not build another Dart notification service. Configure only the owner's Firebase app/project; credentials remain server-side. Verify permission ask-once behavior, foreground/background/terminated taps, exact request routing, expired/blocked/cancelled payloads, duplicate delivery, token refresh/unregister and logout/account switching.

Configure Google OAuth and the exact allowlisted redirect using the Play app-signing identity. Verify Google and email return to the same challenge after process death, including username-required accounts.

Run actual two-phone ranked pairing with concurrent entry, blocked players, cancellation/back/background, 15-second alternative, 60-second stop, reconnect, tie/win/no-result and idempotent receipt/rating updates. Review obvious score-event replay/injection/rate abuse against existing protections; do not advertise cheating prevention beyond the evidence.

Acceptance: real device evidence, not mocks alone. If a feature is deferred, keep it inaccessible and document the exact narrower release scope. No live notification sends to non-consenting users.

## L07 — Complete store, privacy and deletion surfaces

Depends on verified product/data behavior from L03/L05; may proceed while camera review continues. Estimate included in the 8–14 hour store/release package.

Create a traceable data inventory covering auth/email, usernames, avatars, match/rep events, telemetry and optional FCM tokens. Verify frames/landmarks remain local and do not infer “no data collected” from that. Record retention/deletion behavior including retained counterpart match records and service backups.

Using actual owner legal/contact details, prepare the public privacy/support pages and a functional external account-deletion request route, plus clear in-app links. Reuse the existing deletion backend where appropriate; externally initiated deletion must verify account ownership and preserve retry/error safety. A securely handled manual request channel may be sufficient if policy and actual operations support it; do not invent instant deletion. Never put secret-bearing deletion tokens in logs or analytics.

Prepare Play listing copy, real release screenshots, current feature graphic/icon assets, target audience/content rating/ads declarations, Data Safety and Health apps declaration. Explain why Activity and Fitness applies; do not invent medical approvals or accuracy/health claims. Audit reporting/blocking and the support process for usernames/avatars as applicable. Provide reviewer access that works despite OTP and synchronized two-person battle requirements.

Check current official policies. Any missing owner identity, retention decision or support address remains explicitly pending; no fabricated legal statements.

Acceptance: complete factual store packet and functional public endpoints after authorized hosting; copy matches the selected scope and current artifact; no fake reviews or testimonials.

## L08 — Produce and verify the actual release candidate

Depends on L01–L05 and L07; include L06 for full scope. Camera/media gate must pass before a battle-capable pilot.

Freeze the intended patch set and rerun the existing full acceptance checks on its commit. Verify backend compatibility, flags, real config, release assets, no preview fixture scoring, secret scans, AAB/derived APK identity, signature and hashes. Protect upload-key custody; use owner-provided signing material securely.

Install the release-equivalent build on the documented matrix. Run invitation -> install/auth -> practice rep -> both ready -> 60-second real camera round -> confirmed result -> history/share with two actual participants. No API-ready bypass for this gate. Exercise offline/background/process death, permission denial, unknown viewer, no-result, duplicate reps, deletion and accessibility/reflow. Record the actual cold-install/first-battle time without automation idle gaps.

Review hosted load/timeout/recovery and the existing rollback/incident plan. Produce a concrete GO/NO-GO table with each artifact stage separate: built, signed, verified, device-tested, uploaded, submitted, approved, live. Record selected countries, feature scope, support owner and stop conditions.

Acceptance: a usable, traceable battle candidate with all claimed release gates green. Stop only at an essential unmet gate, naming the action required; never call a signed artifact a published app.

## L09 — Create the social identities and prepare the first content experiment

Owner-assisted account work; can proceed alongside engineering without editing app source.

Use the account email, real required owner details, final brand/handle and language/country supplied by the owner. Proposed brand is Training Arena; handle availability must be checked in the platforms. Create new project accounts, preserving the existing personal Instagram account. Use the browser for registration; owner enters passwords/OTP and completes required authentication steps. Follow action-time terms/CAPTCHA confirmation requirements from the browser tool. Do not claim an account exists until its logged-in project profile is visible.

Apply the approved existing brand mark and truthful bio from docs/release/LAUNCH_PLAN_2026-09-20.md. Verify owner-controlled recovery and MFA without writing secrets into this repo. Link to a working beta or live destination appropriate for that platform's account capabilities.

Draft the 14-day content experiment in the launch plan. Deliver at least three complete vertical-video briefs/scripts: actual consenting-user battle, actual product setup demonstration, and clearly labeled fictional AI dramatization using real captured app UI. State necessary footage, permissions/music rights, captions, disclosure and CTA. Do not portray synthetic actors as customers or fabricate scores, testimonials, fitness results, social proof or model accuracy.

Prepare drafts now; only publish specific approved assets to the named project accounts when authorized. Track content -> qualified visits -> installs -> first confirmed human battle -> repeat play. A like, view or share sheet is not activation. Return profile URLs and draft artifact paths; mark missing account/footage input honestly.

## L10 — Run the closed test and manage the Play launch

Depends on L08, verified developer account and a real roster. Use the owner's authorized Play account and named track; otherwise prepare the exact release and resolve only the missing authorization.

Verify account type, identity, package registration and actual Console requirements. Choose the proper internal/closed/production track. For a qualifying new personal account, recruit 16–24 real testers, keep at least 12 continuously opted into closed testing for 14 days, and record useful engagement/feedback. The clock begins at the qualifying opt-in cohort, not at account creation or the first internal upload.

Upload the verified AAB to the authorized test track, then install through Play and verify real signing identity, HTTPS App Links, Google redirect and Install Referrer on a fresh install. Record version/track/hash and actual visible Console outcome. Keep internal testing and production-access eligibility distinct.

During testing, fix genuine blockers via the same single OpenCode writer and reviewed patches. Re-run affected gates and preserve continuing tester engagement. Maintain a concise feedback/changes ledger for the production-access application. Prepare all app-content forms and reviewer access.

After eligibility and production access are actually granted, prepare the exact countries, listing, version and rollout action. Use existing specific publishing authorization; if absent, present the complete candidate for that final decision. First production release may be offered to all users in selected countries; do not assume an update-style percentage rollout or managed publishing is available. Monitor actual crashes, camera complaints, failed joins and server receipts through the established operations tools. Do not create a new monitoring automation unless requested.

Acceptance: separate evidence for test distribution, elapsed eligibility, production-access approval, submission, approval and actual public availability. Google delays are reported, not converted into “done.” If not yet live, state the exact remaining dependency and updated date range.

