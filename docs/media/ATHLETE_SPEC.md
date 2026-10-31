# Athlete media specification

Version 1.0.0 · built 2026-09-17 · owned by task `02`
Package: `app/assets/media/athlete/` · manifest: `app/assets/media/athlete/manifest.json`
Palette source of truth: `design/arena/tokens.json` (consumed, never redefined here)

One rigged mannequin athlete demonstrates both arena exercises. The athlete is
a deliberately stylised training mannequin, not a scanned or photographed
person: no real likeness, no facial features, no copyrighted third-party model.

## 1. Identity

| Property | Value |
| --- | --- |
| Athlete id | `arena-mannequin-v1` |
| Name | Arena Mannequin Athlete v1 |
| Mesh | single skinned mesh, 2 868 vertices, 3 597 triangles, 7 materials |
| Rig | 19 bones, rigid bind (one bone per vertex, weight 1.0), no blendshapes |
| Clips | `PushUp_Demo`, `Squat_Demo` (both in `models/athlete_mannequin_v1.glb`) |
| Height | 1.75 m, ≈7.8 heads, shoulder width 0.44 m |
| World axes | +X forward, +Y up, +Z athlete's right (right-handed) |

Rigid skinning is intentional: joints read as clean mannequin articulations and
the silhouette never tears, which is what makes form legible at small sizes.

## 2. Proportions (metres)

| Landmark | Value |
| --- | --- |
| Total height | 1.750 |
| Head centre / radius | 1.638 / 0.112 |
| Shoulder joint | 1.420, ±0.190 lateral |
| Elbow / wrist | 1.140 / 0.880 |
| Hip joint | 0.950, ±0.105 lateral |
| Knee / ankle | 0.510 (z ±0.150) / 0.095 (z ±0.160) |
| Ball of foot | 0.030 high, 0.18 forward |
| Upper arm / forearm | 0.281 / 0.260 |
| Thigh / shin / foot | 0.442 / 0.415 / 0.192 |
| Pelvis → shoulder centre | 0.490 |

Feet are 0.32 m apart laterally at the ankles: "shoulder-width" for this build.

## 3. Colours and materials

Material colours are baked into the GLB as `baseColorFactor` (no textures), so
the athlete is a few kilobytes instead of a texture atlas. UI roles are taken
from the design tokens; the kit tones are media-only derivations that keep the
athlete readable on a charcoal background. The accent is the exact token value.

| Material | Hex | Source |
| --- | --- | --- |
| `accent` (visor, cuffs, wristbands, waistband, chest mark, shoe soles) | `#D6FF3F` | token `player`, exact |
| `kit_top` (training top) | `#3A4145` | derived from token `raised` `#303537`, +12 % value |
| `kit_bottom` (shorts) | `#2B3033` | derived from token `surface` `#242729`, +8 % value |
| `skin` (head, forearms, legs) | `#C9AC8E` | media-only neutral |
| `hair` (short cap, no style reference) | `#1B1E20` | media-only, charcoal family |
| `glove` (hands) | `#32383A` | media-only |
| `shoe` (upper) | `#22272A` | media-only |
| backdrop | `#131516` → `#1D2022` vertical | media-only charcoal variants |

Violet (`#BEA1FF`) is reserved for the opponent and is **never** used in
athlete media. There is no competing accent palette.

Lighting is a fixed three-light studio rig expressed in camera space so the
athlete looks identical in both exercises and on every screen: key light from
screen-left-top (warm white, 0.88), fill from screen-right (cool grey, 0.45),
lime rim from behind (0.55) to separate the silhouette, plus a cool ambient
(0.24). No environment maps, no textures, no randomness.

## 4. Camera

| Parameter | Value |
| --- | --- |
| View | three-quarter right (athlete's front-right) |
| Azimuth / elevation | 70° from the athlete's forward direction / 9° |
| Lens | 30° vertical field of view (≈equivalently a long phone lens) |
| Distance | 4.218 m to the aim point |
| Frame | 512 × 512 px, 25 fps |
| Safe area | subject stays inside 84 % of the frame |
| Aim point | push-ups `(0.95, 0.40, 0.00)`, squats `(-0.19, 0.87, 0.09)` |

Both exercises share azimuth, elevation, lens, distance and world scale, so the
athlete is exactly the same size in both. Only the aim point is recentred
(squats are nudged 0.26 m along the screen-right axis) so the squat sits beside
its cue plates instead of behind them. This is the documented interpretation of
"same camera framing": same view, same scale, per-pose centring.

Integration note for the 3:4 / 4:3 media frame in `COMPONENT_INVENTORY.md`:
render the square asset with `BoxFit.contain` on the charcoal canvas — the
backdrop is the same charcoal family, so the letterbox is invisible. If task
`07` prefers a native 4:3 asset, the generator can emit one; the aim points and
plate layout would need a short re-tune (recorded in `PROTOTYPE_GAPS`-style).

## 5. Animation

Both clips are authored from body landmarks plus two-bone IK, so ground contact
and limb lengths always hold. Each clip starts and ends on the neutral standing
pose and loops seamlessly (`loop: true` in the manifest).

| Clip | Duration | Frames (GLB) | Timeline |
| --- | --- | --- | --- |
| `PushUp_Demo` | 2.40 s | 0…2.40 s, 25 fps (61 samples, last = first) | top hold 0.19 s → descend 0.82 s → bottom hold 0.31 s → return 0.96 s |
| `Squat_Demo` | 3.00 s | 0…3.00 s, 25 fps (76 samples, last = first) | stand hold 0.30 s → descend 1.08 s → bottom hold 0.42 s → return 1.11 s |

Measured key poses (see `qa/media/tools/measure_poses.py`):

| Pose | Push-up elbow | Push-up knee | Squat knee | Squat torso lean | Hip height |
| --- | --- | --- | --- | --- | --- |
| start | 159.5° | 176.0° | 175.5° | 0° | 0.950 |
| mid | 111.1° | 176.0° | 107.2° | 15° | 0.774 |
| end (bottom) | 91.2° | 176.0° | 80.4° | 30° | 0.600 |

Push-up: hands fixed at wrist height 0.055 m, hands slightly outside the
shoulders (z ±0.235), shoulders travel from 0.580 m to 0.363 m, the body stays
one straight line from the shoulder centre through the pelvis to the ankle, the
ball of the foot stays on the floor (plantar-flexed ankle, heel up).

Squat: ankles stay at 0.095 m with a flat foot, the hip crease finishes 0.138 m
below the knee joint, the knee tracks forward over the mid-foot, arms extend
forward for balance and return to the side. No butt-wink or heel-rise is
representable with a rigid rig, so those two real-world faults are **not**
covered by the demonstration (recorded in `FORM_REVIEW.md`).

## 6. Assets and compression

| Role | Files | Format |
| --- | --- | --- |
| Interactive model | `models/athlete_mannequin_v1.glb` | glTF 2.0 binary, no textures, per-material primitives, `LINEAR` samplers, uint8 joints/weights, 170 KiB |
| Loop video | `loops/{pushup,squat}_loop.mp4` | H.264 high, `yuv420p`, CRF 26, `+faststart`, no audio, 42 / 60 KiB |
| Loop video (alt) | `loops/{pushup,squat}_loop.webp` | animated WebP, q 70, loop forever, 273 / 336 KiB |
| Still fallback | `frames/{stem}_{start,mid,end}.webp` | WebP q 84, method 6, 5–7 KiB |
| Cue overlay | `overlays/{stem}_{start,end}.webp` | lossless WebP with alpha, 6–7 KiB |
| Poster fallback | `posters/{stem}_{start,end}.webp` / `.png` | WebP q 84 19–20 KiB / optimised PNG 55–80 KiB |

Budgets are enforced per file by `qa/media/tools/validate_media_package.py`
(GLB ≤ 400 KiB, MP4 ≤ 450 KiB, animated WebP ≤ 900 KiB, WebP poster ≤ 90 KiB,
PNG poster ≤ 220 KiB, still ≤ 70 KiB, overlay ≤ 60 KiB, package ≤ 3.5 MiB).
Current package total: 1.29 MiB over 23 unique files.

Text in overlays and posters uses the bundled Inter family (task `00`) at
22–30 px inside the 512 px frame; the smallest cue is 14.1 dp when the poster
is shown 328 dp wide and 15.5 dp at 360 dp, so cues stay legible on the target
screen (`qa/media/legibility_360dp.png` records the measurement).

## 7. Manifest and fallback behaviour

`manifest.json` is the app-facing contract. Every entry carries its Flutter
asset key, byte size, SHA-256 and `review_status`.

Resolution order for the demonstration media (never a blank frame):

1. `loops/<stem>_loop.mp4` — hardware decode, smallest file
2. `loops/<stem>_loop.webp` — animated WebP when MP4 decode is unavailable
3. `posters/<stem>_start.webp` — annotated poster, WebP decoder
4. `posters/<stem>_start.png` — annotated poster, guaranteed decode (always bundled)
5. `placeholder` — app-drawn text card, used only when no media is approved or bundled

Release builds must omit any asset whose `review_status` is not `approved`
(the release gate fails until a human signs `docs/media/FORM_REVIEW.md`). An
empty or missing media list, a decode failure or an absent file must render
step 4 (or step 5), never an empty image region.

Lazy-load order: read `manifest.json` at startup (12 KiB); load the start
poster when the preparation screen becomes visible; start the loop only when
the demonstration widget is on screen and the device is not in
reduced-motion/power-save mode; load the GLB only when a 3D viewer is shown.

Offline: all assets are local files, there is no network fetch, no account and
no upload path. Camera frames are never part of this package.

### Flutter wiring (pending owner action)

`app/pubspec.yaml` is owned by task `00`; task `02` must not edit the fonts
section. Add these asset entries to bundle the package (the interface note
`docs/decisions/02-athlete-media-interface-note.md` requests it):

```yaml
  assets:
    - assets/media/athlete/manifest.json
    - assets/media/athlete/models/
    - assets/media/athlete/loops/
    - assets/media/athlete/frames/
    - assets/media/athlete/overlays/
    - assets/media/athlete/posters/
```

## 8. Scope

The demonstrations are an instructional reference for the preparation screen.
They are not a rep counter, not a scoring authority and not computer-vision
verification. Counting thresholds, tracking loss and rep validation belong to
task `03` and live in `app/lib/camera/`; this package makes no claim about
them. Copy inside the poster header states `instructional, not a rep counter`.

## 9. Regeneration

```powershell
python qa/media/tools/build.py            # assets + manifest (about 25 s)
python qa/media/tools/qa_report.py        # reviewer sheets and checks
python qa/media/tools/validate_media_package.py
python qa/media/tools/validate_media_package.py --gate release
python qa/media/tools/measure_poses.py    # printed joint measurements
```

Builds are deterministic: the timestamp comes from `ARENA_MEDIA_TIMESTAMP`
(default `2026-09-17T00:00:00Z`) and ffmpeg runs with `+bitexact`, so re-running
the same code reproduces the same bytes and hashes. Any content change resets
the recorded hashes, so the reviewer table and manifest `review_status` must be
re-approved after a regeneration.

Known limitations, accepted for v1:

- No textures or cloth simulation; a rigid mannequin look is intended.
- Rigid skinning cannot show butt-wink, heel rise, scapular movement or muscle
  engagement; only the gross joint angles and body line are demonstrated.
- Frames are 1:1 and authored for `BoxFit.contain` in the app's media frame.
- The hands and feet are simplified boxes; the face has no features on purpose.
