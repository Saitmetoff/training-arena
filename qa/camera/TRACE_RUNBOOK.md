# Owner diagnostic camera trace session — 23 October 2026

Physical validation is PENDING. Synthetic fixtures and the Android emulator are
functional evidence only. Use both new owner builds for friend battles.

1. Work in `C:\Users\ADMIN\.codex\worktrees\ec95\TrainingArena`, never the saved checkout.
   Identify each attached physical phone with `rtk proxy D:\toolchains\android-sdk\platform-tools\adb.exe devices -l`.
   Inspect existing version/signature and preserve history before replacing an install.
2. Set public client environment values from `app/.env.owner-acceptance.json`:
   ARENA_SUPABASE_URL, ARENA_SUPABASE_ANON_KEY and
   ARENA_AUTH_REDIRECT_URL=trainingarena://challenge/auth. No admin key belongs here.
   Run the actual backend camera/tracing path:

```powershell
rtk proxy powershell -NoProfile -File tools/run-dev.ps1 -Mode Backend -EnableCameraCounting -EnableCameraTrace -Device <serial>
```

   This is a debug build with fixtures/ranked/push off. For deterministic squat
   diagnostics add `-DiagnosticSoloExercise squats`. The override requires debug
   plus tracing; release/trace-off builds ignore it. Labels, saved results and
   personal bests retain the actual exercise. Friend exercises stay server-selected.
3. Battle → Solo set → Count with camera. Use side-on, upright floor placement
   and bright light. Complete the unscored practice rep and wait for framing.
   Test 2 m and 3 m independently, including crop without losing the signal chain.
4. Have a second person record actual completed reps, shallow/bounce/sag/collapse
   attempts, lighting, phone/Android, build/hash and counter version 1.3.0.
5. **End the set/round first.** The session freezes its numeric trace at the end.
   On the result screen tap Export landmark trace, then save the text locally.
   No export/delete is enabled during a scored round; background/reconnect does
   not end the trace. Recording survives replacement of the preview widget.
   The ring retains 180 seconds; export promptly before starting a new practice.
   Exports contain numeric landmarks/timestamps and counters, no camera images,
   audio, account values or device IDs. Sharing is voluntary; nothing uploads
   automatically. Delete exported traces with the diagnostic delete control.

| Scenario at each distance | Observer reps | In-app reps | Trace filename |
| --- | --- | --- | --- |
| 20 slow push-ups | | | |
| 20 normal push-ups | | | |
| 20 fast push-ups | | | |
| Shallow/bounce/sag/collapse attempts | | | |
| 20 normal squats | | | |
| Background/resume and tracking loss | | | |

6. From the worktree `app` directory replay an unedited trace:

```powershell
rtk proxy cmd /c D:\toolchains\flutter-3.47.5\flutter\bin\flutter.bat test test/camera/trace_replay_test.dart --dart-define=POSE_TRACE_PATH=<absolute-trace-path> --dart-define=POSE_TRACE_EXERCISE=pushups --reporter expanded
```

   For squats use POSE_TRACE_EXERCISE=squats. The replay consumes
   round_start_after_us and pause/resume markers, primes framing with unscored
   lead-in and resets the counter at the actual round boundary. Practice reps
   are excluded. A truncated lead-in fails agreement instead of implying a pass.
   Compare replay/in_app_reps/observer counts separately. Investigate every
   mismatch; do not edit traces or average away failures.
7. Record actual evidence in the existing device checklist and
   `qa/camera/beta_device_results.json`. Keep it blocked until real devices meet
   the acceptance criteria and the owner accepts them. See
   `docs/release/OWNER_ACCEPTANCE_2026-10-22.md` for the locked requirements.
