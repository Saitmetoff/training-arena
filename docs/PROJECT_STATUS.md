# Training Arena project status

## Solo-first beta checkpoint — 2026-09-30

Owner-approved beta implementation: signed-out solo launches before ordinary
notices, with incoming/active battles retaining priority. Solo starts above
stats, uses the existing unscored practice, labels manual counts as
self-reported, and never claims Saved after a persistence failure. Save waits
for history and coalesces taps; seven-day history and personal bests compare
the same exercise/source. My challenge link/code reuses the existing account
link with copy/share recovery. Authenticated rematches recover one pending
request in either direction, then require a fresh casual match and readiness;
old scores and receipts remain untouched. Waiting states use server responses.

CameraX Preview and ImageAnalysis now share a ViewPort and send actual numeric
crop/rotation/mirror/affine metadata to Dart. Preview and skeleton use that
same metadata. Counter version remains **1.2.1**; counting thresholds and
false-positive protections are unchanged. Reviewed two-phone evidence is now
a camera-enablement CI gate. Local maintenance is scheduled once per minute
in Postgres without push delivery. Version bumped to **1.0.1+2**; the signed
candidate requires solo/links/sharing on and ranked/push/fixtures/trace off.

Verification: **626 Flutter tests passed, 2 skipped**, analyzer clean;
**59 Deno tests**, **212 pgTAP assertions** (6 files), **31 local HTTP smoke
checks**, **37 release/web Node tests** passed. Repository secret scan exits
**0**; source identity, release flags, web and development App Link checks
pass. The placeholder-domain warning is still valid. Red→green cases include
solo-first placement, failed save, delayed history, rematch action/token
refresh, preview parser validation and short-bottom coaching. Evidence and
commands: `qa/beta/checkpoint-results.json`.

**Not shipped:** hosted project/auth, real domain/public legal values and
release signing remain unconfigured. No physical camera round or overlay
alignment pass has been recorded; Redmi 10 became connected during the run,
but a second physical Android is still missing. No device accuracy claim is
made. The release build stays blocked on those inputs and existing media
review. The visual launch board, blank paired adult roster, observation log
and read-only server metrics are prepared in `qa/beta/`; no tester messages,
social posts, paid generations or ad purchases have been sent.

## Camera bridge normalises ML Kit pixels — 2026-09-25

The device symptoms (permanent "you are too close", no skeleton ever drawn)
were a coordinate-contract fault, not a counter-tuning problem: ML Kit
`PoseLandmark.getPosition()` returns **image pixels** in the upright,
post-rotation analysis frame, the native bridge passed them through unchanged,
and both the counter and the skeleton overlay consumed them as normalised
0..1 values. A pixel-scale body span is always > 0.98, so the gate locked
counting, and pixel positions projected off-screen in the overlay.

Fixed: `PoseAnalyzer.kt` reports the post-rotation `frame_width`/`frame_height`
with each pose event, and `camera_bridge.dart` normalises `x`/`y` against
them (scaling `z` by the width) and drops a pose event without a usable frame
size instead of forwarding pixels. `arenaCounterVersion` 1.2.0 → **1.2.1**;
the bridge protocol docs and the `PoseFrame` comment are updated. Regression:
three new bridge tests, including a pixel-valued clean rep that must count
exactly one (it counted zero before the fix). Analyzer clean, **606/606**
Flutter tests. Still to verify on the device: the analysis frame (640x480,
no CameraX `ViewPort`) versus the overlay's 720x1280 assumption — the
preview/analysis crop needs a physical session now that the units are right.

## T10 round 2 — emulator QA re-run, two defects fixed — 2026-09-24

The stalled task-10 round-2 pass is finished: the emulator walkthrough (cold
link → sign-in → request → accept → preparation → camera permission → ready
gate) was re-verified and captured in `qa/integration/evidence/t10r2/`, and it
found two defects, both fixed.

- **D6 (server)** — a player who readied more than ten seconds before the
  countdown ended was forfeited `opponent_absent` 0.44 s after live started.
  `arena_match_tick` now lifts both active players' presence to the live start
  (`greatest(last_seen_at, starts_at)`) at the countdown → live promotion. The
  first version of the fix stamped the sweep clock instead, which hid a shared
  outage; the smoke caught it and the lift was corrected. Pinned by 4 new
  pgTAP assertions (early ready never forfeits, no receipt at live start,
  live absence still forfeits, shared outage across the live start closes as
  `no_result`/`service_outage`).
- **D7 (app)** — a forfeit receipt rendered as "@x beat me by 0". The result
  body now uses forfeit copy for `opponent_absent`/`abandoned_preparing`/
  `service_outage` instead of a score margin, with a widget regression.

Verified: `flutter analyze` clean, **593/593 Flutter tests** (+2 skipped),
pgTAP **194/194** (4 files), HTTP e2e smoke **24/24** with
`ARENA_DISPATCHER_SECRET`, QA APK rebuilt with both fixes (91,729,591 bytes,
SHA-256 `4BF32EA0…14C7F`). Full record: `qa/integration/REPORT_T10R2.md` and
`qa/integration/results_t10r2.json`.

The fixed result screen was not re-captured on the emulator: the smoke's
`supabase db reset` prerequisite invalidated the QA account session created
during the walkthrough, so that capture needs a fresh sign-in. R1, R2, R6 and
R7 stay open. Deno suites were not re-run (not installed in this shell; the
edge functions are unchanged).

## F3 landmark tracing landed — device session BLOCKED — 2026-09-24

`prompts/camera-fixes/F3_DEVICE_TRACES_AND_THRESHOLDS.md`, first half:
`ARENA_FEATURE_CAMERA_TRACE` (default false, registered in `ArenaConfig`,
`docs/CONTRACT.md` and `docs/release/CONFIGURATION.md`) arms a debug-only
recorder on the camera card that consumes the counter's own frame stream,
keeps the last three minutes in memory and writes
`trace-<exercise>-<timestamp>.txt` — numbers only, in the exact C05 text
format — to app-private storage when the owner taps Export, with a visible
`TRACE ON` label and a delete control. The test serializer now delegates to
the production format module, so fixtures and device traces cannot drift. The
release-hold check fails if the flag is `true` or unpinned and
`.github/workflows/release-checks.yml` pins it `false`; the file is written at
runtime and never enters a build artifact. `path_provider` was promoted from
transitive to direct for the private directory (already in the lock and the
generated plugin registrant; no new package in the APK).

Evidence: `flutter analyze` clean, **592/592 Flutter tests** (579 before, +13:
11 recorder/format, 2 camera-card), release-flag check exit 0 and 7/7
release-tool tests. Full record: `qa/competitive/f3/REPORT.md`.

The device half is **BLOCKED**: no phone was attached (`adb devices -l` lists
emulators only), so no trace exists, no replay test was added, no threshold
was measured or changed, and no checklist row was executed or signed
(`qa/competitive/c05/DEVICE_INPUT_LIST.md` states every value is still a
candidate). The prepared builds are
`app/build/app/outputs/flutter-apk/TrainingArena-f3-trace-debug.apk`
(222,378,595 bytes, SHA-256 `A7F690AC…869A6`; debuggable, so traces can be
pulled with `adb run-as`) and the debug-signed release
`TrainingArena-f3-trace.apk` (91,140,003 bytes, SHA-256 `8031DB1E…97B58A`;
share-sheet export), with the scenario run sheet
`qa/competitive/f3/RUNSHEET.md`. Remaining R1 work: the owner's traced
scenarios, trace replay + in-app/replay count agreement, threshold updates
with named traces, and the human-observed rounds and signatures.

## F4 skeleton overlay landed — host-verified, device session BLOCKED — 2026-09-24

`prompts/camera-fixes/F4_SKELETON_OVERLAY.md`: the camera preview now draws the
landmarks the rep counter already consumes — no detector was added, no
dependency installed. `CameraSession` gained a numbers-only seam
(`latestFrame` returns the exact frame the counter processed; `poseFrames`
broadcasts those references with no buffering or replay) and the snapshot
carries the counter's own `viewMode`/`countingSide`. The new
`PoseSkeletonOverlay` maps normalised landmarks onto the displayed preview with
a pure, unit-tested function (cover/contain, quarter turns, mirror) and
emphasises the counting chain — selected arm or leg chain plus the primary
joint in a side view, shoulder/hand lines and torso in a front view — with dim
non-counting limbs so the meaning survives grayscale. It is visible by default
during practice/ready/live with a live texture and has a one-tap hide control
on the camera card whose choice lasts for the session. Missing, low-likelihood
or absent landmarks paint nothing and leave the existing guidance card.

Evidence: 7 mapping unit cases, chain tests, widget tests (synthetic session
frame, empty and partial frames, hide toggle, pause), and a painted-pixel test
that requires the lime chain in the rendered image. `flutter analyze` clean,
**579/579 Flutter tests** (555 before, +24; 2 skipped: fixture regeneration and
the new opt-in overlay bench). Host paint cost 15.4–21.0 µs/frame
(`qa/competitive/f4/overlay_paint_cost_host.txt`) — a host bound, not a device
number. `rep_counter_test.dart` untouched; no `pubspec.yaml` or Gradle change.
Full record: `qa/competitive/f4/REPORT.md`.

Physical Redmi 10 confirmation is **BLOCKED** (no phone attached; `adb devices
-l` lists emulators only). Alignment, screenshots and the device frame-rate
impact are F3's session; the APK for it is
`app/build/app/outputs/flutter-apk/TrainingArena-solo-camera-skeleton.apk`
(90,894,095 bytes, SHA-256 `D033A6BD…10AFF`).

## F2 head-on counting landed — host-verified, device session BLOCKED — 2026-09-24

`prompts/camera-fixes/F2_FRONT_VIEW_COUNTING.md`: the counter now detects the
camera placement from landmark geometry (`CameraViewMode`, shoulder width over
projected torso length, shoulder z-spread tiebreak, hysteretic; ambiguous
frames keep the previous mode) and counts head-on push-ups with a shoulder-
height-above-the-hands signal (normalised by shoulder width). Front framing
uses the shoulder line as the size proxy, so a foreshortened body is no longer
`tooFar`; front sag is rejected as `bodyNotStraight` against the shoulder-to-
hip offset captured at the top of the set. Squats are explicitly side-view
only and a head-on squat gets the new `wrongView` pause reason with copy that
asks the athlete to turn. Push-up guidance now describes both placements, and
`arena-counter` moved 1.0.0 → 1.1.0.

Evidence: the geometric cause was reproduced on fixtures first — the 2D elbow
angle stays 135.6…172.5° head-on (never ≤ 100°), the side-view span framing
never locks, and the clean head-on fixture counted 0 on the unchanged counter
(`qa/competitive/f2/fixture_before_fix.txt`). After the change the clean
head-on fixture counts 1, half-depth and shake count 0, sag rejects as
`bodyNotStraight`, and a hidden hand never locks framing. Five committed
fixtures generated through `FIXTURE_GEN=1`; 5 replay + 17 front-view tests.
`flutter analyze` clean, **555/555 Flutter tests** (533 before; 1 skipped
regeneration helper). Side-view suite (`rep_counter_test.dart`) unchanged.
Full record: `qa/competitive/f2/REPORT.md`.

Physical Redmi 10 confirmation is **BLOCKED** (no phone attached; `adb devices
-l` lists emulators only). All front-view thresholds are synthetic candidates;
F3 replays real traces before any of them is claimed as measured.

## F1 camera reopen bug fixed and reproduced in an on-device test — 2026-09-23

Root cause: the native plugin disposed the camera controller on
`disposeSession` but kept the reference; the next `startPreview` reused the
dead controller, returned a texture id and silently skipped `bindAll` — black
preview, no landmarks, no error. Fixed in `ArenaCameraPlugin.kt` (drop the
reference, `ensureController()` rebuilds on every start path) and hardened in
`ArenaCameraController.kt` (`start()` fails loudly on a disposed controller).

Evidence: new `app/integration_test/camera_reopen_test.dart` drives three
start/dispose cycles and requires a `cameraReady` cue plus pose events each
time. **Before the fix it failed at the second start**; after the fix 1/1
passes on the emulator. Logs: `qa/competitive/f1/`. Analyzer clean,
**533/533 Flutter tests** (532 before, +1 session contract test). Fixed
non-distributable APK delivered to the owner's phone; physical confirmation
pending. Full record: `qa/competitive/f1/REPORT.md`.

## C07/C08 spikes recorded — clip deferred, web stays an install funnel — 2026-09-23

`prompts/competitive/C07_SHARE_CLIP_RENDERER.md` phase 1 and
`C08_WEB_BATTLE_SPIKE.md` are complete as decision records:

- `docs/decisions/13-share-clip-approach.md` — keep the static share card now;
  revisit native screen recording only after R1 enables camera counting and an
  inventory/consent decision is recorded; reject the encoder-dependency and
  server-rendered paths. Decisive constraint: a camera-off build has no honest
  motion content to record.
- `docs/decisions/14-web-battle-approach.md` — keep `challenge-web/` as the
  accept/install funnel; fix install-drop-off measurement first. A browser
  battle would require a second copy of the rep state machine, and device
  performance could not be measured in this session (marked, not invented).

Both are owner-gated: the decision records carry the checkboxes and the
questions a later phase must answer. No app, web, backend or CI file changed.
Records: `qa/competitive/c07/REPORT.md`, `qa/competitive/c08/REPORT.md`.

## C09 owner input wizards landed — signing, hosting, Play closed test — 2026-09-23

`prompts/competitive/C09_OWNER_INPUT_WIZARDS.md` delivered three dry-run-first
PowerShell wizards plus an index: `tools/wizards/W1-signing.ps1` (R9 keystore,
`key.properties`, CI secrets, fingerprints), `W2-hosting.ps1` (R2/R3/R16
domain, `config.js`, `assetlinks.json`, Supabase link/migrate/secrets/deploy)
and `W3-play-closed-test.ps1` (L10 Console, closed track, roster, upload,
fresh-install verification, forms). All three parse clean in PowerShell 5.1
and complete a dry run with exit 0, no prompts, no network and no writes.
Passwords stay in `SecureString`/`-storepass:env`, `key.properties` is proven
gitignored before it is left on disk, and W3 performs no upload or submission.
Full record: `qa/competitive/c09/REPORT.md`.

## C06 store listing keyword and claims pass landed — copy unchanged — 2026-09-23

`prompts/competitive/C06_STORE_LISTING_AND_ASO.md` added the ASO layer to
`docs/release/PLAY_STORE_PACKET.md` §2: a keyword table with truth
constraints, a forbidden-claims submission checklist, the conditional
solo-set sentence (only when the flag ships true), the name decision note
(12 D-B: keep, revisit before submission) and a follow-up list. Variant A
listing copy was already truthful and was not rewritten; variant B stays
blocked behind R1/R13. Docs only — no source, asset or gate changed.

## C05 counting replay harness landed — thresholds unchanged, L04 input list written — 2026-09-23

`prompts/competitive/C05_COUNTING_ROBUSTNESS_AND_HARNESS.md` found the counter
already implements every targeted protection (framing lock, hysteresis, dwell,
duration, debounce, straight-body, confidence, loss/stall reset, duplicates) —
each with an existing code-driven test. No counting behaviour changed.

Added: a text fixture format with parser/serializer and a replay runner
(`app/test/camera/fixture_replay.dart`), six committed fixtures
(`app/test/camera/fixtures/`, generated from `SyntheticPoseSource` via the
`FIXTURE_GEN=1` regeneration test), eight replay tests, and
`qa/competitive/c05/DEVICE_INPUT_LIST.md` — the per-threshold measurement list
the L04 physical session should capture and replay. The format carries
numbers only, so recorded device traces can be committed without touching the
privacy rules.

Evidence: `flutter analyze` clean, **532/532 Flutter tests** (524 before, +8;
1 skipped regeneration helper). Full record: `qa/competitive/c05/REPORT.md`.

## C04 trust surface audited — copy guard added, no claims changed — 2026-09-23

`prompts/competitive/C04_TRUST_SURFACE.md` found the trust statements already
shipped since the L01 freeze (settings, live round, result, camera guidance,
challenge entry, solo). This pass added the missing guard:
`app/test/copy/forbidden_claims_test.dart` fails on accuracy percentages,
"cheat-proof", guarantees and medical claims in any `lib/` string literal,
and asserts the on-device statement stays present. Nothing user-facing was
rewritten and no claim was invented. Evidence: analyzer clean, 2/2 copy
tests. Full record: `qa/competitive/c04/REPORT.md`.

## C03 solo badges landed — derived from local history, no reward economy — 2026-09-23

`prompts/competitive/C03_PERSONAL_BESTS_AND_BADGES.md` is implemented with six
deterministic badges (`first-set`, `goal-day`, `week-streak`, `month-streak`,
`hundred-reps`, `thousand-reps`) derived from the C01/C02 history — no stored
awards, no server call, no coins/currency/purchases. Personal bests and the
stats view were already delivered by C01/C02 and stay derived.

Added: `app/lib/solo/domain/solo_badges.dart`, the `solo-badges` grid on the
solo page, and 6 badge tests. Evidence: `flutter analyze` clean, **522/522
Flutter tests** (516 before, +6). Full record: `qa/competitive/c03/REPORT.md`.

## C02 solo daily goal and streak landed — device-local, DST-safe — 2026-09-23

`prompts/competitive/C02_DAILY_GOAL_AND_STREAK.md` is implemented
**device-local** instead of server-backed: decision 12 defines solo as
local-only, and no hosted Supabase project exists (R2/R3/R16), so a server
path could not be verified end to end. The upgrade path (idempotent
day-completion upload) is recorded in `qa/competitive/c02/REPORT.md`.

Added: `app/lib/solo/domain/solo_streak.dart` (local calendar days, DST-safe
day stepping, current/longest streak, goal-met rules), streak derivation in
the solo controller, the `solo-streak` card on the solo page, and 9 streak
tests. The goal is `20` reps/day, fixed for v1.

Evidence: `flutter analyze` clean, **516/516 Flutter tests** (507 before,
+9). No server, database or release flag changed.

## C01 solo max-reps mode landed — local only, flag held off in release — 2026-09-23

`prompts/competitive/C01_SOLO_MODE_V1.md` is implemented per the owner
directive recorded in `docs/decisions/12-competitive-direction.md` (D-A: solo
in scope, manual entry allowed for solo only; D-C: camera counting stays off
for the pilot, so manual entry is the working path).

Added: `app/lib/solo/` (result model, local store, controller, page), the
flag-gated `Solo set` entry on the Battle tab, `ARENA_FEATURE_SOLO_MODE`
(config + release hold + workflow pin), and 15 new tests
(`app/test/solo/`). A solo set creates no receipt, rating, leaderboard entry
or server call; a self-reported set is labelled in the UI.

Evidence (2026-09-23): `flutter analyze` clean, **507/507 Flutter tests**
(492 before, +15), release flag check passes, **13/13 release-tool
regressions**. The release workflow pins `ARENA_FEATURE_SOLO_MODE=false`
until the owner enables it. Full record: `qa/competitive/c01/REPORT.md`.

Next in the pack: C02 daily goal + streak (server truth) and C03 bests +
badges, both built on the solo result without touching rating or receipts.

## Task 11 release packet re-verified — review-fix A/B in tree, Batch C open, distribution NO-GO — 2026-09-22

The release checklist, configuration, pilot plan, rollback and incident notes
were re-verified on the current tree (HEAD `1561673` plus the uncommitted
review-fix Batch A/B patch set): `flutter analyze` clean, **492/492 Flutter
tests**, repo and artifact secret scans clean, 12/12 release-tool regressions,
21/21 challenge-web tests, 10/10 prototype groups, App Link release gate
fail-closed without a real host, release-hold check passing, and source +
debug-APK identity passing (`6EA276E0…46C2366`, 222 290 406 B, `1.0.0+1`,
minSdk 24, targetSdk 36, debuggable/QA-only). The Gradle release build now
also aborts on the `example.invalid` placeholder before signing, and the
release-equivalent smoke APK (`B4813C0B…75EFED`, 90 402 075 B, non-debuggable,
debug-signed) was rebuilt from the current tree. Transcript:
`qa/launch/l11/release_checks_2026-09-22.txt`; full record `qa/launch/l11/L11.md`.

**Verdict unchanged: NO-GO for handing a signed artifact to invited testers.**
Signing (R9), the real domain (R2), the hosted project/providers (R3), the
hosted public pages (R16), camera validation (R1), media review (R13) and
push hardening (new **R17**, review Batch C) remain open, each with an owner
and a decision in `docs/release/GO_NO_GO.md` §4–§6. The Batch A/B patch set is
**uncommitted**, so no distribution candidate exists; the L02/L08 artifact
hashes are historical. Nothing was published, deployed, notified or rotated.

## L10 closed-test and Play launch packet prepared — every external stage BLOCKED — 2026-09-21

`qa/launch/l10/PLAY_TEST_AND_LAUNCH_PACKET.md` is the owner-executable runbook:
Console/account verification list (type, identity, package registration — the
20 September guidance named **30 September 2026**), the honest track decision
(internal testing never satisfies the production-access rule; the clock starts
at the 12th continuously opted-in closed tester), the roster plan (16–24
recruited, ≥ 12 continuous, no bought opt-ins), the upload and fresh-install
verification runbook (Play app-signing identity, verified App Links, Google
return, Install Referrer on the Play path only), the stop-condition/single-
writer fix path, the feedback/changes ledger for the production-access
application, and the explicit missing-authorization list.

**Nothing was uploaded, submitted, approved or published; no roster was
recruited and 0 days of eligibility have elapsed.** The candidate is unchanged
since the L08 freeze (`1de6127`): the product-path diff `1de6127..HEAD` is
empty, and fresh source-identity and repo secret-scan checks pass
(`qa/launch/l10/`). Blockers remain R9 signing, R2/R3/R16 hosted config and
public pages, the L04 camera/media decision, owner Console execution and the
roster; no review duration is converted into a promised date. The L10 date
range still starts at the first completed owner input (no inputs landed since
20 September). Full record: `qa/launch/l10/L10.md`.

## L08 candidate built and verified — battle-capable pilot BLOCKED at camera/media, signing and hosted gates — 2026-09-21

The third writer's uncommitted patch set (durable secure sessions, Android
backup exclusions, preview-fixture refusal, on-device Keystore test) was
frozen in **`1de6127`** and the full acceptance re-run on that commit:
analyzer clean, **459/459 Flutter tests**, real-Keystore integration test 2/2
on the API 36 emulator, pgTAP **184/184**, Deno **48 + 10**, HTTP e2e
**24/24**, challenge-web **16/16** (the `--release` gate still fails by design
on the pending owner values), prototype **48/48**, repo/artifact secret scans
clean, fail-closed signing guard verified. A release-equivalent APK
(91 417 891 B, SHA-256 `E3574480…074CC9`, debug-signed, non-distributable,
byte-identical to the L07 smoke APK) and an **unsigned** AAB (89 902 797 B,
`9E77C0D4…C470A`) were built; the bundle check passes (targetSdk 36, 16 KB
alignment, 20 723 380 B arm64 delivery) and the APK passes cold smokes on the
API 36 and **16 KB** API 35 emulators.

**Stage table (built / signed / verified / device-tested / uploaded /
submitted / approved / live): built YES, signed NO (R9), verified YES locally,
device-tested PARTIAL (emulators only; physical matrix and the two-participant
camera battle BLOCKED — R1/R6/R7/R13), uploaded/submitted/approved/live NO.**
Verdict stays **NO-GO** for distribution. Exact owner actions and per-scenario
coverage: `qa/launch/L08.md`; updated rollback/GO/NO-GO notes in
`docs/release/`. Next: owner supplies signing/hosted/camera resources, then
L09/L10. (The L09 section below was written concurrently by its own session
and is preserved verbatim.)

## L09 social identity and content packet drafted — accounts, handles and footage BLOCKED — 2026-09-21

`docs/social/ACCOUNTS.md` contains the registration packet: owner-input list,
handle candidates (`@trainingarena`, `@playtrainingarena`, `@trainingarena.app`
— **availability NOT verified**), current truthful bio variants, the
provisional brand mark hashes, the two acceptable link destinations and the
owner-controlled recovery/MFA checklist. `docs/social/CONTENT_EXPERIMENT.md`
expands the launch plan's 14-day table into a shootable calendar plus the
activation funnel (content → qualified visit → install → first server-confirmed
human battle → repeat play); stages without a real source are marked NOT
INSTRUMENTED and a like/view/share-sheet is never activation.
`docs/social/briefs/BRIEF-01-real-battle.md`, `BRIEF-02-setup-demo.md` and
`BRIEF-03-ai-dramatization.md` are complete vertical scripts with footage,
signed-release and music-rights requirements, captions, disclosure and CTA
gates; nothing fabricates scores, testimonials, results or accuracy, and the
dramatization uses real captured app UI only.

**No account was created or reserved, no handle checked in-platform, no
footage captured and nothing published** (no browser tool in the executor
session; owner email/DOB/handle/language/MFA inputs missing; L04, L05 and R9
still gate capture; no Play track evidenced). The personal Instagram account
was not touched. Handle probes were refused or unusable and are recorded as
such in `qa/launch/l09/handle_probe.txt`; the repo secret scan passes after the
new files. No app source changed. Drafts are **uncommitted**; a concurrent L08
session committed the previously dirty app work (`1de6127`) during this task.
Full record: `qa/launch/l09/L09.md`. Next: owner
supplies the `ACCOUNTS.md` §2 inputs in a browser session; destination choice
waits on the L05 landing.

## L07 packet complete — public pages and external deletion verified locally, publication BLOCKED on owner inputs — 2026-09-21

The factual store/privacy packet is complete: a traceable data inventory
(`docs/privacy/DATA_INVENTORY.md`, every row citing schema or code, camera
frames/landmarks on-device only, every undecided retention period marked
**PENDING (owner)**), the public privacy/support pages and a working external
account-deletion route (`challenge-web/`), in-app Settings links to all three
pages, and the Play packet with the live policy check, listing copy for the
camera-off artifact, Data Safety/Health declarations, reviewer access and
generated store graphics (`docs/release/PLAY_STORE_PACKET.md`). The deletion
route verifies ownership with the documented email one-time code
(`create_user:false`), reuses the existing `delete_account` backend, keeps the
session in memory only and never logs a token; it is proven end to end against
the local stack with the shipped client
(`qa/launch/l07/deletion_route_e2e.txt`). Six real 1080×1920 screenshots were
captured from the release-equivalent smoke APK
(`qa/launch/l07/SCREENSHOTS.md`; the fixture-populated leaderboard shot was
excluded).

Fresh checks: analyzer clean, **459/459 Flutter tests**, challenge-web check
passes while `--release` fails only on the pending owner values, 16/16 web
tests, pgTAP **184/184** after `supabase db reset`, Deno **48 + 10**, repo and
artifact secret scans clean. **No hosted step ran**: the pages are not
published, no Play Console entry exists, and the owner identity/contacts/
retention values are still missing, so **new R16** is open and the external
endpoints are BLOCKED. Camera counting stays off, ranked stays off and the
release verdict stays **NO-GO** (R9 is still the only artifact blocker). Full
record: `qa/launch/L07.md`.

## L06 native push host landed — Google return and ranked matrix BLOCKED on owner inputs — 2026-09-21

The missing Android FCM host now exists for the exact task-08 contract:
`PushBridge` implements `permissionStatus`/`requestPermission` (API 33+
in-context), `deviceToken`, `initialTap`, `dispose` and the
messages/taps/tokens event channels, and `ArenaMessagingService` forwards
tokens and foreground data and posts a local notification whose
`PendingIntent` reuses the `singleTop` `MainActivity` with the data map as
extras. The Google Services plugin (`4.5.0`) and
`firebase-messaging:25.1.3` are pinned and the plugin is applied **only**
when `app/android/app/google-services.json` exists; without it the bridge
reports `notDetermined`, returns no token, keeps the streams empty and
creates no notification channels — the no-push pilot scope is unchanged and
`ARENA_FEATURE_PUSH_NOTIFICATIONS=false` stays.

Local verification: analyzer clean, **459/459 Flutter tests** (8 new L06
tests; 5 more from the concurrent L07 session), Deno arena **48** +
dispatcher **10**, release-equivalent APK and unsigned AAB build, bundle
check (targetSdk 36, 16 KB alignment, **20 617 131 bytes** arm64 delivery),
identity and repository/artifact secret scans clean, and cold-start smokes
on the API 36 and API 35 **16 KB** emulators (clean logs, no notification
channels, no crash). Google/email redirect continuity through the real PKCE
gateway after process death is host-tested, including a username-required
account.

**Blocked, not faked:** live push (permission ask-once/denied, foreground/
background/terminated taps, token rotation/unregister) needs the owner's
Firebase Android app + `google-services.json` and a physical device; the
Google return needs the hosted Supabase project, Google client id/secret and
the Play app-signing SHA-1; the ranked two-phone matrix needs two physical
devices (`adb devices -l` empty), so ranked stays inaccessible with the L03
refusal path. No live notification was sent. Full record and exact evidence:
`qa/launch/L06.md`.

## L05 runbook complete — hosted connection BLOCKED on owner target — 2026-09-20

The L05 deployment runbook is written and the deploy path is locally verified,
but no hosted step ran: there is still **no real domain (D1), no Supabase
project (D3), no hosting destination, no SMTP provider and no secret vault
location**, so nothing external was created, deployed or purchased. R2 and R3
remain open. The exact owner inputs and the ordered commands are in
`qa/launch/l05/DEPLOYMENT_PACKET.md` §0–§2; the hosted verification matrix is
§3; rollback cross-references `docs/release/ROLLBACK.md`.

Local verification (fresh, 2026-09-20): `supabase db reset` clean, pgTAP
**184/184**, arena + dispatcher Deno tests **48 + 10 passed**, challenge-web
guard and unit checks pass, the App Links release gate fails on the placeholder
and passes on a real-format host, and the extended e2e smoke passed **24/24**
including the dispatcher worker boundary (missing/wrong bearer rejected, own
secret accepted) and the shared-outage path — both clients stop heartbeating
and the worker sweep closes the match `no_result`/`service_outage`. The served
function log carries no token, email or bearer value. Full record:
`qa/launch/l05/L05.md`.

**Coordination warning:** a second writer session modified the same working
tree during L05 (app auth/battle files, pubspec, manifest, tests,
`docs/decisions/07-...`, plus untracked `app/integration_test/` and a new
account test). Those changes are preserved **uncommitted** and are not part of
the L05 commit; one writer per tree is required. Next: owner supplies the §0
inputs, then execute the packet; L04 human sessions remain the camera/media
gate and keep `ARENA_FEATURE_CAMERA_COUNTING=false`. Verdict stays **NO-GO**
(R9 signing is still the only artifact blocker).

## L04 packet complete — physical camera and media evidence BLOCKED — 2026-09-20

The L04 validation packet is written and verified, but the prescribed physical
protocol could not run: `adb devices -l` lists **no physical device**, and no
tester, observer or qualified form reviewer is recruited. The camera checklist
stays unsigned, the media release gate still fails by design (25 unreviewed
assets), and `ARENA_FEATURE_CAMERA_COUNTING` must stay **false**. R1, R7 and
R13 remain open. Exact missing resources are listed in
`qa/launch/l04/DEVICE_VALIDATION_PACKET.md` §10 and
`qa/launch/l04/MEDIA_REVIEW_PACKET.md` §7.

One release-path defect was found and fixed while preparing the packet: the
preparation demonstration rendered unreviewed instructional media even though
the manifest (`missing_media_policy.release_builds`) and the Python release
gate require unreviewed assets to be omitted. `battle_athlete_demo.dart` now
skips any asset whose `review_status` is not `approved` and falls back to the
documented placeholder (3 new regression tests; full suite **435/435**,
analyzer clean). No camera code was touched — no physical defect was
reproduced, so nothing was routed to the state machine and no threshold
changed.

A camera-enabled, release-equivalent validation APK was built and checked
(91 444 249 bytes, SHA-256
`53d6bafb5e17a53bbd3af74e3d9d441d68d02b6d58616b9285a2a68032ec8951`,
identity and artifact secret scan clean; debug-signed smoke artifact,
non-distributable). The packet fixes the device slots (low-end API 24–26, mid
API 30–32, flagship API 33+, Tensor checkpoint), the build hash, the scenario
counts (90 twenty-rep rounds / 1 800 observed reps + 18 variant rounds + 13
failure-path rows per device + heat, camera release and the pending L03
Keystore check), the unchanged pass thresholds and the evidence-capture
commands. Media hashes for all 25 assets were verified mechanically; no
signature was simulated. Full record: `qa/launch/l04/L04.md`. Next: schedule
devices/testers/reviewer and execute the packet; L05 may run as a parallel
coding track while L04 human sessions are arranged (one writer per tree).
Release verdict stays **NO-GO**: R9 (signing) remains the only artifact
blocker, and a camera-off demo is not a completed battle release.

## L03 complete — release scope enforced and sessions protected — 2026-09-20

`ARENA_FEATURE_RANKED_MATCHMAKING` now reaches `BattleController`: when it is
off (or camera counting is off) `startRankedSearch` refuses to queue from every
call site and the Battle tab replaces the ranked action with honest copy — no
queue seat, no camera-counted claim. **R11a is closed.** Camera, challenge,
push and preview gates were audited and the result-sharing factory guard with
its task-05 text fallback is preserved unchanged. Regression tests cover the
disabled path, alternate calls, preview receipt refusal and the UI states
(**431/431 Flutter tests**; analyzer clean).

Sessions and the PKCE verifier moved to **Android Keystore-backed storage**
(`flutter_secure_storage`, focused dependency) with a one-time migration that
removes the plaintext SharedPreferences copy only after the secure write
succeeds, fails sign-in closed with a plain `storage` message on secure write
failure, and clears both copies on logout and on successful account deletion
(a failed deletion keeps the session so retry works). Cloud backup is off
(`android:allowBackup="false"`). **R10 is closed on the code side**, pending
one physical-device Keystore/session-migration check in L04. Details and
evidence: `qa/launch/L03.md`.

Build-time flags are explicitly **not** remote kill switches: an audit of the
backend (`arena_queue_join`/`poll`, `arena_maintenance`, Edge actions) found no
operational global switch, so the smallest scoped server control (additive
`arena_controls` table + `AR021` refusal on queue entry, with pgTAP tests,
rollback and compatibility notes) is proposed in
`docs/decisions/07-matchmaking-incident-control-proposal.md` as **R15**; it was
not applied and needs an owner decision before launch.

Release re-verified with the new dependency: release-equivalent APK and
unsigned AAB build, bundle check (targetSdk 36, zipalign -P 16, ~19.6 MB
delivery), and a cold-start API 36 emulator smoke with a clean log (no
`MissingPluginException`/FATAL). Release verdict stays **NO-GO**: signing (R9)
remains the only artifact blocker. Next: L04 (device/camera evidence, including
the secure-storage path on real hardware); keep the L02 R8 keeps and re-run the
API 36/16 KB smokes after dependency changes.

## L02 complete — Android artifact on current Play requirements — 2026-09-20

The Android build now targets **API 36** (Play requirement since 2026-08-31)
and supports **16 KB page sizes** on a pinned, reproducible toolchain:
Flutter 3.47.5 / Dart 3.13.4, Gradle 9.3.1, AGP 9.1.0, Kotlin 2.4.0,
compileSdk/targetSdk 36, minSdk 24, installed in an independent SDK under
`D:\toolchains` (`D:\Kiro` untouched). A release **AAB path** exists locally
and in CI; the manual `release-candidate` job builds signed AAB + APK,
inspects the bundle (manifest, arm64, ELF/ZIP 16 KB alignment, delivery size,
upload-key pin) and never publishes. Delivery estimate for an arm64 API 36
device: **~19.5 MB** (bundletool; the old 307 MB debug APK is not a download
size). Full evidence: `qa/launch/L02.md`.

Fresh checks on the L02 tree: `flutter analyze` clean; 416/416 Flutter tests;
debug APK, release-equivalent APK (debug-signed smoke) and unsigned AAB build;
bundle check, identity checks and secret scans pass. The release APK was
smoke-tested on an **API 36 emulator** (edge-to-edge enforced, no crashes) and
on an **API 35 16 KB page-size emulator** (launches and stays resumed). Two
release-only R8 defects were found and fixed (Room/WorkManager and ML Kit
registrar constructors were stripped).

**Signing (R9) is now the only artifact blocker**: the AAB is unsigned and the
APK is debug-signed; both are explicitly non-distributable. Docs updated:
`docs/release/CONFIGURATION.md` (toolchain pins, the three certificate roles —
upload key vs Play app-signing vs local debug — used consistently for App
Links/OAuth), `docs/release/GO_NO_GO.md` (L02 note, R7/R2/R3 wording, new R14
built-in-Kotlin follow-up). Verdict stays **NO-GO** for distribution.
Next: L03 (feature gates + session storage); start from the L02 commit
(`3efdc07` is the L01 freeze; L02 is the first child commit). Do not reset or
clean this branch; keep the R8 keeps and re-run the API 36/16 KB smokes after
dependency or shrinker changes.

## L01 complete — baseline reconciled, reproduced and frozen — 2026-09-20

The tasks 01–11 implementation that existed only as modified/untracked files at
`bfaa6bd` is now captured in one scoped integration baseline commit:
**`3efdc07fe89536aca785b19833246f54f334c15a`** (357 files, +65 677/−105),
branch `codex/training-arena`. The tree is clean; build output, the emulator
AVD, raw screen captures and local secrets are preserved on disk but remain
gitignored.

Fresh checks on 2026-09-20 (separate from the dated 2026-09-18 counts): analyzer
clean; **416/416 Flutter tests**; 48 arena + 10 dispatcher Deno tests; 6
challenge-web + 48 prototype-smoke checks; prototype/challenge guards pass;
debug APK builds and passes identity/secret scans. `D:\Kiro` was untouched.
`supabase db reset`, `supabase test db --local` (pgTAP) and the HTTP e2e smoke
were blocked during the freeze edits (Docker engine down) and **passed in a
same-day verification pass** against freeze `3efdc07`: reset clean, pgTAP
184/184, HTTP smoke 16/16. Full evidence and exact commands:
`qa/launch/L01.md`.

Doc reconciliation: **R8 closed** by the freeze; **R11 split** — `R11a` ranked
flag is unused (consumer trace; L03 must wire it), `R11b` result sharing is
already enforced at `app/lib/arena_app.dart:136` with a completed entry-path
audit; `supabase/README.md` pgTAP count corrected to 184. Release verdict stays
**NO-GO** for distribution. Remaining work is unchanged: L02 Android/API 36/AAB,
L03 feature gates + session storage, L04 camera/device evidence, L05 hosting/
auth/links, L06 push/ranked, L07 store/privacy/deletion, L08–L10 candidate and
Play. Start the next task from `3efdc07`; do not reset or clean this branch.

## Launch execution authorized — 2026-09-20

The owner reports that the Google Play Console account has been created and
will handle recruitment of the 12 testers. Account verification, production
access and the closed-test start date are not yet evidenced. The owner has
authorized the coordinator to dispatch and manage coding tasks through OpenCode
using DeepSeek V4.1 Flash. Execute the launch closeout pack sequentially with
one writer, starting L01. This authorizes local implementation and verification;
it does not identify a hosted project/domain, signing material or public release
artifact. Physical camera devices and human form review remain required.

## Latest coordination assessment — 2026-09-20

The task-00 status below is historical. The implementation now includes tasks
01–11 and the release-readiness pass, largely as modified/untracked files at
HEAD `bfaa6bd`; it is not a frozen release candidate. Current release verdict
remains NO-GO. Read `docs/release/GO_NO_GO.md` and `qa/REPORT.md` for the
18 September evidence, then `docs/release/LAUNCH_PLAN_2026-09-20.md` for the
current audit, engineering/business/marketing assessment and conditional dates.

This coordination task inspected source and historical QA, verified the installed
OpenCode 1.18.31 model `opencode-go/deepseek-v4.1-flash` with a successful read-only
run, and produced `prompts/LAUNCH_CLOSEOUT_2026-09-20.md`. It changed no app code,
performed no deployment and created no social accounts. No app test suite was
rerun. Camera-ready in the historical emulator path used API calls and is not
physical counting evidence. Additional launch gaps include API 36/AAB delivery,
native push, the unused ranked flag, and store/privacy/deletion preparation.
Result sharing already has a factory gate; R11 needs a precise scope correction.

Owner inputs remain pending: Play account status, physical devices/testers,
social account identity/market, real domain/project and signing ownership.
Exact next step: execute L01 from the new prompt pack through OpenCode, preserve
the dirty implementation, reproduce its checks and establish a scoped baseline.

## Historical task-00 baseline

Date: 2026-09-17
Task: `00_RECONCILE_AND_BOOTSTRAP` (foundation)
Branch: `codex/training-arena`
Repository HEAD at task start: `02c2f2b`
Status: baseline complete and verified; see section 8 for evidence.

## 1. Verified starting state

- The split is in progress: the old FitBattle application, tests, assets,
  scripts, QA evidence and Supabase functions are **staged for deletion**
  (2063 paths), the old root docs and CI workflow are also deleted, and the
  new `app/`, `docs/`, `prompts/`, `supabase/` trees are untracked. No reset,
  restore or clean was run; that split is preserved exactly as found.
- `app/` contained only an Android/Flutter shell (no `pubspec.yaml`, empty
  `lib/` and `test/`), still carrying `com.fitbattle.fitbattle`, the
  `FitBattle` label, deep-link hosts, notification plumbing and comments.
- `docs/API.md` existed and already describes the arena Edge Function, objects,
  actions, match semantics and Elo rules.
- `supabase/migrations/20260917143538_arena_initial.sql` exists but is an
  empty (0-byte) placeholder. It is owned by task `04`.
- `backend/` and `qa/` are empty. `design/` and `prototype/` appeared as empty
  untracked trees while this task ran (another task starting). Task `00` did
  not touch them; task `01` owns them.

## 2. What task 00 established

- A minimal, buildable Flutter app on Android API 24+ with a pinned toolchain:
  Flutter 3.24.5 / Dart 3.5.4, Gradle 8.3, AGP 8.1.0, Kotlin 1.8.22,
  `flutter_lints` 4.0.0. No legacy screens or dependencies were copied.
- Application identifiers renamed end to end: application ID and namespace
  `app.trainingarena.mobile`, label `Training Arena`, Kotlin package
  `app.trainingarena.mobile`. The old `com.fitbattle.fitbattle` Kotlin source
  and runtime plumbing (rest-cue and session-key channels) were deleted.
- The base manifest keeps only `android.permission.INTERNET`. Notification
  permissions/receivers, the reminder drawable and their ProGuard keeps were
  removed (task `08` owns notifications). Challenge intent filters and deep
  link hosts were removed (task `05` owns links). No Firebase files or
  credentials were added.
- Dart foundation: three-tab shell with Battle selected by default, a config
  reader with safe placeholders, one color-token file, and the pure-Dart
  domain value objects (`ArenaExercise`, `ArenaMatchMode`,
  `ArenaMatchStatus`, `ArenaMatchOutcome`, `ArenaProfile`, `ChallengeContext`,
  `ResultReceipt`, `ArenaReceiptPlayer`).
- Contracts written: `docs/CONTRACT.md` (product + exact interfaces for tasks
  `01`-`11`) and `docs/decisions/0001-open-baseline-interface-decisions.md`
  (open owner decisions D1-D5).

## 3. Files owned and changed by task 00

Created:

- `app/pubspec.yaml`, `app/.gitignore`, `app/analysis_options.yaml`
- `app/lib/main.dart`, `app/lib/arena_app.dart`
- `app/lib/config/arena_config.dart`
- `app/lib/domain/arena_types.dart`
- `app/lib/theme/arena_tokens.dart`, `app/lib/theme/arena_theme.dart`
- `app/lib/shell/arena_shell.dart`
- `app/test/arena_shell_smoke_test.dart`
- `app/android/app/src/main/kotlin/app/trainingarena/mobile/MainActivity.kt`
- `docs/CONTRACT.md`, `docs/PROJECT_STATUS.md`,
  `docs/decisions/0001-open-baseline-interface-decisions.md`

Rewritten (de-branded):

- `app/android/app/build.gradle`, `app/android/app/src/main/AndroidManifest.xml`,
  `app/android/app/proguard-rules.pro`,
  `app/android/app/src/androidTest/AndroidManifest.xml`
- `app/android/app/src/main/res/values/colors.xml`,
  `app/android/app/src/main/res/values/styles.xml`,
  `app/android/app/src/main/res/values-night/styles.xml`,
  `app/android/app/src/main/res/drawable/launch_background.xml`,
  `app/android/app/src/main/res/drawable-v21/launch_background.xml`,
  `app/android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`,
  `app/android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml`
- `docs/API.md`: one deployment sentence now says "credentials from the
  previous application" instead of the old brand (the file previously
  contained the legacy name and failed the no-runtime-reference check).

Deleted from the new runtime:

- `app/android/app/src/main/kotlin/com/fitbattle/` (old activity)
- `app/android/app/src/main/res/drawable/ic_stat_reminder.xml` (legacy
  notification icon, unused after removing notification plumbing)

Untouched on purpose: `backend/`, `qa/`, `design/`, `prototype/`, `prompts/`,
`supabase/` (except no changes), and all staged deletions.

## 4. Intentionally deleted by the split (do not restore)

- `fitnessapp/` — 606 paths: the old Flutter application and its tests.
- `qa_shots/` — 1309 paths: old QA screenshots, logs, emulator dumps.
- `design/` — 72 paths: old design assets (new untracked `design/` is the
  arena replacement tree).
- `prompts/` — 31 paths: the old phase prompt pack (new untracked `prompts/`
  is the arena task pack).
- `supabase/` — 17 paths: old migrations/functions (new untracked `supabase/`
  holds the arena `docs/API.md`-aligned migration placeholder).
- `scripts/` — 8 paths: old audit/check scripts.
- `.github/workflows/ci.yml` — old CI workflow.
- Root documents: `README.md`, `handoff.md`, `SKILLS.md`, `STRATEGY.md`,
  `IDEAS.md`, `PROJECT_STATE.md`, `PROJECT_REVIEW.md`,
  `PRODUCT_SPEC_v2.md`, `PROMPTS_ROADMAP_V2.md`, `PHASE_PROMPTS.md`,
  `PROMPT_ENGINEERING_GUIDE.md`, `DESIGN_BRIEF_V3.md`,
  `PERFORMANCE_GUARDRAILS.md`, `COMPETITOR_TEARDOWN.md`,
  `IOS_READINESS.md`, `OPEN_QUESTIONS_ANSWERS.md`,
  `AUDIT_FITBATTLE_2026.md`, plus `.gitignore` and `eng.traineddata`.

These deletions are staged in the index; any commit of the baseline should
include them together with the untracked arena trees so the split is atomic.

## 5. Deferred to owning tasks

- Camera permission and pose tracking: task `03`.
- Challenge intent filters, custom scheme, App Links and landing page:
  task `05` (no link entries exist in the manifest yet).
- Notification permission, receivers and FCM: task `08`.
- Migration content, RPCs and RLS: task `04` (the migration file is empty).
- Release signing keystore and CI: tasks `11` (baseline falls back to debug
  signing when `android/key.properties` is absent).
- Brand mark/launcher icon replacement: task `01` (declared in D4).

## 6. Missing owner decisions

See `docs/decisions/0001-open-baseline-interface-decisions.md`:

- D1 real HTTPS challenge domain (currently `example.invalid`) — blocks `05`.
- D2 custom URL scheme name, if any — task `05`.
- D3 Supabase project and public anon key — task `04`.
- D4 brand mark replacement — task `01`.
- D5 avatar upload deferral — recorded, no action.

## 7. Environment used for verification

- Flutter SDK: the existing local toolchain
  (`<legacy-repo>\.tooling\flutter`, Flutter 3.24.5, Dart 3.5.4), invoked
  read-only as a tool; `PUB_CACHE` was pointed outside the legacy repository
  so no writes landed in it. No file in the legacy repository was edited.
- JDK: Temurin 17.0.20.1 (`<legacy-repo>\.tooling\jdk17`).
- Android SDK: `C:\Users\ADMIN\AppData\Local\Android\Sdk` (API 34 platform).
- `rg` is not installed on this machine; the no-runtime-reference check was
  run with the editor's ripgrep-based search plus a `Select-String` fallback.

## 8. Verification evidence (2026-09-17)

Run from `app/`:

| Command | Result |
| --- | --- |
| `flutter pub get` | resolved 26 dependencies, exit 0 |
| `flutter analyze` | `No issues found!` (3.2s), exit 0 |
| `flutter test` | 4/4 tests passed (shell order, Battle default, tab switching, token colors, config defaults) |
| `flutter build apk --debug` | `Built build\app\outputs\flutter-apk\app-debug.apk`, exit 0 |
| `aapt dump badging app-debug.apk` | `package: name='app.trainingarena.mobile'`, `sdkVersion:'24'`, `targetSdkVersion:'34'`, `application-label:'Training Arena'`, `launchable-activity: app.trainingarena.mobile.MainActivity` |
| no-runtime-reference scan | no legacy brand/package matches in `app/` or `docs/` outside this file |

## 9. Handoff

- Baseline commit: `7d4711e` (`chore(arena): establish Training Arena
  baseline`) on branch `codex/training-arena`, created from `02c2f2b` with
  owner approval. It carries the split deletions plus the task-00 shell.
- `design/`, `prototype/` and `qa/media/` stay untracked: other tasks created
  them after this task started and they commit their own work.
- Rebuild commands: from `app/`, `flutter pub get`, `flutter analyze`,
  `flutter test`; debug APK with
  `flutter build apk --debug` (JDK 17 on `JAVA_HOME`).
- Next: task `04` can fill the empty migration; task `01` can start from the
  frozen tokens; task `05` must wait for decision D1 before adding link
  filters. Tasks `02`, `03`, `06`-`09` can branch from the baseline now.

