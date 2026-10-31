# Task 03 — implement on-device pose tracking and rep counting

You own the camera and counting layer for Training Arena. Work only in `D:\TrainingArena`; read `docs/CONTRACT.md` and the media spec. Do not implement server scoring, challenge links or screen navigation outside the camera feature. Preserve other work and never upload camera frames.

## Goal

Provide a testable camera session for push-ups and squats that counts reps locally, gives clear framing/form feedback and exposes a stable interface to the battle UI. Use Android API 24+ and an on-device pose detector such as Google ML Kit Pose Detection; document the exact version and limitations.

## Interface to implement

Create a Dart-facing `CameraSession` (or the existing contract’s equivalent) with:

- exercise: `pushups` or `squats`;
- permission states: unknown, granted, denied, permanentlyDenied;
- tracking state and user-facing instruction;
- `practiceComplete`, `reps`, `requestPermission`, `startPractice`, `beginRound`, `endRound`, `resetPractice`, `pause`, `resume`, `dispose`;
- events that include rep sequence, local monotonic timestamp, counter version and tracking confidence, never an image or raw frame.

Use a documented Flutter/native bridge. Preferred channel names are `trainingarena/device`, `trainingarena/pose`, and `trainingarena/cues`; adapt only through an interface note if the baseline chose another name.

## Counting behavior

- Require a stable full-body framing check before counting.
- Count a push-up only after a complete down/up transition with hysteresis, minimum dwell/debounce and confidence thresholds. Count a squat only after a complete down/up transition with the same protections adapted to joint angles.
- Pause the local counter when tracking is lost; keep the shared battle clock running. Show the player exactly why counting paused and how to reframe.
- Practice rep is unscored and must complete before ready. Resetting practice must not affect a match score.
- Competitive clients emit idempotent events (`event_id`, sequence, observed time, counter version); the server remains authoritative and may reject events.
- Never offer a manual competitive increment button. Offline demo mode must be labeled and cannot create a result.

## Privacy and lifecycle

Request camera permission in context, explain private on-device processing, handle denial/permanent denial and Settings return, rotate/lock lifecycle correctly, and release the camera/detector on route exit. Do not persist frames, thumbnails or biometric landmarks beyond the active session. Respect low-light and no-camera errors with actionable copy.

## Tests and evidence

- Unit-test the push-up and squat state machines with noisy landmark fixtures: full rep, partial rep, jitter, tracking loss, duplicate event and resume.
- Add bridge tests for permission, pause/resume and disposal.
- Add a deterministic debug fixture path that is visibly non-competitive; do not use it to claim device accuracy.
- Document physical-device validation steps and a threshold for blocking release. A generated 3D animation is a visual aid, not a detector test oracle.

Acceptance means the battle feature can consume a stable counter interface, frames never leave the device, and all uncertain accuracy claims are explicitly listed in `docs/media/FORM_REVIEW.md` or a camera QA note.

