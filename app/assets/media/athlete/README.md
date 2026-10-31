# Athlete media package

One rigged mannequin athlete demonstrates both arena exercises. Everything here
is generated in-repo; see `docs/media/PROVENANCE.md`. All assets are currently
**pending human review** and excluded from release builds.

Start with `manifest.json`. Do not hard-code file names.

## Resolution order (never a blank frame)

1. `loops/{pushup,squat}_loop.mp4` — 512² H.264, no audio, ~42–60 KiB
2. `loops/{pushup,squat}_loop.webp` — animated WebP fallback
3. `posters/{pushup,squat}_start.webp` — annotated poster still
4. `posters/{pushup,squat}_start.png` — guaranteed-decode poster (always bundled)
5. `missing_media_policy.placeholder` — app-drawn text card, no media

```dart
final manifest = jsonDecode(await rootBundle.loadString(
  'assets/media/athlete/manifest.json',
));
final demo = manifest['exercises']['pushups'];   // or 'squats'
final loop = demo['assets']['loop_mp4']['asset']; // then fallback_chain
```

## Contents

| Path | What it is |
| --- | --- |
| `manifest.json` | Asset keys, sizes, SHA-256, review status, fallback chain |
| `models/athlete_mannequin_v1.glb` | Rigged athlete, clips `PushUp_Demo`, `Squat_Demo` |
| `loops/` | Loop videos (MP4 and animated WebP), 25 fps |
| `frames/` | Clean stills: `_start`, `_mid`, `_end` per exercise |
| `overlays/` | 512² alpha cue overlays for the start and end poses |
| `posters/` | Annotated fallback posters (WebP + PNG) |

Budgets, camera, proportions, colours and regeneration commands live in
`docs/media/ATHLETE_SPEC.md`. Human review lives in
`docs/media/FORM_REVIEW.md`. Provenance and licences live in
`docs/media/PROVENANCE.md`.

Rebuild: `python qa/media/tools/build.py` (about 25 s). Validate:
`python qa/media/tools/validate_media_package.py`.
