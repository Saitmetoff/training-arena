# Training Arena launch assessment — 20 September 2026

Status: NOT READY FOR DISTRIBUTION. Planning assessment, not release approval.
Repository: D:/TrainingArena, branch codex/training-arena, HEAD bfaa6bd.
The older D:/Kiro FitBattle project is a separate product; do not resume its phase plan here.

## Decision

Finish the existing invitation-to-battle product. Do not rebuild it or add training plans, AI coaching, chat, followers, subscriptions, or extra exercises.

Recommended first public scope: Android, friend invitations, reviewed push-up/squat instruction, physically validated camera counting, a real hosted backend, reliable sign-in, verified HTTPS links/install recovery, confirmed results and sharing, privacy and account deletion. Pilot may use email OTP and no push. Google sign-in and native push should be completed during closed testing for the intended fuller release. Ranked remains off until its gate works and real two-device evidence passes.

Camera counting cannot be deferred while claiming to launch the battle product. There is no manual score path. Disabling counting produces a recovery/demo test, not the intended MVP.

## What is supported by evidence

The task summaries are snapshots of concurrently changing work, not independent proof that all tasks are currently complete. Do not add their overlapping test counts.

- docs/CONTRACT.md establishes the focused, invite-first product and server receipts.
- qa/REPORT.md records the latest integrated baseline: analyzer clean, 416 Flutter tests, 48 edge tests, 184 pgTAP assertions and 16 HTTP smoke checks on 18 September. These were inspected, not rerun in this planning task.
- The primary emulator flow used API calls for ready because there was no human in the camera. It is not proof of the physical practice-to-live path.
- Source inspection confirms camera selection, preview separation, server receipt handling and the result-share factory integration.
- Source inspection confirms rankedMatchmakingEnabled has no runtime consumers. Battle tab starts ranked search regardless of that flag.
- Result sharing DOES have a factory gate in arena_app.dart:136. R11 should be split: ranked is a confirmed gap; sharing needs an entry-path audit, not a claim that no gate exists.
- Native push is missing. PlatformPushTransport declares channels; MainActivity registers camera, avatar and referrer only. Enabling the push flag cannot implement the missing Android host.
- The release workflow builds an APK, not an AAB. No signed release candidate was established.
- Actual Git status still contains extensive modified/untracked implementation. The baseline commit is not the current app.
- No Android device was attached during this audit. C: now has about 18.4 GiB free and D: about 108 GiB; earlier sub-0.5 GB disk reports are historical.
- The inspected Google Play browser tab was at developer-account type selection. This does not prove that the owner has no other account.
- No code was changed, account created, backend deployed, artifact uploaded or social content posted in this task.

## Engineering assessment

Keep the present architecture. Pure-Dart state machines, small platform bridges, server-owned receipts and transaction/idempotency tests are useful foundations. Rewriting them would consume time without resolving the actual release risks.

The critical uncertainty is camera performance across real bodies, lighting and devices. A shared accurate scoring experience is the product. Run the documented physical protocol early, before paying for acquisition. The documented minimum three-device baseline is 3 testers x 5 rounds x 2 exercises x 3 devices = 90 twenty-rep rounds (1,800 observed reps), plus failure cases and any additional Tensor checkpoint. Schedule people sensibly; do not compress physical exercise into an unsafe marathon. The checklist's existing accuracy/lifecycle/privacy thresholds remain binding; do not loosen them to meet a date.

Server authority proves who owns a receipt, not that a modified client really performed the reported reps. Current rate, sequence and time checks are valuable but do not justify “cheat-proof” claims. Launch without cash prizes and validate ranked abuse scenarios before promoting competitive rankings. Do not add a speculative anti-cheat framework now.

The 1 Hz match heartbeat also has a measurable operating cost. Two active players produce approximately 120 heartbeat calls during one 60-second round, before countdown, reps, recovery and inbox traffic. At 100 simultaneously active players, heartbeat traffic alone is about 100 calls/second. This is arithmetic from the configured interval, not a benchmark. Load-test a small pilot profile and measure requests, latency, errors and cost per completed match before a viral traffic promise.

## Remaining gates and owners

| Work | Evidence / risk | Owner | Exit |
| --- | --- | --- | --- |
| Reconcile and freeze | R8; dirty implementation, stale baseline status | OpenCode + coordinator | Reviewed scoped commit; untracked source included; unrelated work preserved; reproducible checks |
| Current Android release | API 34 toolchain baseline; APK-only CI | OpenCode | API 36+ candidate, tested compatible toolchain, signed AAB and release-equivalent device install |
| Native compatibility | Flutter/ML Kit native libraries; 16 KB unverified | OpenCode + device QA | ELF/ZIP checks and representative 16 KB runtime evidence |
| Camera and media | R1/R7/R13 | Device testers + qualified form reviewer; OpenCode fixes | Signed camera checklist and asset review; no fabricated approval |
| Hosting and identity | R2/R3/R9, D1/D3 | Owner supplies accounts/domain; OpenCode configures | Hosted RPC/edge/auth paths, SMTP delivery, verified links, secure signing custody |
| Ranked/feature scope | R11 | OpenCode | UI and shared action guards, fixture isolation, disabled-state tests |
| Session security | R10 | OpenCode + coordinator | Android Keystore-backed credential storage/backup audit and tested migration, or explicit bounded pilot risk decision |
| Push | R4; native implementation absent | OpenCode + owner Firebase project | Real foreground/background/cold-start and token-rotation evidence |
| Ranked and recovery | R6 | Two-device QA | Real pairing, both ratings exactly once, blocked players, timeouts and reconnects |
| Store/public policies | Additional launch work | Owner + coordinator + OpenCode | Public privacy/deletion/support paths; factual Data Safety/Health forms; listing and review access |
| Hosted operations | Not proven by local stack | OpenCode + release owner | Maintenance/outbox trigger, monitoring, rate limits, recovery and small load test |
| Play account/testing | Account status unconfirmed | Owner | Verified identity/package, eligible testing track and required tester period |

Current Google requirements checked 20 September 2026:

- New mobile submissions require target API 36 from 31 August 2026. The current API 34 evidence is insufficient. [Google target API requirements](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en)
- New apps publish as Android App Bundles. Distinguish upload-key signing from the Play app-signing certificate used by installed apps, assetlinks and OAuth. [AAB requirement](https://support.google.com/googleplay/android-developer/answer/9844279?hl=en), [Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756?hl=en)
- Validate 16 KB compatibility of every packaged native dependency; updating a Gradle number alone is not evidence. [Android guidance](https://developer.android.com/guide/practices/page-sizes)
- Personal developer accounts created after 13 November 2023 generally need at least 12 testers continuously opted into a closed test for 14 days before applying for production access. Internal testing does not satisfy this requirement. Recruit 16–24 engaged testers to reduce dropout risk; do not buy empty opt-ins. [Google testing requirements](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en)
- Verify identity and package-name registration in the actual Console; the current guidance names 30 September 2026 for package registration. [Package registration](https://support.google.com/googleplay/android-developer/answer/16984799?hl=en)
- Account creation requires an in-app deletion path and an external web deletion-request resource meeting policy. A Settings paragraph alone is not the store packet. [Deletion requirements](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en)
- Complete the Health apps declaration, including for closed testing; “Activity and Fitness” appears applicable to this exercise-counting product. Confirm the final declaration against actual behavior. [Health declaration](https://support.google.com/googleplay/android-developer/answer/14738291)
- Budget separately for production-access review and app review. They are not guaranteed durations. First-launch publishing controls differ from later managed publishing; verify the actual release screen. [Publishing review guidance](https://support.google.com/googleplay/android-developer/answer/9859654?hl=en)

## Time estimate and calculation

These are planning ranges, not measured DeepSeek throughput or promised approval dates. Assumptions: one sequential OpenCode writer, coordinator review after each patch, roughly six focused engineering hours per working day, prompt owner decisions within one day, devices/testers available in week one, no detector rewrite. Human QA, account setup and content preparation can overlap coding.

| Work package | Focused engineering/support hours |
| --- | ---: |
| Freeze and reproduce baseline | 4–8 |
| Android toolchain, API 36, AAB, native compatibility | 8–16 |
| Feature gates and session hardening | 6–12 |
| Hosted backend, links, email auth and operations | 8–16 |
| Camera/media validation support and bounded fixes | 10–20 |
| Store, privacy/deletion and release packaging | 8–14 |
| Two-device integration and final regression | 8–14 |
| Base total | 52–100 |
| Google/native push and broader ranked release completion | +14–32 |

52–100 hours / 6 hours per day = about 9–17 working days for the scoped candidate. This excludes account-verification queues, reviewer availability, tester opt-in waiting and a substantial camera defect. Full feature completion is roughly 66–132 hours (11–22 working days), with useful work continuing during the closed-test period.

Calendar expectations from 20 September:

| Scenario | Planning window |
| --- | --- |
| Signed, usable invited-pair/closed-test candidate | Approximately 2–3.5 weeks, 4–14 October |
| Existing verified account without a new-personal-account test gate | Roughly 3–5 weeks to public release, 11–25 October |
| New personal account, successful camera QA, engaged testers | Plan 5–7 weeks to public release, 25 October–8 November |
| Best case with immediate owner setup and unusually smooth QA/reviews | Around 4 weeks; do not advertise this as a commitment |
| Camera/native compatibility or verification problems | 8–10+ weeks; recalculate after the first failed gate |

Critical-path calculation for a new personal account:
candidate available and account ready and 12 testers opted in -> 14 consecutive test days -> production-access review -> production submission/review -> public release.

Use the latest of account readiness, candidate availability and 12th tester opt-in as the test start. Some implementation and store preparation overlap those 14 days, but the waiting period does not start today merely because coding started. Google documents that production-access review usually takes seven days or less, sometimes longer; reserve additional time for app review. No deadline is guaranteed.

After every prompt, replace its estimate with actual elapsed active work and remaining blockers. Do not measure progress by files generated or test counts alone.

## Business and marketing recommendation

The initial promise is “Challenge a friend. Battle for 60 seconds.” The product is an interaction between two people, so acquire pairs, not isolated downloads.

Choose one initial country/language and an adult audience the owner can reach. Recruit friends, university fitness groups and small gym communities for coordinated sessions, with their consent. No messages were sent. Start with the existing pilot's 8–12 pairs; use two scheduled play windows. Do not promise immediate random opponents at all hours.

Primary metric: unique players completing their first server-confirmed battle with another human. Track invitation open -> install/first open -> sign-in -> practice complete -> both ready -> confirmed result -> a later battle, plus D1/D7 return and count-related complaints. Use existing allowlisted events and server receipts; add only missing, consent-appropriate data. A share sheet opening is not a referral. Aggregate by campaign; do not place emails, camera data or auth tokens in attribution.

Illustrative funnel, not a forecast:
10,000 video views x 1% profile/link visits x 25% installs x 50% first-battle completion = about 12–13 activated players.
A plausible-looking view count can therefore produce very few battles. Record each rate rather than assuming virality.
Illustrative referral coefficient:
40% of activated users invite x 2 genuinely new recipients x 30% recipient activation = 0.24 new activated users per activated user. That does not sustain itself without continued acquisition.

Suggested initial product decisions (hypotheses, not industry benchmarks):
- Fix onboarding/counting before paid acquisition if fewer than 70% of 20 recruited pairs complete a first battle with no operator rescue.
- After one week, interview both returning and non-returning pairs. If fewer than about 30% voluntarily battle again, learn why before buying reach.
- Never trade away the existing camera accuracy/privacy/lifecycle gates to meet those growth targets.
- Track support minutes and infrastructure spend per completed match. No subscriptions, paywall or ads in the first validation release; willingness to return comes before willingness to pay.
- Set a capped experiment budget after the owner names geography and budget. Do not invent hosting, creator or customer-acquisition prices.

## TikTok and Instagram execution

Account creation is requested but incomplete. Owner still needs to supply the account email, final handle and language/market. The current personal Instagram account must not be repurposed.

Proposed brand: Training Arena. Handle candidates in order: @trainingarena, @playtrainingarena, @trainingarena.app; availability is NOT verified.
Proposed bio: “Challenge a friend. 60-second push-up & squat battles. Android beta.” Replace “Android beta” with a launch CTA only when a usable test/production destination exists.
Use the existing arena mark provisionally after owner art acceptance. Store recovery credentials and MFA under owner control, never in Git or chat.

Observed browser state:
- TikTok signup loaded, but the email/phone link did not advance during inspection.
- Instagram signup redirected to the signed-in personal account; its switch-account flow offered existing-account login.
- No username was reserved and no registration submitted.
Account credentials/OTP and any required date of birth must come from the owner; never invent them. At the final terms-acceptance step, the browser tool's confirmation policy requires action-time confirmation. Password creation is a user handoff.

Content strategy: show real people and real app recordings whenever possible. Synthetic adults can act in a clearly labeled dramatization, but are not user testimonials. Use the actual product UI in the edit rather than generated fake scores or screens. Never imply real wins, endorsement, camera accuracy or fitness transformation that did not happen.
TikTok requires labels for realistic AI-generated content; Meta also applies AI transparency labeling. [TikTok guidance](https://support.tiktok.com/en/using-tiktok/creating-videos/ai-generated-content), [Meta labeling](https://about.fb.com/news/2025/02/gen-ai-transparency-metas-ads-products/)

Initial 14-post experiment (one original vertical edit per day, adapted for both platforms; hypothesis to test, not an algorithm guarantee):

| Day | Hook / concept | Evidence and CTA |
| --- | --- | --- |
| 1 | “Which friend would accept a 60-second challenge?” | Real invitation flow; join beta with a friend |
| 2 | “We finally settled the push-up argument.” | Consenting pair, actual result; challenge your friend |
| 3 | “Your phone needs to see your whole body.” | Real framing demonstration; save setup guide |
| 4 | “The last five seconds changed the result.” | Genuine close match, no invented outcome |
| 5 | “Push-ups or squats?” | Show both reviewed movements; state available modes accurately |
| 6 | “One link. The same opponent.” | Real install/auth return capture after it passes QA |
| 7 | “We tied.” | Actual draw, fresh challenge CTA; no async replay implication |
| 8 | “What happens when tracking is lost?” | Honest pause/reframe demonstration |
| 9 | “Two friends, two rooms, one minute.” | Real synchronized battle footage |
| 10 | “Can a beginner challenge a friend?” | Voluntary paced demo, no body-shaming or medical claims |
| 11 | “The challenger lost.” | Actual result, fun reaction with permission |
| 12 | “Behind the count.” | On-device processing explanation supported by verified behavior |
| 13 | “Tonight’s beta battle window.” | Only publish after roster/time and live test access exist |
| 14 | Best-performing hook retest | Different opening on the same truthful story; compare activation |

Three reusable 15–25 second scripts:
1. Real UGC: 0–2s friend challenge; 2–5s real invite acceptance; 5–14s both exercising with actual UI; 14–19s real receipt/reaction; 19–23s “Send this to your training partner.”
2. Product demonstration: 0–3s phone setup problem; 3–10s framing and unscored practice; 10–17s real count; 17–22s verified feature and beta CTA.
3. AI dramatization: caption “AI-generated dramatization”; two fictional adults discuss a friendly 60-second challenge; cut to separately captured real app UI; no scripted claim of personal long-term use, real win or guaranteed accuracy.

Prepare drafts during engineering; publish acquisition CTAs only when testers can actually enter. Use the platform's real account/link capabilities after checking them; do not assume every new account can put a clickable website in its bio.

## Operating model and handoff

Coordinator: this Codex task prioritizes, estimates, reviews diffs/results and maintains gates. Coding executor: OpenCode CLI with the verified available model opencode-go/deepseek-v4.1-flash. One writer, one bounded task, no parallel shared-tree edits.

A read-only OpenCode 1.18.31 run with that model succeeded during this audit. It found the missing ranked flag, native push and AAB workflow. Its “camera-off pilot completes rounds” recommendation was rejected because it contradicts the camera-only contract and the emulator QA caveat. Its 6–10 week full-pilot estimate was an unsupported estimate, not adopted as fact.

Read prompts/LAUNCH_CLOSEOUT_2026-09-20.md next. Start L01, then L02. Start arranging devices, form review, account verification and real domain/project ownership immediately alongside coding. Re-estimate after L04 camera evidence.

Files shipped by this planning task: this assessment, the launch prompt pack, and a dated pointer in docs/PROJECT_STATUS.md. No application source edited. Historical QA remains historical. Owner answers pending: Play account status, devices/testers, social identity/market; domain/project and budget also need resolution before external setup.

Exact next action: run L01 through OpenCode using the requested model, preserve the dirty implementation, reproduce the baseline, and report a scoped freeze candidate. Do not run old tasks 00–11 again wholesale.

