# L04 physical-device and camera validation packet

Prepared: 2026-09-20 · Repository: `D:/TrainingArena` · Branch:
`codex/training-arena` · Executor: OpenCode (`opencode-go/deepseek-v4.1-flash`)
Procedure: `docs/camera/CAMERA_QA.md` §4 · Result sheet:
`qa/camera/device_validation_checklist.md` · Status: **prepared, not executed —
BLOCKED on physical devices and human testers** (see §10).

This is the one packet a session coordinator needs. It fixes the device slots,
the build under test, every scenario with its human/device counts, and the pass
thresholds. The thresholds are copied from `docs/camera/CAMERA_QA.md` §4.3 and
must not be weakened to meet a date.

## 1. Roles and human count

| Role | Count | Must be | Does |
| --- | --- | --- | --- |
| Tester (athlete) | 3 | different body builds, able to perform 5×20 push-ups and squats with rest | performs the sets on the device under test |
| Human observer | ≥ 1 | attentive adult, not the tester | counts reps independently, records human vs device count |
| Session coordinator | 1 | owns the build, accounts and evidence | pairs testers, starts matches, fills the checklist, captures logcat |
| Media reviewer | 1 | certified strength coach, physiotherapist or equivalent trainer (`docs/media/FORM_REVIEW.md` §7) | reviews the instructional media; separate from the camera sessions |

The observer and the coordinator may be the same person only when no counting
happens during coordinator actions. The partner tester in a match is never also
the observer for the round being recorded.

**Consent and fatigue (binding):** each tester is told the purpose, that
participation is voluntary and can stop at any time, and that the camera
records nothing and uploads nothing. Rest ≥ 60 s between 20-rep rounds and
rotate testers between rounds; stop a tester at any sign of strain. Do not
schedule more than ~90 observed reps per tester per session or more than one
device slot per session day.

## 2. Device slots (device count = 4 minimum, 5 with the optional slot)

| # | Slot | Requirement | Purpose | Assigned device |
| --- | --- | --- | --- | --- |
| 1 | Low-end | physical device, API 24–26 | minSdk behaviour, detector performance | **unassigned — none attached** |
| 2 | Mid | physical device, API 30–32 | mainstream path | **unassigned — none attached** |
| 3 | Flagship | physical device, API 33+ | latest behaviour | **unassigned — none attached** |
| 4 | Tensor checkpoint | Pixel 6/6 Pro class, if the pilot targets it | known ML Kit beta5 native crash reports | **unassigned — none attached** |
| 5 | Optional | front-camera-only or camera-less device | error copy and installability | not required for the blocking gate |

Inventory check (2026-09-20, this machine): `adb devices -l` lists **no
physical device**; the only local targets are the emulators `TA_API36` (API 36)
and `TA_16K` (API 35, 16 KB pages). **Emulator runs are not physical accuracy
evidence** and may only be used for install/crash smoke checks, never for a
count comparison. If a slot device cannot be sourced, record it as missing and
do not substitute an emulator for the accuracy rows.

A device that cannot be sourced is a pilot-scope decision, not a threshold
change: either drop the affected Android band from the supported range and
re-run the remaining slots, or keep `ARENA_FEATURE_CAMERA_COUNTING=false`.

## 3. Build under test

| Field | Value |
| --- | --- |
| App source commit | `9d94ee4` + the L04 media-policy change (same commit as this packet; the packet itself is docs-only) |
| Build date | 2026-09-20 |
| APK | `app/build/app/outputs/flutter-apk/app-release.apk`, 91 444 249 bytes, SHA-256 `53d6bafb5e17a53bbd3af74e3d9d441d68d02b6d58616b9285a2a68032ec8951` |
| Build kind | release-equivalent, **debug-signed smoke artifact — non-distributable** (R9) |
| Identity check | `app.trainingarena.mobile 1.0.0+1 minSdk 24 targetSdk 36`, `check_artifact_identity.mjs` passed |
| Detector | ML Kit `com.google.mlkit:pose-detection:18.0.0-beta5`, base model (not accurate) |
| Camera stack | CameraX 1.4.1 |
| Runtime info | not surfaced on device by design; the values are compile-time constants in `ArenaCameraPlugin.kt` (`PoseAnalyzer.DETECTOR_SDK`/`DETECTOR_MODEL`, `ArenaCameraController.CAMERAX_VERSION`) plus `Build.VERSION.SDK_INT`/`Build.MODEL`. Record them from the source + `adb shell getprop` per device; the checklist row is filled with those values. |

Feature flags in this build (exact `--dart-define` set):

| Flag | Value | Why |
| --- | --- | --- |
| `ARENA_FEATURE_CAMERA_COUNTING` | `true` | the layer under validation |
| `ARENA_FEATURE_RANKED_MATCHMAKING` | `false` | ranked is out of scope (L06); friend challenges reach the same camera round |
| `ARENA_FEATURE_CHALLENGE_LINKS` | `true` | pairing path |
| `ARENA_FEATURE_RESULT_SHARING` | `true` | unchanged pilot scope |
| `ARENA_FEATURE_PUSH_NOTIFICATIONS` | `false` | no-push pilot |
| `ARENA_FEATURE_PREVIEW_FIXTURES` | `false` | never in a release build |

Build command (from `app/`, secrets never written to the repo; `<anon>` is the
local-stack public anon key, never a service key):

```powershell
$env:JAVA_HOME='D:\Kiro\.tooling\jdk17'
$env:PUB_CACHE='C:\Users\ADMIN\AppData\Local\Pub\Cache'
$env:GRADLE_USER_HOME='C:\Users\ADMIN\AppData\Local\GradleTA'
flutter build apk --release -PallowDebugSignedRelease=true `
  --dart-define=ARENA_SUPABASE_URL=http://127.0.0.1:54321 `
  --dart-define=ARENA_SUPABASE_ANON_KEY=<anon> `
  --dart-define=ARENA_FEATURE_CAMERA_COUNTING=true `
  --dart-define=ARENA_FEATURE_RANKED_MATCHMAKING=false `
  --dart-define=ARENA_FEATURE_CHALLENGE_LINKS=true `
  --dart-define=ARENA_FEATURE_RESULT_SHARING=true `
  --dart-define=ARENA_FEATURE_PUSH_NOTIFICATIONS=false `
  --dart-define=ARENA_FEATURE_PREVIEW_FIXTURES=false
```

A new commit, dependency, threshold or counter change invalidates this packet:
rebuild, record the new hash and restart the affected rows.

### 3.1 Test backend for the sessions

The only working backend today is the local Supabase stack (L01/L03; Docker,
`supabase_db_TrainingArena`). Physical devices are reached through USB:

```powershell
$adb='D:\toolchains\android-sdk\platform-tools\adb.exe'
& $adb reverse tcp:54321 tcp:54321          # repeat after every replug
& $adb install -r app\build\app\outputs\flutter-apk\app-release.apk
```

Each tester needs a signed-in account (email OTP; the code is read from the
local Inbucket at `http://127.0.0.1:54324`). A hosted backend is **not**
available until L05; a camera round needs two signed-in testers (friend
challenge), so a session must have two devices and two accounts even when only
one device slot is under test. The partner device may be any already-validated
slot; it is not part of that round's count comparison.

## 4. How one validated round is produced

1. Both testers sign in on their devices and join the same friend challenge
   (link or code).
2. Preparation shows the demonstration and the private camera preview. The
   designated tester completes the one unscored practice rep; the observer
   confirms framing.
3. The 60-second live round runs. **One observer counts one designated tester**
   for the whole round. The partner performs normally or rests; the partner's
   count is not recorded in that round.
4. At the end of the round the observer records: device count (from the app's
   confirmed count), human count, ±2 agreement, and any false positive
   (a counted rep with no human-observed complete down/up).
5. The next round starts with a fresh challenge (or the immediate rematch
   control). Alternate the designated tester between rounds.

A round whose device count is wrong must be kept in the sheet — do not discard
or re-run it into a clean sheet.

## 5. Scenario matrix and counts

### 5.1 Normal accuracy rounds — 90 rounds, 1 800 observed reps

| Group | Rounds | Per device | Devices | Human observers | Notes |
| --- | --- | --- | --- | --- | --- |
| Push-ups, 3 testers × 5 rounds of 20 | 45 | 15 | 3 | 1 per recorded round | floor-level side view |
| Squats, 3 testers × 5 rounds of 20 | 45 | 15 | 3 | 1 per recorded round | waist/chest-height view |

### 5.2 Variant rounds — 18 rounds (one per device per exercise)

| Variant | Rounds | Per device | Human count | Pass |
| --- | --- | --- | --- | --- |
| Fast touch-and-go, 20 reps | 6 | 2 | observer counts | must still count, or block per §6.1/§6.2 |
| 3-second bottom pause, until round end | 6 | 2 | observer counts | same |
| Step out of frame ~2 s mid-round, 20 reps | 6 | 2 | observer counts | rep split by loss is discarded; app shows a pause reason |

### 5.3 Failure paths — 13 checklist rows per device (bundled into ≤ 3 match cycles)

Rows are the table in `qa/camera/device_validation_checklist.md`: first-run
permission allow / deny / deny-again → Settings return; background mid-round;
lock screen; rotate; another camera app holds the camera; dark room; lens
covered; one limb out of frame; route exit; app-data inspection. Expected
behaviour per row is fixed there and in `CAMERA_QA.md` §4.2. The permission
rows need a fresh install (`adb shell pm clear app.trainingarena.mobile` or
reinstall) once per device.

### 5.4 Heat and camera release — added by L04

| Scenario | How | Record | Blocking |
| --- | --- | --- | --- |
| Sustained use / heat | 6 consecutive live rounds on the slot device without cooldown; record `adb shell dumpsys battery` (temperature) and `adb shell dumpsys thermalservice` (thermal status) before/after | temperature, thermal status, any dropped counting or crash/ANR | any crash, ANR or thermal shutdown blocks; a throttled but correct counter is a note, not a block |
| Camera release after route exit | leave the camera screen, then inspect `adb shell dumpsys media.camera` and the camera indicator | released within 2 s, no leak | leak blocks |

### 5.5 L03 Keystore / session-migration check (pending from L03)

On at least the low-end (API 24–26) and the flagship device:

1. Install the current build, sign in, confirm the session survives an app
   kill and a device reboot.
2. `adb shell run-as app.trainingarena.mobile ls -R` (debug build; use the
   debug APK for this row) and confirm no plaintext `arena.auth.session.v1`
   value is present in `shared_prefs`; the Keystore-backed store is used.
3. Migration: with the pre-L03 build signed in (plaintext session), install
   the current build over it and confirm the user stays signed in and the
   plaintext copy is gone after the first read.
4. Logout and account deletion clear the secure and legacy copies.
5. `adb shell dumpsys package app.trainingarena.mobile` confirms
   `allowBackup=false`.

## 6. Pass thresholds (verbatim from `docs/camera/CAMERA_QA.md` §4.3)

1. **No false positives:** zero counted reps without a human-observed complete
   down/up across all validation rounds. A single confirmed false rep blocks.
2. **Count agreement:** for at least 90 % of 20-rep rounds the device count is
   within ±2 reps of the human count, and the aggregate absolute error across
   all rounds is ≤ 5 %. Higher disagreement blocks.
3. **Pause transparency:** in 100 % of induced tracking-loss, low-light,
   camera-busy and no-person cases the app shows a reason plus a reframe action
   and does not keep counting.
4. **Lifecycle safety:** 100 % of background/lock/rotate/Settings-return cases
   either resume counting correctly or show a reframing instruction; no crash,
   ANR or stuck black preview.
5. **Privacy:** no frame, thumbnail or landmark artifact is found on disk or in
   network traffic during any round.
6. **Hardware risk:** no crash on the Tensor checkpoint device. If the beta5
   native crash reproduces, pin a different validated ML Kit version or drop
   the affected devices from the pilot before enabling counting.

No threshold may be relaxed, rounded or excluded to meet a date.

## 7. Evidence capture (reuse existing tools only)

| Evidence | Command / source |
| --- | --- |
| Build identity | `node tools/release/check_artifact_identity.mjs --apk <apk>` |
| Runtime info | source constants + `adb shell getprop ro.build.version.sdk` / `ro.product.model` |
| Per-round counts | `qa/camera/device_validation_checklist.md` tables |
| Logcat per scenario | `adb logcat -c` then `adb logcat -d > qa/camera/evidence/<device>_<scenario>.txt` |
| Camera release | `adb shell dumpsys media.camera` |
| Heat | `adb shell dumpsys battery`, `adb shell dumpsys thermalservice` |
| Disk/privacy | `adb shell run-as app.trainingarena.mobile ls -R` (debug build) |
| Screenshots | `adb exec-out screencap -p > qa/integration/screens/<device>_<scenario>.png` (gitignored) |

Raw text evidence (logcat, dumpsys) is attached under `qa/camera/evidence/`;
screenshots go to the gitignored `qa/integration/screens/` (the existing
convention). The checklist rows must cite the file names.

## 8. Session schedule and effort

| Block | Time |
| --- | --- |
| Per match cycle (challenge → prep → 60 s round → receipt) | ~4 min |
| Normal rounds per device (30 recorded rounds, 1 observer) | ~2 h + rest |
| Variant rounds per device | ~25 min |
| Failure paths + heat + release + disk per device | ~45 min |
| Install/setup/permission resets per device | ~20 min |
| Full matrix, split over ≥ 3 days (one device slot per day) | ~10–12 h session time |

This is consistent with the L04 estimate of 10–20 support/fix hours plus real
human availability. Do not compress the matrix into one day.

## 9. What is explicitly not evidence

- Emulator runs (`TA_API36`, `TA_16K`, `ArenaQA`) and their screenshots.
- The debug fixture (`CameraSession.debugFixture`, synthetic landmarks).
- Host unit tests under `app/test/camera/`.
- The task-02 demonstration loops and posters (instructional media, not a
  detector oracle).
- API-level "ready" calls or any other bypass of the camera counting path.

## 10. Blocked — exact missing resources

| Missing input | Needed for | Status |
| --- | --- | --- |
| 3 physical devices (API 24–26, API 30–32, API 33+) | every accuracy row | **none attached** (`adb devices -l` empty 2026-09-20) |
| Pixel 6/6 Pro-class Tensor device | §6.6 crash gate | not sourced |
| 3 testers + 1 human observer | every counted round | not recruited |
| Qualified form reviewer | media sign-off (R13) | not identified |
| Two signed-in accounts + USB-attached coordinator machine | match pairing | available locally once devices exist |
| Hosted backend (L05) | realistic network path; not required for counting | not available |

Until these exist, the camera gate (`qa/camera/device_validation_checklist.md`)
stays **unsigned** and `ARENA_FEATURE_CAMERA_COUNTING` stays **false** in any
pilot build. A camera-off demo is not a completed battle release.
