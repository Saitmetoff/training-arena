# Demonstration form review

Status: **pending human review — no asset in this package is approved.**
Owner: task `02` (media) · Approver: a qualified human reviewer (see §7)
Release effect: while any row below is unchecked, the release gate
(`python qa/media/tools/validate_media_package.py --gate release`) fails and
release builds must omit the media and render the manifest placeholder.

Reviewer kit (open these before judging):

| Artifact | Path |
| --- | --- |
| Same-athlete check | `qa/media/identity_strip.png` |
| Start/mid/end comparison, both exercises | `qa/media/contact_sheet_athlete.png` |
| Annotated fallback posters | `qa/media/contact_sheet_posters.png` |
| Loop key frames (what the video shows) | `qa/media/loop_keyframes_pushup.png`, `qa/media/loop_keyframes_squat.png` |
| 360 dp legibility proof | `qa/media/legibility_360dp.png` |
| GLB vs pipeline render | `qa/media/glb_roundtrip_check.png` |
| Machine checks | `qa/media/validation_report.json`, `qa/media/qa_report.json` |
| Joint measurements | `python qa/media/tools/measure_poses.py` |

## 1. How to review

1. Confirm the same athlete in all four posters at a glance: graphite top,
   graphite shorts, lime visor, lime sleeve cuffs, lime wristbands, lime
   waistband, lime shoe soles, no facial features.
2. Watch both loops once end to end. Confirm there is one continuous motion:
   neutral start → correct depth → return to neutral, no teleporting, no limb
   passing through the body, feet/hands planted where the cues say.
3. Compare each loop against the numbered criteria in §3 and §4.
4. Read the poster cues at the simulated 360 dp size and confirm they are
   legible and that the wording is honest.
5. Record the verdict per exercise in §6 with your name, date and the asset
   hashes from §5. Anything you cannot verify stays unchecked and the asset
   stays excluded from release.

## 2. Scope guardrails

- The demonstrations are instructional. They do not verify form, do not count
  reps and do not override the task `03` camera counter thresholds.
- Do not approve copy that implies automatic form scoring or CV verification.
- The mannequin cannot show butt-wink, heel rise, scapular control, bracing or
  muscle engagement. If any of those is required for release, the clamp is to
  re-render with a humanoid mesh and a qualified movement specialist; record it
  in §8 instead of approving the current media.

## 3. Push-up criteria (`pushups`, clip `PushUp_Demo`)

| # | Criterion | Reference in the animation | Pass |
| --- | --- | --- | --- |
| P1 | Same athlete and kit as the squat demo | one mesh, one material set, one lighting rig | ☐ |
| P2 | Start pose is a neutral high plank, not a pike or sag | body line shoulder→pelvis→ankle; elbow 159.5° | ☐ |
| P3 | Bottom depth with elbows ≈90° | elbow 91.2° at the bottom hold | ☐ |
| P4 | Chest lowers toward the floor without touching through it | shoulder 0.580 m → 0.363 m; chest surface ≈0.20 m at the bottom | ☐ |
| P5 | Hands stay planted, roughly under/slightly outside the shoulders | wrist fixed at height 0.055 m, z ±0.235 | ☐ |
| P6 | Elbows track back at roughly 45°, not flared to 90° | IK pole behind and outside the shoulder | ☐ |
| P7 | Hips never sag below or pike above the shoulder–ankle line | pelvis stays on the line in every frame | ☐ |
| P8 | Ankles stay plantar-flexed with the ball of foot on the floor | ball at 0.030 m, heel up | ☐ |
| P9 | Head/neck remain neutral, gaze forward-down | head direction is the body line lifted 25° | ☐ |
| P10 | Loop returns exactly to the start pose | last sample equals first sample | ☐ |
| P11 | Cue copy matches the motion and is instructional | poster cues "Elbows about 90°", "Chest near the floor", "Head to heels in one line" | ☐ |
| P12 | Cues and annotations are legible at 360 dp | smallest cue 15.5 dp at 360 dp, 14.1 dp at a 328 dp card | ☐ |

## 4. Squat criteria (`squats`, clip `Squat_Demo`)

| # | Criterion | Reference in the animation | Pass |
| --- | --- | --- | --- |
| S1 | Same athlete and kit as the push-up demo | shared mesh/materials/lighting | ☐ |
| S2 | Neutral start: tall stance, feet about shoulder width | ankle z ±0.160, knees 175.5°, torso 0° | ☐ |
| S3 | Bottom depth: hip crease below the knee joint | hip 0.600 m vs knee 0.462 m (0.138 m below) | ☐ |
| S4 | Knees track forward over the mid-foot in the sagittal plane | knee 0.193 m forward of the ankle at the bottom | ☐ |
| S5 | Heels stay down through the whole descent | ankle fixed at 0.095 m, flat foot in every frame | ☐ |
| S6 | Torso leans forward without collapsing | 0° → 15° → 30° | ☐ |
| S7 | Arms counterbalance forward and return to the side | wrist target path, elbow 138° at the bottom | ☐ |
| S8 | Knees do not hyperextend at the top | minimum knee bend 4° (176°) | ☐ |
| S9 | Loop returns exactly to the start pose | last sample equals first sample | ☐ |
| S10 | Cue copy matches the motion and is instructional | "Hips below knees", "Knees track over toes", "Feet shoulder-width" | ☐ |
| S11 | Cues and annotations are legible at 360 dp | same measurements as P12 | ☐ |
| S12 | The poster does not hide the joints it asks the athlete to check | knee/hip bar drawn beside the leg, plates in the free gutter | ☐ |

## 5. Asset hashes at review time

Generated 2026-09-17T00:00:00Z. If any file is regenerated these hashes change
and the review restarts.

| Key | Asset | Bytes | SHA-256 |
| --- | --- | --- | --- |
| `models.athlete` | `assets/media/athlete/models/athlete_mannequin_v1.glb` | 173972 | `380f94a0a2f9d199f42c08fd4887864ec4991eee2637cd978c8f67400f3d04f3` |
| `pushups.loop_mp4` | `assets/media/athlete/loops/pushup_loop.mp4` | 42538 | `552d982c3ee1fe594ce756cfb89d18cc42214ee53e15ab933de4f1b0eddbd36c` |
| `pushups.poster_start` | `assets/media/athlete/posters/pushup_start.webp` | 20168 | `9d0265e369e1098d73eb6e8c1cdace056f2c3d0bd93e97a9338a401b5ffee9a5` |
| `pushups.poster_end` | `assets/media/athlete/posters/pushup_end.webp` | 19846 | `0c8f5cc3bbb0ce1fa6d43247280fa7d26bc2aa2a2d38292c9f2569d7edcbc9eb` |
| `pushups.poster_start_png` | `assets/media/athlete/posters/pushup_start.png` | 69928 | `6685633174a69f0c3c290a8c21dd2ad84ceff57e79602bf598332a3abddc2a04` |
| `squats.loop_mp4` | `assets/media/athlete/loops/squat_loop.mp4` | 61609 | `b760fdcdbc6bf5901d5dfde7e46575f4fd3c2fbc4742bb6de47d44bc320c7137` |
| `squats.poster_start` | `assets/media/athlete/posters/squat_start.webp` | 15546 | `935891dadf9c18aac2f86ee1c5b146b5b8c42efa6322ae112bacea3130c80b2a` |
| `squats.poster_end` | `assets/media/athlete/posters/squat_end.webp` | 20280 | `be1a5eecc366fa2485b3acec3f2fbd20cb209678844586a77f3a93c5e8275e47` |
| `squats.poster_start_png` | `assets/media/athlete/posters/squat_start.png` | 56207 | `087b16ffc832a013a1b48e093c507589bc4b232006110c38d6bc884c7ceed00a` |

The complete list (25 entries, including frames and overlays) is printed by
`python qa/media/tools/hash_table.py` and stored in
`app/assets/media/athlete/manifest.json` (`assets[].sha256`).

## 6. Sign-off

| Exercise | Reviewed by | Date | Verdict (approved / changes required) | Notes | Asset hash confirmed |
| --- | --- | --- | --- | --- | --- |
| `pushups` |  |  |  |  | ☐ |
| `squats` |  |  |  |  | ☐ |
| Overlays and poster copy |  |  |  |  | ☐ |
| Placeholder text (`missing_media_policy.placeholder`) |  |  |  |  | ☐ |

After approving, the reviewer (or the media owner on the reviewer's written
authority) must for each shipped asset in `manifest.json`:

1. set `"review_status": "approved"`,
2. add `"review": {"reviewer": "<name>", "reviewed_at": "<ISO date>", "reviewed_asset_sha256": "<sha256>"}`,
3. set the exercise `review.status`, `review.reviewer`, `review.reviewed_at`,
4. re-run `python qa/media/tools/validate_media_package.py --gate release`.

## 7. Reviewer requirements

The reviewer must be able to assess push-up and squat technique (for example a
certified strength coach, physiotherapist or equivalent trainer). A product
reviewer alone can approve copy, layout and provenance but not form accuracy.
The review is a human judgement with the assets as evidence; it is not a
computer-vision check and must not be described as one.

## 8. Unresolved questions and blockers

Blocking before release:

1. **Human form review has not happened.** Every asset is `pending_human_review`
   and excluded from release builds by the gate. Exact blocking list (all 25
   manifest entries) is printed by the release gate.
2. **`app/pubspec.yaml` does not declare the media asset directories** (task
   `00` owns that file, task `02` must not edit its `flutter:` section). Until
   the six lines in `docs/media/ATHLETE_SPEC.md` §7 are added by the owner, the
   app cannot bundle or load the package. Tracked in
   `docs/decisions/02-athlete-media-interface-note.md`.
3. **No in-app integration exists yet.** Task `07` must render the loop /
   poster / overlay through the manifest fallback chain; task `07` owns the
   demonstration widget.

Open questions for the reviewer or the owner:

- Q1 Is the neutral standing start acceptable for the push-up poster, or should
  the push-up start poster use a mid-rep held plank pose (currently the top
  hold, 0.19 s)?
- Q2 Is the cue wording ("Chest near the floor", "Elbows about 90°") precise
  enough, or should it match a specific coaching standard the product wants?
- Q3 On the squat bottom poster the top cue plate overlaps the hands slightly;
  accept, move the plate, or shorten the cue?
- Q4 Should the athlete read as a specific sex/build? The current mannequin is
  deliberately generic; a gendered build would need an owner decision and a new
  review.
- Q5 Is a 1:1 asset with `BoxFit.contain` acceptable in the 3:4/4:3 media frame,
  or is a native 4:3 render required (regeneration is cheap, see ATHLETE_SPEC §9)?
- Q6 Should the package also ship a slower "learn" loop (0.5× speed) for
  first-time users, or is the 2.4 s / 3.0 s loop pace right?
- Q7 Does the reviewer require the 4° knee-bend safety minimum to read as a
  soft knee, or may the leg be perfectly straight at the start?
