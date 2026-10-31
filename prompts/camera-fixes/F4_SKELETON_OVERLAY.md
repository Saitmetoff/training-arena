# F4 — skeleton overlay on the camera preview (side and head-on)

Owner request (verbatim): "Can you also add skeleton tracking on the each
sideways and front head on camera too? you can just install and configure it
from github so if yes then add another prompt."

Depends on: F2 (view modes must exist). Sequential before F3. Estimate: 8–16 h.

Include the common preamble from `prompts/competitive/README.md` and read
`prompts/camera-fixes/README.md` first.

## Dependency premise — read this first

**No GitHub dependency is required, and adding one is rejected by default.**
The app already receives 33 on-device landmarks per frame from the ML Kit pose
bridge (`app/lib/camera/bridge/`, `pose/pose_types.dart`) and the rep counter
already consumes them. The missing piece is purely visual: draw what is
already in memory. A second detector (MediaPipe Tasks, TF.js-style ports or
any repo library) would duplicate detection, double the battery cost and
produce a second set of numbers that can disagree with the counter — the
overlay must show exactly what the counter sees.

If the executor believes a drawing helper is genuinely justified, it must
justify it in one line and it must not perform detection. Default answer: a
Flutter `CustomPainter`.

## Skills to load

- `tdd` — the coordinate mapping and the painter get tests before the UI.

## Required work

1. **Expose landmarks to the UI.** `CameraSession` currently hides the raw
   frames (the counter consumes them). Add a numbers-only seam — a landmark
   stream or a `latestFrame` accessor — that carries `PoseFrame` data already
   in memory: no copies retained, no images, no logging. Cover it with the
   existing fake bridge in `app/test/camera/`.
2. **`PoseSkeletonOverlay` widget** drawn over `CameraPreview`:
   - connects the standard landmark chains (shoulders/elbows/wrists,
     hips/knees/ankles, nose);
   - maps normalised landmarks onto the *displayed* preview: cover-fit,
     letterboxing, display rotation and, when the preview is mirrored,
     the horizontal flip. This mapping is a pure function and is unit-tested
     at the boundaries (0, 0.5, 1, mirrored, rotated);
   - draws nothing (and shows the existing guidance) when tracking is lost,
     when no landmarks exist, or when the preview texture is absent.
3. **View-mode aware (from F2).** Side view: highlight the counting chain —
   shoulder–elbow–wrist for push-ups, hip–knee–ankle for squats — and the
   primary joint. Front view: highlight the front-view signal chain. Meaning
   must not rely on colour alone: dim non-counting limbs so the active chain
   reads in grayscale too.
4. **Visibility.** Visible by default during the practice and counting phases
   of the camera flow, with a one-tap hide control on the camera card; the
   choice persists for the session. Colour only from `ArenaColors`.
5. **Performance.** Measure on the physical Redmi 10: camera frame rate and
   overlay paint cost with the skeleton on and off. If the overlay costs
   frames, throttle the painter — never the counter or the detector.
6. **Privacy.** Landmarks stay in memory; the overlay draws and forgets.
   Nothing is written, logged or exported (the debug trace flag belongs to
   F3, not here).

## Owned paths

`app/lib/camera/` (session API, preview area, overlay widget, types),
`app/test/camera/`, `docs/camera/`, `qa/competitive/f4/`.

## Must not

- Add a pose-detection dependency, or any dependency without an explicit
  one-line justification and owner-visible note.
- Change counting behaviour, thresholds or view detection (F2 owns those).
- Introduce a per-frame allocation storm: reuse paint objects in the painter.
- Touch the solo battle flow, ranked flags or release holds.
- Record, mirror-save or export any frame; no screenshots taken by the app.

## Acceptance

- Pure mapping function unit-tested (identity, cover, letterbox, mirror,
  rotation) and a widget test that paints from a synthetic session frame;
  empty/partial landmark frames paint safely.
- Existing side-view counter suite unchanged; `flutter analyze` and the full
  suite pass; no new dependency in `pubspec.yaml` or Gradle.
- On the physical Redmi 10: skeleton visible and correctly aligned in a
  side-view session **and** a head-on session; screenshots in
  `qa/competitive/f4/`; measured frame-rate impact reported.
- The overlay shows exactly the landmarks the counter consumes — if the
  counter and the drawing ever disagree, that is a bug, not a styling issue.

## Handoff

Standard handoff: mapping rules, the landmark seam added, measured overlay
cost, screenshots, and any alignment case that could not be verified on the
device.
