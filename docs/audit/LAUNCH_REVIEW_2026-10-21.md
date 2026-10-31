# TrainingArena / Fault launch review — 21 October 2026

> HISTORICAL — superseded on 22–23 October 2026 by
> [the current owner acceptance plan](../release/OWNER_ACCEPTANCE_2026-10-22.md).
> The current authorized scope requires camera counting AND real friend battles,
> both email-code and Google sign-in, and reuse/resumption of fit_ap. The solo-first
> recommendation and authorization limits below describe the earlier checkpoint;
> they do not override those later owner decisions.

**Recommendation:** finish and test the existing free Android solo beta, reuse
the existing Fault website, and learn from a small cohort before expanding.
Camera battles remain the product direction; they cannot be advertised as
available until counted rounds and recovery work on physical devices and the
hosted service. A bigger website, 30,000 emails and a subscription checkout are
not technical prerequisites for a small beta. This recommendation changes no
previously approved release gate and authorizes no publication or billing.

This was the launch checkpoint on 21 October; it is retained as historical evidence. The older `GOAL_STATE.md`,
`COMPLETION_AUDIT.md` and release packets remain historical evidence, not current
green status. Fresh test results are recorded below; blocked means blocked.

## Evidence and preservation

The first inspection compared both checkouts read-only:

| Checkout | Observed state before changes |
| --- | --- |
| Saved `D:\TrainingArena` | `codex/training-arena`, `ec270d5`; five modified tracked files, including final WP audit logs; untracked Fault website, its documentation/assets, three Fault migrations and other owner work |
| Isolated review checkout | detached `02c2f2b`, the old September source snapshot; current `app/` and `fault-web/` were absent |

The review branch `codex/launch-readiness-20261021` starts at the **observed
`ec270d5`**, not the stale snapshot. An explicit list preserved 155 source and
documentation files from the saved checkout: nonignored `fault-web/`,
`docs/fault-website/`, `docs/strategy/`, the three Fault migrations and the five
modified tracked files. Ten additional explicit website planning/marketing
documents and Python utility/test files were preserved; bytecode was excluded.
Preservation checkpoint: `348c690` (165 files).
Existing website code is salvaged owner work, not a
newly built site. No ignored environment, provider state, private document,
signing key, build directory or dependency directory was copied. The saved
checkout is not reset, cleaned or edited. Historical screenshots/logs not part
of this source selection remain in the saved checkout; their existence is not
fresh test or hosted evidence.

The coordinator reviewed all turns in the six other project chats and supplied
the following ledger; this review independently checked their code-related
claims against the current checkout:

| Source chat | Relevant decision or evidence |
| --- | --- |
| [Plan the fault.fit launch website](codex://threads/01a10315-406d-7960-8c01-3f246e851aa3) | Fault brand; $30,000 meant quality aspiration, not a spending budget; free waitlist and 30,000-email ambition, not approved paid preorders |
| [Execute Fault website Stage 1](codex://threads/01a105ce-0460-7311-9ee2-533d98a64538) | Existing Next website and protected preview, selected existing development project, free Vercel-domain direction; public delivery and provider/operator gates remained open |
| [Allow partial-frame rep counting](codex://threads/01a0d4cf-1228-7ef0-8a60-694886a7752a) | Physical/native-coordinate defects require true bridge regression and device evidence; owner cannot film or publish themselves |
| [Review Context7 and Supabase goal](codex://threads/01a12ff6-8ca3-7e42-9b12-b7c3ce0e9f46) | Protected tests must not be weakened/deleted; synthetic is not device evidence; bounded fixes; October checkpoint supersedes old 626-green result |
| [Complete Google Play identity check](codex://threads/01a0f74b-d1b9-76c3-b95e-e00ab3704f3d) | Last established state was restricted identity/address evidence and dependent phone verification; no later approval established |
| [Assess project and growth strategy](codex://threads/01a0f435-29d6-7291-b179-1e593162992d) | Earlier launch/growth planning; proposed targets are not observed customers or proof of readiness |

The current source-video conversation additionally establishes the exact raw
footage brief below. A bounded read-only account refresh additionally confirmed:

| Account evidence, 21 October | Observed result |
| --- | --- |
| Supabase `fit_ap` | Existing project, **INACTIVE**, PostgreSQL 17. Migration ledger lookup timed out; presence of the complaint-hold correction is unverified. No resume or database write attempted. |
| Vercel `fault-website` | Existing project confirmed. Latest-any and production deployment lookups returned **403**, missing grant to the owning team. No CLI fallback or new authentication was available. |
| Play | Current console status not refreshed; historical identity restriction remains the last established state, not a new rejection or proof of approval. |

A locally corrected migration or historical protected preview does not establish
a working public signup, current deployment health or a production deployment.

## Current product, architecture and real limits

| Area | Confirmed current implementation | Launch implication |
| --- | --- | --- |
| App | Flutter `app/`, native Android CameraX/ML Kit bridge, app ID `app.trainingarena.mobile`; English; pinned Flutter 3.47.5 | Keep the identity stable while reviewing Fault display/store branding; do not rename package IDs to match an unavailable domain |
| First session | Local signed-out solo, manual self-reported entry, explicit save/retry, seven-day history/PB compared by exercise and source (`app/lib/solo/`) | Small usable path already exists; device walkthrough/save/restart still needed |
| Counting | Candidate side/front counter with geometry, trace export and synthetic fixtures; `qa/camera/beta_device_results.json` blocked with no completed device matrix | Keep release counting off; numeric replay and sound method calls do not establish physical count accuracy or audibility |
| Battles | Real HTTP backend composition, invitation/rematch state machines and Supabase RPC/Edge functions | Hosted two-account sign-in, invite, ready, round result and rematch/recovery are not established by fixtures; camera-off builds cannot complete counted battles |
| Auth | Supabase auth, PKCE continuity, secure native storage and account/deletion surfaces | Requires real Auth settings, redirects, sender and device walkthrough before an account-based beta claim |
| Backend | `supabase/functions/arena`, dispatcher, schema/RLS/RPC migrations and pgTAP | October hardening is candidate work with version and avatar-fixture conflicts; local database and hosted rollout remain separate gates |
| Website | Existing Next 16 `fault-web/`; double opt-in, encrypted retry outbox, suppressions, unsubscribe/webhook recovery, opt-in event/RUM collection and protected review routes | Reuse and verify this funnel; missing configuration returns 503 instead of fake success. No second waitlist is needed |
| Media | Approved illustrative website fallback, not approved product footage; `fault-web/public/MEDIA.md` describes real capture acceptance | Illustrations can stay labelled; real product demonstrations need matching build/device/take and rights |
| Payments | No preorder/subscription checkout or entitlement integration; website FAQ says first beta planned free and later pricing undecided | Email updates are not a paid subscription. No agreed price, charge date, delivery date, refund or subscription terms exist |
| Release | Signing/identity/App Link/16 KB/size checks and fail-closed publication holds exist; Git has no remote | A historical local artifact is not this source's distributable build. CI cannot run remotely until a repository is configured/pushed |

## Safe corrections in this review

1. **Development launcher stops bypassing the backend.** Previously
   `tools/run-dev.ps1 -PrintOnly` printed all eight feature flags `true`.
   `BattleRuntime.fromConfig` returns fixtures before reading the HTTP backend
   when `PREVIEW_FIXTURES` is true. Default mode now launches local solo without
   credentials; `-Mode Backend` uses real ports and requires URL/public key,
   forwarding optional OAuth/domain values and the matching Android host;
   `-Mode Fixtures` is explicit. Camera/trace are explicit diagnostics;
   ranked/push stay off. Public client configuration is passed without printing
   credential values. Three executable Windows regression checks failed before
   and pass after the fix.
2. **An interrupted camera attempt now gets an outcome.** A noisy side → front →
   side switch discarded an active descent. The counter now reports
   `lowConfidence` before clearing it. Seed 4 still accepts nine reps; its ten
   attempts now all have an outcome. Counting thresholds, acceptance assertions,
   version 1.3.0 and protected tests are untouched. This fixes diagnostic silence,
   not the physical detection ambiguity.
3. **Backend request limits now bound actual input.** `readEnvelope` formerly
   consumed the whole request and checked UTF-16 string length. It now limits
   streamed UTF-8 bytes to 4 MiB, cancels oversized streams and preserves split
   UTF-8 characters. Five native Deno regressions pass, including a forged small
   Content-Length, no header, the exact boundary and early cancellation. No
   migration or protected avatar fixture changed.
4. **A missing backend no longer fabricates a live challenge.** The challenge
   landing formerly treated any valid-looking token as `available` when
   `apiBase` was blank. It now shows explicit configuration unavailability,
   retains the readable code and makes no live/install promise. Metadata and
   no-script copy are neutral. Configured valid read-only challenge/install
   recovery remains tested. Six new tests execute the actual shipped scripts;
   three failed before the fix and all pass afterward.
5. **Website readiness and packaging:** the existing waitlist now has
   `npm run check:launch`, with five regressions, reporting missing local variable
   names and separate hosted checks without printing secret values or making
   requests. PostHog is optional instrumentation and appears in warnings, not
   signup blockers; either dispatcher or cron authentication is accepted, with
   cadence still requiring verification. `.env.example` includes the cron secret and optional real
   Android certificate. README distinguishes the daily cron backstop from the
   required retry cadence within the 23-hour deadline. Pretest regenerates
   legacy copies from the actual source, preserving strict equality across
   Windows checkout line endings. Standalone website builds keep their prepared
   assets and do not gain a sibling-directory requirement. Explicit fake
   service-key test values now satisfy the unchanged repository secret scanner.
   The actual signup helper now clarifies: “Email updates, not a paid
   subscription. No payment required.” Its existing no-app-access disclosure
   remains. No new signup, payment or analytics system was added.
6. **CI coverage:** the workflow now includes Fault typecheck/tests/build,
   native Deno tests and executable Windows launcher tests. Signed candidates
   require these jobs plus the existing Flutter verification. Public-output
   regression fixtures run in ordinary verification. Existing red suites remain
   visible; nothing is excluded to manufacture green. Workflow execution on
   GitHub is not claimed because this repository has no remote.
7. **One current handoff:** this file and the dated pointer in `PILOT_PLAN.md`
   supersede old acquisition advice and task-complete language. The exact
   continuous-source brief and non-self-filming constraint are retained.

## Keep, close next, defer

| Priority | Work | Completion evidence |
| --- | --- | --- |
| Keep now | One free Android solo session: open, practice/set, manual entry, self-reported result, save, restart and see history | Same candidate build on real phone; failed save retains retry/result; no fake success |
| Close next | Resolve retained app acceptance conflicts explicitly, run all tests/analyzer, then sign the exact source checkpoint | No protected assertion silently changed; exact counts/version/commit/flags/APK hash |
| Close next for public email capture | Existing Fault schema correction, server credentials, verified sender/webhook, permitted environment, usable public support/operator/retention facts and retry scheduling | Review migration without applying it here; real confirmation/unsubscribe/suppression/recovery smoke; production and preview isolated |
| Close next for distribution | Signing, honest public policies/support/deletion and matching domain/App Links; current Play account status/test-track eligibility | Owner-controlled credentials and factual pages; current console result, not an old chat assumption |
| Gate separately | Counted friend battles | Two physical phones with observer counts, hosted auth/invite/ready/result agreement, connection recovery and fresh rematch; no unresolved result-invalidating defect |
| Defer | Ranked queue, push/Firebase rollout, bosses/clans/currencies, extra exercises, iOS/localization expansion | Reopen from observed user need after supported beta behavior |
| Defer | Subscription checkout, paid ads, large campaign/email automation, 14 creatives before first feedback, more site polish | Defined offer/benefit and retention evidence; actual budget and delivery decision |

**Recommended learning gate, not an approved promise or benchmark:** recruit a
small eligible cohort through owner-approved channels; observe whether they can
start unaided and complete/save the supported session. Record attempted,
started, completed/saved and voluntarily returned after a full seven-day window.
Report numerator/denominator and failures. No automatic failure/success claim
from a tiny sample. For applicable new personal Play accounts, separately plan
for Google's minimum 12 opted-in testers continuously for 14 days before a
production-access application; verify this account's actual eligibility first.
[Official testing requirements](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en).

The current signed workflow still requires hosted/link configuration even for
the proposed solo-first scope. Do not call it an offline-only release pipeline.
Separating that pipeline is a later scope decision; supplying dummy backend
secrets to pass the current workflow is not a shortcut.

## Process mistakes and corrections

These describe decisions and workflow, not personal failings. Clarifications
about a creative brief or a changed preference are not user mistakes.

| Responsibility | Evidence-backed mistake or risk | Correction |
| --- | --- | --- |
| Owner/product process | Competitor feature breadth, the 30,000-email ambition and premium website quality can become gates before anyone tries a usable session (`docs/fault-website/01-brief.md`, decision 12, strategy chat) | Retain ambition as a growth target; approve a small supported beta and stop expanding unrelated systems until its largest observed friction is fixed |
| Shared | Overlapping writers and changing session/checkpoint names made implementation, blocked status and completion hard to distinguish | One writer per area, one current checkpoint; preserve source and exact validation evidence before handoff |
| Assistant | Old 626-green evidence was reused after the October 637-pass/2-skip/3-failure checkpoint | Re-run current source and report retained failures; historical green is not release readiness |
| Assistant | Normalized synthetic payloads missed an actual native pixel-coordinate bridge defect | Preserve native-coordinate regression coverage and device traces; never call synthetic replay physical validation |
| Assistant | The all-flags-on development command secretly selected fixture backend behavior | Explicit modes and executable regression tests; use real HTTP ports for backend validation |
| Assistant | Optimized an eight-second Flow clip after the user needed repeated continuous 60-second source; then proposed free generators before checking duration and repeatability | Apply source-duration, realism, repeatability, budget and rights gates before tool selection; no more short-clip shopping presented as a solution |
| Assistant | Misread user-added meme audio as actor dialogue/captions and repeatedly asked the wrong question | One accepted brief: actor-only silent source; owner adds app and meme sound in editing |
| Assistant | Positive visual language based on sampled frames overstated body-mechanics/sound review and missed reaction headroom/gaze drift | Review the entire continuous file, label unverified dimensions, check hands/body continuity and reaction placement explicitly |
| Assistant | Previous website/video defects included production-default reconciliation, complaint hold clearing, rollback disabling recovery routes, over-expanded preview duration and unsupported generator modes exiting successfully | Preserve October 20 corrections, run their actual suites, keep the corrective hosted migration separate; do not infer a remote rollout from local fixes |
| Shared planning | Repeated reviews and production packaging displaced first-user learning | Finish one supported session and one real funnel; prepare three distinct honest concepts, publish only under the owner's decision, fix the observed largest dropoff |

## Acquisition and the exact video brief

One CTA depends on real release state: **testing/launch email updates** before
access; a **direct supported beta route** when available; a **real store link**
only once public access is verified. Do not force invited usable-beta testers
through another waitlist. Safe clarification for the current website:
“Email updates, not a paid subscription. No payment required.” No date, price,
fake scarcity, subscriber counter or customer testimonial is invented.

The requested source is repeated, **unbroken 60-second vertical takes** of an
adult white blond man, ordinary light/clothes, coherent hands/body and a low
three-quarter phone viewpoint. Frame the man lower with headroom for the owner's
upper app/opponent insert. Confident controlled push-ups → brief upward check →
more effort → upward stare/freeze → restrained disbelief held through the end.
It need not mean 60 seconds of uninterrupted exertion. Preserve the continuous
file and make three reaction variants. No app/phone/interface/captions,
voiceover, music, spoken meme or endcard is in the source. The owner edits it
to roughly 20 seconds and adds the “I got this” meme sound and product insert.

The owner cannot film/post themselves. A consenting third-party performer or
properly licensed source is required; none is secured here. Stock may not
include this duration/reaction. No zero-cost, repeatable AI workflow meeting the
exact brief has been demonstrated. A real performer changes an AI-generation
requirement; product-only content changes the actor format. Label alternatives
honestly. No AI generation, outreach, publication or spending occurred in this
review.

Prepare only three first edits: the requested reversal, “celebrated too early”
with a different reaction, and the actual supported session on the current
build. Further evidence-led drafts can show a genuine test result, one verified
setup correction, a real bug/replay/fix, first-use friction or an actual rematch
once that path is proven. Dramatization cannot serve as an accuracy demo.

Use existing allowlisted source/content/creative IDs and consented lifecycle
events. Count unique confirmed/currently subscribed eligible addresses from the
database, not event totals; tests/suppressed/unsubscribed rows count zero. The
product activation metric is the first completed and saved supported session;
signed-out solo measurement remains voluntary tester observation, not a claim
of an existing remote solo telemetry stream. Battle starts/completions are
relevant only after that path is supported. Evaluate voluntary return only
after full seven-day observation windows; no virality or causal lift claim.

## Preorder/subscription decision

The previously approved website implementation was a **free email waitlist**. No reviewed
chat establishes a paid price, charge/renewal date, refund terms or payment
authorization. The current request reopens the idea; it does not supply those
missing terms. Existing waitlist consent is for updates, not billing or evidence
of willingness to pay. Reuse it for no-charge early interest; do not add a second
generic signup system or a placeholder checkout.

Before a paid offer: decide the actual benefit/product, price/currency, markets,
availability/delivery, billing/entitlement platform, cancellation/refund/support
terms and how these will be displayed. Digital in-app subscriptions generally
require Play billing subject to region/program exceptions; a generic web Stripe
checkout is not justified by the current scope.
[Current Play payments policy](https://support.google.com/googleplay/android-developer/answer/9858738?hl=en).
No provider or billing system was activated, and no charge was taken.

## Verification and remaining blockers

| Fresh local check | Result | Scope/limit |
| --- | --- | --- |
| Pinned Flutter `analyze --no-pub` | **PASS**, no issues | Current `app/` source, Flutter 3.47.5 |
| Pinned Flutter `test --no-pub --reporter expanded` | **FAIL: 640 pass, 2 skip, 2 fail** | The previous silent noisy-attempt failure is fixed; retained protected failures below |
| New interruption regression + existing full stress matrix | **PASS, 3 tests** | 95 synthetic matrix cells; seed-4 outcomes improve 9 → 10 while accepted reps remain 9; no device accuracy claim |
| `rtk proxy npm.cmd ci --ignore-scripts` in `fault-web` | **PASS**; 160 packages, audit reported zero vulnerabilities | Locked local dependency install; audit is not a security certification |
| `rtk proxy npm.cmd run typecheck`, `npm.cmd test`, `npm.cmd run build` in `fault-web` | **PASS**, 45/45 tests and optimized Next build | Final 45-test run after readiness correction; optimized build, including TypeScript, passed again after the final no-payment helper copy. Local PostgreSQL simulation and simulated delivery, no live customer/email proof |
| `rtk proxy npm.cmd run check:launch` in `fault-web` | **Expected refusal, exit 1** | Missing local hosted variable names, closed delivery and incomplete public copy reported; deliberately uncopied secrets do not prove their absence in an existing account |
| Native Deno 2.9.6 `check --node-modules-dir=none` on arena/dispatcher `index.ts` | **PASS** | Both real deployment entrypoints typecheck; no hosted deployment |
| Native Deno full arena + dispatcher tests | **FAIL: 69 pass, 3 fail** | Five new request-limit regressions pass; three unchanged protected avatar-fixture failures below |
| Local Supabase database tests | **NOT RUN** | CLI connection refused at `127.0.0.1:54522`; Docker Linux engine pipe unavailable; no hosted reset or migration attempted |
| `rtk proxy node --test challenge-web/test/*.test.mjs tools/release/test/*.test.mjs` | **PASS, 49/49** | Includes six new actual-script challenge regressions, three Windows launcher checks, public-page and release hold fixtures |
| Challenge static check, release flags, source identity, source App Link consistency | **PASS** | App Link check intentionally allows placeholder in development; this is not real HTTPS verification |
| Repository secret scan | **PASS** | Includes preserved source; scanner unchanged; no secret values printed |
| `rtk proxy python -B -m unittest tools.social.test_generate_ugc_video tools.social.test_ugc_prompt_matrix -v` | **PASS, 8/8**, no skips | Preserves and verifies prior duration/Fal-mode corrections; FFmpeg uses temporary solid-color images only. Prompt matrix/still previews do not solve the continuous actor-source requirement |
| Actual public-output publication check | **FAIL/HOLD**, 11 files at initial scan | Real `[[OWNER:...]]`/`example.invalid` remain in source and copied public pages; do not remove markers without factual values |
| Diff whitespace | New edits pass | Copied raw `FIX_LOG.md` output whitespace remains in the preservation checkpoint; evidence was not silently rewritten |
| New signed APK/AAB, current artifact/16 KB/size, physical walkthrough, hosted end-to-end, remote CI | **NOT RUN** | No signing, current physical evidence, configured local DB or Git remote; historical artifact success does not close these gates |

Exact app invocations used the pinned executable:

```powershell
rtk proxy cmd /c D:\toolchains\flutter-3.47.5\flutter\bin\flutter.bat analyze --no-pub
rtk proxy cmd /c D:\toolchains\flutter-3.47.5\flutter\bin\flutter.bat test --no-pub --reporter expanded
# Run the preceding commands from app/; do not silently use another Flutter version.
rtk proxy npx --yes deno@2.9.6 check --node-modules-dir=none supabase/functions/arena/index.ts supabase/functions/arena-dispatcher/index.ts
rtk proxy npx --yes deno@2.9.6 test supabase/functions/arena/tests supabase/functions/arena-dispatcher/tests
```

Unresolved engineering requirements, not merely missing account inputs:

1. **`push-up counter a missing selected-side ankle gates counting`**, at
   `app/test/camera/rep_counter_test.dart:188` (assertion at 199), expects a missing selected-side
   ankle to block counting; full-chain side selection counts one on the visible
   valid side. **`pushups_half_depth.txt stays rejected with head and feet out of frame`**,
   at `app/test/camera/fixture_replay_test.dart:118` (assertion at 124), expects `CounterRejection.none`
   for the partial-frame shallow sequence; candidate code reports
   `notDeepEnough`. The task requires both changed behavior and unchanged
   protected assertions. Reconcile those requirements explicitly, preserving
   meaningful regression coverage; do not lower a threshold or delete tests to
   obtain green. These two failures still block the existing full-test CI gate.
2. The three protected `avatar_test.ts` positives — **`decodeAvatar accepts a PNG payload`**,
   **`decodeAvatar accepts JPEG and WebP payloads`**, and **`decodeAvatar accepts a matching data URL`** — contain only image signatures,
   not parseable dimensions. Mandatory dimension validation rejects them. The
   real PNG upload app test passes, so this is a fixture/contract conflict, not
   proof that all avatar uploads are broken. Reconcile accepted-fixture policy
   without disabling image validation. Native Deno job stays red meanwhile.
3. `20261012144405_arena_goal_hardening.sql` inventories the actual legacy
   `arena-counter/1.2.1` version but rejects it with the strict semantic-version
   expression; the protected SQL test requires that rejection. Agree the rolling
   compatibility contract, then use a **new** migration preserving the accepted
   version inventory and verify actual database behavior. No existing migration
   or protected assertion was changed here.
4. The Auth gateway sends no CAPTCHA token in its OTP request. Enabling CAPTCHA
   in the hosted settings alone is not an implemented client flow. An email-only
   pilot needs verified SMTP/Auth; Google adds actual OAuth/redirect setup.
   Decide and test bot-protection behavior rather than treating an admin toggle
   as completion.

External/user inputs are scope-dependent: confirm current Play identity and
test-track status; supply signing and real public identity/support/retention
facts; arrange a physical device walkthrough and the two-phone matrix before
camera/battle claims; configure the selected existing development backend and
Auth/provider values for account-based testing, using the existing inactive
`fit_ap` project only after the owner decides its resumption; obtain appropriate
Vercel team read access to refresh deployment status. Review the complaint-hold
migration and actual hosted ledger before any change (local presence is confirmed,
hosted application unverified); choose/provide retry scheduling without
new spending; create/configure a private Git remote for CI. No need to provision
Firebase for the no-push beta. No new hosting/domain purchase is implied.

Exact unresolved engineering conflicts and local-runtime limits belong with the
fresh verification results, not hidden under an owner-input label. Publication,
live collection, billing, outreach and production database changes remain outside
this review's authorization.
