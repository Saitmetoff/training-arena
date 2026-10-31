# Interface note 02 — 3D athlete media package

Date: 2026-09-17
Author: task `02` (3D athlete demonstration media)
Status: informational note; one cross-task action requested from the baseline
owner (theme `flutter:` section) and one from task `07` (in-app integration)

## Why this note exists

`prompts/02_3D_ATHLETE_MEDIA.md` requires reading the product contract and the
design system before working. When this task started, `docs/CONTRACT.md`,
`docs/PROJECT_STATUS.md`, `design/arena/` and `prototype/` did not exist yet
(task `00` and task `01` were still landing). Per `prompts/README.md`, an early
chat must inspect the repository and write an interface note instead of
inventing a competing contract.

The contract used while the baseline was missing is the non-negotiable list in
`prompts/00_RECONCILE_AND_BOOTSTRAP.md` and the visual contract in
`prompts/01_DESIGN_SYSTEM_AND_PROTOTYPE.md`. Both were later confirmed by the
landed `docs/CONTRACT.md` (scope, palette, `ArenaExercise` wire values
`pushups`/`squats`) and `design/arena/tokens.json` (palette, type, spacing).
This task consumed `design/arena/tokens.json` directly: the athlete's accent is
the exact `player` token and the workspace is charcoal, so no competing palette
was introduced.

`D:\Kiro` was not read or modified. No FitBattle media was copied, imported or
referenced; the package is generated from scratch in this repository.

## What this task delivered

- `app/assets/media/athlete/` — one rigged mannequin athlete
  (`models/athlete_mannequin_v1.glb`, two clips), MP4 + animated WebP loops,
  WebP still frames, lossless cue overlays, annotated WebP/PNG posters, and
  `manifest.json`.
- `docs/media/ATHLETE_SPEC.md` — proportions, colours, camera, clip names,
  compression, fallback behaviour, integration and regeneration.
- `docs/media/FORM_REVIEW.md` — reviewer checklist, criteria, hash table,
  sign-off fields, unresolved questions, blocking list.
- `docs/media/PROVENANCE.md` — generation record, licence statement, hashes.
- `qa/media/` — contact sheets, identity strip, loop key frames, 360 dp
  legibility proof, GLB round-trip check, validation reports, generator tools.

Owned paths only: `app/assets/media/`, `docs/media/`, `qa/media/` (plus this
note). No camera, backend, Android manifest, Dart or pubspec file was modified.

## Interfaces other tasks can rely on

Manifest schema `app.trainingarena.media/athlete-manifest@1` at
`assets/media/athlete/manifest.json`:

- `models.athlete` — GLB with clips `PushUp_Demo` and `Squat_Demo`.
- `exercises.pushups` / `exercises.squats` — each with `label`, `clip`,
  `duration_s`, `assets.{glb,loop_mp4,loop_webp,frame_start,frame_mid,frame_end,overlay_start,overlay_end,poster_start,poster_end,poster_start_png,poster_end_png}`
  and a `fallback_chain`.
- Every entry has `asset` (Flutter key), `bytes`, `sha256` and `review_status`.
  All entries are `pending_human_review` and the package is `release_eligible:
  false`; the release gate in `qa/media/tools/validate_media_package.py`
  enforces that unreviewed media never ships.
- Resolution order is `loop_mp4 → loop_webp → poster_start(.webp) →
  poster_start.png → placeholder`. The PNG poster is the guaranteed terminal
  asset; the placeholder is an app-drawn text card (`missing_media_policy`).
  A missing or undecodable asset must never produce a blank frame.

Fixed media facts (do not re-derive):

- Shared view: three-quarter right, azimuth 70°, elevation 9°, 30° lens,
  4.218 m, 512 × 512, 25 fps. Squats are recentred 0.26 m along the
  screen-right axis; scale is identical in both exercises.
- Overlays are 512 × 512 lossless WebP with alpha, drawn to composite over the
  loop at the same size; posters are the same frame plus the overlay plus a
  header strip.
- Asset size budgets and current sizes: `qa/media/validation_report.json`.
- The camera counter's thresholds are **not** in this package. Counting,
  tracking and rep validation stay in task `03`; the demonstrations are
  instructional only.

## Request to the baseline owner (task `00`)

`app/pubspec.yaml` does not declare the media asset directories, and task `02`
must not edit the pubspec `flutter:` section. Add these entries (nothing else
changes) so the shell can bundle the package:

```yaml
  assets:
    - assets/media/athlete/manifest.json
    - assets/media/athlete/models/
    - assets/media/athlete/loops/
    - assets/media/athlete/frames/
    - assets/media/athlete/overlays/
    - assets/media/athlete/posters/
```

Until this is applied the files exist and validate on disk, but a Flutter build
cannot load them. This is recorded as a release blocker in
`docs/media/FORM_REVIEW.md` §8.

## Request to task `07` (battle runtime UI)

- Replace the `3D demonstration placeholder` in preparation with the manifest
  fallback chain, and keep the "instructional, not a rep counter" wording.
- Render the square asset with `BoxFit.contain` on the charcoal canvas (the
  letterbox is invisible against the matching backdrop). A native 4:3 variant
  can be generated on request; see `ATHLETE_SPEC.md` §4.
- Do not imply that the animation verifies form or counts reps; live counts
  come only from task `03`.

## Response to `design/arena/PROTOTYPE_GAPS.md` gap 5

Exit criteria were "Reviewed push-up and squat animations shipped with poster
fallbacks and provenance". Animations, poster fallbacks, provenance and QA
evidence are shipped. "Reviewed" is **not** satisfied: a qualified human form
review has not happened, so every asset stays `pending_human_review` and out of
release builds. Task `10` should treat the media as reviewable design-preview
evidence, not as approved production media.

## Open items

1. Human form review (`docs/media/FORM_REVIEW.md` §§6–8).
2. Pubspec asset declaration (task `00`, above).
3. In-app integration (task `07`, above).
4. Reviewer questions Q1–Q7 in `docs/media/FORM_REVIEW.md` §8.
