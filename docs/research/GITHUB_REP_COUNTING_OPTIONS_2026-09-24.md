# Open-source rep-counting options for the camera — 2026-09-24

Research: 2026-09-24 · OpenCode (`opencode-go/deepseek-v4.1-flash`) ·
Status: **DRAFT, uncommitted, research only.** No source, config, test or
release file was changed. Nothing here changes `docs/CONTRACT.md`,
`docs/PROJECT_STATUS.md` or any release scope; this adds no status section.
Sources checked on 2026-09-24 unless stated. Star counts and publish dates
move; they are snapshots, not guarantees.

Evidence labels:

- **[V]** verified from the cited primary page (repo, official doc, pub.dev
  API) on 2026-09-24.
- **[E]** estimate or secondary write-up; directionally useful, not audited.
- **[I]** inference from the code/config read in this pass, not externally
  verified.

Baseline read for this note: `app/android/.../PoseAnalyzer.kt` (ML Kit
`pose-detection:18.0.0-beta5`, base model, STREAM_MODE, 640×480, 66 ms
throttle), `ArenaCameraController.kt` (CameraX 1.4.1, no `ViewPort`, preview
aspect not pinned), `app/lib/camera/counter/rep_counter.dart` (framing gate:
13 landmarks at in-frame likelihood ≥ 0.55, body span 0.35–0.98, 500 ms stable
framing), `exercise_profile.dart` and `pose_math.dart` [I].

## 0. Headline

**No open-source package fixes what was observed on the Redmi 10, because the
failure is physical: the athlete's head/feet were outside the analysis frame,
and no model can see pixels the lens never captured.** ML Kit documents this
exactly — when a person is not completely inside the image, the missing
landmarks get coordinates outside the frame and low InFrameConfidence values
[V], and our gate then rejects them by design. Every credible alternative
(MediaPipe Pose Landmarker, MoveNet, YOLO-pose) is either the same BlazePose
model family with the same constraint, a downgrade in landmarks, or a
server/GPU research model that cannot run live on a Helio G88. The only
genuine fix set is ours: stop requiring the whole body before counting, tell
the athlete how far back to stand, and make the camera see as wide as the
preview shows. Switching detector is at best a lateral move that buys
segmentation masks and world landmarks (MediaPipe Tasks, Apache-2.0), not
framing tolerance.

## 1. Comparison

| Candidate | Snapshot (checked 2026-09-24) | Licence | Platform / integration | How reps are counted | Fixes the Redmi 10 failure? |
| --- | --- | --- | --- | --- | --- |
| Current stack (baseline) | in tree | n/a | Kotlin CameraX 1.4.1 + ML Kit pose base 18.0.0-beta5 → EventChannel → Dart FSM | angle bands + head-on signal + framing gate | — (this is what failed) |
| `google_mlkit_pose_detection` Flutter plugin | v0.16.1, published 2026-08-17, 82 likes, 17.6k downloads/30d [V] | MIT (monorepo) [V] | Dart plugin, Android/iOS, wraps the same ML Kit 18.0.0-beta5 [V] | nothing — detector only | No; same model, and adopting it means replacing the native camera pipeline |
| MediaPipe Pose Landmarker (Tasks, Android) | `tasks-vision` latest 1.0.0 on Google Maven [V]; repo 37,068★, Apache-2.0, pushed 2026-09-24 [V] | Apache-2.0 repo [V] | Maven AAR in our existing Kotlin controller | nothing — detector only | No; same BlazePose family, same crop limit. Buys GPU delegate, world landmarks, optional segmentation |
| Flutter MediaPipe wrappers: `flutter_mp_pose_landmarker` | v0.1.9, published 2026-08-12, 6 likes, 115 dl/30d [V]; repo licence NOASSERTION [V] | unclear (NOASSERTION) [V] | Kotlin/EventChannel + own CameraX, Android/iOS | none | No; also unlicensed for commercial use |
| `flutter_pose_detection` | v0.4.1, published 2026-01-01, 1 like, 103 dl/30d [V]; README requires Android API 31+ [V] | per pub.dev page [V] | native MediaPipe Tasks path | none | No; minSdk 31 conflicts with our minSdk 24 |
| `live_pose_detector` (Dashstack) | v0.0.1, published ~2026-08, 1 like, 69 dl/30d [V] | MIT [V] | Flutter widget: camera plugin + `google_mlkit_pose_detection` | push-up FSM, calibration + form rules [V] | No; same model. Push-ups only; replaces our whole preview pipeline |
| MoveNet via TF Lite (tensorflow/examples Android demo) | repo 8,279★, Apache-2.0, pushed 2026-08-31 [V]; models on Kaggle [V] | Apache-2.0 repo / model terms on Kaggle [V] | TFLite + own camera, 17 keypoints [V] | none (demo shows landmarks) | No; fewer landmarks (17), same person-crop limit |
| ML Kit k-NN pose classifier (docs + quickstart) | `googlesamples/mlkit` 4,296★, Apache-2.0, pushed 2026-07-21 [V] | Apache-2.0 [V] | Android (Java/Kotlin), works on ML Kit landmarks | k-NN on normalised landmark distances, ~100 samples/class [V] | No; needs the same visible landmarks. Counting accuracy is a different problem than framing |
| RepNet (`google-research/google-research/repnet`) | repo 38,825★, Apache-2.0, pushed 2026-09-23; folder is README + Colab only [V] | Apache-2.0 repo [V] | Colab/TF, video-level, not on-device [V] | class-agnostic period estimation (ResNet + temporal self-similarity) [E] | No; not real-time on a phone |
| ESCounts / RepCount / Countix (research) | ESCounts 32★, MIT, pushed 2024-12-18 [V]; datasets academic-use [V] | MIT repo; dataset academic [V] | PyTorch research code | learned video correspondence | No |
| Community rep counters (giaongo/RepDetect 32★, abishekvashok/Rep-Counter 67★, GC_Fit 1★, RepQuest 0★, squat-counter 0★, PostureAI 0★, ironeye 2★, rep-sensor 0★, rep-counter 1★) [V] | all pushed 2021–2026, mostly Python/JS webcam demos; Android ones ~2023 [V] | mixed (Apache-2.0/MIT/some none) [V] | none reusable in a Flutter Android app as a package | angle FSMs, same idea as ours | No |
| "Get in frame" coaching as a library | **none found** [V] | — | — | — | — (it is product logic, not an OSS package) |

## 2. Candidate notes

### 2.1 MediaPipe Pose Landmarker (Tasks) — the only credible detector swap

- Official Android guide: `com.google.mediapipe:tasks-vision`, model asset
  (`pose_landmarker_lite/full/heavy.task`), LIVE_STREAM mode, 33 landmarks,
  world landmarks in metres, optional segmentation mask, CPU/GPU delegate
  [V] (https://developers.google.com/edge/mediapipe/solutions/vision/pose_landmarker/android).
- Latest `tasks-vision` release on Google Maven is 1.0.0 [V]
  (https://dl.google.com/android/maven2/com/google/mediapipe/tasks-vision/maven-metadata.xml).
- Model input sizes: detector 224×224, landmarker 256×256 (lite/full/heavy)
  [V] (https://developers.google.com/edge/mediapipe/solutions/vision/pose_landmarker).
- Repo: 37,068★, Apache-2.0, actively pushed [V]
  (https://github.com/google-ai-edge/mediapipe). Samples:
  `mediapipe-samples/examples/pose_landmarker/android`, 2,840★, Apache-2.0,
  pushed 2026-09-15 [V]
  (https://github.com/google-ai-edge/mediapipe-samples/tree/main/examples/pose_landmarker/android).
- **What it would replace:** our ML Kit detector only; our counter, camera,
  profiles and EventChannel stay. Effort is a native swap (~2–4 days with
  replayed-trace validation) because we already own the CameraX controller.
- **What it adds:** GPU delegate option, lite/full/heavy accuracy-speed
  choice, segmentation mask (could drive a ghost-silhouette framing overlay),
  real-world coordinates.
- **Verdict:** would **not** have fixed the Redmi 10 failure. Same model
  family, same physics; a landmark outside the frame is still absent.

### 2.2 The official-ish ML Kit Flutter plugin

- `google_mlkit_pose_detection` v0.16.1, published 2026-08-17, 82 likes,
  17,587 downloads/30d, publisher `flutter-ml.dev` — a community
  organisation, not Google [V] (https://pub.dev/packages/google_mlkit_pose_detection).
- It wraps exactly the versions we already run: `android/build.gradle`
  declares `com.google.mlkit:pose-detection:18.0.0-beta5` and
  `pose-detection-accurate:18.0.0-beta5` [V]
  (https://raw.githubusercontent.com/flutter-ml/google_ml_kit_flutter/master/packages/google_mlkit_pose_detection/android/build.gradle).
  Monorepo: 1,281★, MIT, pushed 2026-09-14 [V]
  (https://github.com/flutter-ml/google_ml_kit_flutter).
- **Verdict:** zero accuracy or speed change and it would force our native
  camera/preview work through the `camera` plugin. The current bridge is
  ~250 lines of Kotlin; it is not the cost centre.

### 2.3 Flutter MediaPipe wrappers — all small, none worth adopting

- `flutter_mp_pose_landmarker` v0.1.9 (2026-08-12), 6 likes, 115 dl/30d;
  repo `mohammed893/flutter_pose_mediapipe` is 7★ and shows **NOASSERTION**
  licence [V] — a commercial blocker on its own. Architecture (CameraX +
  EventChannel) is close to ours, which is a hint that the community has not
  found a shortcut past the native work.
- `kwon_mediapipe_landmarker` v0.0.3 (2026-02-02), 1 like, 29 dl/30d, minSdk
  24, reports ~12–15 FPS face+pose on a Snapdragon 8 Gen 3 [V]
  (https://pub.dev/packages/kwon_mediapipe_landmarker).
- `flutter_pose_detection` v0.4.1 (2026-01-01), 1 like, 103 dl/30d; its
  Android path documents **API 31+** [V] (https://pub.dev/packages/flutter_pose_detection)
  — incompatible with minSdk 24, and it brings its own camera.
- `live_pose_detector` v0.0.1 (published ~2026-08), 1 like, 69 dl/30d, MIT,
  is the only package found that ships a **rep counter** (push-ups only,
  `PushUpFormDetector`, calibration + debounce) on top of ML Kit [V]
  (https://pub.dev/packages/live_pose_detector). One month old, one like, no
  CI on a real device, push-ups only — not something to put a commercial set
  count behind.
- **Verdict:** none fixes framing; adopting any of them replaces working
  native code with a less mature dependency.

### 2.4 MoveNet and the TF Lite Android demo

- The Android demo lives in `tensorflow/examples/lite/examples/pose_estimation`
  (repo 8,279★, Apache-2.0, pushed 2026-08-31 [V]); models are downloaded from
  Kaggle (MoveNet Lightning/Thunder/MultiPose) [V]
  (https://github.com/tensorflow/examples/tree/master/lite/examples/pose_estimation/android).
- MoveNet detects **17 keypoints** vs BlazePose's 33; TFJS docs state this
  directly [V]
  (https://github.com/tensorflow/tfjs-models/blob/master/pose-detection/README.md).
  `tfjs-models`: 14,813★, Apache-2.0, pushed 2026-06-23 [V].
- **Verdict:** a downgrade for us (no foot landmarks, no world coordinates,
  same person-crop constraint) and it would mean adding `tflite_flutter`
  plus our own preprocessing. Rejected.

### 2.5 Learned classifiers that are compatible with our existing detector

- Google documents a k-NN pose classifier over ML Kit landmarks, with a
  probability-threshold state machine for repetition counting, and ships the
  reference processor in the ML Kit quickstart app [V]
  (https://developers.google.com/ml-kit/vision/pose-detection/classifying-poses).
  ~100 samples per pose class are the documented minimum [V].
- **What it would change:** replace `enterBottomAngle`/`exitBottomAngle`
  thresholds with learned "up/down" class probabilities — genuinely more
  robust to camera angle and body shape than fixed angles.
- **Verdict:** does **not** fix the observed failure. It consumes the same
  landmark stream, so a body outside the frame is still unusable, and it adds
  a data-collection pipeline. Park it as a post-launch counting-quality idea.

### 2.6 Video repetition-counting research (RepNet, ESCounts, datasets)

- RepNet lives in `google-research/google-research/repnet` and is distributed
  as a Colab notebook only [V]
  (https://github.com/google-research/google-research/tree/master/repnet);
  it is a video-level, class-agnostic period estimator (CVPR 2020 paper:
  ResNet frame encoder + temporal self-similarity matrix) [E]
  (https://research.google/blog/repnet-counting-repetitions-in-videos/).
  The repository is 38,825★ because it hosts all of Google Research — that
  number is not RepNet's [V].
- ESCounts is research PyTorch code, 32★, MIT, last pushed 2024-12-18 [V]
  (https://github.com/sinhasaptarshi/EveryShotCounts); RepCount is an
  **academic-use** dataset [V] (https://svip-lab.github.io/dataset/RepCount_dataset.html).
- **Verdict:** not on-device, not real-time, not a rep event source we can
  ship. Rejected.

### 2.7 Community rep counters — demos, not dependencies

Snapshot from the GitHub API on 2026-09-24 [V]: `giaongo/RepDetect` (Android
Kotlin + ML Kit, 32★, Apache-2.0, last push 2023-12-11),
`SurajKRB/RepDetect` (9★, same date), `abishekvashok/Rep-Counter` (Python,
67★, 2021), `devsharmagit/ironeye` (JS, 2★, 2026-03), `dimsedra/squat-counter`
(Python, 0★, 2026-07), `TheUnknown550/GC_Fit` (Python, 1★, 2025-10),
`kbhavake29/PostureAI` (Android Kotlin, 0★, no licence, 2025-10),
`anshkamkhalia/repquest` (React Native, 0★, MIT, 2026-06),
`matua-agent/rep-sensor` (browser, 0★, 2026-02),
`CybertronianKelvin/rep-counter` (TS lib, 1★, no licence, 2026-05),
`NazarKozak/RepCounterSDK` (Swift/iOS, 5★, MIT, 2026-06). Every Android entry
is an app, not a published package; each would have to be copied and
maintained. **Verdict:** nothing to adopt.

Also checked, nothing usable: `pushupcount` on pub.dev (v0.0.6, ~2 years old,
**BSL-1.0** licence [V] — not permissive), QuickPose's iOS-only commercial SDK
demo [V], and the pub.dev searches for `rep counter`, `pose exercise`,
`workout pose` (top hits are icons/step-counters) [V].

### 2.8 Framing/positioning guidance

Searched for pose-template/ghost-silhouette/"get in frame" open source: no
maintained project found [V]. The products that advertise it (e.g. ShapeUp:
"Set it 6–10 feet away, side-on or facing you ... get in frame"; Busy Dad's
Auto Tracking) are closed-source apps, not libraries [V]
(https://getshapeup.app/). This is UI logic built on landmark span and
missing-landmark checks — the same signals our counter already computes.

## 3. What no library fixes — the physical framing constraint

1. ML Kit's own documentation: "If the person was not completely inside the
   image, the model assigns the missing landmarks coordinates outside the
   frame and gives them low InFrameConfidence values" [V]
   (https://developers.google.com/ml-kit/vision/pose-detection/android). That
   is exactly what the Redmi 10 reported: the body was larger than the frame
   (span > 0.98) and the head/feet were not in it. Our gate requires 13
   landmarks at ≥0.55 and rejects the frame — correctly.
2. The same page requires the subject to be at least 256×256 px and as large
   as possible in the image [V]. Google is explicit that the API wants the
   whole person in shot; no model in this class accepts a body that does not
   fit, because the missing pixels simply do not exist.
3. Model swaps do not change this: MediaPipe, MoveNet and YOLO-family
   landmarkers all infer from the same image. Buying segmentation masks
   (MediaPipe) does not create FOV.
4. The only real levers are optical/UI, not ML:
   - point the phone farther away, or lower/closer to the floor for push-ups;
   - wider lens: CameraX can zoom out below 1.0 only if the device exposes
     the ultra-wide in the logical camera (`ZoomState.minZoomRatio < 1.0`);
     model-dependent and must be probed on the Redmi 10 [I];
   - make sure the analysis frame is not cropped more tightly than the
     preview — our `ImageAnalysis` is 640×480 (4:3) with no `ViewPort`, while
     the preview aspect is chosen by the display; CameraX documents `ViewPort`
     as the coordinate space that keeps use cases on the same crop
     (https://developer.android.com/reference/androidx/camera/core/ViewPort,
     page not fetched directly in this pass; secondary description
     https://medium.com/@ramadan123sayed/camerax-in-jetpack-compose-the-complete-guide-preview-photo-capture-video-recording-a737fac5caf6).
     If the F4 skeleton overlay draws a neck/ankle at the edge of the screen
     while the athlete sees their whole body, that is the first thing to
     check — it is a bug we can fix, unlike a body that is genuinely out of
     shot.
5. And our own gate is stricter than the model needs. For a side-view
   push-up the count signal is shoulder–elbow–wrist; for squats it is
   hip–knee–ankle. Ankles, feet or nose being out of frame do not have to
   block counting as long as the chain that carries the signal is visible and
   above threshold. The 500 ms whole-body lock and the hard `tooClose` state
   are our choices, not constraints of ML Kit.

## 4. Recommendations, ranked by effort

1. **Keep the current counter and make framing non-blocking (~0.5–1 day, no
   new dependency).** Count when the landmarks the signal actually uses are
   visible (side-view push-up: shoulder/elbow/wrist; squat: hip/knee/ankle)
   instead of gating on all 13 landmarks; keep a soft "you are close to the
   camera" cue driven by body span but never let it lock counting while the
   signal landmarks are good; keep the 0.98 span as a coaching hint only.
   Validate against the F3 trace plus the synthetic fixtures already in
   `app/lib/camera/debug/synthetic_pose.dart`. This is the change that would
   have unblocked the observed session if the hands/knees were in frame.
2. **Camera + guidance pass (~1–2 days, needs the Redmi 10).** Add a
   `ViewPort`/`ResolutionSelector` so analysis sees exactly what preview
   sees; probe `minZoomRatio` for ultra-wide zoom-out; raise preview/analysis
   to the same aspect. Then make the on-screen coach actionable: a body-span
   meter with a target band, a "prop the phone further back / lower" line
   specific to the exercise, and a first-run placement screen. This attacks
   the physical cause directly.
3. **Optional detector swap to MediaPipe Pose Landmarker (~2–4 days).** Only
   if we want the segmentation mask for a ghost-silhouette placement overlay
   or GPU headroom on low-end devices. Apache-2.0, Maven AAR, keeps our
   counter and camera. It will not count a body that is out of frame.
4. **Do not adopt** the Flutter wrappers (`live_pose_detector`,
   `flutter_mp_pose_landmarker`, `flutter_pose_detection`,
   `kwon_mediapipe_landmarker`), MoveNet/TFLite, the community repos, the
   k-NN classifier or RepNet for this problem. Reasons and snapshots are in
   §2.

Method and limits: repo metadata via the GitHub API, Google Maven metadata,
the pub.dev API and official Google/ML Kit/MediaPipe docs on 2026-09-24; the
CameraX `ViewPort` reference page and `developer.android.com` were not
reachable from this session and are cited by URL only; no Redmi 10 hardware
was available for this pass, so §3's camera-side checks are labelled [I] and
need a device session.
