# F3 device session — run sheet (owner or executor with the phone)

Prepared 2026-09-24 · Status: **not executed — no phone attached to the
executor environment** (`adb devices -l` lists emulators only).

## Builds (both non-distributable test builds, camera + solo + trace on)

| Build | Use it for | Size | SHA-256 |
| --- | --- | --- | --- |
| `TrainingArena-f3-trace-debug.apk` | **recommended**: install and pull traces with `adb` (debuggable, so `run-as` works) | 222 378 595 B | `A7F690AC2C61C685FB45253F727448E99EE58499A030F3BBC73FB68C358869A6` |
| `TrainingArena-f3-trace.apk` | the F1–F4 code as a debug-signed release build; traces leave through the share sheet | 91 140 003 B | `8031DB1E0106A7D2C94F9B99F97CCC36EE6F399523EC02CA800A2213CC97B58A` |

Both live in `app/build/app/outputs/flutter-apk/`. The debug build's Dart runs
in JIT mode; the counter logic and the native ML Kit detector are identical,
so the trace is the same landmark stream. The release build is the closer
match to shipping behaviour if you prefer it.

```powershell
adb install -r app\build\app\outputs\flutter-apk\TrainingArena-f3-trace-debug.apk
adb shell pm grant app.trainingarena.mobile android.permission.CAMERA
```

(The trace flag is never enabled in a release build; the release-hold check
pins it `false` in the workflow.)

## Before each scenario

1. Battle tab → **Solo set** → **Count with camera**.
2. Do the one practice rep (unscored) and wait until the instruction says the
   framing is locked.
3. Start the scenario. When it is done, tap the **share icon** on the camera
   card (the `TRACE ON · <frames>` label is next to it) **before** ending the
   set. The share sheet opens with
   `trace-<exercise>-<YYYYMMDD-HHMMSS>.txt`; send it to yourself (mail, Drive,
   etc.) and save it into `qa/competitive/f3/incoming/`.
4. Write down, in the table below, the file name and the rep count the app
   showed. The file itself carries `# exercise:` and `# in_app_reps:` comments.
5. The ring keeps the **last 180 seconds**, so export right after the
   scenario. The trash icon deletes exported traces and clears the window.

## Scenarios (record one trace per row)

| # | Exercise | Placement | Scenario | File name | In-app reps |
| --- | --- | --- | --- | --- | --- |
| 1 | push-ups | side | 20 clean reps, natural pace | | |
| 2 | push-ups | head-on | 20 clean reps, natural pace | | |
| 3 | push-ups | side | 5 deliberately shallow (half-depth) reps | | |
| 4 | push-ups | side | 10 s phone handling, body still (shake) | | |
| 5 | push-ups | side | one rep with a hand or leg out of frame ~1 s mid-rep | | |
| 6 | push-ups | side | one sagging-body rep | | |
| 7 | push-ups | side | walk into frame, hold, walk out | | |
| 8 | squats | side | 20 clean reps, natural pace | | |
| 9 | squats | side | 5 deliberately shallow reps | | |
| 10 | squats | side | 10 s shake, body still | | |
| 11 | squats | head-on | expect the "turn side" copy, no count | | |

With the skeleton visible (F4), also capture one screenshot per placement
(side push-ups, head-on push-ups, side squats) into `qa/competitive/f3/` and
note any joint that does not sit on the body.

## After the session

The executor (or a later chat) turns each trace into evidence:

1. Copy the file into `app/test/camera/fixtures/` renamed as
   `redmi10_<yyyy-mm-dd>_<exercise>_<scenario>.txt` (keep the numbers intact).
2. Add a replay case to `app/test/camera/fixture_replay_test.dart`:

   ```dart
   test('redmi10 head-on 20 clean reps matches the in-app count', () {
     final counter =
         RepCounter(ExerciseCounterProfile.forExercise(ArenaExercise.pushUps));
     final fixture =
         loadPoseFixture('redmi10_2026-09-24_pushups_front_clean20.txt');
     final summary = replay(counter, fixture.frames);
     expect(summary.countedReps, 20); // must equal the trace's in_app_reps
   });
   ```

3. If the in-app and replayed counts disagree, that is a bug: report it with
   the trace name; never average it away and never edit the trace.
4. Update `qa/competitive/c05/DEVICE_INPUT_LIST.md` with the measured values
   (old → new, trace name, scenarios that stay green) and
   `qa/camera/device_validation_checklist.md` with the rows actually executed.

## Optional: pull the traces with adb instead of the share sheet

On the debug build above (debuggable), the traces can be pulled directly —
no share sheet, no interruption:

```powershell
New-Item -ItemType Directory -Force qa\competitive\f3\incoming | Out-Null
adb shell run-as app.trainingarena.mobile ls app_flutter/camera-traces | ForEach-Object {
  $name = $_.Trim()
  if ($name) {
    cmd /c "adb exec-out run-as app.trainingarena.mobile cat app_flutter/camera-traces/$name > qa\competitive\f3\incoming\$name"
  }
}
```

`cmd /c` keeps the file bytes exact (PowerShell's `>` would rewrite them as
UTF-16). You can also tap Export on the camera card on either build and use
the share sheet; the file is identical.
