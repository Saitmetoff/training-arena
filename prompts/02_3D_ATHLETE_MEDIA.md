# Task 02 — create the consistent 3D athlete demonstration package

You own the exercise media package for Training Arena. Work only in `D:\TrainingArena`, and read the product contract and design system first. Do not touch the camera algorithm, backend or production screen code owned by other prompts. Never use the old FitBattle media as if it were approved production media.

## Goal

Deliver one recognizable 3D athlete used consistently for both exercise demonstrations. The athlete should make form easy to understand on a phone, fit the charcoal/lime/violet identity and be safe to review before release.

## Requirements

- Create or procure one rigged, redistributable 3D human with neutral appearance, graphite training clothes and small lime identity accents. Keep face/skin/hair details respectful and avoid a real person’s likeness without permission.
- Produce two reviewed demonstrations: a push-up and a squat. Each has a neutral start pose, correct depth/end pose, return path, side or three-quarter camera view, consistent scale and a short loop or still fallback.
- Export lightweight mobile assets (for example GLB/GLTF plus pre-rendered MP4/WebP fallback) with licenses and provenance. Include poster frames and high-contrast annotation overlays for start/end/form cues. Keep files small enough for a first launch and lazy-load them.
- Use the exact same athlete, clothing, lighting language and camera framing in both exercises. Do not ship generated imagery as “verified” form until a human reviewer approves it.
- Keep demonstrations instructional, not a scoring authority. The camera counter’s thresholds remain documented in task `03`.

## Deliverables

- `app/assets/media/athlete/` with optimized assets and poster frames.
- `docs/media/ATHLETE_SPEC.md` describing proportions, colors, camera, animation names, compression and fallback behavior.
- `docs/media/FORM_REVIEW.md` with reviewer checklist, push-up/squat criteria, reviewer/date/asset hash fields and unresolved questions.
- `docs/media/PROVENANCE.md` with source/license or generation record; do not include private credentials.
- `qa/media/` with contact sheets or rendered reference frames that a reviewer can compare across exercises.
- A small asset manifest consumed by the app; missing media must resolve to a deliberate poster/fallback, never a blank frame.

## Acceptance checks

- A reviewer can identify the same athlete in both demonstrations at a glance.
- Start/end poses, camera framing and form cues are legible on a 360dp-wide screen.
- Assets load offline from the packaged fallback and do not require raw video upload or a network account.
- Every shipped file has a license/provenance entry and human review status. Unreviewed assets are clearly marked and excluded from release builds.
- The package does not claim computer-vision verification merely because a 3D animation exists.

If a true production asset cannot be completed in this task, deliver the exact blocking list and keep only clearly labeled design-preview assets in the prototype path.

